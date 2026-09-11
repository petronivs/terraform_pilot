variable "image_name" {
  description = "Docker image to pull and run"
  type        = string
  default     = "nginx:alpine"
}

variable "container_name" {
  description = "Name for the running container"
  type        = string
  default     = "terraform-pilot-nginx"
}

variable "network_name" {
  description = "Name for the Docker network"
  type        = string
  default     = "terraform-pilot-net"
}

variable "host_port" {
  description = "Host port to publish the container's port 80 on"
  type        = number
  default     = 8080
}
