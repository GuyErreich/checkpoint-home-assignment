# Health and performance monitoring based auto-scaling configuration
# 
# This configuration provides health-based step scaling and CloudWatch alarms
# that complement the ECS module's built-in target tracking auto-scaling

# Health-based step scaling policy for rapid response to health issues
resource "aws_appautoscaling_policy" "api_health_step_policy" {
  count = var.enable_monitoring && var.enable_load_balancer ? 1 : 0

  name               = "${var.cluster_name}-api-health-step-scaling"
  policy_type        = "StepScaling"
  resource_id        = "service/${var.cluster_name}/${var.container_name_api}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown               = 30   # 30 seconds - immediate response to health issues
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment         = 1  # Add 1 task when health degrades
    }
  }

  # This policy will be associated with existing auto-scaling target from ECS module
  depends_on = [
    module.ecs
  ]
}
