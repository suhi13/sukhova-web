locals {
  account_id  = data.aws_caller_identity.current.account_id
  name_prefix = var.name_prefix

  tags = {
    team     = "devops"
    solution = "jenkins"
  }
}
