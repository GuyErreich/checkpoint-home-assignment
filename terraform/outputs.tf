output "default_subnet_ids" {
  value = module.vpc.public_subnets
}

output "ecs_worker_cluster" {
  value = module.ecs_services.cluster_name
}

