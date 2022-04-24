################################################################################
# Creating Role for EC2 instances
################################################################################
data "aws_iam_policy_document" "jenkins_slave_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "jenkins_slave_role" {
  name               = "${var.name_prefix}-slave-role"
  assume_role_policy = data.aws_iam_policy_document.jenkins_slave_policy.json
}

resource "aws_iam_role_policy_attachment" "jenkins_slave_policy_attachment" {
  role       = aws_iam_role.jenkins_slave_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "jenkins_slave_admin_policy_attachment" {
  role       = aws_iam_role.jenkins_slave_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "jenkins_slave_profile" {
  name = "${var.name_prefix}-slave-profile"
  role = aws_iam_role.jenkins_slave_role.name
}

################################################################################
# Getting ECS optimized AMI
################################################################################

data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

##########################################
#  Creating Launch template and Auto Scaling group
##########################################
data "template_file" "user_data" {
  template = <<EOF
    #!/bin/bash
    echo ECS_CLUSTER=${var.name_prefix}-main >> /etc/ecs/ecs.config
  EOF
}

resource "aws_launch_template" "jenkins_slave_lt" {
  name          = "${var.name_prefix}-slave-lt"
  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = var.slave_instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.jenkins_slave_profile.name
  }
  // Avoiding cycle error
  user_data = base64encode(data.template_file.user_data.rendered)

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { "Name" = "${var.name_prefix}-slave" })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(var.tags, { "Name" = "${var.name_prefix}-slave" })
  }

  tags = var.tags

}

resource "aws_autoscaling_group" "jenkins_slave_asg" {
  name                  = "${var.name_prefix}-slave-asg"
  desired_capacity      = 0
  max_size              = 1
  min_size              = 0
  vpc_zone_identifier   = var.efs_subnet_ids
  health_check_type     = "EC2"
  protect_from_scale_in = true

  launch_template {
    id      = aws_launch_template.jenkins_slave_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "team"
    value               = "DevOps"
    propagate_at_launch = true
  }

  tag {
    key                 = "managed"
    value               = "terraform"
    propagate_at_launch = true
  }
  lifecycle {
    ignore_changes = [
      desired_capacity
    ]
  }
}

resource "aws_ecs_capacity_provider" "jenkins_slave_ec2_provider" {
  name = "${var.name_prefix}-EC2"
  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.jenkins_slave_asg.arn
    managed_termination_protection = "ENABLED"
    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}
