#!/usr/bin/env bash
set -euo pipefail
#
# deploy_to_host.sh — Deploy this site behind an existing Traefik on a Debian host.
#
# Required ENV:
#   SITE_NAME          Short name for the stack (e.g., jpsr)
#   SITE_HOSTS         Space-separated hostnames (e.g., "example.com www.example.com")
#   SITE_IMAGE         Image:tag (e.g., ghcr.io/you/app:latest)
#
# Optional ENV:
#   TRAEFIK_DIR="/opt/traefik"       # path to Traefik helper scripts (already installed)
#   TARGET_DIR="/opt/sites"          # where per-site compose files live on the host
#   NETWORK_NAME="traefik_proxy"     # shared docker network
#
# Example:
#   sudo SITE_NAME="jpsr" \
#        SITE_HOSTS="joshphillipssr.com www.joshphillipssr.com" \
#        SITE_IMAGE="ghcr.io/joshphillipssr/jpsr-site:latest" \
#        bash /opt/joshphillipssr.com/scripts/deploy_to_host.sh

: "${SITE_NAME:?SITE_NAME required}"
: "${SITE_HOSTS:?SITE_HOSTS required}"
: "${SITE_IMAGE:?SITE_IMAGE required}"

TRAEFIK_DIR="${TRAEFIK_DIR:-/opt/traefik}"
TARGET_DIR="${TARGET_DIR:-/opt/sites}"
NETWORK_NAME="${NETWORK_NAME:-traefik_proxy}"

need_root() {
  if [[ $EUID -ne 0 ]]; then
    # If we're running from a real file, re-exec that file with sudo.
    if [[ -n "${BASH_SOURCE[0]:-}" && -r "${BASH_SOURCE[0]}" && "${BASH_SOURCE[0]}" != "bash" ]]; then
      echo "Re-exec with sudo..."
      exec sudo --preserve-env=SITE_NAME,SITE_HOSTS,SITE_IMAGE,TRAEFIK_DIR,TARGET_DIR,NETWORK_NAME "${BASH_SOURCE[0]}" "$@"
    else
      # Running via 'bash -c' (e.g., curl ... | bash or bash -c "$(curl ...)"), there's no file path to re-exec.
      cat >&2 <<'EOF'
This deployment script needs root privileges but was invoked without sudo in a mode
where it cannot re-exec itself (e.g., via `bash -c` or piped stdin).

Please run it like this from a sudo-capable user:

  sudo SITE_NAME="..." SITE_HOSTS="..." SITE_IMAGE="..." \
       bash /opt/joshphillipssr.com/scripts/deploy_to_host.sh
EOF
      exit 1
    fi
  fi
}
need_root

log() { printf "\n==> %s\n" "$*"; }

ensure_docker() {
  if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    log "Docker present"
    return
  fi
  log "Installing Docker (Debian)"
  apt-get update
  apt-get -y install ca-certificates curl gnupg lsb-release
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update
  apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  systemctl enable --now docker
}

check_network() {
  if ! docker network inspect "$NETWORK_NAME" >/dev/null 2>&1; then
    echo "Error: Docker network '$NETWORK_NAME' not found."
    echo "Traefik must already be deployed and the shared network created."
    echo "Create the network with your Traefik repo, e.g.:"
    echo "  NETWORK_NAME=\"$NETWORK_NAME\" \"$TRAEFIK_DIR/traefik/scripts/create_network.sh\""
    exit 1
  fi
}

deploy_site() {
  log "Deploying site '${SITE_NAME}' for hosts: ${SITE_HOSTS}"
  SITE_NAME="$SITE_NAME" \
  SITE_HOSTS="$SITE_HOSTS" \
  SITE_IMAGE="$SITE_IMAGE" \
  TARGET_DIR="$TARGET_DIR" \
  NETWORK_NAME="$NETWORK_NAME" \
  bash "$TRAEFIK_DIR/traefik/scripts/deploy_site.sh"
}

post_checks() {
  log "Active containers"
  docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
  echo
  echo "Try:   curl -I https://$(echo "$SITE_HOSTS" | awk '{print $1}')"
}

ensure_docker
check_network
deploy_site
post_checks

echo
echo "✅ Done. DNS for these hosts should point at this server with Cloudflare proxy ON."
echo "   Certificates will be issued/renewed automatically via Let's Encrypt DNS-01."