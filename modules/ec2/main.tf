# ec2
locals {
    common_variables = {
        region = "ap-southeast-1"
        profile = "default"
    }
    common_tags = {
        Environment = "dev"
        Project = "terraform-project"
        Owner = "kentaindeed"
        CreatedBy = "terraform"
        CreatedAt = "2025-01-01"
    }
    availability_zones = [
        "ap-northeast-1a", 
        "ap-northeast-1c", 
        "ap-northeast-1d"
    ]
    
    # 名前のプレフィックスを定義
    name_prefix = "${local.common_tags.Environment}-${local.common_tags.Project}"
}


resource "aws_instance" "ec2" {
    count         = var.instance_count
    ami           = var.ami
    instance_type = var.instance_type
    subnet_id     = var.subnet_ids[count.index % length(var.subnet_ids)]
    vpc_security_group_ids = var.security_group_ids 
    tags = merge(local.common_tags, {
        Name = "${local.common_tags.Project}-ec2-${count.index + 1}"
    })
    iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

}

# IAMロールを作成
resource "aws_iam_role" "ec2_ssm_role" {
  name = "EC2-SSM-Role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# SSMポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# インスタンスプロファイル
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

