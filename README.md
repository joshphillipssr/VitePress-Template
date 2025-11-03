#!/usr/bin/env bash
set -euo pipefail
# Ensure a shared Docker network exists for Traefik and sites.
#
# Optional:
#   NETWORK_NAME="traefik_proxy"

NETWORK_NAME="${NETWORK_NAME:-traefik_proxy}"

# Ensure Docker available
if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker not found or not in PATH." >&2
  exit 1
fi
if ! docker info >/dev/null 2>&1; then
  echo "Error: cannot talk to the Docker daemon. Ensure your user is in the 'docker' group." >&2
  exit 1
fi

if docker network inspect "${NETWORK_NAME}" >/dev/null 2>&1; then
  echo "Network '${NETWORK_NAME}' already exists."
else
  echo "Creating network '${NETWORK_NAME}'..."
  docker network create "${NETWORK_NAME}" >/dev/null
  echo "✅ Created network '${NETWORK_NAME}'."
fi
#!/usr/bin/env bash
set -euo pipefail
# Update a deployed site by pulling the latest image and recreating the stack.
#
# Required:
#   SITE_NAME="shortname"
# Optional:
#   TARGET_DIR="/opt/sites" (default)
#
# Example:
#   SITE_NAME="jpsr" ./traefik/scripts/update_site.sh

: "${SITE_NAME:?SITE_NAME required}"
TARGET_DIR="${TARGET_DIR:-/opt/sites}"
BASE="${TARGET_DIR}/${SITE_NAME}"
COMPOSE_FILE="${BASE}/docker-compose.yml"

# Ensure Docker available
if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker not found or not in PATH." >&2
  exit 1
fi
if ! docker info >/dev/null 2>&1; then
  echo "Error: cannot talk to the Docker daemon. Ensure your user is in the 'docker' group." >&2
  exit 1
fi

if [[ ! -f "${COMPOSE_FILE}" ]]; then
  echo "No docker-compose.yml found for site '${SITE_NAME}' in ${BASE}."
  exit 1
fi

echo "Pulling latest image(s) for ${SITE_NAME}..."
docker compose -f "${COMPOSE_FILE}" pull

echo "Recreating ${SITE_NAME} with updated image(s)..."
docker compose -f "${COMPOSE_FILE}" up -d

echo "✅ Updated ${SITE_NAME}."
#!/usr/bin/env bash
set -euo pipefail
# Remove a deployed site stack and its compose directory.
#
# Required:
#   SITE_NAME="shortname"
# Optional:
#   TARGET_DIR="/opt/sites" (default)
#
# Example:
#   SITE_NAME="jpsr" ./traefik/scripts/remove_site.sh

: "${SITE_NAME:?SITE_NAME required}"
TARGET_DIR="${TARGET_DIR:-/opt/sites}"
BASE="${TARGET_DIR}/${SITE_NAME}"
COMPOSE_FILE="${BASE}/docker-compose.yml"

# Ensure Docker available
if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker not found or not in PATH." >&2
  exit 1
fi
if ! docker info >/dev/null 2>&1; then
  echo "Error: cannot talk to the Docker daemon. Ensure your user is in the 'docker' group." >&2
  exit 1
fi

if [[ ! -f "${COMPOSE_FILE}" ]]; then
  echo "No docker-compose.yml found for site '${SITE_NAME}' in ${BASE}."
  exit 0
fi

echo "Stopping and removing ${SITE_NAME}..."
docker compose -f "${COMPOSE_FILE}" down --remove-orphans

echo "Cleaning ${BASE}..."
rm -rf "${BASE}"

echo "✅ Removed ${SITE_NAME}."