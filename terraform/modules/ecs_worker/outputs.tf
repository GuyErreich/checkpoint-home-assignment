output "cluster_name" {
  value = module.ecs.cluster_name
}

output "dashboard_url" {
  description = "CloudWatch Dashboard URL for ECS monitoring"
  value       = var.enable_monitoring ? "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.health_monitoring[0].dashboard_name}" : null
}

output "performance_dashboard_url" {
  description = "CloudWatch Performance Dashboard URL"
  value       = var.enable_monitoring ? "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.performance_monitoring[0].dashboard_name}" : null
}

output "sns_topic_arn" {
  description = "SNS topic ARN for general alerts"
  value       = var.enable_monitoring ? aws_sns_topic.alerts[0].arn : null
}

output "critical_alerts_topic_arn" {
  description = "SNS topic ARN for critical alerts"
  value       = var.enable_monitoring ? aws_sns_topic.critical_alerts[0].arn : null
}

output "warning_alerts_topic_arn" {
  description = "SNS topic ARN for warning alerts"
  value       = var.enable_monitoring ? aws_sns_topic.warning_alerts[0].arn : null
}

output "log_groups" {
  description = "CloudWatch log groups for application logs"
  value = var.enable_monitoring ? {
    api_logs    = local.api_log_group_arn
    worker_logs = local.worker_log_group_arn
  } : null
}

output "api_target_group_arn" {
  description = "ARN of the API service target group for load balancing"
  value       = module.alb.target_groups["api_ecs"].arn
}

output "api_alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.dns_name
}

output "api_url" {
  description = "URL to access the API service"
  value       = "http://${module.alb.dns_name}"
}

output "ec2_instances_command" {
  description = "AWS CLI command to list EC2 instances in the cluster"
  value       = "aws ec2 describe-instances --filters 'Name=tag:Name,Values=${var.cluster_name}-ecs-free-tier' --query 'Reservations[*].Instances[*].[InstanceId,PublicIpAddress,State.Name]' --output table"
}

# VPC outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets
}

output "public_subnet_ids" {
  description = "List of public subnet IDs (alias for compatibility)"
  value       = module.vpc.public_subnets
}

output "security_group_id" {
  description = "ID of the ECS security group"
  value       = module.ecs_security_group.security_group_id
}

# sha256:380c0b3c8a1336c269d79928f72ab193a481a0b0d8b7951db0cb89bd508d360e