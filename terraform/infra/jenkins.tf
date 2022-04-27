module myip {
  source  = "4ops/myip/http"
  version = "1.0.0"
}

// An example of creating a KMS key
resource "aws_kms_key" "efs_kms_key" {
  description = "KMS key used to encrypt Jenkins EFS volume"
}

module "serverless_jenkins" {
  source                          = "./modules/jenkins_platform"
  name_prefix                     = local.name_prefix
  tags                            = local.tags
  vpc_id                          = module.vpc.vpc_id
  efs_kms_key_arn                 = aws_kms_key.efs_kms_key.arn
  efs_subnet_ids                  = module.vpc.private_subnets
  jenkins_controller_subnet_ids   = module.vpc.private_subnets
  alb_subnet_ids                  = module.vpc.public_subnets
  alb_ingress_allow_cidrs         = ["0.0.0.0/0"]
  alb_acm_certificate_arn         = var.alb_acm_certificate_arn
  route53_create_alias            = true
  route53_alias_name              = var.jenkins_dns_alias
  route53_zone_id                 = var.route53_zone_id
}

