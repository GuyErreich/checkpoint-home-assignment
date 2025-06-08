# Application Load Balancer with Target Groups using AWS ALB module
# 
# This configuration leverages service health checks at the "/" path for both:
# 1. ALB Target Group health checks (configured here)
# 2. ECS Service container health checks (configured in main.tf)
# 
# Both use the same endpoint, intervals, and timeout settings for consistency

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name = "${var.cluster_name}-api-alb"

  load_balancer_type = "application"
  vpc_id            = module.vpc.vpc_id
  subnets           = module.vpc.public_subnets

  # For development - enable deletion protection in production
  enable_deletion_protection = false

  # Security Group configuration
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "HTTP access for API service"
    }
  }
  
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = var.vpc_cidr_block
      description = "All outbound traffic to VPC"
    }
  }

  # Listener configuration
  listeners = {
    api_http = {
      port     = 80
      protocol = "HTTP"

      forward = {
        target_group_key = "api_ecs"
      }
    }
  }

  # Target Group configuration
  target_groups = {
    api_ecs = {
      name                              = "${var.cluster_name}-api-tg"
      backend_protocol                  = "HTTP"
      backend_port                      = 80
      target_type                       = "instance"  # Bridge network mode
      deregistration_delay              = 5           # Fast deregistration for development
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        healthy_threshold   = 2
        interval            = 30
        matcher             = "200"
        path                = "/"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }

      # ECS will attach the instances to this target group
      create_attachment = false
    }
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-api-alb"
    Purpose = "API-LoadBalancer"
  })

  # Implicit dependencies through resource references:
  # - VPC dependency: vpc_id = module.vpc.vpc_id
  # - Subnets dependency: subnets = module.vpc.public_subnets
  # - No explicit depends_on needed to avoid circular dependencies
}
