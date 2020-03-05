
provider "aws" {
}
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  required_tags = {
    "Environment"    = "${var.build_environment}"
    "AutomationType" = "terraform"
    "Application-name" = "AWS Sample CICD App"
  }
}

module "patch" {
  source               = "./patch"
  build_environment    = "${var.build_environment}"
  core-environment     = "non-prod"
  tags                 = "${local.required_tags}"
}
