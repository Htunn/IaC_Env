provider "aws" {
    region = "ap-southeast-1"
}

resource "aws_db_instance" "example" {
    identifier_prefix = "terraform-up-and-running"
    engine = "mysql"
    allocated_storage = 10
    instance_class = "db.t2.micro"
    name = "example_database"
    username = "admin"

    # How should we set the password?
    password = "password"
}

#data "aws_secretsmanager_secret_version" "db_password" {
#    secret_id = "mysql-master-password-stage"
#}
# export TF_VAR_db_password="(YOUR_DB_PASSWORD)"

terraform {
    backend "s3" {
        # Replace this with your bucket name
        bucket = "terraform-up-and-running-htunn"
        key = "stage/data-stores/mysql/terraform.tfstate"
        region = "ap-southeast-1"

        # Replace this with your DynamoDB table name!
        dynamodb_table = "terraform-up-and-running-locks"
        encrypt = true
    }
}