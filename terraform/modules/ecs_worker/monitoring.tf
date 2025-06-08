# ==============================================================================
# CLOUDWATCH DASHBOARDS FOR MONITORING AND VISUALIZATION
# ==============================================================================
# This file contains CloudWatch dashboards for monitoring and visualization:
# - Health monitoring dashboard
# - Performance monitoring dashboard
# - Resource utilization dashboard
# - Real-time monitoring widgets
# ==============================================================================

# Health Monitoring Dashboard
resource "aws_cloudwatch_dashboard" "health_monitoring" {
  count          = var.enable_monitoring ? 1 : 0
  dashboard_name = "${var.cluster_name}-health-monitoring"

  dashboard_body = jsonencode({
    widgets = [
      # Service Health Overview
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "RunningCount", "ServiceName", var.container_name_api, "ClusterName", var.cluster_name],
            [".", "DesiredCount", ".", ".", ".", "."],
            [".", "RunningCount", ".", var.container_name_worker, ".", "."],
            [".", "DesiredCount", ".", ".", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "Service Health - Running vs Desired Tasks"
          period  = 300
          yAxis = {
            left = { min = 0 }
          }
        }
      },
      # Resource Utilization
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", var.container_name_api, "ClusterName", var.cluster_name],
            [".", "MemoryUtilization", ".", ".", ".", "."],
            [".", "CPUUtilization", ".", var.container_name_worker, ".", "."],
            [".", "MemoryUtilization", ".", ".", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "Resource Utilization"
          period  = 300
          yAxis = {
            left = { min = 0, max = 100 }
          }
        }
      }
    ]
  })
}

# Performance Monitoring Dashboard
resource "aws_cloudwatch_dashboard" "performance_monitoring" {
  count          = var.enable_monitoring ? 1 : 0
  dashboard_name = "${var.cluster_name}-performance-monitoring"

  dashboard_body = jsonencode({
    widgets = concat([
      # SQS Queue Metrics
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfVisibleMessages", "QueueName", var.sqs_queue_name],
            [".", "ApproximateNumberOfMessagesNotVisible", ".", "."],
            [".", "NumberOfMessagesReceived", ".", "."],
            [".", "NumberOfMessagesDeleted", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "SQS Queue Performance"
          period  = 300
          yAxis = {
            left = { min = 0 }
          }
        }
      },
      # EC2 Instance Metrics
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/AutoScaling", "GroupDesiredCapacity", "AutoScalingGroupName", "${var.cluster_name}-free-tier-asg"],
            [".", "GroupInServiceInstances", ".", "."],
            [".", "GroupPendingInstances", ".", "."],
            [".", "GroupTerminatingInstances", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "EC2 Auto Scaling Group"
          period  = 300
          yAxis = {
            left = { min = 0 }
          }
        }
      }
    ], [
      # ALB Metrics - always included since ALB is always enabled
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 24
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", module.alb.target_groups["api_ecs"].arn_suffix, "LoadBalancer", module.alb.arn_suffix],
            [".", "UnHealthyHostCount", ".", ".", ".", "."],
            [".", "RequestCount", ".", ".", ".", "."],
            [".", "TargetResponseTime", ".", ".", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "Application Load Balancer Health"
          period  = 300
          yAxis = {
            left = { min = 0 }
          }
        }
      }
    ])
  })
}

# ==============================================================================
