# SSH Key Pair management for EC2 instances
# This file handles SSH key creation and storage for debugging access to ECS instances

# Generate SSH key pair
resource "tls_private_key" "ecs_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair with the generated public key
resource "aws_key_pair" "ecs_key_pair" {
  key_name   = "${var.project_name}-ecs-key"
  public_key = tls_private_key.ecs_ssh_key.public_key_openssh

  tags = merge(var.tags, {
    Name = "${var.project_name}-ecs-ssh-key"
    Purpose = "ECS-debugging"
  })
}

# Store private key locally for immediate access (with secure permissions)
resource "local_file" "private_key" {
  content         = tls_private_key.ecs_ssh_key.private_key_pem
  filename        = "${path.module}/${var.project_name}-ecs-key.pem"
  file_permission = "0600"

  # Only create if we're in development/debugging mode
  count = var.enable_ssh_access ? 1 : 0
}

# Store public key in SSM Parameter Store for reference
resource "aws_ssm_parameter" "ssh_public_key" {
  name        = "/ec2/${var.project_name}/ssh-public-key"
  type        = "String"
  value       = tls_private_key.ecs_ssh_key.public_key_openssh
  description = "SSH public key for ${var.project_name} ECS instances - debugging access"

  tags = merge(var.tags, {
    Name = "${var.project_name}-ssh-public-key"
    Type = "SSH-Key"
  })
}

# Store private key in SSM Parameter Store as SecureString for secure remote access
resource "aws_ssm_parameter" "ssh_private_key" {
  name        = "/ec2/${var.project_name}/ssh-private-key"
  type        = "SecureString" 
  value       = tls_private_key.ecs_ssh_key.private_key_pem
  description = "SSH private key for ${var.project_name} ECS instances - secure storage"

  tags = merge(var.tags, {
    Name = "${var.project_name}-ssh-private-key"
    Type = "SSH-Key-Private"
    Sensitive = "true"
  })
}
