variable "project_name" { type = string }

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "cpg_bucket" {
  bucket = "${var.project_name}-cpg-bucket-${random_id.suffix.hex}"
}

output "bucket_name" {
  value = aws_s3_bucket.cpg_bucket.id
}

output "bucket_arn" {
  value = aws_s3_bucket.cpg_bucket.arn
}
