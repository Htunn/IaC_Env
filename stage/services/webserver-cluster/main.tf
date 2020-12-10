provider "aws" {
    region = "ap-southeast-1"
}

resource "aws_launch_configuration" "example" {
    image_id = "ami-0c20b8b385217763f"
    instance_type = "t2.micro"
    security_groups = [aws_security_group.instance.id]
    user_data = data.template_file.user_data.rendered


    lifecycle {
      create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "example" {
    launch_configuration = aws_launch_configuration.example.name
  #  vpc_zone_identifier = data.aws_subnet_ids.default.ids

    target_group_arns = [aws_lb_target_group.asg.arn]
    health_check_type = "ELB"

    min_size = 2
    max_size = 10

    tag{
        key = "Name"
        value = "terraform-asg-example"
        propagate_at_launch = true
    }
}

data "aws_vpc" "default" {
    default = true
}

data "aws_subnet_ids" "default" {
    vpc_id = data.aws_vpc.default.id
}

resource "aws_security_group" "instance" {
    name = "terraform-example-instance"

    ingress {
        from_port = var.server_port
        to_port = var.server_port 
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
  
}

resource "aws_lb" "example" {
    name = "terraform-asg-example"
    load_balancer_type = "application"
    subnets = data.aws_subnet_ids.default.ids 
    security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.example.arn
    port = 80
    protocol = "HTTP"

    # By Default , return a simple 404 page
    default_action {
        type = "fixed-response"

        fixed_response {
            content_type = "text/plain"
            message_body = "404: page not found"
            status_code = "404"
        }
    }
}

resource "aws_lb_listener_rule" "asg" {
    listener_arn = aws_lb_listener.http.arn
    priority = 100

    condition {
        path_pattern {
            values = ["*"]
        }
    }

    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.asg.arn
    }
}

resource "aws_security_group" "alb" {
    name = "terraform-example-alb"

    # Allow inbound HTTP requests
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Allow all outbound requests
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_lb_target_group" "asg" {
    name = "terraform-asg-example"
    port = var.server_port
    protocol = "HTTP"

    health_check {
        path = "/"
        protocol = "HTTP"
        matcher = "200"
        interval = 15
        timeout = 3
        healthy_threshold = 2
        unhealthy_threshold = 2
    }
}


terraform {
    backend "s3" {
        # Replace this with your bucket name!
        key = "stage/services/webserver-cluster/terraform.state"
        bucket = "terraform-up-and-running-htunn"
        region = "ap-southeast-1" 

        # Replace this with your DynamoDB table name!
        dynamodb_table = "terraform-up-and-running-locks"
        encrypt = true
    }
}

data "terraform_remote_state" "db" {
    backend = "s3"

    config = {
        bucket = "(terraform-up-and-running-htunn)"
        key = "stage/data-stores/mysql/terraform.tfstate"
        region = "ap-southeast-1"
    }
}

data "template_file" "user_data" {
    template = file("user-data.sh")

    vars = {
        server_port = var.server_port
        db_address = data.terraform_remote_state.db.outputs.address 
        db_port = data.terraform_remote_state.db.outputs.port 
    }
}

module "webserver_cluster" {
    source = "github.com/Htunn/IaC_Test//services/webserver-cluster?ref=v0.0.1"

   # cluster_name = "webservers-stage"
   # db_remote_state_bucket = "(terraform-up-and-running-htunn)"
   # db_remote_state_key = "stage/data-stores/mysql/terraform.tfstate"
    cluster_name           = var.cluster_name
    db_remote_state_bucket = var.db_remote_state_bucket
    db_remote_state_key    = var.db_remote_state_key
    instance_type = "t2.micro"
    min_size = 2
    max_size = 2
}

resource "aws_security_group_rule" "allow_testing_inbound" {
    type = "ingress"
    security_group_id = module.webserver_cluster.alb_security_group_id

    from_port = 12345
    to_port = 12345
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}