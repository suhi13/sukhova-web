#------------------------------------------------------------------------------
# ECR
#------------------------------------------------------------------------------
resource "aws_ecr_repository" "api" {
  name                 =  "${var.name_prefix}-api"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration  {
      scan_on_push = true
  }
}

resource "aws_ecr_repository" "frontend" {
  name                 =  "${var.name_prefix}-frontend"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration  {
      scan_on_push = true
  }
}

resource "aws_ecr_repository" "admin" {
  name                 =  "${var.name_prefix}-admin"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration  {
      scan_on_push = true
  }
}
