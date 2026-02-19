# ai-knowledge-stock

knowledge をストックして、AIで要約や検索を行うシステム。

## 概要

このリポジトリは、以下の3層構成を前提としたプロジェクトです。

- frontend: React + TypeScript + Vite
- backend: FastAPI + SQLAlchemy
- database: PostgreSQL

ローカル環境は Docker Compose、AWS 環境は Terraform で構築します。

## ディレクトリ構成

- `frontend/` フロントエンドアプリケーション
- `backend/` バックエンド API
- `database/` DBコンテナ関連
- `docker/` Compose ファイル（`compose.local.yml`, `compose.aws.yml`）
- `config/` 非機密の設定ファイル（ポート、接続先など）
- `env/` 機密設定ファイル（git 管理対象外）
- `infra/aws/` AWS Terraform コード
- `script/` build/destroy などの補助スクリプト

## ローカル環境の利用方法

### 1. 環境構築

```bash
make build-local
```

- 初回実行時、`env/env.database` がなければ対話で作成されます。
- `docker/compose.local.yml` を利用して `frontend/backend/database` を起動します。

### 2. 停止・削除

```bash
make destroy-local
```

## AWS環境の利用方法

### 1. 事前準備

- AWS CLI 認証を済ませておく
- Terraform が未導入でも `make build-aws` で自動セットアップ対応
- `env/env.infra` に `CLIENT_IP_CIDR` を設定（未設定なら対話入力）
- tfstate 用 S3 バケットを事前作成しておく
  - バケット名: `tfstate-ai-knowledge-stock`
  - key: `ai-knowledge-stock/prd/terraform.tfstate`
  - リージョン: `ap-northeast-1`
  - バージョニング: 有効
- ECR リポジトリが存在していること
  - `ai-knowledge-stock/frontend`
  - `ai-knowledge-stock/backend`
  - `ai-knowledge-stock/database`

`env/env.infra` 例:

```env
CLIENT_IP_CIDR=113.155.37.221/32
```

### 2. Terraform plan まで実行

```bash
make build-aws
```

- 実行前に AWS ログイン状態を確認（未ログイン時は停止）
- S3 tfstate バケット存在とバージョニング状態を確認（不備があれば停止）
- 指定 ECR リポジトリ存在を確認（不足があれば停止）
- `infra/aws` で `terraform init` / `terraform validate` / `terraform plan -out=tfplan` を実行
- 機密値は Terraform に直接渡さない構成
- `terraform plan` の結果表示後、`terraform apply` の実行可否を確認
  - `y` 入力時のみ apply 実行

### 3. Secrets の value 投入

```bash
make put-secrets-aws
```

- `env/env.database` の値を Secrets Manager に登録します
- 対象: `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`

### 4. AWS環境の削除

```bash
make destroy-aws
```

- destroy 実行前に確認プロンプトが表示され、`y` 入力時のみ実行
- `make destory-aws`（スペルは指示仕様に合わせたエイリアス）でも同じ処理を実行可能

## 主要設定ファイル

- `config/common.conf`
  - `FRONT_CONTAINER_PORT`, `BACK_CONTAINER_PORT`, `DATABASE_CONTAINER_PORT` など
- `config/frontend.conf`
  - `BACK_BASE_URL`, `BACK_BASE_PORT` など
- `config/backend.conf`
  - `CORS_ORIGINS` など
- `env/env.database`（機密）
  - `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`

## セキュリティ方針（AWS）

- 機密情報は Secrets Manager で管理
- Terraform は secret のキー（名前）を作成し、value は別スクリプトで登録
- EC2 起動時に Secrets Manager から取得してコンテナへ環境変数として渡す

## 補足

- 開発時はまず `make build-local` でローカル確認
- AWS は `make build-aws`（planと確認付きapply）→ `make put-secrets-aws` の順で運用
