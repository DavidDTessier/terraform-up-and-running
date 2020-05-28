// setup providers
provider "aws" {
    region = "ca-central-1"
}

resource "aws_instance" "my-instance" {
    ami = "ami-07744b6c7178930b5" // Amazon Machine Image ID of an Ubuntu 18.04 AMI  in Canada Central
    instance_type = terraform.workspace == "default" ? "t2.micro" : "t2.medium"    // EC2 Instance to run
   // vpc_security_group_ids = [aws_security_group.my-instance-sec-grp.id]
   // user_data = <<-EOF
   //             #!/bin/bash
    //            echo "Hello, World" > index.html
   //             nohup busybox httpd -f -p ${var.server_port} &
   //             EOF
    tags = {
        Name = "terraform-example"
    }
}

terraform {
    backend "s3" {
        key = "workspaces-example/terraform.tfstate"
    }
}