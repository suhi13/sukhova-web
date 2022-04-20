terraform {
  required_version = ">= 0.13"
  backend "s3" {
    bucket  = "tf-sukhova-20220401"
    key     = "infra"
    encrypt = true
    region  = "eu-central-1"
  }
}

provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  token                  = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
}
