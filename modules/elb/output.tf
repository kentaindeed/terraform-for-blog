# target group 
output "elb-tg" {
    value = aws_lb_target_group.elb-tg.arn
}