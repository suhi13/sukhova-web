data "aws_caller_identity" "current" {}

data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket  = "tf-sukhova-20220401"
    key     = "infra.tfstate"
    region  = "eu-central-1"
  }
}