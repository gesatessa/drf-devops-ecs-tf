# ------------------------------------------------- #
resource "aws_iam_policy" "task_execution_role_policy" {
  name        = "${local.prefix}-"
  path        = "/"
  policy      = file("./templates/ecs/task-execution-role-policy.json")
  description = "ECS Task Execution Role Policy"
  # This policy allows ECS tasks to pull images and write logs to CloudWatch
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${local.prefix}-ecs-task-execution-role"
  assume_role_policy = file("./templates/ecs/task-assume-role-policy.json")
}

resource "aws_iam_role_policy_attachment" "task_execution_role_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.task_execution_role_policy.arn
}

# ------------------------------------------------ #
resource "aws_iam_role" "app_task" {
  name               = "${local.prefix}-app-task-role"
  assume_role_policy = file("./templates/ecs/task-assume-role-policy.json")
}

resource "aws_iam_policy" "task_ssm_policy" {
  name        = "${local.prefix}-task-ssm-role-policy"
  path        = "/"
  policy      = file("./templates/ecs/task-ssm-policy.json")
  description = "ECS Task SSM Policy"
  # This policy allows ECS tasks to access SSM Parameter Store
}

resource "aws_iam_role_policy_attachment" "task_ssm_role_attachment" {
  role       = aws_iam_role.app_task.name
  policy_arn = aws_iam_policy.task_ssm_policy.arn
}

# ------------------------------------------------- #
resource "aws_cloudwatch_log_group" "ecs_task_logs" {
  name = "${local.prefix}-api-logs"
  #retention_in_days = 7
  tags = {
    Name = "${local.prefix}-api-logs"
  }
}

resource "aws_ecs_cluster" "main" {
  name = "${local.prefix}-ecs-cluster"

  tags = {
    Name = "${local.prefix}-ecs-cluster"
  }
}

# ------------------------------------------------- #
resource "aws_ecs_task_definition" "api" {
  family                   = "${local.prefix}-api-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn # for pulling images and logging
  task_role_arn      = aws_iam_role.app_task.arn                # for accessing other AWS services (e.g., SSM)

  container_definitions = jsonencode(local.task_containers)
  # container_definitions = jsonencode([{},{}])  # for multiple containers

  volume {
    name = "static"
  }

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  tags = {
    Name = "${local.prefix}-api-task"
  }
}

# ------------------------------------------------- #
resource "aws_security_group" "ecs_tasks" {
  name        = "${local.prefix}-ecs-tasks-sg"
  description = "Access rules for the ECS service"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outbound HTTPS traffic"
  }

  egress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    cidr_blocks = [
      aws_subnet.private_a.cidr_block,
    ]
    description = "Allow outbound Postgres traffic to RDS"
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow inbound HTTP traffic"
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/3.24.1/docs/resources/ecs_service
resource "aws_ecs_service" "api" {
  name            = "${local.prefix}-api"
  cluster         = aws_ecs_cluster.main.name
  task_definition = aws_ecs_task_definition.api.family
  desired_count   = 1

  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/platform-fargate.html
  launch_type      = "FARGATE" # default is EC2
  platform_version = "1.4.0"

  enable_execute_command = true

  network_configuration {
    assign_public_ip = true # just for testing; in production, use private subnets with a NAT gateway

    subnets = [
      aws_subnet.public_a.id
    ]

    security_groups = [
      aws_security_group.ecs_tasks.id
    ]
  }
}