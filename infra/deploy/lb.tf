resource "aws_security_group" "lb" {
  name   = "${local.prefix}-lb-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "Allow HTTP traffic from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS traffic from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic for port 8000 (our app)"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "api" {
  name               = "${local.prefix}-api-lb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets = [
    aws_subnet.public_a.id,
    #aws_subnet.public_b.id
  ]
}

resource "aws_lb_target_group" "api" {
  name     = "${local.prefix}-api-tg"
  port     = 8000   # port where our app is listening
  protocol = "HTTP" # our app listens on HTTP in private subnet
  vpc_id   = aws_vpc.main.id
  # forward the traffic to IP addresses (ECS tasks) instead of instance IDs
  # basically we forward the request from LB to the internal IP of the ECS task
  target_type = "ip"

  # make sure the LB forwards traffic only to healthy instances
  health_check {
    path = "/api/healthz/"
    # protocol            = "HTTP"
    # matcher             = "200-399"
    # interval            = 30
    # timeout             = 5
    # healthy_threshold   = 2
    # unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "api_http" {
  load_balancer_arn = aws_lb.api.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

# resource "aws_lb_listener" "api_https" {
#   load_balancer_arn = aws_lb.api.arn
#   port              = 443
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = var.acm_certificate_arn

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.api.arn
#   }
# }
