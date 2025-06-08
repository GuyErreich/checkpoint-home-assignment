output "default_subnet_ids" {
  description = "Public subnet IDs from VPC"
  value       = module.ecs_services.public_subnet_ids
}

output "ecs_security_group_id" {
  description = "Security group ID for ECS instances"
  value       = module.ecs_services.security_group_id
}

output "ecs_worker_cluster" {
  value = module.ecs_services.cluster_name
}

output "monitoring_dashboard_url" {
  description = "CloudWatch Dashboard URL for monitoring your ECS services"
  value       = module.ecs_services.dashboard_url
}

output "sns_alerts_topic" {
  description = "SNS topic for alerts - subscribe your email to receive notifications"
  value       = module.ecs_services.sns_topic_arn
}

output "log_groups" {
  description = "CloudWatch log groups for your services"
  value       = module.ecs_services.log_groups
}

output "s3_bucket_name" {
  description = "S3 bucket name for worker storage"
  value       = module.s3_bucket.bucket
}

output "sqs_queue_url" {
  description = "SQS queue URL for message processing"
  value       = module.sqs_queue.url
}


output "api_target_group_arn" {
  description = "ARN of the API service target group for load balancing"
  value       = module.ecs_services.api_target_group_arn
}

output "api_alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.ecs_services.api_alb_dns_name
}

output "api_url" {
  description = "URL to access the API service"
  value       = module.ecs_services.api_url
}

# SSH Key Management Outputs
output "ssh_key_name" {
  description = "Name of the SSH key pair for ECS instances"
  value       = aws_key_pair.ecs_key_pair.key_name
}

output "ssh_private_key_ssm_parameter" {
  description = "SSM Parameter name containing the SSH private key"
  value       = aws_ssm_parameter.ssh_private_key.name
}

output "ssh_public_key_ssm_parameter" {
  description = "SSM Parameter name containing the SSH public key"
  value       = aws_ssm_parameter.ssh_public_key.name
}

output "ssh_private_key_local_file" {
  description = "Local file path to SSH private key (if enabled)"
  value       = var.enable_ssh_access ? local_file.private_key[0].filename : "SSH access disabled"
}

