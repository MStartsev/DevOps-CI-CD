# DynamoDB table for Terraform state locking
# Prevents concurrent state modifications (race conditions)

resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"  # no capacity planning needed for lock table
  hash_key     = "LockID"           # required key name for Terraform S3 backend

  attribute {
    name = "LockID"
    type = "S"
  }

  # Enable point-in-time recovery
  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name      = var.table_name
    ManagedBy = "Terraform"
    Purpose   = "terraform-state-lock"
  }
}
