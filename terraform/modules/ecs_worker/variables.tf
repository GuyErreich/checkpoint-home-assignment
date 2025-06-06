variable "cluster_name" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_id" {
  type = string
}

variable "tags" {
  type = map(string)
}

# API service
variable "container_name_api" {
  type = string
}

variable "image_url_api" {
  type = string
}

variable "cpu_api" {
  type = number
}

variable "memory_api" {
  type = number
}

# Worker service
variable "container_name_worker" {
  type = string
}

variable "image_url_worker" {
  type = string
}

variable "cpu_worker" {
  type = number
}

variable "memory_worker" {
  type = number
}

# Shared resources
variable "sqs_url" {
  type = string
}

variable "s3_bucket" {
  type = string
}