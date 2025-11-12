#!/usr/bin/env bash
set -euo pipefail

: "${SITE_NAME:?SITE_NAME required}"
SITE_DIR="/opt/sites/${SITE_NAME}"
COMPOSE="${SITE_DIR}/docker-compose.yml"

if [[ ! -f "$COMPOSE" ]]; then
  echo "Error: ${COMPOSE} not found. Deploy the site first."
  exit 1
fi

echo "==> Updating ${SITE_NAME}"
docker compose -f "$COMPOSE" pull
docker compose -f "$COMPOSE" up -d
docker compose -f "$COMPOSE" ps

echo "✅ ${SITE_NAME} updated successfully."
