output "name" {
    description = "Name of the SSM parameter"
    value       = aws_ssm_parameter.token.name
}