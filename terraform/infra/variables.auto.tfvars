# common
aws_region              = "eu-central-1"
route53_domain_name     = "rootin.cc"
route53_zone_id         = "Z04900351YJJ9CUR7BRAT"
alb_acm_certificate_arn = "arn:aws:acm:eu-central-1:623550112002:certificate/99a4631c-4334-41f3-af19-7f75a2ded363"


# networking variables
cluster_name            = "sukhova-eks"
iac_environment_tag     = "development"
name_prefix             = "sukhova"
main_network_block      = "10.0.0.0/16"
subnet_prefix_extension = 4
zone_offset             = 8

