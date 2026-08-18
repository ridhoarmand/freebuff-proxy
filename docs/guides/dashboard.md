# Dashboard Guide

The embedded admin web UI gives you live relay state, per-token quotas, a Configuration Studio with presets and quick knobs, request tracing, live logs, and metrics, in the same single binary. Built with **Svelte 5 + Tailwind CSS v4** and self-hosted **Geist** typography, it is compiled into the binary at build time (`//go:embed all:dist`) with zero runtime Node.js or external CDN dependencies.

## Access

Open `http://127.0.0.1:3457/admin` (your `LISTEN_ADDR`). You land on the login page unless `ADMIN_TOKEN` is unset.

| Setting | Behavior |
|---|---|
| `ADMIN_TOKEN` set | Login required: `ADMIN_TOKEN` is both the bearer token for `/admin/reload` and the login password. Enter it on the login page; a signed `HttpOnly` + `SameSite=Strict` cookie unlocks the dashboard for 24h (`Secure` is added only when the login arrived over TLS or `X-Forwarded-Proto: https`). Failed logins are rate-limited per IP (5 fails → 1 minute lockout). |
| `ADMIN_TOKEN` unset | Dashboard is open (legacy behavior, matching `/admin/reload`); a startup warning notes the token is unset, and the in-page badge reminds you to set it when the proxy is reachable beyond loopback. The **sensitive routes additionally require authentication when configured**, protecting secrets, token mutations, and runtime reconfiguration. |

The session cookie is stateless (HMAC-signed expiry, per-process random key): restarting the proxy signs everyone out, which is the safe default.

## Pages & Capabilities

- **Overview**: Live status header with active mode (`Pooled`, `Hybrid`, `Bridge`), registered model count, process uptime, and safe mode status badge. Features a 1-click **End-to-End Smoke Test** (sends a real request through the proxy and renders timing breakdown and preview) alongside live token cards detailing session status, risk scores, daily messages vs `MAX_MESSAGES_PER_DAY`, queue position, and transient retries.
- **Tokens & Quotas**: Comprehensive token pool management featuring:
  - **Always-Visible 3-Mode Controller**: Toggle seamlessly between `Pooled`, `Hybrid`, and `Bridge` modes.
  - **Per-Model Quotas Table**: Displays live limits, recent usage, period reset times, and entitlements with color-coded usage bars.
  - **Runtime Token Actions**: Add Token to Pool form (`cb_...`), **Test** (zero-cost upstream validity probe), **Unlock** (clears cooldown/locks), **Finish runs**, **Remove last token**, and **Test all tokens**.
  - All token additions and mode switches are automatically persisted to `.env` without requiring a server restart.
- **Models Registry**: Live catalog of all available models, upstream agent mappings, default model badges (for `deepseek/deepseek-v4-flash`), and configured `MODEL_ALIASES`. Model IDs and aliases include 1-click copy actions.
- **Live Traces**: In-memory ring buffer (last 200 requests) showing timestamp, chosen token, requested model, status (`ok`, `rate_limited`, `banned`, `upstream`), latency, and error breakdown. Refreshes every 3s.
- **Model Playground**: Interactive prompt console with real-time **Server-Sent Events (SSE) chat streaming**, model picker, shortcut support (`Ctrl+Enter`), and collapsible thinking/reasoning blocks.
- **Configuration Studio**: Visual hot-reloading `.env` management studio:
  - **One-Click Presets**: *🛡️ Stealth Anti-Ban*, *⚡ Maximum Speed (0 Jitter)*, *🐞 Deep Debugging*, *🔄 Hybrid Relay*.
  - **Interactive Quick Knobs**: 1-click boolean switches (`SAFE_MODE`, `HYBRID_MODE`, `DEBUG_DUMP`), enum pills (`COST_MODE`, `TLS_FINGERPRINT`, `LOG_LEVEL`), and duration chips (`REQUEST_JITTER`, `ROTATION_INTERVAL`, `REQUEST_TIMEOUT`) that synchronize with the `.env` editor in real-time.
  - **Hover & Click Quick Info Cards**: Explains every parameter, category, and default fallback value.
  - **Atomic Validation**: Saves are validated against strict schema rules with automatic rollback on error.
- **Client Setup & Tool Integration**:
  - **Universal Configuration**: Clickable 1-click copy tiles for Base URL, API Key, and Default Model.
  - **Tool-Specific Snippets**: Ready-to-use configuration blocks for **OpenCode**, **Continue / Cline**, **aider**, **9router**, and **cURL**.
  - **OAuth Login Wizard**: Headless token generator (`POST /admin/login/start` → poll `GET /admin/login/status`) with browser auth URL.
  - **Diagnostics Suite**: One-click system diagnostic check covering configuration, port availability, DNS, TLS, and token health.
- **In-Memory Logs**: Live circular buffer (last 200 records) mirroring the structured process logger with level filtering (`ALL`, `INFO`, `DEBUG`, `WARN`, `ERROR`), real-time search, and key-value field tags.
- **Telemetry & Metrics**: Stat cards with SVG trend sparklines for Requests Served, Transient Retries, and Fingerprint Rotations, plus direct link to Prometheus `/metrics`.

## Docker Usage

The config editor writes `./.env` **relative to the proxy's working directory**. Inside Docker, ensure your `.env` is bind-mounted if you want mutations from the dashboard to persist across container restarts.

```yaml
services:
  freebuff-proxy:
    image: ghcr.io/trefeon/freebuff-proxy:latest
    ports:
      - "3457:3457"
    volumes:
      - ./.env:/app/.env
```

## Hardening Recommendations

1. **Set `ADMIN_TOKEN`**: Provide a strong secret token to require password authentication for the web dashboard.
2. Keep `LISTEN_ADDR` on `127.0.0.1:3457` (loopback) unless deliberately exposing the proxy behind a reverse proxy with TLS termination.
3. Secret masking: The dashboard masks sensitive values (`AUTH_TOKENS`, `API_KEYS`, `ADMIN_TOKEN`) in the Effective Configuration table.

---
Related: [README](../../README.md), [Getting Started](getting-started.md), [Client Integration](client-integration.md), [9router Integration](9router-integration.md).
