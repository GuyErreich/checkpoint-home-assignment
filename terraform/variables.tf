variable "cluster_name" {
  type = string
}

variable "region" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
variable "container_name_api" {
  type = string  
}

variable "image_url_api" {
  type = string
}

variable "cpu_api" {
  type    = number
  default = 256
}

variable "memory_api" {
  type    = number
  default = 512
}

variable "container_name_worker" {
  type = string
}

variable "image_url_worker" {
  type = string
}

variable "cpu_worker" {
  type    = number
  default = 256
}

variable "memory_worker" {
  type    = number
  default = 512
}

variable "alert_email" {
  type        = string
  description = "Email address to receive CloudWatch alerts"
  default     = ""
}

variable "enable_monitoring" {
  type        = bool
  description = "Enable CloudWatch monitoring and alerts"
  default     = true
}

variable "project_name" {
  type        = string
  description = "Project name used for resource naming and tagging"
  default     = "devops"
}

variable "enable_ssh_access" {
  type        = bool
  description = "Enable SSH access to ECS instances for debugging (creates local private key file)"
  default     = true
}
