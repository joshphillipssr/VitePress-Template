# Quick Start

Use this guide to turn the VitePress template into your own site repository
and deploy it behind an existing Traefik stack that was provisioned with the
[Traefik-Deployment](https://github.com/joshphillipssr/Traefik-Deployment)
project.

The example below creates a site called `joshphillipssr.com`, but you can swap
names/hosts for your own domain.

---

## Prerequisites

- A domain managed in Cloudflare with `A`/`AAAA` records pointing at your VPS and
	SSL/TLS mode set to **Full (strict)**.
- Traefik already running on the host via Traefik-Deployment (two-phase prep
	with `host_prep_root.sh` → `host_prep_deploy.sh`, then `traefik_up.sh`).
- The shared Docker network exists (default `traefik_proxy`). If not, create it
	on the host: `NETWORK_NAME=traefik_proxy /opt/traefik/scripts/create_network.sh`.
- A non-root sudo-capable user on the host (e.g., `deploy` or an admin user that
	can sudo). Scripts will re-exec with sudo when required.
- Yarn installed locally if you want to edit content before pushing.

---

## 1) Create your site repo from the template

1. On GitHub, click **Use this template** → **Create a new repository**.
2. Name it (e.g., `joshphillipssr.com`) and make it public or private as you
	 prefer.
3. Clone your new repo locally:

	 ```bash
	 git clone https://github.com/<you>/<your-site>.git
	 cd <your-site>
	 ```

4. Optional: Update branding/content under `docs/` and `.vitepress/config.ts`.

---

## 2) Configure CI image name (GHCR)

Edit `.github/workflows/build-and-push.yml` and set the image tag to your
namespace:

```yaml
tags: ghcr.io/<your-username>/<your-site>:latest
```

Commit and push to `main`. GitHub Actions will build and push the Docker image
to GHCR. After the first push, mark the package **Public** so the host can pull
without credentials.

---

## 3) (Optional) Local smoke test

```bash
yarn install
yarn docs:dev
# open http://localhost:5175
```

Build locally if you want to verify:

```bash
yarn docs:build
```

---

## 4) Prepare the host with your site repo

Run this as a sudo-capable user (not necessarily `deploy`). The script will
clone/sync your repo into `/opt/sites/<SITE_NAME>` and mark deploy scripts
executable.

```bash
sudo SITE_REPO="https://github.com/<you>/<your-site>.git" \
		 SITE_DIR="/opt/sites/<SITE_NAME>" \
		 bash -c "$(curl -fsSL https://raw.githubusercontent.com/<you>/<your-site>/main/scripts/bootstrap_site_on_host.sh)"
```

Example for `joshphillipssr.com`:

```bash
sudo SITE_REPO="https://github.com/joshphillipssr/joshphillipssr.com.git" \
		 SITE_DIR="/opt/sites/jpsr" \
		 bash -c "$(curl -fsSL https://raw.githubusercontent.com/joshphillipssr/joshphillipssr.com/main/scripts/bootstrap_site_on_host.sh)"
```

After it finishes, switch to the `deploy` user (or keep using sudo for the next
step): `sudo -iu deploy`.

---

## 5) Deploy behind Traefik

Run from the host. The script re-execs with sudo and expects Traefik’s network
to already exist.

```bash
sudo SITE_NAME="<SITE_NAME>" \
		 SITE_HOSTS="example.com www.example.com" \
		 SITE_IMAGE="ghcr.io/<you>/<your-site>:latest" \
		 TRAEFIK_DIR="/opt/traefik" \
		 TARGET_DIR="/opt/sites" \
		 NETWORK_NAME="traefik_proxy" \
		 bash /opt/sites/<SITE_NAME>/scripts/deploy_to_host.sh
```

What it does:
- Writes `/opt/sites/<SITE_NAME>/docker-compose.yml` with Traefik labels.
- Ensures Docker is installed (installs if missing on Debian).
- Validates the shared Docker network.
- Brings the container up with `docker compose up -d`.

Verification:

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
curl -I https://example.com
```

Certificates issue automatically via Traefik’s DNS-01 resolver (Cloudflare).

---

## 6) Update after new pushes

When GitHub Actions publishes a new image, update the running site from the
host:

```bash
SITE_NAME="<SITE_NAME>" /opt/sites/<SITE_NAME>/scripts/update_site.sh
```

If you prefer using the helper from Traefik-Deployment, run:

```bash
SITE_NAME="<SITE_NAME>" /opt/traefik/scripts/update_site.sh
```

You can wire this into a webhook or scheduled job if desired.

---

## 7) Remove the site (optional)

Stop and remove the site’s compose stack, then delete its files:

```bash
SITE_NAME="<SITE_NAME>" /opt/traefik/scripts/remove_site.sh
```

---

## Troubleshooting

- **Network missing:** Create it with `NETWORK_NAME=traefik_proxy /opt/traefik/scripts/create_network.sh`.
- **Permission denied running scripts:** `chmod +x /opt/sites/<SITE_NAME>/scripts/*.sh`.
- **GHCR pull fails:** Ensure the package is Public and the image tag matches
	`SITE_IMAGE`.
- **TLS/HTTP issues:** Confirm Cloudflare proxy is on and SSL mode is Full
	(strict); verify DNS points to the host.

---

You now have a reproducible path from template → repo → image → Traefik-backed
deployment.
