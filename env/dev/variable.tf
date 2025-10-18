variable "ami" {
  description = "AMI ID for EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "instance_count" {
  description = "Number of instances to create"
  type        = number
}

variable "aws_region" {
    type = string
    default = "ap-southeast-1"
}

variable "aws_profile" {
    type = string
    default = "default"
}

variable "env" {
    type = string
    default = "dev"
}