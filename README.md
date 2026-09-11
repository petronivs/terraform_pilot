# terraform_pilot

A small local learning project for getting hands-on with Terraform, using the
[`kreuzwerker/docker`](https://registry.terraform.io/providers/kreuzwerker/docker/latest)
provider so it runs entirely against a local Docker daemon — no cloud account
or credentials required.

## What it does

Running `terraform apply` creates:

- `docker_network.app_net` — a dedicated bridge network (`terraform-pilot-net`)
- `docker_image.nginx` — pulls the `nginx:alpine` image
- `docker_container.web` — one nginx container **per entry in `replica_ports`**
  (`for_each` over that list, default `[8080, 8082]`), each named
  `<container_name>-<port>`, publishing container port 80 to its host port,
  with the `www/` directory bind-mounted read-only over nginx's html root

## Files

| File | Purpose |
|---|---|
| `versions.tf` | Required Terraform version and provider declaration |
| `variables.tf` | Inputs: `image_name`, `container_name`, `network_name`, `replica_ports`, `site_content_dir` |
| `main.tf` | The network, image, and (via `for_each`) one container per replica port |
| `outputs.tf` | `container_names` and `urls` lists, one entry per replica |
| `www/index.html` | Static page served by nginx (edit and refresh, no `apply` needed) |
| `tests/nginx.tftest.hcl` | Automated tests (see [Testing](#testing)) |

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Viewing the page

Once `apply` finishes, every replica container is up and serving
immediately — no extra step needed. Confirm they're running:

```bash
docker ps --filter name=terraform-pilot-nginx
```

Then open each URL from the `urls` output (default
`http://localhost:8080` and `http://localhost:8082`) in a browser. If you're
running Terraform inside WSL, Docker Desktop shares its daemon and forwards
ports to Windows too, so these work from a browser on either side.

To check from the command line instead of a browser:

```bash
terraform output -json urls
curl http://localhost:8080
curl http://localhost:8082
```

You should see the same custom page from `www/index.html` on every replica —
it's bind-mounted read-only into each container, so editing that one file
updates all of them at once. Refresh the browser to see changes immediately,
with no `terraform apply` needed (only structural changes like the mount
path itself require re-apply). Containers stay up until you run
`terraform destroy` — they do not stop on their own.

Note: changing `replica_ports` (adding, removing, or reordering ports),
`site_content_dir`, or the volume block itself forces affected containers to
be destroyed and recreated, since Docker mounts and published ports can't be
changed on a running container — `terraform apply` will show that plan when
it happens.

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

- a `plan`-only run that verifies the network, image, and each planned
  replica container are configured with the expected names
- an `apply` run that actually creates two replica containers (using
  overridden `container_name`/`network_name`/`replica_ports` so they don't
  collide with containers you may already have running manually) and asserts
  each one's ports, volume mount, and the `container_names`/`urls` outputs
  are correct

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
