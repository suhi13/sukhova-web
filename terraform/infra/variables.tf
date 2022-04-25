# VPC variables
variable "aws_region" {
  default     = "eu-central-1"
  description = "AWS region"
}
variable "cluster_name" {
  type        = string
  description = "EKS cluster name."
}
variable "iac_environment_tag" {
  type        = string
  description = "AWS tag to indicate environment name of each infrastructure object."
}
variable "name_prefix" {
  type        = string
  description = "Prefix to be used on each infrastructure object Name created in AWS."
}
variable "main_network_block" {
  type        = string
  description = "Base CIDR block to be used in our VPC."
}
variable "subnet_prefix_extension" {
  type        = number
  description = "CIDR block bits extension to calculate CIDR blocks of each subnetwork."
}
variable "zone_offset" {
  type        = number
  description = "CIDR block bits extension offset to calculate Public subnets, avoiding collisions with Private subnets."
}

# Jenkins
variable route53_domain_name {
  type        = string
  description = "The domain"
}

variable route53_zone_id {
  type        = string
  description = "The route53 zone id where DNS entries will be created"
}

variable jenkins_dns_alias {
  type        = string
  description = "The DNS alias to be associated with the deployed jenkins instance"
  default     = "jenkins"
}

variable alb_acm_certificate_arn {
  type        = string
  description = "The ACM certificate ARN to use for the alb"
}

