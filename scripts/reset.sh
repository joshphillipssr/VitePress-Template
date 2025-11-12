

#!/usr/bin/env bash
# reset.sh — Clean server for a fresh README test run
# WARNING: This script will remove all containers, images, networks, volumes,
# and project directories under /opt related to Traefik and jpsr.

set -euo pipefail

echo "==> Stopping and removing all Docker containers..."
docker ps -aq | xargs -r docker stop
docker ps -aq | xargs -r docker rm

echo "==> Pruning Docker volumes, networks, and images..."
docker volume prune -f
docker network prune -f
docker system prune -af

echo "==> Removing old project directories..."
sudo rm -rf /opt/joshphillipssr.com /opt/sites /opt/traefik

echo "==> Removing the 'deploy' user and group if present..."
if id deploy &>/dev/null; then
  sudo deluser --remove-home deploy || true
  sudo groupdel deploy || true
else
  echo "User 'deploy' not found, skipping."
fi

echo "==> Checking Docker installation..."
if ! command -v docker &>/dev/null; then
  echo "Docker not found. It will be reinstalled by host_prep.sh."
else
  docker --version
  docker compose version || true
fi

echo "✅ Reset complete. The server is now ready for a full re-run of the README."
echo "Next steps:"
echo "  1. Run host_prep.sh from the Traefik-Deployment repo to reinstall dependencies."
echo "  2. Follow the README from Step 0 onward."