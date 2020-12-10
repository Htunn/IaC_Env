resource "aws_instance" "example" {
    ami = "ami-0c20b8b385217763f"
    instance_type = "t2.micro"
}

terraform {
    backend "s3" {
        # Replace this with your bucket name!
        bucket = "terraform-up-and-running-htunn"
        key = "workspaces-example/terraform.tfstate"
        region = "ap-southeast-1"

        # Replace this with your DynamoDB table name!
        dynamodb_table = "terraform-up-and-running-locks"
        encrypt = true
    }
}