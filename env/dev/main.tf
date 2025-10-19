# network
module "network" {
    source = "../../modules/network"
    # デフォルト値を使用（必要に応じて上書き可能）
}

module "ec2" {
    source = "../../modules/ec2"
    # vpc_id = module.network.vpc_id
    subnet_ids = module.network.public_subnet_ids
    security_group_ids  = module.network.web_security_group_ids
    # デフォルト値を使用（必要に応じて上書き可能）

    ami = var.ami
    instance_type = var.instance_type
    instance_count = var.instance_count
}

module "elb" {
    source = "../../modules/elb"
    vpc_id = module.network.vpc_id
    subnet_ids = module.network.public_subnet_ids
    security_group_ids  = module.network.web_security_group_ids
    alb_security_group_ids  = module.network.alb_security_group_ids
    # デフォルト値を使用（必要に応じて上書き可能）

    instance_ids = module.ec2.instance_ids
    instance_count = var.instance_count
    ami = var.ami
}


# S3 bucket for Terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-bucket-dev-kentaindeed"
  
  tags = {
    Name        = "Terraform State Bucket Dev"
    Environment = "dev"
    Purpose     = "terraform-state"
    Owner       = "kentaindeed"
  }

#   lifecycle {
#     prevent_destroy = true
#   }
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Terraform backend configuration (temporarily commented out)
terraform {
  backend "s3" {
    bucket = "terraform-state-bucket-dev-kentaindeed"
    key    = "terraform.tfstate"
    region = "ap-northeast-1"
    encrypt = true
    use_lockfile  = true
  }
}
