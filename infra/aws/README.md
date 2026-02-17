# aws infra

Terraform で AWS 環境を構築するディレクトリ。

## 構築対象
- VPC / Subnet / Route / IGW
- ALB / Target Group / Listener Rule
- EC2 (frontend, backend, database)
- IAM Role / Instance Profile

## 実行
ルートディレクトリで以下を実行。

```bash
make build-aws
make put-secrets-aws
make destroy-aws
```

`make build-aws` は `terraform init/validate/plan` まで実行し、`apply` は実行しない。
