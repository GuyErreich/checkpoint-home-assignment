# ==============================================================================
# SNS TOPICS AND SUBSCRIPTIONS FOR HEALTH MONITORING
# ==============================================================================
# This file contains all SNS resources for health check monitoring:
# - SNS topics for different types of alerts
# - Email subscriptions for notifications
# - SMS subscriptions (if needed)
# ==============================================================================

# SNS Topic for Health Check Alerts
resource "aws_sns_topic" "alerts" {
  count = var.enable_monitoring ? 1 : 0
  name  = "${var.cluster_name}-health-alerts"
  
  tags = merge(var.tags, {
    Purpose = "Health Check Monitoring"
    ManagedBy = "Terraform"
  })
}

# Email subscription for health alerts
resource "aws_sns_topic_subscription" "email_alerts" {
  count     = var.enable_monitoring && var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = var.alert_email
  
  # Confirmation will be sent to email
  # User needs to confirm subscription manually
}

# ==============================================================================
# ADDITIONAL SNS TOPICS (if needed for different alert types)
# ==============================================================================

# Critical alerts topic (for immediate attention)
resource "aws_sns_topic" "critical_alerts" {
  count = var.enable_monitoring ? 1 : 0
  name  = "${var.cluster_name}-critical-alerts"
  
  tags = merge(var.tags, {
    Purpose = "Critical Health Monitoring"
    ManagedBy = "Terraform"
  })
}

# Warning alerts topic (for non-critical issues)
resource "aws_sns_topic" "warning_alerts" {
  count = var.enable_monitoring ? 1 : 0
  name  = "${var.cluster_name}-warning-alerts"
  
  tags = merge(var.tags, {
    Purpose = "Warning Health Monitoring"
    ManagedBy = "Terraform"
  })
}

# ==============================================================================
# ALERT ESCALATION LOGIC
# ==============================================================================

# Email subscription for critical alerts
resource "aws_sns_topic_subscription" "critical_email_alerts" {
  count     = var.enable_monitoring && var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.critical_alerts[0].arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Email subscription for warning alerts  
resource "aws_sns_topic_subscription" "warning_email_alerts" {
  count     = var.enable_monitoring && var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.warning_alerts[0].arn
  protocol  = "email"
  endpoint  = var.alert_email
}
