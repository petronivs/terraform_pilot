resource "docker_network" "app_net" {
  name = var.network_name
}

resource "docker_image" "nginx" {
  name         = var.image_name
  keep_locally = true
}

locals {
  replica_ports_set = toset([for p in var.replica_ports : tostring(p)])
}

resource "docker_container" "web" {
  for_each = local.replica_ports_set

  name  = "${var.container_name}-${each.value}"
  image = docker_image.nginx.image_id

  networks_advanced {
    name = docker_network.app_net.name
  }

  ports {
    internal = 80
    external = tonumber(each.value)
  }

  volumes {
    host_path      = abspath("${path.module}/${var.site_content_dir}")
    container_path = "/usr/share/nginx/html"
    read_only      = true
  }
}
