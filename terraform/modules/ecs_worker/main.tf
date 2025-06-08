module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.0"

  cluster_name = var.cluster_name

  # Use EC2 capacity provider with Auto Scaling Group (Free Tier optimized)
  autoscaling_capacity_providers = {
    free-tier = {
      auto_scaling_group_arn         = module.autoscaling.autoscaling_group_arn
      managed_termination_protection = "DISABLED"  # Allow termination for cost savings
      managed_draining              = "ENABLED"   # Graceful shutdown

      managed_scaling = {
        maximum_scaling_step_size = 1   # Scale one instance at a time
        minimum_scaling_step_size = 1
        status                    = "ENABLED"
        target_capacity           = 80  # Scale when 80% capacity reached
        instance_warmup_period    = 300 # 5 minutes warmup
      }

      default_capacity_provider_strategy = {
        weight = 100
        base   = 1
      }
    }

    
  }

  # Default capacity provider strategy managed by ECS module internally
  default_capacity_provider_use_fargate = false

  # Enable monitoring for better observability
  cluster_settings = {
    name  = "containerInsights"
    value = "enabled"  # Essential for monitoring and debugging
  }

  services = {
    api = {
      name                = var.container_name_api
      cpu                 = var.cpu_api
      memory              = var.memory_api
      desired_count       = 1
      launch_type         = "EC2"
      requires_compatibilities = ["EC2"]
      
      # Use bridge network mode to avoid ENI conflicts - same as worker service
      network_mode = "bridge"
      
      # Enable execute command for debugging
      enable_execute_command = true
      
      create_task_exec_iam_role = true
      create_tasks_iam_role     = true
      
      # Add volume for writable temporary directory
      volume = [
        {
          name = "tmp_volume"
          # This creates an empty directory volume that containers can write to
        }
      ]
      
      # Configure optimized auto-scaling with fast response times
      enable_autoscaling    = true
      autoscaling_min_capacity = 1
      autoscaling_max_capacity = 3  # Free tier friendly
      
      # Optimized auto-scaling policies with fast cooldowns
      # NOTE: Removed ALB-based request_count policy to avoid for_each issues with unknown values
      autoscaling_policies = {
        cpu = {
          policy_type = "TargetTrackingScaling"
          target_tracking_scaling_policy_configuration = {
            target_value = 70.0
            predefined_metric_specification = {
              predefined_metric_type = "ECSServiceAverageCPUUtilization"
            }
            scale_out_cooldown = 60   # 1 minute - fast response
            scale_in_cooldown  = 120  # 2 minutes - conservative
          }
        }
        memory = {
          policy_type = "TargetTrackingScaling"
          target_tracking_scaling_policy_configuration = {
            target_value = 80.0
            predefined_metric_specification = {
              predefined_metric_type = "ECSServiceAverageMemoryUtilization"
            }
            scale_out_cooldown = 60   # 1 minute - fast response
            scale_in_cooldown  = 120  # 2 minutes - conservative
          }
        }
      }

      # IAM policies for API service to access SQS and SSM (CloudWatch Logs handled automatically)
      tasks_iam_role_statements = [
        {
          actions = [
            "sqs:SendMessage",
            "sqs:GetQueueAttributes"
          ]
          resources = [var.sqs_queue_arn]
        },
        {
          actions = [
            "ssm:GetParameter"
          ]
          resources = [data.aws_ssm_parameter.api_token.arn]
        }
      ]

      # Load balancer configuration - always use ALB module target group
      load_balancer = {
        service = {
          target_group_arn = module.alb.target_groups["api_ecs"].arn
          container_name   = var.container_name_api
          container_port   = 80
        }
      }

      container_definitions = {
        (var.container_name_api) = {
          image = local.api_image_with_digest
          essential = true
          port_mappings = [
            {
              containerPort = 80
              hostPort      = 80
            }
          ]
          environment = [
            {
              name  = "SQS_QUEUE_URL"
              value = var.sqs_url
            },
            {
              name  = "AWS_DEFAULT_REGION"
              value = var.aws_region
            },
            {
              name  = "TOKEN_SSM_PARAM"
              value = var.ssm_token_param
            }
          ]
          
          # Enhanced security configurations for API service
          readonly_root_filesystem = true
          user = "1000:1000"  # Run as non-root user
          
          # Restrict Linux capabilities but add only essential ones for Gunicorn
          linux_parameters = {
            init_process_enabled = false
            capabilities = {
              drop = ["ALL"]  # Drop all capabilities first
              add  = [
                "SETUID",      # Required for Gunicorn worker process management
                "SETGID",      # Required for Gunicorn worker process management
                "DAC_OVERRIDE" # Required for temporary file creation
              ]
            }
          }
          
          # Mount writable volume for temporary files
          mount_points = [
            {
              sourceVolume  = "tmp_volume"
              containerPath = "/tmp"
              readOnly      = false
            }
          ]
          
          # ECS health check using Python urllib (available in Python containers)
          health_check = {
            command = ["CMD-SHELL", "python3 -c \"import urllib.request; urllib.request.urlopen('http://localhost/')\" || exit 1"]
            interval = 30      # Same as ALB target group
            timeout = 5        # Same as ALB target group  
            retries = 3        # Standard retry count
            start_period = 60  # Allow 60 seconds for container startup
          }
          
          # CloudWatch logging will be automatically configured by ECS module
        }
      }
    }

    worker = {
      name                = var.container_name_worker
      cpu                 = var.cpu_worker
      memory              = var.memory_worker
      desired_count       = 1
      launch_type         = "EC2"
      requires_compatibilities = ["EC2"]
      
      # Use bridge network mode to avoid ENI conflicts - worker doesn't need external access
      network_mode = "bridge"

      create_task_exec_iam_role = true
      create_tasks_iam_role     = true
      
      # Configure optimized auto-scaling for worker service
      enable_autoscaling    = true
      autoscaling_min_capacity = 1
      autoscaling_max_capacity = 2  # Free tier friendly
      
      # SQS-based auto-scaling policy for worker service
      autoscaling_policies = {
        sqs_queue = {
          policy_type = "TargetTrackingScaling"
          target_tracking_scaling_policy_configuration = {
            target_value = 5.0  # Target 5 messages per worker
            customized_metric_specification = {
              metric_name = "ApproximateNumberOfVisibleMessages"
              namespace   = "AWS/SQS"
              statistic   = "Average"
              dimensions = [
                {
                  name  = "QueueName"
                  value = var.sqs_queue_name
                }
              ]
            }
            scale_out_cooldown = 90   # 1.5 minutes - allow time for processing
            scale_in_cooldown  = 240  # 4 minutes - conservative for workers
          }
        }
        cpu = {
          policy_type = "TargetTrackingScaling"
          target_tracking_scaling_policy_configuration = {
            target_value = 70.0
            predefined_metric_specification = {
              predefined_metric_type = "ECSServiceAverageCPUUtilization"
            }
            scale_out_cooldown = 90
            scale_in_cooldown  = 240
          }
        }
      }
      
      # IAM policies for worker service to access SQS and S3 (CloudWatch Logs handled automatically)
      tasks_iam_role_statements = [
        {
          actions = [
            "sqs:ReceiveMessage",
            "sqs:DeleteMessage",
            "sqs:GetQueueAttributes"
          ]
          resources = [var.sqs_queue_arn]
        },
        {
          actions = [
            "s3:PutObject",
            "s3:PutObjectAcl"
          ]
          resources = ["${var.s3_bucket_arn}/*"]
        }
      ]

      container_definitions = {
        (var.container_name_worker) = {
          image = local.worker_image_with_digest
          essential = true
          environment = [
            {
              name  = "SQS_QUEUE_URL"
              value = var.sqs_url
            },
            {
              name  = "S3_BUCKET"
              value = var.s3_bucket
            },
            {
              name  = "AWS_DEFAULT_REGION"
              value = var.aws_region
            }
          ]
          
          # Enhanced security configurations
          readonly_root_filesystem = true
          user = "1000:1000"  # Run as non-root user
          
          # Restrict Linux capabilities for better security
          linux_parameters = {
            init_process_enabled = false
            capabilities = {
              drop = ["ALL"]  # Drop all capabilities
              add  = []       # Add only required capabilities
            }
          }
          
          # Health check for worker service - Verify main.py process is running
          # Checks that the main Python process (PID 1) is actually running main.py
          # This ensures the worker process is alive and functioning
          health_check = {
            command = ["CMD-SHELL", "python3 -c \"import os; cmdline = open('/proc/1/cmdline', 'rb').read().decode('utf-8', errors='ignore'); exit(0 if 'main.py' in cmdline else 1)\" || exit 1"]
            interval = 30      # Check every 30 seconds
            timeout = 10       # Slightly longer timeout for reliability
            retries = 3        # Allow 3 consecutive failures
            start_period = 120 # Extended startup grace period for worker initialization
          }
          
          # CloudWatch logging will be automatically configured by ECS module
        }
      }
    }
  }

  # Ensure module dependencies are resolved before creating services
  depends_on = [
    module.autoscaling,
    module.alb  # ALB must be created before ECS services that reference it
  ]

  tags = var.tags
}

