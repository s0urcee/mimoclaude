#!/usr/bin/env bash
# mimoclaude — Use Claude Code with Xiaomi MiMo or other alternative backends
# Usage: mimoclaude [--backend mimo|or|fw|anthropic] [--remote] [--status] [--cost] [--benchmark]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Config ---
MIMO_URL="https://token-plan-sgp.xiaomimimo.com/anthropic"
OPENROUTER_URL="https://openrouter.ai/api"
FIREWORKS_URL="https://api.fireworks.ai/inference"

BACKEND="${MIMOCLAUDE_DEFAULT_BACKEND:-mimo}"
ACTION="launch"
SWITCH_BACKEND=""
PROXY_PID=""

# --- Parse args ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --backend|-b) BACKEND="$2"; shift 2 ;;
        --switch|-s)  ACTION="switch"; SWITCH_BACKEND="$2"; shift 2 ;;
        --remote|-r)  ACTION="remote"; shift ;;
        --status)     ACTION="status"; shift ;;
        --cost)       ACTION="cost"; shift ;;
        --benchmark)  ACTION="benchmark"; shift ;;
        --help|-h)    ACTION="help"; shift ;;
        *)            break ;;
    esac
done

cleanup_proxy() {
    if [[ -n "$PROXY_PID" ]] && kill -0 "$PROXY_PID" 2>/dev/null; then
        kill "$PROXY_PID" 2>/dev/null || true
        echo "  Proxy stopped."
    fi
}
trap cleanup_proxy EXIT

mask_key() {
    local k="$1"
    if [[ -z "$k" ]]; then echo "MISSING"; else echo "set (****${k: -4})"; fi
}

resolve_backend() {
    local url="" key="" opus="" sonnet="" haiku="" subagent=""
    case "$BACKEND" in
        mo|mimo)
            key="${MIMO_API_KEY:-}"
            [[ -z "$key" ]] && { echo "ERROR: MIMO_API_KEY not set" >&2; exit 1; }
            url="$MIMO_URL"
            opus="mimo-v2.5-pro"; sonnet="mimo-v2.5-pro"
            haiku="mimo-v2-flash"; subagent="mimo-v2-flash"
            ;;
        or|openrouter)
            key="${OPENROUTER_API_KEY:-}"
            [[ -z "$key" ]] && { echo "ERROR: OPENROUTER_API_KEY not set" >&2; exit 1; }
            url="$OPENROUTER_URL"
            opus="deepseek/deepseek-v4-pro"; sonnet="deepseek/deepseek-v4-pro"
            haiku="deepseek/deepseek-v4-pro"; subagent="deepseek/deepseek-v4-pro"
            ;;
        fw|fireworks)
            key="${FIREWORKS_API_KEY:-}"
            [[ -z "$key" ]] && { echo "ERROR: FIREWORKS_API_KEY not set" >&2; exit 1; }
            url="$FIREWORKS_URL"
            opus="accounts/fireworks/models/deepseek-v4-pro"
            sonnet="accounts/fireworks/models/deepseek-v4-pro"
            haiku="accounts/fireworks/models/deepseek-v4-pro"
            subagent="accounts/fireworks/models/deepseek-v4-pro"
            ;;
        anthropic) ;;
        *) echo "ERROR: Unknown backend '$BACKEND'. Use: mimo, or, fw, anthropic" >&2; exit 1 ;;
    esac
    RESOLVED_URL="$url"; RESOLVED_KEY="$key"
    RESOLVED_OPUS="$opus"; RESOLVED_SONNET="$sonnet"
    RESOLVED_HAIKU="$haiku"; RESOLVED_SUBAGENT="$subagent"
}

set_model_env() {
    export ANTHROPIC_DEFAULT_OPUS_MODEL="$RESOLVED_OPUS"
    export ANTHROPIC_DEFAULT_SONNET_MODEL="$RESOLVED_SONNET"
    export ANTHROPIC_DEFAULT_HAIKU_MODEL="$RESOLVED_HAIKU"
    export CLAUDE_CODE_SUBAGENT_MODEL="$RESOLVED_SUBAGENT"
    export CLAUDE_CODE_EFFORT_LEVEL="max"
}

