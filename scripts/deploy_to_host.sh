#!/usr/bin/env bash
set -euo pipefail
#
# deploy_to_host.sh — Bootstrap infra (Traefik) and deploy this site on a Debian host.
#
# Required ENV:
#   CF_API_TOKEN       Cloudflare token (Zone.DNS:Edit + Zone.Zone:Read)
#   EMAIL              Email for Let's Encrypt account
#   SITE_NAME          Short name for the stack (e.g., jpsr)
#   SITE_HOSTS         Space-separated hostnames (e.g., "example.com www.example.com")
#   SITE_IMAGE         Image:tag (e.g., ghcr.io/you/app:latest)
#
# Optional ENV:
#   USE_STAGING=false  Use LE staging CA (true/false)
#   TRAEFIK_REPO="https://github.com/joshphillipssr/Traefik-Deployment.git"
#   TRAEFIK_DIR="/opt/traefik"       # where the infra repo will live on the host
#   TARGET_DIR="/opt/sites"          # where per-site compose files live on the host
#   NETWORK_NAME="traefik_proxy"     # shared docker network
#
# Example:
#   sudo CF_API_TOKEN="..." EMAIL="you@example.com" \
#        SITE_NAME="jpsr" SITE_HOSTS="joshphillipssr.com www.joshphillipssr.com" \
#        SITE_IMAGE="ghcr.io/joshphillipssr/jpsr-site:latest" \
#        ./scripts/deploy_to_host.sh

: "${CF_API_TOKEN:?CF_API_TOKEN required}"
: "${EMAIL:?EMAIL required}"
: "${SITE_NAME:?SITE_NAME required}"
: "${SITE_HOSTS:?SITE_HOSTS required}"
: "${SITE_IMAGE:?SITE_IMAGE required}"

USE_STAGING="${USE_STAGING:-false}"
TRAEFIK_REPO="${TRAEFIK_REPO:-https://github.com/joshphillipssr/Traefik-Deployment.git}"
TRAEFIK_DIR="${TRAEFIK_DIR:-/opt/traefik}"
TARGET_DIR="${TARGET_DIR:-/opt/sites}"
NETWORK_NAME="${NETWORK_NAME:-traefik_proxy}"

need_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "Re-exec with sudo..."
    exec sudo --preserve-env=CF_API_TOKEN,EMAIL,SITE_NAME,SITE_HOSTS,SITE_IMAGE,USE_STAGING,TRAEFIK_REPO,TRAEFIK_DIR,TARGET_DIR,NETWORK_NAME "$0" "$@"
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

clone_or_update_infra() {
  if [[ -d "$TRAEFIK_DIR/.git" ]]; then
    log "Updating Traefik-Deployment repo in $TRAEFIK_DIR"
    git -C "$TRAEFIK_DIR" fetch --all --prune
    git -C "$TRAEFIK_DIR" switch -q main || true
    git -C "$TRAEFIK_DIR" pull --ff-only
  else
    log "Cloning Traefik-Deployment to $TRAEFIK_DIR"
    git clone "$TRAEFIK_REPO" "$TRAEFIK_DIR"
  fi
  chmod +x "$TRAEFIK_DIR"/traefik/scripts/*.sh
}

bring_up_traefik() {
  log "Creating shared Docker network ($NETWORK_NAME)"
  NETWORK_NAME="$NETWORK_NAME" "$TRAEFIK_DIR/traefik/scripts/create_network.sh"

  log "Starting Traefik (staging=${USE_STAGING})"
  CF_API_TOKEN="$CF_API_TOKEN" EMAIL="$EMAIL" USE_STAGING="$USE_STAGING" \
    "$TRAEFIK_DIR/traefik/scripts/traefik_up.sh"
}

deploy_site() {
  log "Deploying site '${SITE_NAME}' for hosts: ${SITE_HOSTS}"
  TARGET_DIR="$TARGET_DIR" NETWORK_NAME="$NETWORK_NAME" \
    "$TRAEFIK_DIR/traefik/scripts/deploy_site.sh" \
      SITE_NAME="$SITE_NAME" \
      SITE_HOSTS="$SITE_HOSTS" \
      SITE_IMAGE="$SITE_IMAGE"
}

post_checks() {
  log "Active containers"
  docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
  echo
  echo "Try:   curl -I https://$(echo "$SITE_HOSTS" | awk '{print $1}')"
}

ensure_docker
clone_or_update_infra
bring_up_traefik
deploy_site
post_checks

echo
echo "✅ Done. DNS for these hosts should point at this server with Cloudflare proxy ON."
echo "   Certificates will be issued/renewed automatically via Let's Encrypt DNS-01."