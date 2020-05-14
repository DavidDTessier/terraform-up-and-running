// setup provider
provider "aws" {
    region = "ca-central-1"
}

// create micro ec2 instance
resource "aws_instance" "my-instance" {
    ami = "ami-07744b6c7178930b5" // Amazon Machine Image ID of an Ubuntu 18.04 AMI  in Canada Central
    instance_type = "t2.micro"    // EC2 Instance to run

    tags = {
        Name = "terraform-example"
    }
}
