variable "cluster_name" {
  type = string
}

variable "region" {
  type = string
}

variable "security_group_id" {
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
