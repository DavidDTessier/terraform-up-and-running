
resource "aws_launch_configuration" "launch-confg" {
    image_id = "ami-07744b6c7178930b5" // Amazon Machine Image ID of an Ubuntu 18.04 AMI  in Canada Central
    instance_type = var.instance_type    // EC2 Instance to run
    security_groups = [aws_security_group.instance-sec-grp.id]
    
    user_data = data.template_file.user_data.rendered

    # Required when using a launch configuration with an 
    # auto scaling group
    # https://www.terraform.io/docs/providers/aws/r/launch_c onfiguration.html
    
    lifecycle {
        create_before_destroy = true
    }
}

data "template_file" "user_data" {
    template = file("${path.module}/user_data.sh")

    vars = {
        server_port = var.server_port
        db_address = data.terraform_remote_state.db.outputs.address
        db_port = data.terraform_remote_state.db.outputs.port
    }
}

resource "aws_autoscaling_group" "asg" {
  launch_configuration = aws_launch_configuration.launch-confg.name
  vpc_zone_identifier = data.aws_subnet_ids.default.ids
  
  target_group_arns = [aws_lb_target_group.alb-trgt-grp.arn]
  health_check_type = "ELB"

  min_size = var.min_size
  max_size = var.max_size

  tag {
      key  = "Name"
      value = var.cluster_name
      propagate_at_launch = true
  }
}

resource "aws_security_group" "instance-sec-grp" {
  name = "${var.cluster_name}-instance-sec-grp"
}

resource "aws_security_group_rule" "allow_server_http_inbound" {
    type = "ingress"
    security_group_id  = aws_security_group.instance-sec-grp.id

    from_port = var.server_port
    to_port = var.server_port
    protocol = local.tcp_protocol
    cidr_blocks = local.all_ips
}

// AWS Elastic Application Load Balancer
resource "aws_lb" "alb" {
  name = var.cluster_name
  load_balancer_type = "application"
  subnets = data.aws_subnet_ids.default.ids
  security_groups = [aws_security_group.alb-sec-grp.id]
}

resource "aws_security_group" "alb-sec-grp" {
  name = "${var.cluster_name}-alb-sec-grp"
}

resource "aws_security_group_rule" "allow_http_inbound" {
    type = "ingress"
    security_group_id  = aws_security_group.alb-sec-grp.id

    from_port = local.http_port
    to_port = local.http_port
    protocol = local.tcp_protocol
    cidr_blocks = local.all_ips
}

// ALB Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port = local.http_port
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

resource "aws_security_group_rule" "allow_all_outbound" {
    type = "egress"
    security_group_id  = aws_security_group.alb-sec-grp.id

    from_port = local.any_port
    to_port = local.any_port
    protocol = local.any_protocol
    cidr_blocks = local.all_ips
}


resource "aws_lb_target_group" "alb-trgt-grp" {
  name = var.cluster_name
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

resource "aws_lb_listener_rule" "alb-rule" {
    listener_arn = aws_lb_listener.http.arn
    priority = 100
    condition {
        path_pattern {
            values = ["*"]
        }
    }

    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.alb-trgt-grp.arn
    } 
}

data "terraform_remote_state" "db" { 
    backend = "s3"
    
    config = {
        bucket = var.db_remote_state_bucket
        key = var.db_remote_state_key
        region = var.db_remote_state_region
    }
}

locals {
  http_port = 80
  any_port = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips = ["0.0.0.0/0"]
}

data "aws_vpc" "default" {
    default = true
}

data "aws_subnet_ids" "default" {
    vpc_id = data.aws_vpc.default.id
}
