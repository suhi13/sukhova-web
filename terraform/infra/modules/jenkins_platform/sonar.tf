data "template_file" sonar_container_def {
  template = file("${path.module}/templates/sonarqube.json.tpl")

  vars = {
    name                = "${var.name_prefix}-sonar"
    sonar_port          = 9000
    container_image     = var.sonarqube_image
    region              = local.region
    account_id          = local.account_id  
    log_group           = aws_cloudwatch_log_group.jenkins_controller_log_group.name
    memory              = var.jenkins_controller_memory
    cpu                 = var.jenkins_controller_cpu
  }
}

resource "aws_security_group" sonar_security_group {
  name        = "${var.name_prefix}-sonar"
  description = "${var.name_prefix} Sonarqube security group"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    self            = true
    security_groups = var.alb_create_security_group ? [aws_security_group.alb_security_group[0].id] : var.alb_security_group_ids
    from_port       = 9000
    to_port         = 9000
    description     = "Communication channel to Sonarqube"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_lb_target_group" sonar {
  name        = replace("${var.name_prefix}-sonar", "_", "-")
  port        = 9000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled = true
    path    = "/"
  }
  tags       = var.tags
  depends_on = [aws_lb.this]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener_rule" sonar_rule {
  listener_arn = aws_lb_listener.https.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sonar.arn
  }

  condition {
    host_header {
      values = ["sonar.*"]
    }
  }
}

resource "aws_route53_record" sonar {
  count = var.route53_create_alias ? 1 : 0

  zone_id = var.route53_zone_id
  name    = var.route53_sonar_alias_name
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}

resource "aws_ecs_task_definition" sonar {
  family                   = "${var.name_prefix}-sonar"
  task_role_arn            = var.jenkins_controller_task_role_arn != null ? var.jenkins_controller_task_role_arn : aws_iam_role.jenkins_controller_task_role.arn
  execution_role_arn       = var.ecs_execution_role_arn != null ? var.ecs_execution_role_arn : aws_iam_role.jenkins_controller_task_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.jenkins_controller_cpu
  memory                   = var.jenkins_controller_memory
  container_definitions    = data.template_file.sonar_container_def.rendered

  tags = var.tags
}

resource "aws_ecs_service" sonar {
  name             = "${var.name_prefix}-sonar"
  task_definition  = aws_ecs_task_definition.sonar.arn
  cluster          = aws_ecs_cluster.jenkins_controller.id
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "1.4.0"
  // Assuming we cannot have more than one instance at a time. Ever. 
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0
  service_registries {
    registry_arn  = aws_service_discovery_service.sonar.arn
    port          =  9000
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.sonar.arn
    container_name   = "${var.name_prefix}-sonar"
    container_port   = 9000
  }

  network_configuration {
    subnets          = var.jenkins_controller_subnet_ids
    security_groups  = [aws_security_group.sonar_security_group.id]
    assign_public_ip = false
  }

  depends_on = [aws_lb_listener.https]
}

resource "aws_service_discovery_service" "sonar" {
  name = "sonar"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.controller.id
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
