# mimoclaude

Use Claude Code's autonomous agent loop with **Xiaomi MiMo**, **OpenRouter**, or any Anthropic-compatible backend. Same UX, fraction of the cost.

## What this does

Claude Code is the best autonomous coding agent — but it costs $200/month with usage caps. **MiMo V2.5 Pro** (1T params, 1M context) costs $0.87/M output tokens and scores competitively on benchmarks.

**mimoclaude** swaps the brain while keeping the body:

```
Your terminal
  +-- Claude Code CLI (tool loop, file editing, bash, git - unchanged)
        +-- API calls -> MiMo V2.5 Pro ($0.87/M) instead of Anthropic ($15/M)
```

Everything works: file reading, editing, bash execution, subagent spawning, autonomous multi-step coding loops.

## Quick start

### 1. Get a MiMo API key

Sign up at [platform.xiaomimimo.com](https://platform.xiaomimimo.com), copy your API key.

### 2. Set environment variable

**Windows (PowerShell):**
```powershell
setx MIMO_API_KEY "sk-your-key-here"
```

**macOS/Linux:**
```bash
echo 'export MIMO_API_KEY="sk-your-key-here"' >> ~/.bashrc
source ~/.bashrc
```

### 3. Install

**macOS/Linux:**
```bash
chmod +x mimoclaude.sh
sudo ln -s "$(pwd)/mimoclaude.sh" /usr/local/bin/mimoclaude
```

**Windows:**
```powershell
Copy-Item mimoclaude.ps1 "$env:USERPROFILE\.local\bin\mimoclaude.ps1"
```

### 4. Use it

```bash
mimoclaude                   # Launch Claude Code with MiMo V2.5 Pro
mimoclaude --status          # Show available backends and keys
mimoclaude --backend or      # Use OpenRouter
mimoclaude --backend fw      # Use Fireworks AI (fastest)
mimoclaude --backend anthropic  # Normal Claude Code (when you need Opus)
mimoclaude --cost            # Show pricing comparison
mimoclaude --benchmark       # Latency test across all providers
```

## How it works

Claude Code reads these environment variables to determine where to send API calls:

| Variable | What it does |
|---|---|
| `ANTHROPIC_BASE_URL` | API endpoint (default: api.anthropic.com) |
| `ANTHROPIC_AUTH_TOKEN` | API key for the backend |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | Model name for Opus-tier tasks |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | Model name for Sonnet-tier tasks |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | Model name for Haiku-tier (subagents) |
| `CLAUDE_CODE_SUBAGENT_MODEL` | Model for spawned subagents |

**mimoclaude** sets these per-session (not permanently), launches Claude Code, then restores your original settings on exit.

## Supported backends

| Backend | Flag | Input/M | Output/M | Notes |
|---|---|---|---|---|
| **MiMo** (default) | `--backend mimo` | $0.435 | $0.87 | 1T params, 1M context, SG endpoint |
| **OpenRouter** | `--backend or` | $0.44 | $0.87 | Cheapest, lowest latency from US/EU |
| **Fireworks AI** | `--backend fw` | $1.74 | $3.48 | Fastest inference |
| **Anthropic** | `--backend anthropic` | $3.00 | $15.00 | Original Claude Opus (for hard problems) |

### Setup per backend

**MiMo** (default - just needs `MIMO_API_KEY`):
```bash
export MIMO_API_KEY="sk-..."     # macOS/Linux
setx MIMO_API_KEY "sk-..."       # Windows
```

**OpenRouter** (optional):
```bash
export OPENROUTER_API_KEY="sk-or-..."
```

**Fireworks AI** (optional):
```bash
export FIREWORKS_API_KEY="fw_..."
```

## Cost comparison

| Usage level | Anthropic Max | mimoclaude (MiMo) | Savings |
|---|---|---|---|
| Light (10 days/mo) | $200/mo (capped) | ~$15/mo | 92% |
| Heavy (25 days/mo) | $200/mo (capped) | ~$40/mo | 80% |
| With auto loops | $200/mo (capped) | ~$60/mo | 70% |

MiMo V2.5 Flash is even cheaper at $0.14/M input / $0.28/M output for subagent work.

## Live switching (no restart)

Switch between backends **mid-session** from inside Claude Code itself.

### Slash commands (recommended)

Add these files to `~/.claude/commands/`:

**`mimo.md`:**
```
Switch the model proxy to MiMo. Run this command silently and report the result:
curl -sX POST http://127.0.0.1:3200/_proxy/mode -d "backend=mimo"
If successful, say: "Switched to MiMo."
```

**`anthropic.md`:**
```
Switch the model proxy back to Anthropic. Run this command silently and report the result:
curl -sX POST http://127.0.0.1:3200/_proxy/mode -d "backend=anthropic"
If successful, say: "Switched to Anthropic."
```

Then type `/mimo` or `/anthropic` in any Claude Code session to switch instantly.

### Cost tracking

The proxy tracks token usage and calculates savings vs Anthropic pricing:

```bash
curl -s http://127.0.0.1:3200/_proxy/cost
```

## Remote control (`--remote`)

Open a Claude Code session in any browser with MiMo as the brain:

```bash
mimoclaude --remote                # Remote control + MiMo
mimoclaude --remote -b or          # Remote control + OpenRouter
mimoclaude --remote -b anthropic   # Remote control + Anthropic
```

## License

MIT — forked from [deepclaude](https://github.com/aattaran/deepclaude)
