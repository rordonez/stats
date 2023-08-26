locals {
  subnet_ids = [aws_default_subnet.default_subnet_a.id, aws_default_subnet.default_subnet_b.id]
}

data "aws_iam_role" "task_execution" {
  name = "ecsTaskExecutionRole"
}


data "aws_ecr_repository" "service" {
  for_each = { for s in var.services : s.name => s }
  name = each.key
}

resource "aws_service_discovery_http_namespace" "app-namespace" {
  name        = var.application_name
  description = "Namespace for Service Discovery"
}

resource "aws_ecs_task_definition" "app_task" {
  for_each = { for s in var.services : s.name => s }
  family                   = each.key
  container_definitions    = jsonencode([
    {
      name         = each.key,
      image        = "${data.aws_ecr_repository.service[each.key].repository_url}:${var.application_version}",
      essential    = true,
      portMappings = [
        {
          containerPort = each.value.container.port,
          hostPort      = each.value.container.host_port
          name          = each.key
        }
      ],
      environment = [
        for var_name, var_value in each.value.container.environment :
        {
          name  = var_name
          value = var_value
        }
      ]
      memory = each.value.container.memory,
      cpu    = each.value.container.cpu
    }
  ])
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = each.value.container.memory
  cpu                      = each.value.container.cpu
  execution_role_arn       = data.aws_iam_role.task_execution.arn
  tags = {
    Name        = each.key
    Component   = "Application ECS task"
    Environment = var.environment
  }
}


data "aws_ecs_cluster" "ecs" {
  cluster_name = var.ecs_cluster_name
}

resource "aws_ecs_service" "app_service" {
  for_each = {for s in var.services : s.name => s }
  name            = each.key
  cluster         = data.aws_ecs_cluster.ecs.id
  task_definition = aws_ecs_task_definition.app_task[each.key].arn
  launch_type     = "FARGATE"
  desired_count   = each.value.replicas

  dynamic "load_balancer" {
    for_each = each.value.proxy ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.target_group.arn
      container_name   = each.key
      container_port   = each.value.container.port
    }
  }

  service_connect_configuration {
    enabled = true
    namespace = aws_service_discovery_http_namespace.app-namespace.arn
    service {
      client_alias {
        dns_name = each.key
        port = each.value.container.port
      }
      discovery_name = each.key
      port_name = each.key
    }
  }

  network_configuration {
    subnets          = local.subnet_ids
    assign_public_ip = true
    security_groups  = [aws_security_group.service_security_group.id]
  }
  tags = {
    Name        = each.key
    Component   = "ECS service"
    Environment = var.environment
  }
}

resource "aws_alb" "application_load_balancer" {
  name               = "load-balancer-${var.application_name}"
  load_balancer_type = "application"
  subnets            = local.subnet_ids
  security_groups    = [aws_security_group.load_balancer_security_group.id]
  tags = {
    Name        = var.application_name
    Component   = "Application Load Balancer"
    Environment = var.environment
  }
}

resource "aws_security_group" "load_balancer_security_group" {
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name        = var.application_name
    Component   = "Load balancer security group"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "target_group" {
  name        = "target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_default_vpc.default_vpc.id
  tags = {
    Name        = var.application_name
    Component   = "Load balancer security group"
    Environment = var.environment
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_alb.application_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
  tags = {
    Name        = var.application_name
    Component   = "Load balancer listener"
    Environment = var.environment
  }
}

resource "aws_security_group" "service_security_group" {
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name        = var.application_name
    Component   = "Load balancer security group"
    Environment = var.environment
  }
}

# For the purpose of this exercise, I will keep basic network configurations
resource "aws_default_vpc" "default_vpc" {
}

resource "aws_default_subnet" "default_subnet_a" {
  availability_zone = "us-east-1a"
}

resource "aws_default_subnet" "default_subnet_b" {
  availability_zone = "us-east-1b"
}
