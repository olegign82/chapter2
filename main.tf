provider "aws" {
  region = "us-east-1"
}

resource "aws_launch_configuration" "example" {
  image_id                = "ami-0e86e20dae9224db8"
  instance_type           = "t2.micro"
  security_groups  = [aws_security_group.instance.id]
  
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF

  #Required when using a launch configuration with an auto scaling group.
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "instance" {
  name     = "terraform-example-instance"
  vpc_id = "vpc-05277f25aafd7dd86"

  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type = number
  default = 8080
}

output "public_ip" {
  value = aws_launch_configuration.example.associate_public_ip_address
  description = "The publis IP address of the web server"
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier = data.aws_subnets.default.ids
  
  min_size = 2
  max_size = 10

  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
}

#data "aws_vpc" "default" {
#  default = true
#}

data "aws_subnets" "default" {
  filter {
    name = "vpc-id"
    values = ["vpc-05277f25aafd7dd86"]
  }
}

