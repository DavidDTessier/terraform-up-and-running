// setup provider
provider "aws" {
    region = "ca-central-1"
}

resource "aws_s3_bucket" "ddt_terraform_state" {
  bucket = "ddt-terraform-state"

  #Prevent accidental deletion of this s3 bucket
  lifecycle {
      prevent_destroy = true
  }

  # Enable versioning so we can see the full version
  # history of our state files
  versioning {
      enabled = true
  }

  # Enable server-side encryption by defaul
  server_side_encryption_configuration {
      rule {
          apply_server_side_encryption_by_default {
              sse_algorithm = "AES256"
          }
      }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name = "my-terraform-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"

  attribute {
      name = "LockID"
      type = "S"
  }
}

terraform {
    backend "s3" {
        # Bucket details for storing state
        bucket = "ddt-terraform-state"
        key = "global/s3/terraform.tfstate"
        region = "ca-central-1"

        # DynamoDb details for gaing Lock on state
        dynamodb_table = "my-terraform-state-locks"
        encrypt = true # ensures state will be encrypted
    }
}

output "s3_bucket_arn" {
  value = "aws_s3_bucket.ddt-terraform-state.arn"
  description = "The ARN of the s3 bucket"
}

output "dynamodb_table_name" {
  value = "aws_dynamodb_table.my-terraform-state-locks.name"
  description = "The name of the DynamoDB table"
}




