

module "ecs_services" {
  source = "./modules/ecs_worker"

  cluster_name      = var.cluster_name
  subnet_ids        = module.vpc.public_subnets
  security_group_id = var.security_group_id
  tags = var.tags
  container_name_api = "api-service"
  image_url_api      = var.image_url_api
  cpu_api            = var.cpu_api
  memory_api         = var.memory_api
  container_name_worker = var.container_name_worker
  image_url_worker      = var.image_url_worker
  cpu_worker            = var.cpu_worker
  memory_worker         = var.memory_worker
  sqs_url   = module.sqs_queue.url
  s3_bucket = module.s3_bucket.bucket
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
