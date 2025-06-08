# Local values for the ECS worker module

locals {
  # Extract log group names from ECS module outputs for CloudWatch Logs Insights queries
  api_log_group_name    = split(":", module.ecs.services["api"].container_definitions[var.container_name_api].cloudwatch_log_group_arn)[6]
  worker_log_group_name = split(":", module.ecs.services["worker"].container_definitions[var.container_name_worker].cloudwatch_log_group_arn)[6]
  
  # Log group ARNs for outputs
  api_log_group_arn    = module.ecs.services["api"].container_definitions[var.container_name_api].cloudwatch_log_group_arn
  worker_log_group_arn = module.ecs.services["worker"].container_definitions[var.container_name_worker].cloudwatch_log_group_arn
  
  # Image references with digests for automatic update detection
  api_image_with_digest    = "${var.image_url_api}@${var.image_digest_api}"
  worker_image_with_digest = "${var.image_url_worker}@${var.image_digest_worker}"
}
