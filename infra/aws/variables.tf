variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "ap-northeast-1"
}

variable "aws_account_id" {
  type        = string
  description = "AWS account ID"
  default     = "636965820260"
}

variable "project_tag_value" {
  type        = string
  description = "Project tag value"
  default     = "AI-knowledge-stock"
}

variable "client_ip_cidr" {
  type        = string
  description = "Allowed client IP CIDR for ALB ingress"
  default     = "113.155.37.221/32"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "subnet1_cidr" {
  type        = string
  description = "Subnet1 CIDR block"
  default     = "10.0.1.0/24"
}

variable "subnet2_cidr" {
  type        = string
  description = "Subnet2 CIDR block"
  default     = "10.0.2.0/24"
}

variable "subnet1_az" {
  type        = string
  description = "Subnet1 AZ"
  default     = "ap-northeast-1a"
}

variable "subnet2_az" {
  type        = string
  description = "Subnet2 AZ"
  default     = "ap-northeast-1d"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "front_container_port" {
  type        = number
  description = "Frontend container port"
}

variable "back_container_port" {
  type        = number
  description = "Backend container port"
}

variable "database_container_port" {
  type        = number
  description = "Database container port"
}

variable "front_image_uri" {
  type        = string
  description = "Frontend ECR image URI"
  default     = "636965820260.dkr.ecr.ap-northeast-1.amazonaws.com/ai-knowledge-stock/frontend:latest"
}

variable "back_image_uri" {
  type        = string
  description = "Backend ECR image URI"
  default     = "636965820260.dkr.ecr.ap-northeast-1.amazonaws.com/ai-knowledge-stock/backend:latest"
}

variable "database_image_uri" {
  type        = string
  description = "Database ECR image URI"
  default     = "636965820260.dkr.ecr.ap-northeast-1.amazonaws.com/ai-knowledge-stock/database:latest"
}

variable "frontend_ecr_repository_name" {
  type        = string
  description = "Frontend ECR repository name"
  default     = "ai-knowledge-stock/frontend"
}

variable "backend_ecr_repository_name" {
  type        = string
  description = "Backend ECR repository name"
  default     = "ai-knowledge-stock/backend"
}

variable "database_ecr_repository_name" {
  type        = string
  description = "Database ECR repository name"
  default     = "ai-knowledge-stock/database"
}

variable "github_repository" {
  type        = string
  description = "GitHub repository in owner/name format"
  default     = "taksugiu/ai-knowledge-stock"
}

variable "github_actions_role_name" {
  type        = string
  description = "IAM role name for GitHub Actions OIDC"
  default     = "github-actions-ecr-push-role"
}

variable "cors_origins" {
  type        = string
  description = "CORS origins for backend"
  default     = ""
}

variable "postgres_user_secret_name" {
  type        = string
  description = "Secrets Manager secret name for POSTGRES_USER"
  default     = "ai-knowledge-stock/postgres/user"
}

variable "postgres_password_secret_name" {
  type        = string
  description = "Secrets Manager secret name for POSTGRES_PASSWORD"
  default     = "ai-knowledge-stock/postgres/password"
}

variable "postgres_db_secret_name" {
  type        = string
  description = "Secrets Manager secret name for POSTGRES_DB"
  default     = "ai-knowledge-stock/postgres/db"
}
