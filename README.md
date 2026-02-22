# kasm-desktop-openclaw

Single-container setup running [OpenClaw](https://openclaw.ai) Gateway + Node Host inside [Kasm Desktop](https://kasmweb.com), providing a browser-accessible virtual desktop where an AI agent can control the environment — execute commands, browse the web, and manage files.

> **For production use**, the recommended setup is OpenClaw on a dedicated device with a proper desktop environment. This project is for specific use cases where a containerized GUI environment is useful.

## When to Use This

- **Sandboxed environment** — Run the agent in an isolated container so it can't touch your host system. Useful for testing untrusted prompts or experimenting freely.
- **Pre-configured browser sessions** — Log into websites (GitHub, Gmail, etc.) inside the managed Chromium profile ahead of time, so the agent can interact with authenticated pages without exposing your real browser sessions.
- **Non-headless browser verification** — See exactly what the agent sees in a real browser GUI, instead of trusting headless screenshots. Debug visual issues, watch the agent navigate in real time via VNC.
- **Zero-config for light users** — No terminal, no CLI setup, no config files to edit on your machine. Just `docker compose up` and open a browser. Everything is accessible through the Kasm Desktop GUI.
- **MCP servers that need a display** — Some MCP servers or tools expect a GUI environment to function.
- **Reproducible demos** — Spin up a clean, identical environment every time. Useful for demos, workshops, or CI pipelines that need a GUI.

## Architecture

Everything runs in one container based on `kasmweb/desktop:1.18.0`:

For example:
```
┌─────────────────────────────────────────────┐
│  Docker Container                           │
│                                             │
│  Kasm Desktop (:6901)                       │
│  ├── OpenClaw Gateway (:18789)              │
│  ├── OpenClaw Node Host                     │
│  └── Managed Chromium (:18800)              │
└─────────────────────────────────────────────┘
```

## Quick Start

```bash
cp .env.example .env
# Edit .env — set OPENCLAW_GATEWAY_TOKEN

cp openclaw.json.example openclaw.json
# Edit openclaw.json — set API keys, model, and other OpenClaw options

docker compose up -d --build
```

Access:
- **Kasm Desktop**: https://localhost:6901 (user: `kasm_user`, password: value of `VNC_PW`)
- **Control UI**: http://localhost:18789/#token=YOUR_TOKEN

## Configuration

### `.env` (Docker-level)

| Variable | Description | Default |
|---|---|---|
| `OPENCLAW_GATEWAY_TOKEN` | Auth token for gateway API | (required) |
| `VNC_PW` | Kasm Desktop VNC password | `password` |

### `openclaw.json` (Agent config)

OpenClaw configuration is managed via `openclaw.json` in the project root, which is mounted into the container. Edit this file directly on the host — changes take effect on container restart.

See the [OpenClaw Configuration Reference](https://molty.finna.ai/docs/gateway/configuration-reference) for all available options

## Usage

1. Open Kasm Desktop at `https://localhost:6901` (user: `kasm_user`, password: value of `VNC_PW`)
2. Double-click the **OpenClaw Control UI** shortcut on the desktop
3. Go to the **Chat** tab and talk to the agent
4. The agent can browse the web, run commands, and manage files inside the container

## Limitations

- **No Docker-in-Docker** — The container itself is a Docker image, so running Docker inside it is not straightforward. Tools or MCP servers that require spawning containers won't work here.
- **Not a replacement for a real device** — For more advanced setups (e.g. attaching a Kasm Desktop as a GUI node to a separate OpenClaw gateway with volumes), you're better off running OpenClaw on a dedicated machine.
- **Container-specific limitations** — Since this runs in a Docker container rather than a VM or bare metal, unexpected issues may arise due to containerization constraints and environment differences.

## File Structure

```
.
├── .env.example          # Template
├── openclaw.json.example # Template
├── docker-compose.yml
└── kasm/
    ├── custom_startup.sh
    └── dockerfile-kasm-desktop-openclaw
```

## License

This project itself has no specific license. It is a combination of [Kasm Desktop](https://kasmweb.com) and [OpenClaw](https://openclaw.ai) images/files. Each component is subject to its own respective license and terms of use. Please refer to the official documentation and license agreements for Kasm and OpenClaw.

## Disclaimer

This project is provided as-is for experimental and development purposes. The authors are not responsible for any issues, data loss, or unexpected behavior that may occur when running this containerized setup. Users assume full responsibility for their use of this project.
