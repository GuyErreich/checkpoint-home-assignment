# VPC and Networking Configuration
# This file contains all VPC-related resources for the ECS cluster

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.21"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr_block

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets  = [
    cidrsubnet(var.vpc_cidr_block, 8, 1),  # 10.0.1.0/24 (from 10.0.0.0/16)
    cidrsubnet(var.vpc_cidr_block, 8, 2)   # 10.0.2.0/24 (from 10.0.0.0/16)
  ]

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-vpc"
    Environment = "dev"
  })
}

# Security Group for ECS instances using terraform-aws-modules
module "ecs_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.1"

  name        = "${var.cluster_name}-ecs-sg"
  description = "Security group for ECS EC2 instances"
  vpc_id      = module.vpc.vpc_id

  # TODO: test the possibility to remove  later and relay only on AWS Console
  # SSH access for debugging
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH access for debugging"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  # ALB to ECS communication using security group reference (more secure)
  ingress_with_source_security_group_id = [
    {
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      description              = "Allow ALB to reach ECS instances on port 80"
      source_security_group_id = module.alb.security_group_id
    }
  ]

  # Allow all outbound traffic (for Docker pulls, AWS API calls, etc.)
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "All outbound traffic"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = merge(var.tags, {
    Name        = "${var.cluster_name}-ecs-security-group"
    Environment = "dev"
  })
}
