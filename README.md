# terraform_pilot

A small local learning project for getting hands-on with Terraform, using the
[`kreuzwerker/docker`](https://registry.terraform.io/providers/kreuzwerker/docker/latest)
provider so it runs entirely against a local Docker daemon — no cloud account
or credentials required.

## What it does

Running `terraform apply` creates:

- `docker_network.app_net` — a dedicated bridge network (`terraform-pilot-net`)
- `docker_image.nginx` — pulls the `nginx:alpine` image
- `docker_container.web` — runs an nginx container on that network, publishing
  container port 80 to a host port (default `8080`)

## Files

| File | Purpose |
|---|---|
| `versions.tf` | Required Terraform version and provider declaration |
| `variables.tf` | Inputs: `image_name`, `container_name`, `host_port` |
| `main.tf` | The network, image, and container resources |
| `outputs.tf` | Container name and the URL to hit it at |

## Usage

```bash
terraform init
terraform plan
terraform apply
```

Then visit `http://localhost:8080` (or whatever `host_port` is set to).

Tear it down with:

```bash
terraform destroy
```

## Requirements

- Terraform >= 1.5
- Docker daemon reachable (Docker Desktop, or any Docker Engine)

## Notes

- `terraform.tfstate` and `.terraform/` are gitignored since state can contain
  sensitive resource data — see `.gitignore`.
- Built and tested inside WSL (Ubuntu, arm64) against Docker Desktop's shared
  daemon.
