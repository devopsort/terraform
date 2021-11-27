resource "aws_ecr_repository" "repo-obl" {
  for_each = var.ECR_Repos
  name                 = each.value.name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}