locals {
  proxy_container_definitions = [
    {
      name              = "proxy"
      image             = var.ecr_proxy_image
      essential         = true
      memoryReservation = 256
      user              = "nginx"

      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "APP_HOST", value = "127.0.0.1" }
      ]

      mountPoints = [
        {
          sourceVolume  = "static"
          containerPath = "/vol/static"
          readOnly      = true
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_task_logs.name
          awslogs-region        = data.aws_region.current.id
          awslogs-stream-prefix = "proxy"
        }
      }
    }
  ]

  api_container_definitions = [
    {
      name              = "api"
      image             = var.ecr_api_image
      essential         = true
      memoryReservation = 256
      user              = "django-user"

      environment = [
        { name = "DB_HOST", value = aws_db_instance.main.address },
        { name = "DB_NAME", value = aws_db_instance.main.db_name },
        { name = "DB_PORT", value = "5432" },
        { name = "DB_USER", value = aws_db_instance.main.username },
        { name = "DB_PASS", value = aws_db_instance.main.password },
        { name = "DJANGO_SECRET_KEY", value = var.django_secret_key },
        { name = "ALLOWED_HOSTS", value = "*" },
      ]

      mountPoints = [
        {
          sourceVolume  = "static"
          containerPath = "/vol/web/static"
          readOnly      = false
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_task_logs.name
          awslogs-region        = data.aws_region.current.id
          awslogs-stream-prefix = "api"
        }
      }
    }
  ]

  # MERGE BOTH CONTAINERS INTO ONE LIST
  task_containers = concat(
    local.proxy_container_definitions,
    local.api_container_definitions,
  )
}
