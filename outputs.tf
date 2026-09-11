output "container_names" {
  description = "Names of all replica containers"
  value       = [for c in docker_container.web : c.name]
}

output "urls" {
  description = "URL for each replica, in the same order as replica_ports"
  value       = [for p in var.replica_ports : "http://localhost:${p}"]
}
