#!/usr/bin/env bash
set -euo pipefail
# Usage (run anywhere on the host):
#   sudo SITE_REPO="https://github.com/joshphillipssr/joshphillipssr.com.git" \
#        SITE_DIR="/opt/joshphillipssr.com" \
#        ./bootstrap_site_on_host.sh

: "${SITE_REPO:?SITE_REPO required}"
SITE_DIR="${SITE_DIR:-/opt/joshphillipssr.com}"

if [[ $EUID -ne 0 ]]; then
  # If we're running from a real file, re-exec that file with sudo.
  if [[ -n "${BASH_SOURCE[0]:-}" && -r "${BASH_SOURCE[0]}" && "${BASH_SOURCE[0]}" != "bash" ]]; then
    echo "Re-exec with sudo..."
    exec sudo --preserve-env=SITE_REPO,SITE_DIR "${BASH_SOURCE[0]}" "$@"
  else
    # We're running via 'bash -c' (e.g., curl ... | bash or bash -c \"$(curl ...)\").
    # In this mode, there is no script file path to re-exec. Ask the user to invoke with sudo upfront.
    cat >&2 <<'EOF'
This bootstrap script needs root privileges but was invoked without sudo in a mode
where it cannot re-exec itself (e.g., via `bash -c` or piped stdin).

Please run it like this:

  sudo SITE_REPO="https://github.com/joshphillipssr/joshphillipssr.com.git" \
       SITE_DIR="/opt/joshphillipssr.com" \
       bash -c "$(curl -fsSL https://raw.githubusercontent.com/joshphillipssr/joshphillipssr.com/main/scripts/bootstrap_site_on_host.sh)"
EOF
    exit 1
  fi
fi

if [[ -d "$SITE_DIR/.git" ]]; then
  echo "Updating site repo in $SITE_DIR"
  git -C "$SITE_DIR" fetch --all --prune
  git -C "$SITE_DIR" switch -q main || true
  git -C "$SITE_DIR" pull --ff-only
else
  echo "Cloning site repo to $SITE_DIR"
  git clone "$SITE_REPO" "$SITE_DIR"
fi

chmod +x "$SITE_DIR/scripts/deploy_to_host.sh"
echo "Now deploy with:"
echo "  sudo CF_API_TOKEN='...' EMAIL='you@example.com' \\"
echo "       SITE_NAME='jpsr' SITE_HOSTS='joshphillipssr.com www.joshphillipssr.com' \\"
echo "       SITE_IMAGE='ghcr.io/joshphillipssr/jpsr-site:latest' \\"
echo "       $SITE_DIR/scripts/deploy_to_host.sh"