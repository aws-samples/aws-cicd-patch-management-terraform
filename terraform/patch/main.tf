data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# A bucket to keep all Patch files
resource "aws_s3_bucket" "patch_bucket" {
  bucket = "${var.core-environment}-${data.aws_caller_identity.current.account_id}-patch-bucket"
  acl    = "private"
  tags   = "${var.tags}"
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket" "patch_bucket-script" {
  bucket = "${var.core-environment}-${data.aws_caller_identity.current.account_id}-patch-scripts-bucket"
  acl    = "private"
  tags   = "${var.tags}"
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

data "archive_file" "zip_patch" {
  type        = "zip"
  source_dir = "${path.module}/templates/patch"
  output_path = "${path.module}/patch.zip"
}

resource "aws_s3_bucket_object" "patchupload" {
   bucket = "${aws_s3_bucket.patch_bucket-script.bucket}"
   key    = "patch.zip"
   source = "${data.archive_file.zip_patch.output_path}"
   etag   = "${data.archive_file.zip_patch.output_md5}"
}