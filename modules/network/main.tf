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

# vpc 
resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr_block

    enable_dns_hostnames = true
    enable_dns_support = true
    tags = merge(local.common_tags, {
        Name = "${local.name_prefix}-vpc"
    })
}

# vpc endpoint ssm agent
resource "aws_vpc_endpoint" "ssmendpoint" {
    vpc_id = aws_vpc.main.id
    service_name = "com.amazonaws.ap-northeast-1.ssm"
    vpc_endpoint_type = "Interface"
    private_dns_enabled = true
    security_group_ids = [aws_security_group.developers.id]
    subnet_ids = aws_subnet.public.*.id

    tags = merge(local.common_tags, {
        Name = "${local.name_prefix}-ssm-endpoint"
  })
}

# internet gateway
resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id
    tags = merge(local.common_tags, {
        Name = "${local.name_prefix}-igw"
    })
}

# public subnet *2
resource "aws_subnet" "public" {
    count = 2
    vpc_id = aws_vpc.main.id
    availability_zone = local.availability_zones[count.index]
    cidr_block = "10.0.${count.index}.0/24"
    tags = merge(local.common_tags, {
        Name = "${local.name_prefix}-public-subnet-${count.index}"
    })
}


# public route table
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id
    tags = merge(local.common_tags, {
        Name = "${local.name_prefix}-public-rt"
    })
}

# public route
resource "aws_route" "public" {
    route_table_id = aws_route_table.public.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
}

# public subnet association
resource "aws_route_table_association" "public" {
    count = 2
    subnet_id = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.public.id
}


# security group for developers
resource "aws_security_group" "developers" {
    name        = "${local.name_prefix}-developers"
    description = "security group for developers"
    vpc_id      = aws_vpc.main.id
    
    tags = merge(local.common_tags, {
        Name = "${local.name_prefix}-developers-sg"
    })
    
    # inline rulesとseparate rulesの混在を避けるため、
    # revoke_rules_on_deleteを使用
    revoke_rules_on_delete = true
    
    lifecycle {
        create_before_destroy = true
    }
}

# SSH rule
resource "aws_security_group_rule" "ssh_ingress" {
    type              = "ingress"
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/32"]
    security_group_id = aws_security_group.developers.id
    description       = "SSH access"
}

# HTTP rule
resource "aws_security_group_rule" "http_ingress" {
    type              = "ingress"
    from_port         = 80
    to_port           = 80
    protocol          = "tcp"
    source_security_group_id = aws_security_group.alb-security.id
    security_group_id = aws_security_group.developers.id
    description       = "HTTP access"
}

# HTTPS rule
resource "aws_security_group_rule" "https_ingress" {
    type              = "ingress"
    from_port         = 443
    to_port           = 443
    protocol          = "tcp"
    source_security_group_id = aws_security_group.alb-security.id
    security_group_id = aws_security_group.developers.id
    description       = "HTTPS access"
}

# ssm HTTPS rule
resource "aws_security_group_rule" "ssm_https_ingress" {
    type              = "ingress"
    from_port         = 443
    to_port           = 443
    protocol          = "tcp"
    source_security_group_id = aws_security_group.ssm-security.id
    security_group_id = aws_security_group.developers.id
    description       = "HTTPS access"
}

# Egress rule
resource "aws_security_group_rule" "all_egress" {
    type              = "egress"
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.developers.id
    description       = "All outbound traffic"
}

# ALB セキュリティグループ
resource "aws_security_group" "alb-security" {
    name        = "${local.name_prefix}-alb-sg"
    description = "Security group for ALB"
    vpc_id      = aws_vpc.main.id
    
    tags = merge(local.common_tags, {
        Name = "${local.name_prefix}-alb-sg"
    })
    
    revoke_rules_on_delete = true
    
    lifecycle {
        create_before_destroy = true
    }
}

# http rule
resource "aws_security_group_rule" "http_ingress_alb" {
    type              = "ingress"
    from_port         = 80
    to_port           = 80
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.alb-security.id
    description       = "HTTP access"
}

# https rule
resource "aws_security_group_rule" "https_ingress_alb" {
    type              = "ingress"
    from_port         = 443
    to_port           = 443
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.alb-security.id
    description       = "HTTPS access"
}


# vpc endpoint ssm agent セキュリティグループ
resource "aws_security_group" "ssm-security" {
    name        = "${local.name_prefix}-ssm-sg"
    description = "Security group for VPC Endpoint SSM Agent"
    vpc_id      = aws_vpc.main.id
    
    tags = merge(local.common_tags, {
        Name = "${local.name_prefix}-ssm-sg"
    })
    
    revoke_rules_on_delete = true
    
    lifecycle {
        create_before_destroy = true
    }
}


resource "aws_security_group_rule" "ssm-security" {
    type              = "ingress"
    from_port         = 443
    to_port           = 443
    protocol          = "tcp"
    cidr_blocks       = [aws_vpc.main.cidr_block]
    security_group_id = aws_security_group.ssm-security.id
    description       = "HTTPS access"
}