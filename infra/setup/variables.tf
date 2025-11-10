variable "project_name" {
  default = "recipe-api"
}

variable "aws_region" {
  default = "us-east-1"
  type    = string
}

variable "tf_state_bucket" {
  default = "recipe-379738700125-django-api"
}

variable "contact" {
  default = "admin.devops@abcorp.moc"
}