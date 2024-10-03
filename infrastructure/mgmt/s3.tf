resource "aws_s3_bucket" "build_artifacts" {
  bucket = "nhse-iam-hcw-build-artifacts-${var.account}"
}
