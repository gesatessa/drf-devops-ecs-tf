output "vpc_id" {
  description = "ID of the main VPC"
  value       = aws_vpc.main.id
}

output "internet_gateway_id" {
  description = "ID of the main Internet Gateway"
  value       = aws_internet_gateway.main.id
}
