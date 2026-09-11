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

variable "replica_ports" {
  description = "Host ports to publish; one nginx replica container is created per port"
  type        = list(number)
  default     = [8080, 8082]
}

variable "site_content_dir" {
  description = "Directory (relative to this module) bind-mounted into the container as nginx's html root"
  type        = string
  default     = "www"
}
