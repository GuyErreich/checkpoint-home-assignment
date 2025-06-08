# Get current AWS region
data "aws_region" "current" {}

# Get Docker image digests to detect image updates
data "docker_registry_image" "api_image" {
  name = var.image_url_api
}

data "docker_registry_image" "worker_image" {
  name = var.image_url_worker
}

module "ecs_services" {
  source = "./modules/ecs_worker"

  cluster_name      = var.cluster_name
  aws_region        = data.aws_region.current.name
  vpc_cidr_block    = "10.0.0.0/16"  # Add VPC CIDR block
  tags = var.tags
  container_name_api = var.container_name_api
  image_url_api      = var.image_url_api
  image_digest_api   = data.docker_registry_image.api_image.sha256_digest
  cpu_api            = var.cpu_api
  memory_api         = var.memory_api
  container_name_worker = var.container_name_worker
  image_url_worker      = var.image_url_worker
  image_digest_worker   = data.docker_registry_image.worker_image.sha256_digest
  cpu_worker            = var.cpu_worker
  memory_worker         = var.memory_worker
  sqs_url   = module.sqs_queue.url
  sqs_queue_name = module.sqs_queue.id  # SQS queue name
  sqs_queue_arn = module.sqs_queue.arn
  s3_bucket = module.s3_bucket.bucket
  s3_bucket_arn = module.s3_bucket.bucket_arn
  ssm_token_param = module.ssm_token.name
  enable_load_balancer = true
  
  # Monitoring configuration
  alert_email       = var.alert_email
  enable_monitoring = var.enable_monitoring
  
  # SSH access configuration
  ssh_key_name      = aws_key_pair.ecs_key_pair.key_name

  # Ensure dependencies are created before ECS services
  depends_on = [
    module.s3_bucket,
    module.sqs_queue,
    module.ssm_token,
    aws_key_pair.ecs_key_pair
  ]
}

module "s3_bucket" {
  source = "./modules/s3_bucket"
}

module "sqs_queue" {
  source = "./modules/sqs_queue"
}

module "ssm_token" {
  source = "./modules/ssm_token"
  token_value = "my-secret-token"
}
