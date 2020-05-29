provider "aws" {
  region = "ca-central-1"
}

resource "aws_db_instance" "dt-mysql-db" {
  identifier_prefix = "dt"
  engine = "mysql"
  allocated_storage = 10
  instance_class = "db.t2.micro"
  name = "example_db"
  username = "mysql_admin"

  final_snapshot_identifier = "dt-mysql-db-snapshot-final"
  skip_final_snapshot = true

  # How Should we set the password??
  password = var.db_password
}

terraform {
    backend "s3" {
       key = "stage/data-stores/mysql/terraform.tfstate"
    }
}

