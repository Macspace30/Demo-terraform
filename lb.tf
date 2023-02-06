#This module creates a http load balancer for our ecs service

#creation of the http lb
resource "aws_alb" "main" {
  name = "${var.demowebapp}-${var.environment}"

  
  internal = var.internal
  subnets = var.private_subnets
  
  security_groups = [aws_security_group.nsg_lb.id]
  tags            = var.tags

  
  access_logs {
    enabled = true
    bucket  = aws_s3_bucket.lb_access_logs.bucket
  }
}

resource "aws_alb_target_group" "main" {
  name                 = "${var.demowebapp}-${var.environment}"
  port                 = var.lb_port
  protocol             = var.lb_protocol
  vpc_id               = var.vpc
  target_type          = "ip"
  deregistration_delay = var.deregistration_delay

  health_check {
    path                = var.health_check
    matcher             = var.health_check_code
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = 5
    unhealthy_threshold = 5
  }

  tags = var.tags
}

#listener for load balancer HTTP commented out to test https
#resource "aws_alb_listener" "http" {
#  load_balancer_arn = aws_alb.main.id
#  port              = var.lb_port
#  protocol          = var.lb_protocol
#
#  default_action {
#    target_group_arn = aws_alb_target_group.main.id
#    type             = "forward"
#  }
#}

#http lb sg rule
#resource "aws_security_group_rule" "ingress_lb_http" {
#  type              = "ingress"
#  description       = var.lb_protocol
#  from_port         = var.lb_port
#  to_port           = var.lb_port
#  protocol          = "tcp"
#  cidr_blocks       = ["0.0.0.0/0"]
#  security_group_id = aws_security_group.nsg_lb.id
#}

data "aws_elb_service_account" "main" {
}

# create bucket for logs
resource "aws_s3_bucket" "lb_access_logs" {
  bucket        = "${var.demowebapp}-${var.environment}-lb-access-logs"
  acl           = "private"
  tags          = var.tags
  force_destroy = true

  lifecycle_rule {
    id                                     = "cleanup"
    enabled                                = true
    abort_incomplete_multipart_upload_days = 1
    prefix                                 = ""

    expiration {
      days = var.lb_access_logs_expiration_days
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

#bucket policy
resource "aws_s3_bucket_policy" "lb_access_logs" {
  bucket = aws_s3_bucket.lb_access_logs.id

  policy = <<POLICY
{
  "Id": "Policy",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.lb_access_logs.arn}",
        "${aws_s3_bucket.lb_access_logs.arn}/*"
      ],
      "Principal": {
        "AWS": [ "${data.aws_elb_service_account.main.arn}" ]
      }
    }
  ]
}
POLICY
}

#dns name for the lb
output "lb_dns" {
  value = aws_alb.main.dns_name
}

