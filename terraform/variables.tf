variable "build_environment" {
  type    = "string"
  default = "dev"
  description = "This is the build environment"
}

variable "sns_topic_name" {
  type    = "string"
  default = "aws-serverless-patching"
  description = "SNS topic name"
}
