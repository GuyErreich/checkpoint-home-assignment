resource "aws_ssm_parameter" "token" {
  name  = "/api/token"
  type  = "SecureString"
  value = var.token_value

  tags = {
    Name = "api-auth-token"
  }
}