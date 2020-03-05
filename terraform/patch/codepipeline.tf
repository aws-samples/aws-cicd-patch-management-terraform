resource "aws_codepipeline" "codepipeline" {
  name     = "patch-pipeline"
  role_arn = "${aws_iam_role.codePipeline_role.arn}"
  tags     = "${var.tags}"

  artifact_store {
    location = "${aws_s3_bucket.patch_bucket-script.bucket}"
    type     = "S3"
  }

  # Configure CodePipeline poll code from S3 if there is any change.
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["code"]

      configuration = {
        S3Bucket             = "${aws_s3_bucket.patch_bucket-script.id}"
        S3ObjectKey          = "patch.zip"
        PollForSourceChanges = "true"
      }
    }
  }

  stage {
    name = "Build-for-Golden-AMI-and-Dev"

    action {
      name      = "Approval-for-Golden-AMI-and-Dev"
      category  = "Approval"
      owner     = "AWS"
      provider  = "Manual"
      version   = "1"
      run_order = 1

      configuration = {
               NotificationArn = "${aws_sns_topic.sns.arn}"
               CustomData = "Test"
                #ExternalEntityLink = "${var.approve_url}"
      }
    }

    action {
      name            = "Build-dev"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["code"]
      version         = "1"
      run_order       = 2

      configuration = {
        ProjectName = "Build-dev"
      }
    }

    action {
      name            = "Build-Golden-AMI"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["code"]
      version         = "1"
      run_order       = 3

      configuration = {
        ProjectName = "Build-Golden-AMI"
      }
    }
  }

  # QA
  stage {
    name = "Build-for-QA"

    action {
      name       = "Approve-for-QA"
      category   = "Approval"
      owner      = "AWS"
      provider   = "Manual"
      version    = "1"
      run_order  = 1

      configuration = {
        NotificationArn    = "${aws_sns_topic.sns.arn}"
        CustomData         = "Test"
        #ExternalEntityLink = "${var.approve_url}"
      }
    }

    action {
      name            = "Build-for-QA"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["code"]
      version         = "1"
      run_order       = 2

      configuration = {
        ProjectName = "Build-qa"
      }
    }
  }

  #STAGE

  stage {
    name = "Build-for-Stage"

    action {
      name       = "Approval-for-Stage"
      category   = "Approval"
      owner      = "AWS"
      provider   = "Manual"
      version    = "1"
      run_order  = 1

      configuration = {
        NotificationArn = "${aws_sns_topic.sns.arn}"
        CustomData = "Test"

        #ExternalEntityLink = "${var.approve_url}"
      }
    }

    action {
      name            = "Build-for-Stage"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["code"]
      version         = "1"
      run_order       = 2

      configuration = {
        ProjectName = "Build-stg"
      }
    }
  }

}
