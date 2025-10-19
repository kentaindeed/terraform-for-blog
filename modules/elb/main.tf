#elb
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

# load balanacer 
resource "aws_lb" "elb" {
    load_balancer_type = "application"
    name = "${local.name_prefix}-elb"
    internal = false
    ip_address_type = "ipv4"
    subnets = var.subnet_ids
    security_groups = var.alb_security_group_ids

    tags = {
        Name = "${local.name_prefix}-elb"
    }
}

# target group
resource "aws_lb_target_group" "elb-tg" {
    name = "${local.name_prefix}-tg"
    port = 80
    protocol = "HTTP"
    vpc_id = var.vpc_id

    # sticker session
    stickiness {
        type = "lb_cookie"
        cookie_duration = 1800
        enabled = true
    }

    #healthcheck 設定
    health_check {
        path = "/"
        port = 80
        protocol = "HTTP"
        matcher = "200"
        interval = 10
        timeout = 5
        healthy_threshold = 2
        unhealthy_threshold = 2
    }

    tags = {
        Name = "${local.name_prefix}-tg"
    }
}

# target group attachment
resource "aws_lb_target_group_attachment" "elb-tg-attachment" {
    count = length(var.instance_ids)
    target_group_arn = aws_lb_target_group.elb-tg.arn
    target_id = var.instance_ids[count.index]
    port = 80
}

# lister rule
resource "aws_lb_listener" "elb-listener" {
    load_balancer_arn = aws_lb.elb.arn
    port = 80
    protocol = "HTTP"
    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.elb-tg.arn
    }
}