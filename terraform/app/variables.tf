variable "name_prefix" {
  type        = string
  default     = "shopizer"
  description = "Prefix to be used on each infrastructure object Name created in AWS."
}

variable "aws_region" {
  default     = "eu-central-1"
  description = "AWS region"
}

variable alb_acm_certificate_arn {
  type        = string
  description = "The ACM certificate ARN to use for the alb"
}

variable route53_zone_id {
  type    = string
  default = null
}

//variable route53_alias_name {
//  type    = string
//}

//variable app_dns_alias {
//  type        = string
//  description = "The DNS alias to be associated with the deployed application"
//}

variable image_tag {
  type    = string
  default = "latest"
}