# Free Tier Auto Scaling Group for ECS EC2 instances
module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 6.5"

  name = "${var.cluster_name}-free-tier-asg"

  image_id      = data.aws_ssm_parameter.ecs_optimized_ami.value  
  instance_type = "t2.micro"  # Free tier eligible - ONLY t2.micro
  key_name      = var.ssh_key_name  # SSH key for debugging access

  vpc_zone_identifier = module.vpc.public_subnets
  health_check_type   = "EC2"  # EC2 health check (ECS is not supported)
  health_check_grace_period = 300

  # Free tier constraints - max 2 instances to stay within limits
  min_size         = 1  # Always keep 1 running
  max_size         = 2  # Never exceed 2 (750 hours free tier = ~1 instance 24/7)
  desired_capacity = 1  # Start with 1
  
  # Prevent timeout issues
  wait_for_capacity_timeout = "15m"  # Extend timeout
  wait_for_elb_capacity     = 1      # Wait for at least 1 healthy instance

  # Launch template
  create_launch_template = true
  launch_template_name        = "${var.cluster_name}-free-tier-lt"
  launch_template_description = "Free tier launch template for ECS cluster"
  update_default_version      = true

  security_groups = [module.ecs_security_group.security_group_id]
  
  # Network interface configuration for public IP assignment
  network_interfaces = [
    {
      delete_on_termination = true
      description          = "Primary network interface"
      device_index         = 0
      security_groups      = [module.ecs_security_group.security_group_id]
      associate_public_ip_address = true
    }
  ]
  
  # IAM instance profile for ECS
  create_iam_instance_profile = true
  iam_role_name               = "${var.cluster_name}-ecs-instance-role"
  iam_role_description        = "ECS role for ${var.cluster_name}"
  iam_role_policies = {
    AmazonEC2ContainerServiceforEC2Role = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
    AmazonSSMManagedInstanceCore        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  # ECS config
  user_data = base64encode(local.user_data)

  # Instance tags
  tag_specifications = [
    {
      resource_type = "instance"
      tags = merge(var.tags, {
        Name = "${var.cluster_name}-ecs-free-tier"
        AutoScaling = "free-tier-only"
      })
    }
  ]

  # Required autoscaling group tags for ECS management
  autoscaling_group_tags = {
    AmazonECSManaged = true
  }

  # Scaling policies removed - ECS manages scaling through capacity provider
  # scaling_policies = {}  # Empty to avoid conflicts with ECS managed scaling

  # Ensure dependencies are resolved before creating autoscaling group
  depends_on = [
    module.vpc,
    module.ecs_security_group
  ]

  tags = var.tags
}

locals {
  user_data = <<-EOT
    #!/bin/bash
    cat <<'EOF' >> /etc/ecs/ecs.config
    ECS_CLUSTER=${var.cluster_name}
    ECS_LOGLEVEL=debug
    EOF
  EOT
}
