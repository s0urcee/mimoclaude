# Model Proxy for Remote Control

When using `claude remote-control`, the bridge authentication must go to Anthropic while model API calls go to MiMo. This proxy handles the split.

## How it works

```
claude remote-control
  ├── Bridge WebSocket → wss://bridge.claudeusercontent.com (Anthropic, hardcoded)
  └── Model API calls  → http://localhost:3200 (this proxy)
                            ├── /v1/messages → token-plan-sgp.xiaomimimo.com (MiMo API key)
                            ├── /_proxy/mode  → switch backend live (POST)
                            ├── /_proxy/status → backend info (GET)
                            ├── /_proxy/cost  → token usage + savings (GET)
                            └── everything else → api.anthropic.com (passthrough)
```

## Usage

```javascript
import { startModelProxy } from './model-proxy.js';

const proxy = await startModelProxy({
    targetUrl: 'https://token-plan-sgp.xiaomimimo.com/anthropic',
    apiKey: process.env.MIMO_API_KEY,
});

console.log(`Proxy on port ${proxy.port}`);

// Set env vars for claude remote-control:
// ANTHROPIC_BASE_URL=http://127.0.0.1:${proxy.port}
// ANTHROPIC_DEFAULT_OPUS_MODEL=mimo-v2.5-pro
// (do NOT set ANTHROPIC_AUTH_TOKEN — OAuth handles bridge auth)

// When done:
proxy.close();
```

## Model remap

The proxy automatically remaps Anthropic model names to MiMo:

| Claude Code sends | Proxy remaps to |
|---|---|
| `claude-opus-4-7` | `mimo-v2.5-pro` |
| `claude-sonnet-4-6` | `mimo-v2.5-pro` |
| `claude-haiku-4-5-20251001` | `mimo-v2-flash` |

## Why a proxy?

Claude Code's remote control uses two separate channels:
1. **Bridge** (WebSocket to `wss://bridge.claudeusercontent.com`) — hardcoded, needs Anthropic OAuth
2. **Model API** (HTTP to `ANTHROPIC_BASE_URL`) — configurable

Setting `ANTHROPIC_AUTH_TOKEN` to a MiMo key breaks the bridge. The proxy lets you keep Anthropic OAuth for the bridge while routing model calls to MiMo.
