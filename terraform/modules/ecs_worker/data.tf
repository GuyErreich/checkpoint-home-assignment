# Data sources for the ECS worker module

# Get current AWS region
data "aws_region" "current" {}

# Get availability zones for the current region
data "aws_availability_zones" "available" {
  state = "available"
}

# Get the latest ECS-optimized AMI
data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

# Get the API token parameter to access its ARN
data "aws_ssm_parameter" "api_token" {
  name = "/api/token"
}
