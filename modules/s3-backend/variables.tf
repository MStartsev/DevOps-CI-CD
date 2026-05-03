variable "bucket_name" {
  description = "Name of the S3 bucket for Terraform state storage (must be globally unique)"
  type        = string
}

variable "table_name" {
  description = "Name of the DynamoDB table for state locking"
  type        = string
  default     = "terraform-locks"
}
