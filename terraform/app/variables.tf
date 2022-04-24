variable "name_prefix" {
  type        = string
  default     = "shopizer"
  description = "Prefix to be used on each infrastructure object Name created in AWS."
}

variable "aws_region" {
  default     = "eu-central-1"
  description = "AWS region"
}

