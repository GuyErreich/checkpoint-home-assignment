resource "aws_sqs_queue" "main" {
  name = "devops-worker-queue"

  tags = {
    Name = "devops-worker-queue"
  }
}
