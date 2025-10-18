variable "vpc_cidr_block" {
    description = "CIDR block for VPC"
    type = string
    default = "10.0.0.0/16"
}

variable "aws_region" {
    description = "AWS region"
    type = string
    default = "ap-northeast-1"
}

variable "aws_profile" {
    description = "AWS profile"
    type = string
    default = "default"
}

variable "env" {
    description = "Environment"
    type = string
    default = "dev"
}
