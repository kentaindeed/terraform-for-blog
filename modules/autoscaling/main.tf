# auto scaling
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

resource "aws_autoscaling_group" "terraform-asg" {
  name                      = "${local.name_prefix}-asg"
  load_balancers = var.elb
  max_size                  = 1
  min_size                  = 1
  desired_capacity          = 1
  health_check_grace_period = 30
  health_check_type         = "EC2"
  force_delete              = true
  launch_template {
        id      = aws_launch_template.myapp_launch_template.id
        version = "$Latest"
  }
  vpc_zone_identifier       = var.subnet_ids
  target_group_arns         = var.elb-tg
  availability_zones = local.availability_zones
  availability_zone_distributions = local.availability_zones
  default_cooldown          = 30
}

#launch template
resource "aws_launch_template" "myapp_launch_template" {
  name = "${local.name_prefix}-launch-template"
  default_version = 1
  latest_version = 1
  description = "launch template for myapp"
  image_id = var.ami
  instance_type = var.instance_type
  vpc_security_group_ids = var.security_group_ids
#   key_name = var.instance_keypair
}