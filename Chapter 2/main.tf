// setup provider
provider "aws" {
    region = "ca-central-1"
}

variable "server_port" {
    description = "The port the server will use for HTTP requests"
    type = number
    default = 8080
}

// create micro ec2 instance
/*resource "aws_instance" "my-instance" {
    ami = "ami-07744b6c7178930b5" // Amazon Machine Image ID of an Ubuntu 18.04 AMI  in Canada Central
    instance_type = "t2.micro"    // EC2 Instance to run
    vpc_security_group_ids = [aws_security_group.my-instance-sec-grp.id]
    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p ${var.server_port} &
                EOF
    tags = {
        Name = "terraform-example"
    }
}
*/

resource "aws_launch_configuration" "launch-confg-example" {
    image_id = "ami-07744b6c7178930b5" // Amazon Machine Image ID of an Ubuntu 18.04 AMI  in Canada Central
    instance_type = "t2.micro"    // EC2 Instance to run
    security_groups = [aws_security_group.my-instance-sec-grp.id]
    
    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p ${var.server_port} &
                EOF
    # Required when using a launch configuration with an 
    # auto scaling group
    # https://www.terraform.io/docs/providers/aws/r/launch_c onfiguration.html
    
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "asg-example" {
  launch_configuration = aws_launch_configuration.launch-confg-example.name
  vpc_zone_identifier = data.aws_subnet_ids.default.ids
  
  target_group_arns = [aws_lb_target_group.asg-alb-trgt-grp.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 10

  tag {
      key  = "Name"
      value = "terraform-asg-example"
      propagate_at_launch = true
  }
}

// AWS Elastic Application Load Balancer
resource "aws_lb" "my-asg-lb" {
  name = "terraform-asg-example"
  load_balancer_type = "application"
  subnets = data.aws_subnet_ids.default.ids
  security_groups = [aws_security_group.alb-sec-grp.id]
}

// ALB Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.my-asg-lb.arn
  port = 80
  protocol = "HTTP"

  # By default, return a simple 404 page
  default_action {
      type = "fixed-response"

      fixed_response {
          content_type = "text/plain"
          message_body = "404: page not found"
          status_code = 404
      }
  }
}

resource "aws_security_group" "alb-sec-grp" {
  name = "terraform-example-alb-sec-grp"

  # Allow inbound HTTP requrests
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

resource "aws_lb_target_group" "asg-alb-trgt-grp" {
  name = "terraform-asg-alb-trgt-grp"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id

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

resource "aws_lb_listener_rule" "asg-lb-rule" {
    listener_arn = aws_lb_listener.http.arn
    priority = 100
    condition {
        field = "path-pattern"
        values = ["*"]
    }

    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.asg-alb-trgt-grp.arn
    }
  
}


data "aws_vpc" "default" {
    default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}


//security group
resource "aws_security_group" "my-instance-sec-grp" {
    name = "terraform-example-sec-grp"

    ingress {
        from_port = var.server_port
        to_port = var.server_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"] // Allow from any IP
    }
  
}

output "alb_dns_name" {
  value = aws_lb.my-asg-lb.dns_name
  description = "The domain name of the load balancer"
}

