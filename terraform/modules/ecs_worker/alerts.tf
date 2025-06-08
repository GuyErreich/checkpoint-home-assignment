# ==============================================================================
# COMPOSITE ALARMS AND ALERT LOGIC
# ==============================================================================
# This file contains composite alarms that combine multiple individual alarms
# to provide intelligent alerting and reduce noise:
# - Comprehensive health monitoring
# - Critical system failures
# - Performance degradation alerts
# ==============================================================================

# Comprehensive Health Monitoring Composite Alarm
resource "aws_cloudwatch_composite_alarm" "comprehensive_health" {
  count         = var.enable_monitoring ? 1 : 0
  alarm_name    = "${var.cluster_name}-comprehensive-health"
  alarm_description = "Comprehensive health monitoring - alerts on any service health issue"
  
  alarm_rule = join(" OR ", concat([
    "ALARM(${aws_cloudwatch_metric_alarm.api_service_health[0].alarm_name})",
    "ALARM(${aws_cloudwatch_metric_alarm.worker_service_health[0].alarm_name})"
  ], var.enable_load_balancer ? [
    "ALARM(${aws_cloudwatch_metric_alarm.alb_unhealthy_hosts[0].alarm_name})"
  ] : []))
  
  actions_enabled = true
  alarm_actions   = [aws_sns_topic.critical_alerts[0].arn]
  ok_actions      = [aws_sns_topic.critical_alerts[0].arn]
  
  tags = merge(var.tags, {
    Purpose = "Comprehensive Health Monitoring"
    ManagedBy = "Terraform"
    AlertType = "Critical"
  })
}

# Performance Degradation Composite Alarm
resource "aws_cloudwatch_composite_alarm" "performance_degradation" {
  count         = var.enable_monitoring ? 1 : 0
  alarm_name    = "${var.cluster_name}-performance-degradation"
  alarm_description = "Performance degradation across system components"
  
  alarm_rule = join(" OR ", concat([
    "ALARM(${aws_cloudwatch_metric_alarm.cpu_high[0].alarm_name})",
    "ALARM(${aws_cloudwatch_metric_alarm.memory_high[0].alarm_name})",
    "ALARM(${aws_cloudwatch_metric_alarm.sqs_queue_depth[0].alarm_name})"
  ], var.enable_load_balancer ? [
    "ALARM(${aws_cloudwatch_metric_alarm.alb_response_time[0].alarm_name})"
  ] : []))
  
  actions_enabled = true
  alarm_actions   = [aws_sns_topic.warning_alerts[0].arn]
  ok_actions      = [aws_sns_topic.warning_alerts[0].arn]
  
  tags = merge(var.tags, {
    Purpose = "Performance Monitoring"
    ManagedBy = "Terraform"
    AlertType = "Warning"
  })
}

# Critical System Failure Composite Alarm
resource "aws_cloudwatch_composite_alarm" "critical_system_failure" {
  count         = var.enable_monitoring ? 1 : 0
  alarm_name    = "${var.cluster_name}-critical-system-failure"
  alarm_description = "Critical system failure requiring immediate attention"
  
  # This alarm triggers when both API and Worker services are down
  alarm_rule = join(" AND ", [
    "ALARM(${aws_cloudwatch_metric_alarm.api_service_health[0].alarm_name})",
    "ALARM(${aws_cloudwatch_metric_alarm.worker_service_health[0].alarm_name})"
  ])
  
  actions_enabled = true
  alarm_actions   = [aws_sns_topic.critical_alerts[0].arn]
  ok_actions      = [aws_sns_topic.critical_alerts[0].arn]
  
  tags = merge(var.tags, {
    Purpose = "Critical System Monitoring"
    ManagedBy = "Terraform"
    AlertType = "Critical"
  })
}


