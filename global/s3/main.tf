provider "aws" {
    region = "ap-southeast-1"
}

resource "aws_s3_bucket" "terraform_state" {
    bucket = "terraform-up-and-running-htunn" 


    # Prevent accidental deletion of this s3 bucket
    lifecycle {
        prevent_destroy = true
    }

    # Enable versioning so we can see the full version history of our 
    # state file
    versioning {
        enabled = true
    }

    # Enable server-side encryption by default
    server_side_encryption_configuration {
        rule {
            apply_server_side_encryption_by_default {
                sse_algorithm = "AES256"
            }
        }
    }
}

resource "aws_dynamodb_table" "terraform_locks" {
    name = "terraform-up-and-running-locks"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "LockID"

    attribute {
        name = "LockID"
        type = "S"
    }
}

terraform {
    backend "s3" {
        # Replace this with your bucket name!
        key = "global/s3/terraform.tfstate"
        bucket = "terraform-up-and-running-htunn"
        region = "ap-southeast-1" 

        # Replace this with your DynamoDB table name!
        dynamodb_table = "terraform-up-and-running-locks"
        encrypt = true
    }
}

