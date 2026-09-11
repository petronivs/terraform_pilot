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
| `variables.tf` | Inputs: `image_name`, `container_name`, `network_name`, `host_port` |
| `main.tf` | The network, image, and container resources |
| `outputs.tf` | Container name and the URL to hit it at |
| `tests/nginx.tftest.hcl` | Automated tests (see [Testing](#testing)) |

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Viewing the page

Once `apply` finishes, the container is up and serving immediately — no
extra step needed. Confirm it's running:

```bash
docker ps --filter name=terraform-pilot-nginx
```

Then open `http://localhost:8080` (or whatever `host_port` is set to) in a
browser. If you're running Terraform inside WSL, Docker Desktop shares its
daemon and forwards ports to Windows too, so `localhost:8080` works from a
browser on either side.

To check it from the command line instead of a browser:

```bash
curl http://localhost:8080
```

You should see the default "Welcome to nginx!" page. The container stays up
until you run `terraform destroy` — it does not stop on its own.

Tear it down with:

```bash
terraform destroy
```

## Testing

This project uses Terraform's native [`terraform test`](https://developer.hashicorp.com/terraform/language/tests)
framework (built in since Terraform 1.6, no extra tooling required):

```bash
terraform test
```

`tests/nginx.tftest.hcl` runs two checks:

- a `plan`-only run that verifies the network, image, and container are
  configured with the expected names
- an `apply` run that actually creates a container (using overridden
  `container_name`/`network_name`/`host_port` so it doesn't collide with a
  container you may already have running manually) and asserts its ports and
  outputs are correct

Resources created during the `apply` test are automatically destroyed by
Terraform when the test finishes — this does not affect any container you
started yourself with a regular `terraform apply`.

## Requirements

- Terraform >= 1.5
- Docker daemon reachable (Docker Desktop, or any Docker Engine)

## Notes

- `terraform.tfstate` and `.terraform/` are gitignored since state can contain
  sensitive resource data — see `.gitignore`.
- Built and tested inside WSL (Ubuntu, arm64) against Docker Desktop's shared
  daemon.
