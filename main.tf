resource "docker_network" "app_net" {
  name = "terraform-pilot-net"
}

resource "docker_image" "nginx" {
  name         = var.image_name
  keep_locally = true
}

resource "docker_container" "web" {
  name  = var.container_name
  image = docker_image.nginx.image_id

  networks_advanced {
    name = docker_network.app_net.name
  }

  ports {
    internal = 80
    external = var.host_port
  }
}
