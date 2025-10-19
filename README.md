# VPC Terraform Project

AWS上にVPC、EC2インスタンス、Application Load Balancerを構築するTerraformプロジェクトです。

## 📋 プロジェクト概要

このプロジェクトは、以下のAWSリソースを自動構築します：

- **VPC**: カスタムネットワーク環境
- **パブリックサブネット**: 2つのAZ（ap-northeast-1a, ap-northeast-1c）
- **インターネットゲートウェイ**: 外部接続用
- **Application Load Balancer (ALB)**: 高可用性ロードバランサー
- **Auto Scaling Group**: 自動スケーリング機能
- **Launch Template**: EC2インスタンス起動テンプレート
- **Target Group**: ALBとEC2インスタンス間の負荷分散
- **セキュリティグループ**: ALB経由のアクセス制御
- **EC2インスタンス**: 開発用サーバー（Auto Scaling対応）
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
│  ┌─────────────────────────────────────┐ │
│  │         Target Group               │ │
│  │      (Health Check)                │ │
│  └─────────────────────────────────────┘ │
│                     │                   │
│  ┌─────────────────────────────────────┐ │
│  │       Auto Scaling Group           │ │
│  │    (Min: 1, Max: 1, Desired: 1)    │ │
│  └─────────────────────────────────────┘ │
│                     │                   │
│  ┌─────────────────┐ ┌─────────────────┐│
│  │ Public Subnet   │ │ Public Subnet   ││
│  │ 10.0.0.0/24     │ │ 10.0.1.0/24     ││
│  │ ap-northeast-1a │ │ ap-northeast-1c ││
│  │                 │ │                 ││
│  │   [EC2]         │ │   [EC2]         ││
│  │ (Auto Scaling)  │ │ (Auto Scaling)  ││
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
    ├── ec2/                   # EC2モジュール（スタンドアロン用）
    │   ├── main.tf            # EC2インスタンス、IAMロール
    │   ├── variable.tf        # 変数定義
    │   └── output.tf          # インスタンスID、IP出力
    ├── elb/                   # ELBモジュール
    │   ├── main.tf            # Application Load Balancer
    │   ├── variable.tf        # 変数定義
    │   └── output.tf          # ALB情報出力
    └── autoscaling/           # Auto Scalingモジュール（新規追加）
        ├── main.tf            # Auto Scaling Group、Launch Template
        ├── variable.tf        # 変数定義
        └── output.tf          # ASG情報出力
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
| `instance_count` | インスタンス数（EC2モジュール用） | `1` | `2` |

### Auto Scaling設定

| 変数名 | 説明 | デフォルト値 | 例 |
|--------|------|-------------|-----|
| `min_size` | 最小インスタンス数 | `1` | `2` |
| `max_size` | 最大インスタンス数 | `1` | `5` |
| `desired_capacity` | 希望インスタンス数 | `1` | `3` |
| `health_check_grace_period` | ヘルスチェック猶予期間（秒） | `30` | `300` |
| `health_check_type` | ヘルスチェックタイプ | `EC2` | `ELB` |

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

- **Backend**: S3 (`terraform-state-bucket-dev-kentaindeed`)
- **暗号化**: AES256で有効
- **バージョニング**: 有効（状態ファイルの履歴管理）
- **パブリックアクセス**: 完全ブロック
- **状態ファイル**: `terraform.tfstate`
- **リージョン**: `ap-northeast-1`

### Backend設定
```hcl
terraform {
  backend "s3" {
    bucket = "terraform-state-bucket-dev-kentaindeed"
    key    = "terraform.tfstate"
    region = "ap-northeast-1"
    encrypt = true
  }
}
```

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

2. **Backend設定変更エラー**
   ```bash
   # 状態ファイル移行
   terraform init -migrate-state
   ```

3. **権限エラー**
   - AWS CLIの設定とIAM権限を確認
   - EC2、ELB、S3の権限が必要

4. **リージョン不一致**
   - `local.tf`と`terraform.tfvars`のリージョン設定を確認

5. **モジュール変数エラー**
   - 各モジュールの`variable.tf`で必要な変数が定義されているか確認

### ログ確認

