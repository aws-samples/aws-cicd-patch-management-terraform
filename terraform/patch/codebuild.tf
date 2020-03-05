data "template_file" "buildspec" {
  template = "${file("${path.module}/templates/buildspec.yml")}"
  vars = {
    topic_arn                   = "${aws_sns_topic.sns.arn}"
    updateGoldenImage           = "True"
  }
}


data "template_file" "buildspec1" {
  template = "${file("${path.module}/templates/buildspec-golden-ami.yml")}"
  vars = {
    updateGoldenImage           = "True"
    topic_arn                   = "${aws_sns_topic.sns.arn}"
  }
}

resource "aws_codebuild_project" "codebuild" {
  name          = "Build-${element(var.cbenv, 1)}"
  description   = "Software Patch Management Using AWS Serverless CICD"
  build_timeout = "60"
  service_role  = "${aws_iam_role.codebuild_role.arn}"
  tags          = "${var.tags}"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "${var.computetype}"
    image                       = "${var.image_type}"
    type                        = "${var.containter_type}"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "environment"
      value = "${element(var.cbenv, 1)}"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "${data.template_file.buildspec.rendered}"
  }
}

resource "aws_codebuild_project" "codebuild_golden_ami" {
  name          = "Build-Golden-AMI"
  description   = "Software Patch Management Using AWS Serverless CICD"
  build_timeout = "60"
  service_role  = "${aws_iam_role.codebuild_role.arn}"
  tags          = "${var.tags}"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "${var.computetype}"
    image                       = "${var.image_type}"
    type                        = "${var.containter_type}"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "environment"
      value = "dev"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "${data.template_file.buildspec1.rendered}"
  }
}

resource "aws_codebuild_project" "codebuild1" {
  name          = "Build-${element(var.cbenv, 2)}"
  description   = "Software Patch Management Using AWS Serverless CICD"
  build_timeout = "60"
  service_role  = "${aws_iam_role.codebuild_role.arn}"
  tags          = "${var.tags}"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "${var.computetype}"
    image                       = "${var.image_type}"
    type                        = "${var.containter_type}"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "environment"
      value = "${element(var.cbenv, 2)}"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "${data.template_file.buildspec.rendered}"
  }
}

resource "aws_codebuild_project" "codebuild2" {
  name          = "Build-${element(var.cbenv, 3)}"
  description   = "Software Patch Management Using AWS Serverless CICD"
  build_timeout = "60"
  service_role  = "${aws_iam_role.codebuild_role.arn}"
  tags          = "${var.tags}"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "${var.computetype}"
    image                       = "${var.image_type}"
    type                        = "${var.containter_type}"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "environment"
      value = "${element(var.cbenv, 3)}"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "${data.template_file.buildspec.rendered}"
  }
}

resource "aws_codebuild_project" "codebuild3" {
  name  = "Build-prod"
  description   = "Software Patch Management Using AWS Serverless CICD"
  build_timeout = "60"
  service_role  = "${aws_iam_role.codebuild_role.arn}"
  tags          = "${var.tags}"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "${var.computetype}"
    image                       = "${var.image_type}"
    type                        = "${var.containter_type}"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "environment"
      value = "prod"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "${data.template_file.buildspec.rendered}"
  }
}
