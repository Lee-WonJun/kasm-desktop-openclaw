#!/usr/bin/env bash
set -uo pipefail

export HOME=/home/kasm-user
STATE_DIR="${HOME}/.openclaw"

mkdir -p "${STATE_DIR}" "${HOME}/openclaw-workspace"

# Gateway token via state .env (auto-read by all openclaw commands)
if [ ! -f "${STATE_DIR}/.env" ]; then
  cat > "${STATE_DIR}/.env" <<EOF
OPENCLAW_GATEWAY_TOKEN=${OPENCLAW_GATEWAY_TOKEN:?required}
EOF
fi

# Desktop shortcut
mkdir -p "${HOME}/Desktop"
cat > "${HOME}/Desktop/OpenClaw.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=OpenClaw Control UI
Exec=google-chrome --no-sandbox --user-data-dir=${HOME}/.openclaw-ui-profile http://localhost:18789/#token=${OPENCLAW_GATEWAY_TOKEN}
Icon=utilities-terminal
Terminal=false
EOF
chmod +x "${HOME}/Desktop/OpenClaw.desktop"

BIND_MODE="${OPENCLAW_BIND:-loopback}"

if [ "$BIND_MODE" = "lan" ]; then
  # lan mode: need separate state dir for node (role conflict) + scope upgrade
  NODE_STATE_DIR="${HOME}/.openclaw-node"
  mkdir -p "${NODE_STATE_DIR}"
  cp "${STATE_DIR}/.env" "${NODE_STATE_DIR}/.env"
  cp "${STATE_DIR}/openclaw.json" "${NODE_STATE_DIR}/openclaw.json"

  # Clean identity on first run so it pairs fresh as operator
  if [ ! -f "${STATE_DIR}/identity/device-auth.json" ]; then
    rm -rf "${STATE_DIR}/identity" 2>/dev/null
    FIRST_RUN=1
  else
    FIRST_RUN=0
  fi

  openclaw gateway --bind lan --port 18789 --allow-unconfigured &

  for i in $(seq 1 30); do
    curl -sf http://localhost:18789/ >/dev/null 2>&1 && break
    sleep 1
  done

  if [ "$FIRST_RUN" = "1" ]; then
    openclaw devices list >/dev/null 2>&1 || true
    sleep 2
    # Upgrade scope in paired.json if auto-approve only gave operator.read
    python3 -c "
import json, os
paired_file = os.path.expanduser('~/.openclaw/devices/paired.json')
if not os.path.exists(paired_file):
    exit(0)
with open(paired_file) as f:
    data = json.load(f)
full_scopes = ['operator.admin', 'operator.approvals', 'operator.pairing']
changed = False
for dev in data.values():
    if dev.get('role') == 'operator' and dev.get('clientId') in ('cli', 'gateway-client'):
        if set(dev.get('scopes', [])) != set(full_scopes):
            dev['scopes'] = full_scopes
            for t in dev.get('tokens', {}).values():
                if t.get('role') == 'operator':
                    t['scopes'] = full_scopes
            changed = True
if changed:
    with open(paired_file, 'w') as f:
        json.dump(data, f, indent=2)
    print('Upgraded operator scopes to full admin')
" 2>/dev/null
  fi

  export OPENCLAW_STATE_DIR="${NODE_STATE_DIR}"
else
  # loopback mode: separate state dir for node (same role conflict as lan)
  NODE_STATE_DIR="${HOME}/.openclaw-node"
  mkdir -p "${NODE_STATE_DIR}"
  cp "${STATE_DIR}/.env" "${NODE_STATE_DIR}/.env"
  cp "${STATE_DIR}/openclaw.json" "${NODE_STATE_DIR}/openclaw.json"

  openclaw gateway --port 18789 --allow-unconfigured &

  for i in $(seq 1 30); do
    curl -sf http://localhost:18789/ >/dev/null 2>&1 && break
    sleep 1
  done

  export OPENCLAW_STATE_DIR="${NODE_STATE_DIR}"
fi

while true; do
  openclaw node run --host 127.0.0.1 --port 18789 --display-name "Local Node" || true
  sleep 5
done
