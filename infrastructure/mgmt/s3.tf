resource "aws_s3_bucket" "build_artifacts" {
  bucket = "nhse-iam-hcw-build-artifacts-${var.account}"
}

resource "aws_s3_bucket_versioning" "build_artifacts_versioning" {
  bucket = aws_s3_bucket.build_artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}