show_status() {
    echo ""
    echo "  mimoclaude — Backend Status"
    echo "  ==========================="
    echo ""
    echo "  Keys:"
    echo "    MIMO_API_KEY:         $(mask_key "${MIMO_API_KEY:-}")"
    echo "    OPENROUTER_API_KEY:   $(mask_key "${OPENROUTER_API_KEY:-}")"
    echo "    FIREWORKS_API_KEY:    $(mask_key "${FIREWORKS_API_KEY:-}")"
    echo ""
    echo "  Backends:"
    echo "    mimoclaude                   # MiMo V2.5 Pro (default)"
    echo "    mimoclaude -b or             # OpenRouter"
    echo "    mimoclaude -b fw             # Fireworks AI (fastest)"
    echo "    mimoclaude -b anthropic      # Normal Claude Code"
    echo "    mimoclaude --remote           # Remote control + MiMo"
    echo "    mimoclaude --remote -b or     # Remote control + OpenRouter"
    echo ""
    local proxy_status
    proxy_status=$(curl -s http://127.0.0.1:3200/_proxy/status 2>/dev/null) || proxy_status=""
    if [[ -n "$proxy_status" ]]; then
        echo "  Proxy: running"
        echo "    $proxy_status"
    else
        echo "  Proxy: not running"
    fi
    echo ""
}

show_cost() {
    echo ""
    echo "  MiMo V2.5 Pricing (99% price cut May 2026)"
    echo "  =========================================="
    echo ""
    echo "  Provider        Input/M    Output/M   Cache Hit/M"
    echo "  ----------      --------   --------   -----------"
    echo "  MiMo V2.5       \$0.14      \$0.28      (provider)"
    echo "  MiMo V2.5 Pro   \$0.435     \$0.87      (provider)"
    echo "  OpenRouter      \$0.44      \$0.87      (provider)"
    echo "  Fireworks       \$1.74      \$3.48      (provider)"
    echo "  Anthropic       \$3.00      \$15.00     \$0.30"
    echo ""
    echo "  Monthly estimate (heavy use, 25 days): \$15-50"
    echo ""
}

show_help() {
    echo "mimoclaude — Claude Code with MiMo and alternative backends"
    echo ""
    echo "Usage: mimoclaude [options] [-- claude-args...]"
    echo ""
    echo "Options:"
    echo "  -b, --backend <mimo|or|fw|anthropic>  Backend (default: mimo)"
    echo "  -r, --remote                           Remote control mode (browser URL)"
    echo "  --status                                Show keys and backends"
    echo "  --cost                                  Pricing comparison"
    echo "  --benchmark                             Latency test"
    echo "  -s, --switch <backend>                  Switch proxy mid-session"
    echo "  -h, --help                              This help"
    echo ""
    echo "Environment variables:"
    echo "  MIMO_API_KEY           MiMo API key (required for default)"
    echo "  OPENROUTER_API_KEY     OpenRouter API key (required for or)"
    echo "  FIREWORKS_API_KEY      Fireworks API key (required for fw)"
    echo "  MIMOCLAUDE_DEFAULT_BACKEND  Default backend (default: mimo)"
}

do_switch() {
    local backend="$SWITCH_BACKEND"
    case "$backend" in
        mo|mimo)       backend="mimo" ;;
        or|openrouter) backend="openrouter" ;;
        fw|fireworks)  backend="fireworks" ;;
        anthropic)     backend="anthropic" ;;
        *) echo "ERROR: Unknown backend '$backend'. Use: mimo, or, fw, anthropic" >&2; exit 1 ;;
    esac
    local resp
    resp=$(curl -sX POST http://127.0.0.1:3200/_proxy/mode -d "backend=$backend" 2>/dev/null) || {
        echo "  Proxy not running. Start with: mimoclaude" >&2; exit 1
    }
    echo "  $resp"
}

