resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "main" {
  bucket = "devops-worker-storage-${random_id.suffix.hex}"
  force_destroy = true

  tags = {
    Name = "devops-worker-storage"
  }
}
