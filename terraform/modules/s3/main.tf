resource "aws_s3_bucket" "tf_state" {
  bucket = var.tf_state_bucket

  tags = {
    Name        = "Terraform State Bucket"
    Environment = "infra"
  }
}

resource "aws_s3_bucket" "foundryvtt_backups" {
  bucket = var.backups_bucket

  tags = {
    Name        = "FoundryVTT Backups"
    Environment = "infra"
  }
}

resource "aws_s3_bucket_versioning" "foundryvtt_backups" {
  bucket = aws_s3_bucket.foundryvtt_backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "foundryvtt_backups" {
  bucket = aws_s3_bucket.foundryvtt_backups.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    filter {
      prefix = ""  # Apply to all objects in the bucket
    }
  }
} 

resource "aws_s3_bucket" "jck_sh_site" {
  bucket = "jck.sh"

  tags = {
    Name        = "jck.sh Site"
    Environment = "infra"
  }
}

# Enable static website hosting
resource "aws_s3_bucket_website_configuration" "jck_sh_site" {
  bucket = aws_s3_bucket.jck_sh_site.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "404/index.html"
  }
}

# Public read access from cloudflare
resource "aws_s3_bucket_policy" "jck_sh_site" {
  bucket = aws_s3_bucket.jck_sh_site.id

  depends_on = [aws_s3_bucket_public_access_block.jck_sh_site]

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "DenyNonCloudflareIPs",
        Effect    = "Deny",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.jck_sh_site.arn}/*",
        Condition = {
          NotIpAddress = {
            "aws:SourceIp" = [
              "173.245.48.0/20",
              "103.21.244.0/22",
              "103.22.200.0/22",
              "103.31.4.0/22",
              "141.101.64.0/18",
              "108.162.192.0/18",
              "190.93.240.0/20",
              "188.114.96.0/20",
              "197.234.240.0/22",
              "198.41.128.0/17",
              "162.158.0.0/15",
              "104.16.0.0/13",
              "104.24.0.0/14",
              "172.64.0.0/13",
              "131.0.72.0/22"
            ]
          }
        }
      },
      {
        Sid       = "AllowCloudflareOnly",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.jck_sh_site.arn}/*"
      }
    ]
  })
}


resource "aws_s3_bucket_public_access_block" "jck_sh_site" {
  bucket = aws_s3_bucket.jck_sh_site.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}