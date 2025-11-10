output "cd_user_access_key_id" {
  value = aws_iam_access_key.cd.id
}

output "cd_user_secret_access_key" {
  value     = aws_iam_access_key.cd.secret
  sensitive = true

}

output "ecr_api_repo_url" {
  value = aws_ecr_repository.api.repository_url
}

output "ecr_proxy_repo_url" {
  value = aws_ecr_repository.proxy.repository_url
}
