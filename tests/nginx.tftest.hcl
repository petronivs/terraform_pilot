# Global overrides so tests never collide with a manually-run `terraform
# apply` deployment on the default ports/names.
variables {
  container_name = "terraform-pilot-nginx-test"
  network_name    = "terraform-pilot-net-test"
  replica_ports   = [8090, 8091]
}

# --- Tests against the nginx_site module directly ---

run "module_plan_has_expected_resources" {
  command = plan

  module {
    source = "./modules/nginx_site"
  }

  assert {
    condition     = docker_network.app_net.name == "terraform-pilot-net-test"
    error_message = "Network should use the overridden test name"
  }

  assert {
    condition     = docker_image.nginx.name == "nginx:alpine"
    error_message = "Default image should be nginx:alpine"
  }

  assert {
    condition     = length(docker_container.web) == 2
    error_message = "One container should be planned per entry in replica_ports"
  }

  assert {
    condition     = docker_container.web["8090"].name == "terraform-pilot-nginx-test-8090"
    error_message = "Replica container name should be suffixed with its port"
  }

  assert {
    condition     = docker_container.web["8091"].name == "terraform-pilot-nginx-test-8091"
    error_message = "Replica container name should be suffixed with its port"
  }
}

run "module_apply_creates_working_replicas" {
  command = apply

  module {
    source = "./modules/nginx_site"
  }

  assert {
    condition     = length(docker_container.web) == 2
    error_message = "One container should be created per entry in replica_ports"
  }

  assert {
    condition     = one(docker_container.web["8090"].ports).external == 8090
    error_message = "First replica's external port did not match replica_ports"
  }

  assert {
    condition     = one(docker_container.web["8091"].ports).external == 8091
    error_message = "Second replica's external port did not match replica_ports"
  }

  assert {
    condition     = one(docker_container.web["8090"].ports).internal == 80
    error_message = "Internal port mapping did not match expected value"
  }

  assert {
    condition     = length(docker_container.web["8090"].volumes) == 1
    error_message = "Each replica should have exactly one mounted volume for custom site content"
  }

  assert {
    condition     = one(docker_container.web["8090"].volumes).container_path == "/usr/share/nginx/html"
    error_message = "Volume should be mounted at nginx's html directory"
  }

  assert {
    condition     = one(docker_container.web["8090"].volumes).read_only == true
    error_message = "Site content volume should be mounted read-only"
  }

  assert {
    condition     = contains(output.urls, "http://localhost:8090")
    error_message = "Module's urls output should include a URL for each replica port"
  }

  assert {
    condition     = contains(output.urls, "http://localhost:8091")
    error_message = "Module's urls output should include a URL for each replica port"
  }

  assert {
    condition     = contains(output.container_names, "terraform-pilot-nginx-test-8090")
    error_message = "Module's container_names output should include every replica's name"
  }
}

# --- Test that the root module correctly wires the module's outputs through ---

run "root_module_exposes_module_outputs" {
  command = apply

  variables {
    replica_ports = [8092, 8093]
    network_name   = "terraform-pilot-net-test-root"
  }

  assert {
    condition     = contains(output.urls, "http://localhost:8092")
    error_message = "Root urls output should pass through the module's urls"
  }

  assert {
    condition     = contains(output.urls, "http://localhost:8093")
    error_message = "Root urls output should pass through the module's urls"
  }

  assert {
    condition     = contains(output.container_names, "terraform-pilot-nginx-test-8092")
    error_message = "Root container_names output should pass through the module's container_names"
  }
}
