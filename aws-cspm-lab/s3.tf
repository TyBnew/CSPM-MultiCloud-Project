resource "aws_s3_bucket" "misconfigured_public" {
  bucket = "tyler-cspm-lab-public-0727"

  tags = {
    Name    = "cspm-lab-misconfigured-public"
    Project = "cspm-lab"
    Purpose = "intentional-misconfig"
  }
}

resource "aws_s3_bucket_public_access_block" "misconfigured_public" {
  bucket = aws_s3_bucket.misconfigured_public.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket" "secure" {
  bucket = "tyler-cspm-lab-secure-0727"

  tags = {
    Name    = "cspm-lab-secure"
    Project = "cspm-lab"
  }
}

resource "aws_s3_bucket_public_access_block" "secure" {
  bucket = aws_s3_bucket.secure.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "secure" {
  bucket = aws_s3_bucket.secure.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "secure" {
  bucket = aws_s3_bucket.secure.id

  versioning_configuration {
    status = "Enabled"
  }
}