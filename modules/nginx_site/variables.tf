variable "image_name" {
  description = "Docker image to pull and run"
  type        = string
  default     = "nginx:alpine"
}

variable "container_name" {
  description = "Base name for the running containers (each replica appends -<port>)"
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

variable "site_content_path" {
  description = "Absolute host directory bind-mounted into each container as nginx's html root. Defaults to this module's own www/ directory when not set by the caller."
  type        = string
  default     = null
}
