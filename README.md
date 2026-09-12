# terraform_pilot

A small local learning project for getting hands-on with Terraform, using the
[`kreuzwerker/docker`](https://registry.terraform.io/providers/kreuzwerker/docker/latest)
provider so it runs entirely against a local Docker daemon — no cloud account
or credentials required.

## What it does

The root module just calls a reusable child module, `modules/nginx_site`,
which creates:

- `docker_network.app_net` — a dedicated bridge network (`terraform-pilot-net`)
- `docker_image.nginx` — pulls the `nginx:alpine` image
- `docker_container.web` — one nginx container **per entry in `replica_ports`**
  (`for_each` over that list, default `[8080, 8082]`), each named
  `<container_name>-<port>`, publishing container port 80 to its host port,
  with a directory bind-mounted read-only over nginx's html root

Structuring it as a root module calling a child module (instead of putting
resources directly at the top level) mirrors how real-world cloud Terraform
repos are usually organized — a root module per environment, calling shared
child modules for each piece of infrastructure. Swapping the module's
internals for `azurerm_*` resources later wouldn't change how it's called.

## Files

| File | Purpose |
|---|---|
| `versions.tf` | Required Terraform version and provider declaration |
| `variables.tf` | Root inputs: `image_name`, `container_name`, `network_name`, `replica_ports`, `site_content_dir` |
| `main.tf` | Calls `module.web` (`./modules/nginx_site`), passing through the root variables |
| `outputs.tf` | `container_names` and `urls`, passed through from `module.web` |
| `modules/nginx_site/` | The actual network/image/container resources — see its own variables/outputs |
| `www/index.html` | Static page served by nginx (edit and refresh, no `apply` needed) |
| `tests/nginx.tftest.hcl` | Automated tests (see [Testing](#testing)) |

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Changing the number of replicas or ports

The number of nginx containers, and which host ports they use, is controlled
entirely by the `replica_ports` variable (default `[8080, 8082]`) — one
container is created per port in the list. To change it, either edit the
default in `variables.tf`, or override it without editing code:

```bash
# Three replicas instead of two
terraform apply -var='replica_ports=[8080, 8081, 8082]'

# Just one replica
terraform apply -var='replica_ports=[8080]'
```

Or set it in a `terraform.tfvars` file (gitignored — see [Notes](#notes)
below) so you don't have to pass `-var` every time:

```hcl
# terraform.tfvars
replica_ports = [8080, 8081, 8082]
```

Each port must be free on your host and unique in the list — Terraform will
error at apply time if a port is already bound by something else. Adding a
port creates a new container; removing one destroys the corresponding
container; changing a port value destroys and recreates that one container
(the others are untouched, since each is a separate `for_each` instance).

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

## A lesson from this refactor: moving resources into a module

When the resources here were moved from the root `main.tf` directly into
`modules/nginx_site`, their state addresses changed (e.g.
`docker_network.app_net` became `module.web.docker_network.app_net`).
Terraform doesn't know those two addresses refer to the "same" infrastructure
unless you tell it, so `terraform apply` planned a full destroy-then-create
instead of an in-place rename — which is exactly what happened here (briefly
took the containers down before recreating them).

The correct way to do this kind of refactor without downtime is a `moved`
block, e.g. in `main.tf`:

```hcl
moved {
  from = docker_network.app_net
  to   = module.web.docker_network.app_net
}
```

One `moved` block per resource (covering all `for_each`/`count` instances at
once, no index needed) tells Terraform to treat the old and new addresses as
the same object and update state in place — no destroy, no recreate. This
matters a lot more once real cloud resources are involved: destroying and
recreating an `azurerm_storage_account` or database isn't just a brief
restart, it can mean real data loss or a non-trivial outage. Worth reaching
for `moved` blocks by default any time a refactor changes resource addresses,
not just when it's convenient.

## Testing

This project uses Terraform's native [`terraform test`](https://developer.hashicorp.com/terraform/language/tests)
framework (built in since Terraform 1.6, no extra tooling required):

```bash
terraform test
```

`tests/nginx.tftest.hcl` runs three checks, using overridden
`container_name`/`network_name`/`replica_ports` throughout so nothing
collides with containers you may already have running manually:

- a `plan`-only run against `modules/nginx_site` directly (via a per-run
  `module { source = "./modules/nginx_site" }` block) that verifies the
  network, image, and each planned replica container are configured with the
  expected names
- an `apply` run, also against the module directly, that actually creates two
  replica containers and asserts each one's ports, volume mount, and the
  module's `container_names`/`urls` outputs are correct
- an `apply` run against the **root** configuration (no module override) that
  checks the root's `container_names`/`urls` outputs correctly pass through
  whatever `module.web` produces — i.e., that the root module is wiring the
  child module correctly, not just that the child module works in isolation

Resources created during `apply` runs are automatically destroyed by
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
