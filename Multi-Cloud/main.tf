// setup providers
provider "aws" {
    region = "ca-central-1"
}

provider "google" {
    credentials = file("gcp-creds.json")
    project = "dtessier-sandbox-275911"
    region  = "northamerica-northeast1"
    zone    = "northamerica-northeast1-a"
}

// create vm instances

resource "aws_instance" "my-instance" {
    ami = "ami-07744b6c7178930b5" // Amazon Machine Image ID of an Ubuntu 18.04 AMI  in Canada Central
    instance_type = "t2.micro"    // EC2 Instance to run
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

resource "google_compute_instance" "my_instance" {
    name = "terraform-instance"
    machine_type = "f1-micro"

    boot_disk {
        initialize_params {
            image = "debian-cloud/debian-9"
        }
    }

    network_interface {
        # A default network is create for all GCP Projects
        network = google_compute_network.vpc_network.self_link
        access_config {
        }
    }
  
}

resource "google_compute_network" "vpc_network" {
    name = "terraform-network"
    auto_create_subnetworks = "true"
}

terraform {
    backend "s3" {
        key = "multi-cloud/terraform.tfstate"
    }
}


