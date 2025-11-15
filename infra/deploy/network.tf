resource "aws_vpc" "main" {
  cidr_block = "10.10.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${local.prefix}-main" # 👈 this sets the VPC's visible name in the console
    Environment = terraform.workspace
  }
}


resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.prefix}-main-igw"
  }
}

# public subnet ========================= #
# used for LB

# public subnet A ----------------------- #
resource "aws_subnet" "public_a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.10.22.0/24"
  # availability_zone = "${var.aws_region}a"
  availability_zone       = "${data.aws_region.current.id}a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${local.prefix}-public-a"
    Environment = terraform.workspace
  }
}

resource "aws_route_table" "public_a" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${local.prefix}-public-a-rt"
    Environment = terraform.workspace
  }
}

resource "aws_route_table_association" "name" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_a.id
}

resource "aws_route" "public_a_internet_access" {
  route_table_id         = aws_route_table.public_a.id
  destination_cidr_block = "0.0.0.0/0" # public access
  gateway_id             = aws_internet_gateway.main.id
}

# private subnet ========================= #
# used for internal services (EC2, RDS, etc)

# private subnet A ----------------------- #
resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.10.88.0/24"
  availability_zone       = "${data.aws_region.current.id}a"
  map_public_ip_on_launch = false

  tags = {
    Name        = "${local.prefix}-private-a"
    Environment = terraform.workspace
  }
}

resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.10.99.0/24"
  availability_zone       = "${data.aws_region.current.id}b"
  map_public_ip_on_launch = false

  tags = {
    Name        = "${local.prefix}-private-b"
    Environment = terraform.workspace
  }
}

# VPC endpoints ========================= #
# endpoints to allow access to AWS services without internet
# including, ECR, cludwatch, SSM,

resource "aws_security_group" "endpoint_access" {
  name   = "${local.prefix}-endpoint-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "Allow HTTPS access from within the VPC"
  }
}

# resource "aws_vpc_endpoint" "ecr" {
#   vpc_id = aws_vpc.main.id
#   service_name = "com.amazonaws.${data.aws_region.current.id}.ecr.api"
#   vpc_endpoint_type = "Interface" # no need to setup route tables for interface endpoints
#   private_dns_enabled = true

#   subnet_ids = [
#     aws_subnet.private_a.id,
#   ]

#   security_group_ids = [
#     aws_security_group.endpoint_access.id,
#   ]

#   tags = {
#     Name = "${local.prefix}-ecr-endpoint"
#     Environment = terraform.workspace
#   }
# }

# --------------------------------------- #
locals {
  vpc_endpoints = {
    ecr_api = {
      service_suffix = "ecr.api"
      name_suffix    = "ecr-endpoint"
    }
    ecr_dkr = {
      service_suffix = "ecr.dkr"
      name_suffix    = "ecr-dkr-endpoint"
    }
    cloudwatch_logs = {
      service_suffix = "logs"
      name_suffix    = "cloudwatch-logs-endpoint"
    }
    ssmmessages = {
      service_suffix = "ssmmessages"
      name_suffix    = "ssmmessages-endpoint"
    }
  }
}

resource "aws_vpc_endpoint" "this" {
  for_each = local.vpc_endpoints

  vpc_id              = aws_vpc.main.id
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  service_name = "com.amazonaws.${data.aws_region.current.id}.${each.value.service_suffix}"

  subnet_ids = [
    aws_subnet.private_a.id,
  ]

  security_group_ids = [
    aws_security_group.endpoint_access.id,
  ]

  tags = {
    Name        = "${local.prefix}-${each.value.name_suffix}"
    Environment = terraform.workspace
  }
}


# --------------------------------------- #

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.id}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    #aws_route_table.public_a.id, 
    aws_vpc.main.default_route_table_id
  ]

  tags = {
    Name        = "${local.prefix}-s3-endpoint"
    Environment = terraform.workspace
  }
}
