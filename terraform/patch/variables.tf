variable "build_environment" {
  type    = "string"
}

variable "computetype" {
  type    = "string"
  default = "BUILD_GENERAL1_SMALL"
  description = "Containter size for Code Build"
}

variable "containter_type" {
  type    = "string"
  default = "LINUX_CONTAINER"
  description = "Containter type for Code Build"

}

variable "codebuildPolicy" {
  type    = "string"
  default = "codebuild-patch-policy"
  description = "CodeBuild policy name"
}

variable "codebuildrolearn" {
  default = "codebuild-patch-role"
  type    = "string"
  description = "ARN name for CodeBuild role"
}

variable "codepipelinePolicy" {
  type    = "string"
  default = "codepipeline-patch-policy"
  description = "CodePipeline policy name"
}

variable "cbenv" {
  type    = "list"
  default = ["dev", "qa", "stg"]
  description ="List of environments"
}

variable "core-environment" {
  type    = "string"
  default = "non-prod"
}

variable "image_type" {
  type    = "string"
  default = "aws/codebuild/python:3.7.1"
  description = "Image type for Lambda function container"
}

variable "sns_topic_name" {
  type    = "string"
  default = "Patch"
  description = "SNS topic name"
}

variable "s3Policy" {
  type    = "string"
  default = "s3FullAccessPolicy"
  description = "S3 Bucket policy"
}

variable "s3Role" {
  type    = "string"
  default = "s3FullAccessRole"
  description = "S3 full role"
}

variable "region" {
  type = "string"
  default = "us-east-1"
  description = "Region to deploy the terraform in"
  
}


variable "tags" {
  description = "Additional Tags"
  type        = "map"
}
