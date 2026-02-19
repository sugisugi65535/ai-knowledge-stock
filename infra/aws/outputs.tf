output "alb_dns_name" {
  value       = aws_lb.main.dns_name
  description = "ALB DNS name"
}

output "frontend_instance_id" {
  value       = aws_instance.frontend.id
  description = "Frontend EC2 instance ID"
}

output "backend_instance_id" {
  value       = aws_instance.backend.id
  description = "Backend EC2 instance ID"
}

output "database_instance_id" {
  value       = aws_instance.database.id
  description = "Database EC2 instance ID"
}

output "postgres_user_secret_name" {
  value       = aws_secretsmanager_secret.postgres_user.name
  description = "Secrets Manager name for POSTGRES_USER"
}

output "postgres_password_secret_name" {
  value       = aws_secretsmanager_secret.postgres_password.name
  description = "Secrets Manager name for POSTGRES_PASSWORD"
}

output "postgres_db_secret_name" {
  value       = aws_secretsmanager_secret.postgres_db.name
  description = "Secrets Manager name for POSTGRES_DB"
}

output "github_actions_ecr_push_role_arn" {
  value       = aws_iam_role.github_actions_ecr_push_role.arn
  description = "IAM role ARN for GitHub Actions OIDC"
}
