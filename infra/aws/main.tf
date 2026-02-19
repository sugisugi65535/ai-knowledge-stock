provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project = var.project_tag_value
    }
  }
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

locals {
  name_prefix = "ai-knowledge-stock"
  ecr_repository_arns = [
    "arn:aws:ecr:${var.aws_region}:${var.aws_account_id}:repository/${var.frontend_ecr_repository_name}",
    "arn:aws:ecr:${var.aws_region}:${var.aws_account_id}:repository/${var.backend_ecr_repository_name}",
    "arn:aws:ecr:${var.aws_region}:${var.aws_account_id}:repository/${var.database_ecr_repository_name}"
  ]
}

# 機密値の「キー」だけをTerraformで作成し、値は別スクリプトで投入する。
resource "aws_secretsmanager_secret" "postgres_user" {
  name = var.postgres_user_secret_name

  tags = {
    Name = "${local.name_prefix}-postgres-user-secret"
  }
}

resource "aws_secretsmanager_secret" "postgres_password" {
  name = var.postgres_password_secret_name

  tags = {
    Name = "${local.name_prefix}-postgres-password-secret"
  }
}

resource "aws_secretsmanager_secret" "postgres_db" {
  name = var.postgres_db_secret_name

  tags = {
    Name = "${local.name_prefix}-postgres-db-secret"
  }
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet1_cidr
  availability_zone       = var.subnet1_az
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-subnet1"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet2_cidr
  availability_zone       = var.subnet2_az
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-subnet2"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.name_prefix}-public-rt"
  }
}

resource "aws_route_table_association" "subnet1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "subnet2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "ALB security group"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "alb-sg"
  }
}

resource "aws_security_group_rule" "alb_ingress_80" {
  type              = "ingress"
  description       = "Allow HTTP from client IP"
  security_group_id = aws_security_group.alb_sg.id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [var.client_ip_cidr]
}

resource "aws_security_group_rule" "alb_egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.alb_sg.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group" "ec2_frontend_sg" {
  name        = "ec2-frontend-sg"
  description = "Frontend EC2 security group"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "ec2-frontend-sg"
  }
}

resource "aws_security_group_rule" "frontend_ingress_from_alb" {
  type                     = "ingress"
  security_group_id        = aws_security_group.ec2_frontend_sg.id
  from_port                = var.front_container_port
  to_port                  = var.front_container_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "frontend_egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.ec2_frontend_sg.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group" "ec2_backend_sg" {
  name        = "ec2-backend-sg"
  description = "Backend EC2 security group"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "ec2-backend-sg"
  }
}

resource "aws_security_group_rule" "backend_ingress_from_alb" {
  type                     = "ingress"
  security_group_id        = aws_security_group.ec2_backend_sg.id
  from_port                = var.back_container_port
  to_port                  = var.back_container_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "backend_egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.ec2_backend_sg.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group" "ec2_database_sg" {
  name        = "ec2-database-sg"
  description = "Database EC2 security group"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "ec2-database-sg"
  }
}

resource "aws_security_group_rule" "database_ingress_from_backend" {
  type                     = "ingress"
  security_group_id        = aws_security_group.ec2_database_sg.id
  from_port                = var.database_container_port
  to_port                  = var.database_container_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ec2_backend_sg.id
}

resource "aws_security_group_rule" "database_egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.ec2_database_sg.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_iam_role" "user_role_ec2" {
  name = "user-role-ec2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.user_role_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.user_role_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "user_role_ec2_secrets_read" {
  name        = "user-role-ec2-secrets-read"
  description = "Read-only access to required Secrets Manager secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          aws_secretsmanager_secret.postgres_user.arn,
          aws_secretsmanager_secret.postgres_password.arn,
          aws_secretsmanager_secret.postgres_db.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "secrets_read" {
  role       = aws_iam_role.user_role_ec2.name
  policy_arn = aws_iam_policy.user_role_ec2_secrets_read.arn
}

# GitHub Actions OIDC連携でECRへpushするための設定
resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
}

