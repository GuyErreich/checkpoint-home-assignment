module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.0"

  cluster_name = var.cluster_name

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
  }

  services = {
    api = {
      name                = var.container_name_api
      cpu                 = var.cpu_api
      memory              = var.memory_api
      desired_count       = 1
      subnet_ids          = var.subnet_ids
      security_group_ids  = [var.security_group_id]
      assign_public_ip    = true
      enable_execute_command = true

      create_task_exec_iam_role = true
      create_tasks_iam_role     = true
      create_iam_role           = true

      container_definitions = {
        api = {
          image = var.image_url_api
          essential = true
          port_mappings = [{
            containerPort = 80
            hostPort      = 80
          }]
          environment = [
            { name = "TOKEN_SSM_PARAM", value = "/api/token" },
            { name = "SQS_QUEUE_URL", value = var.sqs_url }
          ]
        }
      }
    }

    worker = {
      name                = var.container_name_worker
      cpu                 = var.cpu_worker
      memory              = var.memory_worker
      desired_count       = 1
      subnet_ids          = var.subnet_ids
      security_group_ids  = [var.security_group_id]
      assign_public_ip    = true
      enable_execute_command = true

      create_task_exec_iam_role = true
      create_tasks_iam_role     = true
      create_iam_role           = true

      container_definitions = {
        worker = {
          image = var.image_url_worker
          essential = true
          environment = [
            { name = "SQS_QUEUE_URL", value = var.sqs_url },
            { name = "S3_BUCKET", value = var.s3_bucket }
          ]
        }
      }
    }
  }

  tags = var.tags
}
