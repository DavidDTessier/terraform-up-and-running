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
    security_group_ids = [aws_security_group.my-instance-sec-grp.id]
    
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
  vpc_zone_identifier = data.aws_subnet_ids.default.aws_subnet_ids

  min_size = 2
  max_size = 10

  tag {
      key  = "Name"
      value = "terraform-asg-example"
      propagate_at_launch = true
  }
}

resource "aws_lb" "name" {
  
}



data "aws_vpc" "default" {
    default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = aws_vpc.default.id
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

output "public_ip" {
  value = aws_instance.my-instance.public_ip
  description = "The public IP address of the web server"
}

