variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}

variable "bucket_name" {
  description = "Name of the S3 bucket for static and media files"
  type        = string
  default     = "ay-l-final-project-static"
}

variable "cloudfront_price_class" {
  description = "CloudFront distribution price class"
  type        = string
  default     = "PriceClass_100"
}