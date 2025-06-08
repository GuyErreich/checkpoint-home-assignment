variable "cluster_name" {
  type = string
}

variable "enable_load_balancer" {
  type        = bool
  default     = true
  description = "Enable load balancer target group creation for API service"
}

variable "ssh_key_name" {
  type        = string
  description = "Name of the SSH key pair for EC2 instances debugging access"
}

variable "vpc_cidr_block" {
  type        = string
  description = "VPC CIDR block for the cluster"
  default     = "10.0.0.0/16"
}

variable "aws_region" {
  type        = string
  description = "AWS region for ECS cluster and resources"
}

variable "tags" {
  type = map(string)
}

# API service
variable "container_name_api" {
  type = string
}

variable "image_url_api" {
  type = string
}

variable "image_digest_api" {
  type        = string
  description = "SHA256 digest of the API image to detect updates"
}

variable "cpu_api" {
  type = number
}

variable "memory_api" {
  type = number
}

# Worker service
variable "container_name_worker" {
  type = string
}

variable "image_url_worker" {
  type = string
}

variable "image_digest_worker" {
  type        = string
  description = "SHA256 digest of the worker image to detect updates"
}

variable "cpu_worker" {
  type = number
}

variable "memory_worker" {
  type = number
}

# Shared resources
variable "sqs_url" {
  type = string
}

variable "sqs_queue_name" {
  type        = string
  description = "Name of the SQS queue for monitoring and auto-scaling"
}

variable "sqs_queue_arn" {
  type        = string
  description = "ARN of the SQS queue for worker service permissions"
}

variable "s3_bucket" {
  type = string
}

variable "s3_bucket_arn" {
  type        = string
  description = "ARN of the S3 bucket for worker service permissions"
}

variable "ssm_token_param" {
  type        = string
  description = "SSM parameter name for the token used by the worker service"
}

# Monitoring configuration
variable "alert_email" {
  type        = string
  description = "Email address to receive CloudWatch alerts"
  default     = ""
}

variable "enable_monitoring" {
  type        = bool
  description = "Enable CloudWatch monitoring and alerts"
  default     = true
}