# ==============================================================================
# CLOUDWATCH ALARMS FOR HEALTH MONITORING
# ==============================================================================
# This file contains all CloudWatch metric alarms for monitoring:
# - ECS service health alarms
# - Resource utilization alarms  
# - ALB health alarms
# - Individual metric thresholds
# ==============================================================================

# Service Health - API Service Running Count
resource "aws_cloudwatch_metric_alarm" "api_service_health" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.cluster_name}-api-service-health"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "RunningCount"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "API service has no healthy running tasks"
  alarm_actions       = [aws_sns_topic.alerts[0].arn]
  ok_actions          = [aws_sns_topic.alerts[0].arn]
  treat_missing_data  = "breaching"

  dimensions = {
    ServiceName = var.container_name_api
    ClusterName = var.cluster_name
  }

  tags = merge(var.tags, {
    Purpose = "Health Check Monitoring"
    AlarmType = "Service Health"
  })
}

# Service Health - Worker Service Running Count
resource "aws_cloudwatch_metric_alarm" "worker_service_health" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.cluster_name}-worker-service-health"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "RunningCount"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Worker service has no healthy running tasks"
  alarm_actions       = [aws_sns_topic.alerts[0].arn]
  ok_actions          = [aws_sns_topic.alerts[0].arn]
  treat_missing_data  = "breaching"

  dimensions = {
    ServiceName = var.container_name_worker
    ClusterName = var.cluster_name
  }

  tags = merge(var.tags, {
    Purpose = "Health Check Monitoring"
    AlarmType = "Service Health"
  })
}

# Resource Utilization - CPU High
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.cluster_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "CPU utilization is high across services"
  alarm_actions       = [aws_sns_topic.warning_alerts[0].arn]
  ok_actions          = [aws_sns_topic.warning_alerts[0].arn]

  dimensions = {
    ClusterName = var.cluster_name
  }

  tags = merge(var.tags, {
    Purpose = "Resource Monitoring"
    AlarmType = "Performance"
  })
}

# Resource Utilization - Memory High
resource "aws_cloudwatch_metric_alarm" "memory_high" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.cluster_name}-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"
  alarm_description   = "Memory utilization is high across services"
  alarm_actions       = [aws_sns_topic.warning_alerts[0].arn]
  ok_actions          = [aws_sns_topic.warning_alerts[0].arn]

  dimensions = {
    ClusterName = var.cluster_name
  }

  tags = merge(var.tags, {
    Purpose = "Resource Monitoring"
    AlarmType = "Performance"
  })
}

# ALB Health Monitoring (when load balancer is enabled)
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  count = var.enable_monitoring ? 1 : 0
  
  alarm_name          = "${var.cluster_name}-alb-unhealthy-hosts"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "ALB has no healthy targets"
  alarm_actions       = [aws_sns_topic.critical_alerts[0].arn]
  ok_actions          = [aws_sns_topic.critical_alerts[0].arn]
  treat_missing_data  = "breaching"

  dimensions = {
    TargetGroup  = module.alb.target_groups["api_ecs"].arn_suffix
    LoadBalancer = module.alb.arn_suffix
  }

  tags = merge(var.tags, {
    Purpose = "ALB Health Monitoring"
    AlarmType = "Load Balancer"
  })
}

# ALB Response Time Monitoring
resource "aws_cloudwatch_metric_alarm" "alb_response_time" {
  count = var.enable_monitoring ? 1 : 0
  
  alarm_name          = "${var.cluster_name}-alb-response-time-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "1.0"  # 1 second
  alarm_description   = "ALB response time is high"
  alarm_actions       = [aws_sns_topic.warning_alerts[0].arn]
  ok_actions          = [aws_sns_topic.warning_alerts[0].arn]

  dimensions = {
    LoadBalancer = module.alb.arn_suffix
  }

  tags = merge(var.tags, {
    Purpose = "ALB Performance Monitoring"
    AlarmType = "Performance"
  })
}

# SQS Queue Depth Monitoring (for worker scaling)
resource "aws_cloudwatch_metric_alarm" "sqs_queue_depth" {
  count = var.enable_monitoring ? 1 : 0
  
  alarm_name          = "${var.cluster_name}-sqs-queue-depth-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApproximateNumberOfVisibleMessages"
  namespace           = "AWS/SQS"
  period              = "300"
  statistic           = "Average"
  threshold           = "10"  # More than 10 messages in queue
  alarm_description   = "SQS queue has high message backlog"
  alarm_actions       = [aws_sns_topic.warning_alerts[0].arn]
  ok_actions          = [aws_sns_topic.warning_alerts[0].arn]

  dimensions = {
    QueueName = var.sqs_queue_name
  }

  tags = merge(var.tags, {
    Purpose = "SQS Monitoring"
    AlarmType = "Queue Depth"
  })
}

# ==============================================================================
# AUTO-SCALING TRIGGER ALARMS
# ==============================================================================

# Health-based scaling alarm for API service
resource "aws_cloudwatch_metric_alarm" "api_health_scaling" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${var.cluster_name}-api-health-scaling-trigger"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"  # Respond quickly to health issues
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Trigger scaling when healthy host count drops"
  alarm_actions       = [aws_appautoscaling_policy.api_health_step_policy[0].arn]
  treat_missing_data  = "breaching"

  dimensions = {
    TargetGroup  = module.alb.target_groups["api_ecs"].arn_suffix
    LoadBalancer = module.alb.arn_suffix
  }

  tags = merge(var.tags, {
    Purpose = "Health-based Auto Scaling Trigger"
  })
}
