#!/usr/bin/env bash
#
# cleanup.sh — Clean JUST the jpsr site deployment on this host.
#
# This script will:
#   - Stop and remove the jpsr container/stack
#   - Remove /opt/sites/jpsr (the runtime deploy dir)
#   - Remove /opt/joshphillipssr.com (the site repo clone)
#
# It will NOT:
#   - Touch Traefik
#   - Touch the 'deploy' user
#   - Prune Docker globally
#   - Remove the shared 'traefik_proxy' network
#
# Run with:
#   sudo /opt/joshphillipssr.com/scripts/cleanup.sh
#

set -euo pipefail

SITE_NAME="${SITE_NAME:-jpsr}"
SITE_DEPLOY_DIR="/opt/sites/${SITE_NAME}"
SITE_REPO_DIR="/opt/joshphillipssr.com"

if [[ "$EUID" -ne 0 ]]; then
  echo "This script must be run as root. Try:"
  echo "  sudo $0"
  exit 1
fi

echo "==> Cleaning site '${SITE_NAME}'"
echo "    Deploy dir: ${SITE_DEPLOY_DIR}"
echo "    Repo dir:   ${SITE_REPO_DIR}"

echo "==> Stopping site via docker compose (if present)..."
if [[ -f "${SITE_DEPLOY_DIR}/docker-compose.yml" ]]; then
  docker compose -f "${SITE_DEPLOY_DIR}/docker-compose.yml" down || true
else
  echo "No docker-compose.yml found at ${SITE_DEPLOY_DIR}, skipping compose down."
fi

echo "==> Ensuring any standalone '${SITE_NAME}' container is removed..."
if docker ps -a --format '{{.Names}}' | grep -qx "${SITE_NAME}"; then
  docker rm -f "${SITE_NAME}" || true
else
  echo "Container '${SITE_NAME}' not found, skipping."
fi

echo "==> Removing site deploy directory: ${SITE_DEPLOY_DIR}"
rm -rf "${SITE_DEPLOY_DIR}"

echo "==> Removing site repo clone (if present): ${SITE_REPO_DIR}"
rm -rf "${SITE_REPO_DIR}"

echo "✅ Site cleanup complete."
echo "Host Traefik, Docker install, and shared networks/users were left intact."
echo
echo "You can now re-bootstrap the site by following Step 3 in the jpsr README."