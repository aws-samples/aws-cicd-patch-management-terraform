# CloudWatch Group

resource "aws_cloudwatch_log_group" "sdn_patch" {
  name  = "CICD_Pipeline"
  tags  = "${var.tags}"
}

resource "aws_sns_topic" "sns" {
  name  = "${var.sns_topic_name}"
  tags  = "${var.tags}"
}

# Bucket Policy

resource "aws_s3_bucket_policy" "b" {
  bucket = "${aws_s3_bucket.patch_bucket.id}"
  policy = "${data.template_file.bucket_policy.rendered}"
}

resource "aws_s3_bucket_policy" "c" {
  bucket = "${aws_s3_bucket.patch_bucket-script.id}"
  policy = "${data.template_file.bucket_policy2.rendered}"
}

# IAM Roles and Policy

resource "aws_iam_role" "iam_s3_role" {
  name               = "${var.s3Role}"
  assume_role_policy = "${data.template_file.ec2_role.rendered}"

  tags = {
    Name = "s3fullaccesss"
  }
}

resource "aws_iam_policy" "s3policy" {
  name        = "${var.s3Policy}"
  path        = "/"
  description = "This policy is used to provide full access on S3"
  policy      = "${data.template_file.ec2s3_policy.rendered}"
}

# Code Builld Policy and role

resource "aws_iam_role" "codebuild_role" {
  name               = "codebuild-patch-role"
  assume_role_policy = "${data.template_file.codebuild_role.rendered}"
}

resource "aws_iam_role_policy" "codebuild_policy" {
  role   = "${aws_iam_role.codebuild_role.name}"
  name   = "${var.codebuildPolicy}"
  policy = "${data.template_file.codebuild_policy.rendered}"
}

# CodePipeline Role
resource "aws_iam_role" "codePipeline_role" {
  name               = "codepipeline-patch-role"
  assume_role_policy = "${data.template_file.codepipeline_role.rendered}"
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  role   = "${aws_iam_role.codePipeline_role.name}"
  name   = "${var.codepipelinePolicy}"
  policy = "${data.template_file.codepipeline_policy.rendered}"
}

# Attaching the S3 role

resource "aws_iam_role_policy_attachment" "s3-attach-role" {
  role       = "${aws_iam_role.iam_s3_role.name}"
  policy_arn = "${aws_iam_policy.s3policy.arn}"
}


# DATA TEMPLATES

data "template_file" "codebuild_policy" {
  template = "${file("${path.module}/templates/policies/codebuild_policy.json")}"

  vars = {
    sdn_bucket        = "${aws_s3_bucket.patch_bucket.arn}"
    sdn_bucket_script = "${aws_s3_bucket.patch_bucket-script.arn}"
    region            = "${data.aws_region.current.name}"
    account_id        = "${data.aws_caller_identity.current.account_id}"
  }
}

data "template_file" "codepipeline_policy" {
  template = "${file("${path.module}/templates/policies/codepipeline_policy.json")}"

  vars = {
    sdn_bucket        = "${aws_s3_bucket.patch_bucket.arn}"
    sdn_bucket_script = "${aws_s3_bucket.patch_bucket-script.arn}"
  }
}

data "template_file" "ec2s3_policy" {
  template = "${file("${path.module}/templates/policies/s3access_policy.json")}"

  vars = {
    sdn_bucket        = "${aws_s3_bucket.patch_bucket.arn}"
    sdn_bucket_script = "${aws_s3_bucket.patch_bucket-script.arn}"
  }
}

data "template_file" "bucket_policy" {
  template = "${file("${path.module}/templates/policies/bucket_policy.json")}"

  vars = {
    sdn_bucket     = "${aws_s3_bucket.patch_bucket.arn}"
    iam_role       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
    codebuild_role = "${aws_iam_role.codebuild_role.arn}"
  }
}

data "template_file" "bucket_policy2" {
  template = "${file("${path.module}/templates/policies/bucket_policy.json")}"

  vars = {
    sdn_bucket     = "${aws_s3_bucket.patch_bucket-script.arn}"
    iam_role       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
    codebuild_role = "${aws_iam_role.codePipeline_role.arn}"
  }
}

data "template_file" "codebuild_role" {
  template = "${file("${path.module}/templates/policies/asumerole_policy.json")}"

  vars = {
    role_assume = "codebuild.amazonaws.com"
  }
}

data "template_file" "ec2_role" {
  template = "${file("${path.module}/templates/policies/asumerole_policy.json")}"

  vars = {
    role_assume = "ec2.amazonaws.com"
  }
}

data "template_file" "codepipeline_role" {
  template = "${file("${path.module}/templates/policies/asumerole_policy.json")}"

  vars = {
    role_assume = "codepipeline.amazonaws.com"
  }
}
