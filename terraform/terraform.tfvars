# General cluster settings
cluster_name = "devops-cluster"
region       = "us-east-1"

# API Service (Microservice 1) - Minimal for free tier
container_name_api = "api-service"
image_url_api      = "ghcr.io/guyerreich/checkpoint-home-assignment-api-ms"
cpu_api            = 256
memory_api         = 256  # Reduced memory

# Worker Service (Microservice 2) - Minimal for free tier
container_name_worker = "worker-service"
image_url_worker      = "ghcr.io/guyerreich/checkpoint-home-assignment-worker-ms"
cpu_worker            = 256
memory_worker         = 256  # Reduced memory

# Monitoring Configuration
alert_email = "gerreich.dev@gmail.com"  # Replace with your email
enable_monitoring = true

# SSH Access Configuration
enable_ssh_access = true

# Tags for all resources
tags = {
  Environment = "dev"
  Owner       = "your-name"
  Project     = "devops-assignment"
}
