terraform {
  required_version = ">= 0.13"
  backend "s3" {
    bucket  = "tf-sukhova-20220401"
    key     = "app.tfstate"
    encrypt = true
    region  = "eu-central-1"
  }
}

provider "aws" {
  region = var.aws_region
}

