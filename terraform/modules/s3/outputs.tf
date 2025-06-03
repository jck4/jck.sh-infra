output "site_bucket_name" {
  description = "Name of the website bucket"
  value       = aws_s3_bucket.jck_sh_site.id
}

output "site_bucket_arn" {
  description = "ARN of the website bucket"
  value       = aws_s3_bucket.jck_sh_site.arn
}

output "site_bucket_regional_domain_name" {
  description = "Regional domain name of the website bucket"
  value       = aws_s3_bucket.jck_sh_site.bucket_regional_domain_name
} 