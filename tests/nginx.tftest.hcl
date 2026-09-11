# Overrides used by the apply-based test below, to avoid colliding with a
# manually-run `terraform apply` deployment (default container name / port).
variables {
  container_name = "terraform-pilot-nginx-test"
  network_name    = "terraform-pilot-net-test"
  host_port       = 8081
}

run "plan_has_expected_resources" {
  command = plan

  assert {
    condition     = docker_network.app_net.name == "terraform-pilot-net-test"
    error_message = "Network should use the overridden test name"
  }

  assert {
    condition     = docker_image.nginx.name == "nginx:alpine"
    error_message = "Default image should be nginx:alpine"
  }

  assert {
    condition     = docker_container.web.name == "terraform-pilot-nginx-test"
    error_message = "Container should use the overridden test name"
  }
}

run "apply_creates_working_container" {
  command = apply

  assert {
    condition     = docker_container.web.name == "terraform-pilot-nginx-test"
    error_message = "Container name did not match expected test name"
  }

  assert {
    condition     = one(docker_container.web.ports).external == 8081
    error_message = "External port mapping did not match expected value"
  }

  assert {
    condition     = one(docker_container.web.ports).internal == 80
    error_message = "Internal port mapping did not match expected value"
  }

  assert {
    condition     = output.url == "http://localhost:8081"
    error_message = "url output should reflect the overridden host_port"
  }

  assert {
    condition     = output.container_name == "terraform-pilot-nginx-test"
    error_message = "container_name output did not match expected test name"
  }

  assert {
    condition     = length(docker_container.web.volumes) == 1
    error_message = "Container should have exactly one mounted volume for custom site content"
  }

  assert {
    condition     = one(docker_container.web.volumes).container_path == "/usr/share/nginx/html"
    error_message = "Volume should be mounted at nginx's html directory"
  }

  assert {
    condition     = one(docker_container.web.volumes).read_only == true
    error_message = "Site content volume should be mounted read-only"
  }
}