resource "aws_iam_role" "github_actions_ecr_push_role" {
  name = var.github_actions_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository}:*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "github_actions_ecr_push_policy" {
  name        = "github-actions-ecr-push-policy"
  description = "Allow GitHub Actions to push images to ECR repositories"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:BatchGetImage"
        ]
        Resource = local.ecr_repository_arns
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_ecr_push_policy_attachment" {
  role       = aws_iam_role.github_actions_ecr_push_role.name
  policy_arn = aws_iam_policy.github_actions_ecr_push_policy.arn
}

resource "aws_iam_instance_profile" "user_role_ec2_profile" {
  name = "user-role-ec2-instance-profile"
  role = aws_iam_role.user_role_ec2.name
}

resource "aws_instance" "database" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.subnet1.id
  vpc_security_group_ids      = [aws_security_group.ec2_database_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.user_role_ec2_profile.name
  user_data = templatefile("${path.module}/templates/database_user_data.sh.tftpl", {
    aws_region               = var.aws_region
    ecr_registry             = split("/", var.database_image_uri)[0]
    image_uri                = var.database_image_uri
    database_container_port  = var.database_container_port
    postgres_user_secret     = aws_secretsmanager_secret.postgres_user.name
    postgres_password_secret = aws_secretsmanager_secret.postgres_password.name
    postgres_db_secret       = aws_secretsmanager_secret.postgres_db.name
  })

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  tags = {
    Name = "${local.name_prefix}-database"
  }
}

resource "aws_instance" "backend" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.subnet1.id
  vpc_security_group_ids      = [aws_security_group.ec2_backend_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.user_role_ec2_profile.name
  user_data = templatefile("${path.module}/templates/backend_user_data.sh.tftpl", {
    aws_region               = var.aws_region
    ecr_registry             = split("/", var.back_image_uri)[0]
    image_uri                = var.back_image_uri
    back_container_port      = var.back_container_port
    database_private_ip      = aws_instance.database.private_ip
    database_container_port  = var.database_container_port
    postgres_user_secret     = aws_secretsmanager_secret.postgres_user.name
    postgres_password_secret = aws_secretsmanager_secret.postgres_password.name
    postgres_db_secret       = aws_secretsmanager_secret.postgres_db.name
    cors_origins = var.cors_origins != "" ? var.cors_origins : format(
      "http://%s,http://%s:80",
      aws_lb.main.dns_name,
      aws_lb.main.dns_name
    )
  })

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  tags = {
    Name = "${local.name_prefix}-backend"
  }
}

resource "aws_instance" "frontend" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.subnet1.id
  vpc_security_group_ids      = [aws_security_group.ec2_frontend_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.user_role_ec2_profile.name
  user_data = templatefile("${path.module}/templates/frontend_user_data.sh.tftpl", {
    aws_region           = var.aws_region
    ecr_registry         = split("/", var.front_image_uri)[0]
    image_uri            = var.front_image_uri
    front_container_port = var.front_container_port
    back_base_url        = aws_lb.main.dns_name
    back_base_port       = 80
  })

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  tags = {
    Name = "${local.name_prefix}-frontend"
  }
}

resource "aws_lb" "main" {
  name               = "ai-knowledge-stock-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  tags = {
    Name = "ai-knowledge-stock-alb"
  }
}

resource "aws_lb_target_group" "frontend" {
  name        = "ai-ks-front-tg"
  vpc_id      = aws_vpc.main.id
  port        = var.front_container_port
  protocol    = "HTTP"
  target_type = "instance"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group" "backend" {
  name        = "ai-ks-back-tg"
  vpc_id      = aws_vpc.main.id
  port        = var.back_container_port
  protocol    = "HTTP"
  target_type = "instance"

  health_check {
    path                = "/api/healthz"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group_attachment" "frontend" {
  target_group_arn = aws_lb_target_group.frontend.arn
  target_id        = aws_instance.frontend.id
  port             = var.front_container_port
}

resource "aws_lb_target_group_attachment" "backend" {
  target_group_arn = aws_lb_target_group.backend.arn
  target_id        = aws_instance.backend.id
  port             = var.back_container_port
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_listener_rule" "api_path" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}
