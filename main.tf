module "web" {
  source = "./modules/nginx_site"

  image_name         = var.image_name
  container_name     = var.container_name
  network_name       = var.network_name
  replica_ports      = var.replica_ports
  site_content_path  = abspath("${path.module}/${var.site_content_dir}")
}