run_benchmark() {
    echo ""
    echo "  Latency Benchmark (1 request each)"
    echo "  ==================================="
    for name in mimo openrouter fireworks; do
        local url="" key="" model="" use_bearer=""
        case "$name" in
            mimo)       url="$MIMO_URL"; key="${MIMO_API_KEY:-}"; model="mimo-v2.5-pro"; use_bearer="" ;;
            openrouter) url="$OPENROUTER_URL"; key="${OPENROUTER_API_KEY:-}"; model="deepseek/deepseek-v4-pro"; use_bearer="1" ;;
            fireworks)  url="$FIREWORKS_URL"; key="${FIREWORKS_API_KEY:-}"; model="accounts/fireworks/models/deepseek-v4-pro"; use_bearer="1" ;;
        esac
        if [[ -z "$key" ]]; then echo "  $name: SKIP (no key)"; continue; fi
        local start_ms=$(date +%s%3N 2>/dev/null || python3 -c 'import time;print(int(time.time()*1000))')
        local status
        if [[ -n "$use_bearer" ]]; then
            status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$url/v1/messages" \
                -H "authorization: Bearer $key" -H "content-type: application/json" -H "anthropic-version: 2023-06-01" \
                -d "{\"model\":\"$model\",\"max_tokens\":32,\"messages\":[{\"role\":\"user\",\"content\":\"Reply: ok\"}]}" \
                --max-time 30 2>/dev/null || echo "timeout")
        else
            status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$url/v1/messages" \
                -H "x-api-key: $key" -H "content-type: application/json" -H "anthropic-version: 2023-06-01" \
                -d "{\"model\":\"$model\",\"max_tokens\":32,\"messages\":[{\"role\":\"user\",\"content\":\"Reply: ok\"}]}" \
                --max-time 30 2>/dev/null || echo "timeout")
        fi
        local end_ms=$(date +%s%3N 2>/dev/null || python3 -c 'import time;print(int(time.time()*1000))')
        local elapsed=$((end_ms - start_ms))
        if [[ "$status" == "200" ]]; then
            echo "  $name: OK (${elapsed}ms)"
        else
            echo "  $name: FAIL ($status, ${elapsed}ms)"
        fi
    done
    echo ""
}

launch_claude() {
    if [[ "$BACKEND" == "anthropic" ]]; then
        echo "  Launching Claude Code (normal Anthropic backend)..."
        unset ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN
        unset ANTHROPIC_DEFAULT_OPUS_MODEL ANTHROPIC_DEFAULT_SONNET_MODEL
        unset ANTHROPIC_DEFAULT_HAIKU_MODEL CLAUDE_CODE_SUBAGENT_MODEL
        unset CLAUDE_CODE_EFFORT_LEVEL
        exec claude "$@"
    fi

    resolve_backend

    echo "  Launching Claude Code via $BACKEND..."
    echo "  Endpoint: $RESOLVED_URL"
    echo "  Model: $RESOLVED_OPUS (main) + $RESOLVED_HAIKU (subagents)"
    echo ""

    export ANTHROPIC_BASE_URL="$RESOLVED_URL"
    export ANTHROPIC_AUTH_TOKEN="$RESOLVED_KEY"
    set_model_env
    unset ANTHROPIC_API_KEY

    exec claude "$@"
}

launch_remote() {
    if [[ "$BACKEND" == "anthropic" ]]; then
        echo "  Launching remote control (Anthropic)..."
        unset ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN
        unset ANTHROPIC_DEFAULT_OPUS_MODEL ANTHROPIC_DEFAULT_SONNET_MODEL
        unset ANTHROPIC_DEFAULT_HAIKU_MODEL CLAUDE_CODE_SUBAGENT_MODEL
        unset CLAUDE_CODE_EFFORT_LEVEL ANTHROPIC_API_KEY
        exec claude remote-control "$@"
    fi

    resolve_backend

    echo "  Starting model proxy for $BACKEND..."

    local port_file
    port_file=$(mktemp)
    node "$SCRIPT_DIR/proxy/start-proxy.js" "$RESOLVED_URL" "$RESOLVED_KEY" > "$port_file" &
    PROXY_PID=$!

    local tries=0
    while [[ ! -s "$port_file" ]] && [[ $tries -lt 30 ]]; do
        sleep 0.2
        tries=$((tries + 1))
    done

    if [[ ! -s "$port_file" ]]; then
        echo "ERROR: Proxy failed to start" >&2
        rm -f "$port_file"
        exit 1
    fi

    local proxy_port
    proxy_port=$(head -1 "$port_file")
    rm -f "$port_file"

    echo "  Proxy on :$proxy_port -> $RESOLVED_URL"
    echo "  Launching remote control via $BACKEND..."
    echo ""

    export ANTHROPIC_BASE_URL="http://127.0.0.1:$proxy_port"
    set_model_env
    unset ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN

    claude remote-control "$@"
}

# --- Main ---
case "$ACTION" in
    status)    show_status ;;
    cost)      show_cost ;;
    benchmark) run_benchmark ;;
    help)      show_help ;;
    switch)    do_switch ;;
    remote)    launch_remote "$@" ;;
    launch)    launch_claude "$@" ;;
esac
