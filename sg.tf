#This module creates a security for the lb and task

resource "aws_security_group" "nsg_lb" {
  name        = "${var.demowebapp}-${var.environment}-lb"
  vpc_id      = var.vpc

  tags = var.tags
}

resource "aws_security_group" "nsg_task" {
  name        = "${var.demowebapp}-${var.environment}-task"
  vpc_id      = var.vpc

  tags = var.tags
}

#sg rule only allow tcp traffic on specified port
resource "aws_security_group_rule" "nsg_lb_egress_rule" {
  type                     = "egress"
  from_port                = "0"
  to_port                  = "0"
  protocol                 = "-1"
  source_security_group_id = aws_security_group.nsg_task.id

  security_group_id = aws_security_group.nsg_lb.id
}

resource "aws_security_group_rule" "nsg_task_ingress_rule" {
  type                     = "ingress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nsg_lb.id

  security_group_id = aws_security_group.nsg_task.id
}

#allow all outgoing 
resource "aws_security_group_rule" "nsg_task_egress_rule" {
  type        = "egress"
  from_port   = "0"
  to_port     = "0"
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.nsg_task.id
}
