#This module creates our ecs service

resource "aws_ecs_cluster" "demowebapp" {
  name = "${var.demowebapp}-${var.environment}"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = var.tags
}

#target for as 
resource "aws_appautoscaling_target" "app_scale_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.demowebapp.name}/${aws_ecs_service.demowebapp.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  max_capacity       = var.ecs_autoscale_max_instances
  min_capacity       = var.ecs_autoscale_min_instances
}


#task definintion
resource "aws_ecs_task_definition" "demowebapp" {
  family                   = "${var.demowebapp}-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn


  container_definitions = <<DEFINITION
[
  {
    "name": "${var.container_name}",
    "image": "${var.demowebapp_image}",
    "essential": true,
    "portMappings": [
      {
        "protocol": "tcp",
        "containerPort": ${var.container_port},
        "hostPort": ${var.container_port}
      }
    ],
    "environment": [
      {
        "name": "PORT",
        "value": "${var.container_port}"
      },
      {
        "name": "HEALTHCHECK",
        "value": "${var.health_check}"
      },
      {
        "name": "ENABLE_LOGGING",
        "value": "true"
      },
      {
        "name": "PRODUCT",
        "value": "${var.demowebapp}"
      },
      {
        "name": "ENVIRONMENT",
        "value": "${var.environment}"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/fargate/service/${var.demowebapp}-${var.environment}",
        "awslogs-region": "${var.region}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
DEFINITION


  tags = var.tags
}

#ecs service 
resource "aws_ecs_service" "demowebapp" {
  name            = "${var.demowebapp}-${var.environment}"
  cluster         = aws_ecs_cluster.demowebapp.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.demowebapp.arn
  desired_count   = var.replicas

  network_configuration {
    security_groups = [aws_security_group.nsg_task.id]
    subnets         = var.private_subnets
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.main.id
    container_name   = var.container_name
    container_port   = var.container_port
  }

  tags                    = var.tags
  enable_ecs_managed_tags = true
  propagate_tags          = "SERVICE"

  #has to be done after the alb because it breaks if done out of order
  depends_on = [aws_alb_listener.http]

  lifecycle {
    ignore_changes = [task_definition]
  }
}

#create log gorup
resource "aws_cloudwatch_log_group" "logs" {
  name              = "/fargate/service/${var.demowebapp}-${var.environment}"
  retention_in_days = var.logs_retention_in_days
  tags              = var.tags
}

#role for running
resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "${var.demowebapp}-${var.environment}-ecs"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ECRFullAccess" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::860758160586:policy/ECRFullAccess"
}