```bash
# Terraform詳細ログ
export TF_LOG=DEBUG
terraform plan

# 診断情報確認
terraform validate
terraform fmt -check
```

### ALB接続確認

```bash
# ALBのDNS名確認
terraform output alb_dns_name

# ヘルスチェック確認
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
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

## 🔄 モジュール構成

### Network Module
- VPC、サブネット、インターネットゲートウェイ
- ALB用とEC2用のセキュリティグループ
- ルートテーブルとアソシエーション
- VPC Endpoint（SSM用）

### EC2 Module（スタンドアロン用）
- EC2インスタンス（複数AZに分散配置）
- IAMロール（SSM用）
- インスタンスプロファイル

### ELB Module
- Application Load Balancer
- Target Group（ヘルスチェック設定付き）
- リスナー設定（HTTP/HTTPS）
- Target Group Attachment

### Auto Scaling Module（推奨）
- Auto Scaling Group（自動スケーリング）
- Launch Template（EC2起動設定）
- Target Group連携
- ヘルスチェック設定（EC2 + ELB）
- 複数AZ対応

## 🌐 アクセス方法

### Web アクセス
```bash
# ALBのDNS名でアクセス
http://<alb-dns-name>
https://<alb-dns-name>
```

### EC2 管理アクセス
```bash
# Session Manager経由（推奨）
aws ssm start-session --target <instance-id>

# SSH（必要に応じて）
ssh -i your-key.pem ec2-user@<private-ip>
```

---

**注意**: このプロジェクトはKiro AIアシスタントの設定変更ポリシーに従って管理されています。Terraformファイルの変更は必ず承認を得てから実行してください。
## 🔧 
Auto Scaling設定

### 基本設定
- **最小インスタンス数**: 1
- **最大インスタンス数**: 1  
- **希望インスタンス数**: 1
- **ヘルスチェック猶予期間**: 30秒
- **ヘルスチェックタイプ**: EC2

### Launch Template
- **AMI**: 設定可能（デフォルト: Amazon Linux 2）
- **インスタンスタイプ**: 設定可能（デフォルト: t2.micro）
- **セキュリティグループ**: ALB経由のアクセスのみ許可
- **VPC**: 複数AZに分散配置

### スケーリングポリシー
現在は手動スケーリングのみ対応。将来的にCloudWatchメトリクスベースの自動スケーリングを追加予定。

## 🚨 重要な注意事項

### モジュール選択
- **Auto Scalingを使用する場合**: `autoscaling`モジュールのみを有効化
- **スタンドアロンEC2を使用する場合**: `ec2`モジュールのみを有効化
- **両方同時使用は非推奨**: リソースの重複や競合が発生する可能性

### 現在の設定
```hcl
# env/dev/main.tf で以下のモジュールが有効
module "network" { ... }      # ネットワーク基盤
module "ec2" { ... }          # スタンドアロンEC2
module "elb" { ... }          # Application Load Balancer  
module "autoscaling" { ... }  # Auto Scaling Group
```

### 推奨構成
本番環境では`autoscaling`モジュールの使用を推奨します：
- 高可用性の確保
- 自動復旧機能
- 将来的なスケーリング対応

## 🔍 ヘルスチェック

### Target Group ヘルスチェック
- **パス**: `/`
- **ポート**: 80
- **プロトコル**: HTTP
- **正常レスポンス**: 200
- **間隔**: 10秒
- **タイムアウト**: 5秒
- **正常閾値**: 2回
- **異常閾値**: 2回

### Auto Scaling ヘルスチェック
- **タイプ**: EC2（インスタンスレベル）
- **猶予期間**: 30秒
- **Target Group連携**: 有効

## 🔄 デプロイメント戦略

### Blue-Green デプロイメント
Launch Templateを更新してローリングアップデートが可能：

```bash
# Launch Templateの更新
terraform apply

# インスタンスの段階的更新
aws autoscaling start-instance-refresh --auto-scaling-group-name <asg-name>
```

### ゼロダウンタイムデプロイ
- Target Groupのヘルスチェックにより、新しいインスタンスが正常になってから古いインスタンスを削除
- ALBが自動的にトラフィックを正常なインスタンスにルーティング
