# VPC Terraform Project

AWS上にVPC、EC2インスタンス、Application Load Balancerを構築するTerraformプロジェクトです。

## 📋 プロジェクト概要

このプロジェクトは、以下のAWSリソースを自動構築します：

- **VPC**: カスタムネットワーク環境
- **パブリックサブネット**: 2つのAZ（ap-northeast-1a, ap-northeast-1c）
- **インターネットゲートウェイ**: 外部接続用
- **Application Load Balancer (ALB)**: 高可用性ロードバランサー
- **セキュリティグループ**: ALB経由のアクセス制御
- **EC2インスタンス**: 開発用サーバー
- **S3バケット**: Terraform状態ファイル保存用（バージョニング有効）

## 🏗️ アーキテクチャ

```
                    Internet
                        │
┌─────────────────────────────────────────┐
│                  VPC                    │
│              10.0.0.0/16                │
│                                         │
│  ┌─────────────────────────────────────┐ │
│  │      Internet Gateway              │ │
│  └─────────────────────────────────────┘ │
│                     │                   │
│  ┌─────────────────────────────────────┐ │
│  │   Application Load Balancer (ALB)  │ │
│  │         (Public Access)            │ │
│  └─────────────────────────────────────┘ │
│                     │                   │
│  ┌─────────────────┐ ┌─────────────────┐│
│  │ Public Subnet   │ │ Public Subnet   ││
│  │ 10.0.0.0/24     │ │ 10.0.1.0/24     ││
│  │ ap-northeast-1a │ │ ap-northeast-1c ││
│  │                 │ │                 ││
│  │   [EC2]         │ │   [EC2]         ││
│  │ (ALB経由のみ)    │ │ (ALB経由のみ)    ││
│  └─────────────────┘ └─────────────────┘│
└─────────────────────────────────────────┘
```

## 📁 プロジェクト構造

```
vpc-terraform/
├── README.md
├── local.tf                    # 共通変数定義
├── .gitignore
├── .kiro/
│   └── steering/              # Kiro設定ルール
│       └── terraform-change-policy.md
├── env/
│   └── dev/                   # 開発環境
│       ├── main.tf            # メイン設定
│       ├── variable.tf        # 変数定義
│       └── terraform.tfvars   # 変数値
└── modules/
    ├── network/               # ネットワークモジュール
    │   ├── main.tf            # VPC、サブネット、セキュリティグループ
    │   ├── variable.tf        # 変数定義
    │   └── output.tf          # 出力値
    ├── ec2/                   # EC2モジュール
    │   ├── main.tf            # EC2インスタンス、IAMロール
    │   ├── variable.tf        # 変数定義
    │   └── output.tf          # インスタンスID、IP出力
    └── elb/                   # ELBモジュール（新規追加）
        ├── main.tf            # Application Load Balancer
        ├── variable.tf        # 変数定義
        └── output.tf          # ALB情報出力
```

## 🚀 セットアップ手順

### 前提条件

- AWS CLI設定済み
- Terraform v1.0以上
- 適切なAWS権限

### 1. リポジトリクローン

```bash
git clone <repository-url>
cd vpc-terraform
```

### 2. 環境設定

```bash
cd env/dev
```

### 3. 変数設定

`terraform.tfvars`を編集して環境に合わせて設定：

```hcl
# EC2 Configuration
ami           = "ami-0228232d282f16465"  # Amazon Linux 2 AMI
instance_type = "t3.small"
instance_count = 1
```

### 4. S3バケット名変更

`main.tf`のS3バケット名を一意な名前に変更：

```hcl
bucket = "terraform-state-bucket-dev-your-unique-name"
```

### 5. 初期化と実行

```bash
# Terraform初期化
terraform init

# 実行計画確認
terraform plan

# リソース作成
terraform apply
```

## ⚙️ 設定可能な変数

### EC2設定

| 変数名 | 説明 | デフォルト値 | 例 |
|--------|------|-------------|-----|
| `ami` | AMI ID | - | `ami-0228232d282f16465` |
| `instance_type` | インスタンスタイプ | `t2.micro` | `t3.small` |
| `instance_count` | インスタンス数 | `1` | `2` |

### ネットワーク設定

| 変数名 | 説明 | デフォルト値 |
|--------|------|-------------|
| `vpc_cidr_block` | VPC CIDR | `10.0.0.0/16` |
| `aws_region` | AWSリージョン | `ap-northeast-1` |
| `aws_profile` | AWSプロファイル | `default` |

## 🔒 セキュリティグループ

### ALB用セキュリティグループ (`alb_security`)
- **HTTP (80)**: 全世界からアクセス可能 (`0.0.0.0/0`)
- **HTTPS (443)**: 全世界からアクセス可能 (`0.0.0.0/0`)
- **Egress**: 全ての外向き通信許可

### EC2用セキュリティグループ (`developers`)
- **SSH (22)**: 特定IPからのみ (`153.239.139.130/32`)
- **HTTP (80)**: ALB経由のみ（ALBセキュリティグループから）
- **HTTPS (443)**: ALB経由のみ（ALBセキュリティグループから）
- **Egress**: 全ての外向き通信許可

### セキュリティ設計
- **外部からの直接アクセス**: ALBのみ
- **EC2への直接アクセス**: SSH以外は不可
- **Webトラフィック**: 必ずALB経由でルーティング

## 🔧 EC2接続方法

### Session Manager（推奨）

```bash
# AWS Systems Manager経由で接続
aws ssm start-session --target <instance-id>
```

### SSH接続

キーペアを設定している場合：

```bash
ssh -i your-key.pem ec2-user@<public-ip>
```

## 📦 Terraform状態管理

- **Backend**: S3
- **暗号化**: 有効
- **バージョニング**: 有効
- **状態ファイル**: `terraform.tfstate`

## 🧹 リソース削除

```bash
# 全リソース削除
terraform destroy
```

**注意**: S3バケットは手動で削除する必要がある場合があります。

## 📝 トラブルシューティング

### よくある問題

1. **S3バケット名重複**
   - `main.tf`のバケット名を一意な名前に変更

2. **権限エラー**
   - AWS CLIの設定とIAM権限を確認

3. **リージョン不一致**
   - `local.tf`と`terraform.tfvars`のリージョン設定を確認

### ログ確認

```bash
# Terraform詳細ログ
export TF_LOG=DEBUG
terraform plan
```

## 🤝 貢献

1. フォークしてブランチ作成
2. 変更をコミット
3. プルリクエスト作成

## 📄 ライセンス

MIT License

## 👤 作成者

- **Owner**: kentaindeed
- **Project**: terraform-project
- **Environment**: dev

---

**注意**: このプロジェクトはKiro AIアシスタントの設定変更ポリシーに従って管理されています。設定変更は必ず承認を得てから実行してください。