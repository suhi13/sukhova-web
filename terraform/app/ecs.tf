#------------------------------------------------------------------------------
# ALB
#------------------------------------------------------------------------------
resource "aws_security_group" alb_security_group {
  name        = "${var.name_prefix}-app"
  description = "${var.name_prefix} alb security group"
  vpc_id      = data.terraform_remote_state.infra.outputs.vpc.vpc_id
  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP Public access"
  }
  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS Public access"
  }
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.tags
}

resource "aws_lb" this {
  name               = replace("${var.name_prefix}-app-alb", "_", "-")
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_security_group.id]
  subnets            = data.terraform_remote_state.infra.outputs.vpc.private_subnets
  tags               = local.tags
}

resource "aws_lb_listener" http {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" https {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-FS-1-2-Res-2019-08"
  certificate_arn   = var.alb_acm_certificate_arn
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content"
      status_code  = "200"
    }
  }
}

#------------------------------------------------------------------------------
# ECS Cluster
#------------------------------------------------------------------------------
module "ecs-cluster" {
  source    = "cn-terraform/ecs-cluster/aws"
  version   = "1.0.9"
  name      = "${var.name_prefix}-app"
  tags      = local.tags
}

resource "aws_service_discovery_private_dns_namespace" "app" {
  name        = var.name_prefix
  vpc         = data.terraform_remote_state.infra.outputs.vpc.vpc_id
  description = "Application discovery managed zone."
}

#------------------------------------------------------------------------------
# ECS Task Definitions
#------------------------------------------------------------------------------
module "task-definition-api" {
  source          = "cn-terraform/ecs-fargate-task-definition/aws"
  name_prefix     = "${var.name_prefix}-api"
  container_name  = "${var.name_prefix}-api:${var.image_tag}"
  container_image = aws_ecr_repository.api.repository_url
}

#------------------------------------------------------------------------------
# API ECS Service
#------------------------------------------------------------------------------
resource "aws_security_group" api_security_group {
  name        = "${var.name_prefix}-api"
  description = "${var.name_prefix} API security group"
  vpc_id      = data.terraform_remote_state.infra.outputs.vpc.vpc_id

  ingress {
    protocol        = "tcp"
    self            = true
    security_groups = [aws_security_group.alb_security_group.id]
    from_port       = 80
    to_port         = 80
    description     = "Communication channel to API"
  }
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.tags
}

resource "aws_lb_target_group" api {
  name        = replace("${var.name_prefix}-api", "_", "-")
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.infra.outputs.vpc.vpc_id
  target_type = "ip"

  health_check {
    enabled = true
    path    = "/"
  }
  tags       = local.tags
  depends_on = [aws_lb.this]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener_rule" api_rule {
  listener_arn = aws_lb_listener.https.arn
  priority     = 10
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
  condition {
    host_header {
      values = ["api.*"]
    }
  }
}

resource "aws_ecs_service" api {
  name             = "${var.name_prefix}-api"
  task_definition  = module.task-definition-api.aws_ecs_task_definition_td_arn
  cluster          = module.ecs-cluster.aws_ecs_cluster_cluster_arn
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "1.4.0"
  service_registries {
    registry_arn  = aws_service_discovery_service.api.arn
    port          =  80
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "${var.name_prefix}-api"
    container_port   = 80
  }
  network_configuration {
    subnets          = data.terraform_remote_state.infra.outputs.vpc.private_subnets
    security_groups  = [aws_security_group.api_security_group.id]
    assign_public_ip = false
  }
  depends_on = [aws_lb_listener.https]
}

/*
resource "aws_route53_record" api {
  zone_id = var.route53_zone_id
  name    = var.route53_api_alias_name
  type    = "A"
  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}
*/
resource "aws_service_discovery_service" "api" {
  name = "${var.name_prefix}-api"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.app.id
    routing_policy = "MULTIVALUE"
    dns_records {
      ttl = 10
      type = "A"
    }
    dns_records {
      ttl  = 10
      type = "SRV"
    }
  }
  health_check_custom_config {
    failure_threshold = 5
  }
}
