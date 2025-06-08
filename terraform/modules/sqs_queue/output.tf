output "id" {
  value = aws_sqs_queue.main.id
}

output "url" {
  value = aws_sqs_queue.main.url
}

output "arn" {
  description = "ARN of the SQS queue"
  value = aws_sqs_queue.main.arn
}