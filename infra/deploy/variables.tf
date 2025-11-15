variable "project_name" {
  default = "recipe-api"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "contact" {
  default = "admin.devops@abcorp.moc"
}

variable "db_username" {
  default = "adminx"

}

variable "db_password" {
  description = "The password for the RDS database"
  type        = string
  sensitive   = true
}

variable "ecr_proxy_image" {
  description = "The ECR image URI for the proxy container"
}

variable "ecr_api_image" {

}

variable "django_secret_key" {

}
