output "bucket_id" {
  description = "ID (name) of the S3 bucket"
  value       = aws_s3_bucket.static.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.static.arn
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket"
  value       = aws_s3_bucket.static.bucket_regional_domain_name
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.static.id
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution (*.cloudfront.net)"
  value       = aws_cloudfront_distribution.static.domain_name
}