# EC2 Roles and Policies

data "aws_iam_policy_document" "assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "role_policy" {
  statement {
    actions = [
      "ec2:DescribeTags",
      "ec2:CreateTags",
      "ec2:DescribeInstances",
      "autoscaling:DescribeAutoScalingGroups",
      "cloudwatch:PutMetricData",
      "ec2:DescribeTags",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
    ]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "role_policy_s3" {
  statement {
    actions = [
       "s3:ListBucket",
       "s3:GetBucketAcl",
       "s3:GetBucketLocation",
       "s3:GetObject",
       "s3:GetObjectVersion",
    ]
    resources = [
      "arn:aws:s3:::sdn-*",
      "arn:aws:s3:::sdn-*/*",
    ]
  }
}

resource "aws_iam_role" "role" {
  name               = "${var.build_environment}_ec2_role"
  assume_role_policy = "${data.aws_iam_policy_document.assume_policy.json}"
}

resource "aws_iam_policy" "policy" {
  name   = "${var.build_environment}_ec2_policy"
  policy = "${data.aws_iam_policy_document.role_policy.json}"
}

resource "aws_iam_policy" "policy_s3" {
  name   = "${var.build_environment}_s3_policy"
  policy = "${data.aws_iam_policy_document.role_policy_s3.json}"
}

resource "aws_iam_role_policy_attachment" "policy_attach" {
  role       = "${aws_iam_role.role.name}"
  policy_arn = "${aws_iam_policy.policy.arn}"
}

resource "aws_iam_role_policy_attachment" "policy_attach1" {
  role       = "${aws_iam_role.role.name}"
  policy_arn = "${aws_iam_policy.policy_s3.arn}"
}

resource "aws_iam_role_policy_attachment" "policy_attach_ssm" {
  role       = "${aws_iam_role.role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}
