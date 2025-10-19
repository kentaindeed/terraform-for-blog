output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

# security group
# Web用（HTTP + HTTPS + SSH）のセキュリティグループIDリスト
output "web_security_group_ids" {
  description = "Web server security group IDs (HTTP, HTTPS, SSH)"
  value = [
    aws_security_group.developers.id
  ]
}

output "alb_security_group_ids" {
  description = "ALB security group ID"
  value       = [
    aws_security_group.alb-security.id
  ]
}