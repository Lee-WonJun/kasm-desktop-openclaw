#!/usr/bin/env bash
set -uo pipefail

export HOME=/home/kasm-user
STATE_DIR="${HOME}/.openclaw"
NODE_STATE_DIR="${HOME}/.openclaw-node"

mkdir -p "${STATE_DIR}" "${NODE_STATE_DIR}" "${HOME}/openclaw-workspace"

# Gateway token via state .env (auto-read by all openclaw commands)
if [ ! -f "${STATE_DIR}/.env" ]; then
  cat > "${STATE_DIR}/.env" <<EOF
OPENCLAW_GATEWAY_TOKEN=${OPENCLAW_GATEWAY_TOKEN:?required}
GROQ_API_KEY=${GROQ_API_KEY:-}
EOF
fi
cp "${STATE_DIR}/.env" "${NODE_STATE_DIR}/.env"

# Config (only on first run — volume persists it)
if [ ! -f "${STATE_DIR}/openclaw.json" ]; then
  cat > "${STATE_DIR}/openclaw.json" <<EOF
{
  "gateway": { "mode": "local" },
  "agents": {
    "defaults": {
      "model": { "primary": "${OPENCLAW_MODEL:-groq/meta-llama/llama-4-scout-17b-16e-instruct}" },
      "workspace": "/home/kasm-user/openclaw-workspace"
    }
  },
  "browser": { "enabled": true, "headless": false, "defaultProfile": "openclaw" }
}
EOF
fi
# Node needs same config (especially browser.defaultProfile)
cp "${STATE_DIR}/openclaw.json" "${NODE_STATE_DIR}/openclaw.json"

# Clean stale identity so main state dir pairs as operator (not node)
rm -rf "${STATE_DIR}/identity" "${STATE_DIR}/node.json" 2>/dev/null

# Desktop shortcut
mkdir -p "${HOME}/Desktop"
cat > "${HOME}/Desktop/OpenClaw.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=OpenClaw Control UI
Exec=xdg-open http://localhost:18789/#token=${OPENCLAW_GATEWAY_TOKEN}
Icon=utilities-terminal
Terminal=false
EOF
chmod +x "${HOME}/Desktop/OpenClaw.desktop"

# Gateway (background)
openclaw gateway --bind lan --port 18789 --allow-unconfigured &

for i in $(seq 1 30); do
  curl -sf http://localhost:18789/ >/dev/null 2>&1 && break
  sleep 1
done

# Node host in separate state dir (so main dir stays operator role)
export OPENCLAW_STATE_DIR="${NODE_STATE_DIR}"
while true; do
  openclaw node run --host 127.0.0.1 --port 18789 --display-name "Local Node" || true
  sleep 5
done
