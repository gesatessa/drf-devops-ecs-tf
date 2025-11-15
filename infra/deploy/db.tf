resource "aws_db_subnet_group" "main" {
  name = "${local.prefix}-rds"
  subnet_ids = [
    aws_subnet.private_a.id,
  ]

  tags = {
    Name = "${local.prefix}-db-subnet-grp"
  }
}

resource "aws_security_group" "rds" {
  description = "Allow inbound Postgres traffic from ECS tasks"
  name        = "${local.prefix}-rds-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    #cidr_blocks = [aws_security_group.ecs_tasks.id]
    description = "Allow Postgres access from ECS tasks"

    # make sure only ECS tasks can access RDS
    # security_groups = [aws_security_group.ecs_tasks.id]
  }

  tags = {
    Name = "${local.prefix}-rds-sg"
  }
}

resource "aws_db_instance" "main" {
  identifier                 = "${local.prefix}-db" # the resource name in the aws console
  db_name                    = "recipe_db"
  allocated_storage          = 20
  storage_type               = "gp3"
  engine                     = "postgres"
  engine_version             = "17.4"
  auto_minor_version_upgrade = true
  instance_class             = "db.t4g.micro"
  username                   = var.db_username
  password                   = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  skip_final_snapshot     = true  # in production, set up a final snapshot
  multi_az                = false # in production, consider multi-AZ for high availability
  backup_retention_period = 0     # in production, set to a positive number for backups
  publicly_accessible     = false # RDS should not be publicly accessible

  tags = {
    Name = "${local.prefix}-rds-instance"
  }
}
