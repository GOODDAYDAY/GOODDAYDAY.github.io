+++
date = '2026-03-10T23:00:00+08:00'
draft = false
title = '[Project] 2. Synapulse — A Self-Hosted Personal AI Assistant'
categories = ["Project"]
tags = ["AI Assistant", "Discord Bot", "LLM", "MCP", "Python"]
+++

<div align="center">
<img src="/images/Project%20-%202%20-%20Synapulse/synapulse-logo.jpeg" alt="Synapulse" width="128">
</div>

## Overview

Synapulse (Synapse + Pulse) is a self-hosted personal AI assistant that lives in your Discord server. The idea came from [OpenClaw](https://github.com/nicepkg/openclaw) — after seeing what it could do, I decided to build the personal assistant I had always wanted, one that is lightweight, transparent, and fully under my control.

- GitHub: [GOODDAYDAY/Synapulse](https://github.com/GOODDAYDAY/Synapulse)

## Demo

|                             Weather query                             |                     Web search + recommendation                      |
|:---------------------------------------------------------------------:|:--------------------------------------------------------------------:|
| ![Weather](/images/Project%20-%202%20-%20Synapulse/1.%20what%20is%20the%20weather%20today.gif) | ![Keyboard](/images/Project%20-%202%20-%20Synapulse/2.%20recommend%20me%20one%20keyboard.gif) |

|                                Reminder (notify mode)                                 |                           Reminder (prompt mode)                            |
|:-------------------------------------------------------------------------------------:|:---------------------------------------------------------------------------:|
| ![Notify](/images/Project%20-%202%20-%20Synapulse/3.%20notify%20me%20drink%20water%20after%201%20minutes..gif) | ![Prompt](/images/Project%20-%202%20-%20Synapulse/4.%20notify%20me%20news%20after%201%20minutes.gif) |

|                                            File creation + send                                             |
|:-----------------------------------------------------------------------------------------------------------:|
| ![File](/images/Project%20-%202%20-%20Synapulse/5.%20create%20a%20file%20contains%20news%20about%20irar%20and%20send%20to%20me..gif) |

## Features

| Feature | Description |
|---------|-------------|
| **AI Chat** | @mention the bot in Discord to chat, supports multiple AI providers |
| **Tool Calling** | Multi-round AI tool-call loop (up to 10 rounds), tools auto-discovered at startup, with token compression |
| **Shell Execution** | AI proactively uses shell commands for system queries, calculations, git operations. Cross-platform: PowerShell on Windows, bash on Linux/macOS |
| **Persistent Memory** | Conversations saved and auto-summarized, cross-session memory |
| **Task Management** | To-dos with priorities and due dates, AI sees pending tasks proactively |
| **Memo / Notes** | Save and search personal notes via natural language |
| **Reminders** | Set reminders with relative time (`+5m`, `+1h`) or absolute time. Two modes: **notify** for passive nudges, **prompt** for scheduled AI actions (e.g. "tell me the weather in 1 hour") |
| **File Operations** | Read, write, search, and manage local files within allowed paths |
| **Email Monitoring** | Background jobs watch Gmail, Outlook, QQ Mail via IMAP, push summaries to Discord |
| **MCP Integration** | Connect to 55+ pre-configured MCP servers (GitHub, Notion, filesystem, databases), on-demand loading to save tokens |
| **Model Rotation** | Multi-endpoint YAML config with tag-based routing, priority, and automatic rate-limit fallback |
| **File & Shell** | Read/write local files, execute shell commands with safety blacklist and timeout |
| **Notification Interaction** | Reply to any bot message and the AI sees the original content as context |
| **Hot-Reload Config** | Edit job schedules, prompts, MCP servers, model endpoints at runtime without restart |

## Architecture

### Tech Stack

| Component | Technology |
|-----------|-----------|
| **Language** | Python 3.11+ |
| **Channel** | Discord (discord.py) |
| **AI Providers** | OpenAI-compatible (GitHub Models, Ollama, custom endpoints) |
| **Storage** | JSON file-based (one file per data type) |
| **Tool Extension** | MCP (Model Context Protocol) + native auto-discovery |
| **Background Jobs** | Async cron jobs for email monitoring, reminder checking |

### Project Structure

```
apps/bot/
├── main.py                    # Entry point
├── config/                    # Settings, prompts, logging
├── core/
│   ├── handler.py             # Bootstrap: wire all components via DI
│   ├── loader.py              # Auto-discover tools and jobs from folders
│   ├── mention.py             # Tool-call loop, memory load/save, summarization
│   └── reminder.py            # Background reminder checker
config/                          # Runtime config (models.yaml, mcp.json, jobs.json)
output/                          # Runtime output (logs, data)
├── provider/
│   ├── base.py                # OpenAIProvider, AnthropicProvider
│   ├── endpoint.py            # EndpointPool: rotation, rate-limit fallback
│   └── copilot/auth.py        # GitHub OAuth Device Flow
├── channel/
│   └── discord/client.py      # Discord bot integration
├── tool/                      # Native tools (auto-discovered)
│   ├── base.py                # BaseTool, OpenAITool, AnthropicTool
│   ├── brave_search/          # Web search
│   ├── local_files/           # Read/write local files (sandboxed)
│   ├── memo/                  # Notes management
│   ├── task/                  # Todo list
│   ├── reminder/              # Reminders
│   ├── weather/               # Weather via OpenWeatherMap
│   ├── shell_exec/            # Shell commands (with safety blacklist)
│   └── mcp_server/            # Manage MCP connections via chat
├── job/                       # Background jobs (auto-discovered)
│   ├── cron.py                # CronJob base with hot-reload
│   ├── gmail/                 # Gmail monitoring
│   ├── outlook/               # Outlook monitoring
│   └── qqmail/                # QQ Mail monitoring
├── mcp/
│   └── client.py              # MCPManager: spawn, discover, route
└── memory/
    └── database.py            # JSON file persistence
```

### Core Loop

The tool-call loop in `core/mention.py`:

1. **Load memory**: conversation history (last 20 turns) + summary from database
2. **Load tasks**: pending to-dos injected into system prompt
3. **Build prompts**: system prompt (tool hints + memory + tasks) + user prompt (stored history + channel history + referenced message + current message)
4. **Call AI**: send messages to provider
5. **Tool-call loop** (max 10 rounds):
   - If AI returns text → save turn to database, maybe summarize, return text
   - If AI requests tool calls:
     - Compress old tool results to save tokens
     - Validate arguments against JSON Schema
     - Execute tool (native or MCP)
     - Append result to messages
     - Sleep 1s (rate-limit protection)
     - Continue loop
6. If max rounds hit → return "got stuck in a loop" message

### Memory System

**Storage**: JSON files — `conversations.json`, `summaries.json`, `memos.json`, `reminders.json`, `tasks.json`

**Memory flow**:

| Phase | Action |
|-------|--------|
| **Before AI call** | Load last 20 turns + summary, cap history at 3000 chars |
| **System prompt** | Inject memory summary + pending tasks (cap 1000 chars) |
| **After AI reply** | Save user message + AI response + tool names used |
| **Auto-summarize** | When turns > 20: summarize old turns via LLM, keep recent 5 |

**Summarization**: cascading — new summary includes previous summary + new turns. Old turns deleted only after summarization succeeds.

### Tool System

Tools inherit from `BaseTool` with format mixins:

```python
class Tool(OpenAITool, AnthropicTool):
    name = "my_tool"
    description = "What it does"
    parameters = {...}  # JSON Schema
    usage_hint = "Short routing hint for system prompt"

    async def execute(self, **kwargs) -> str:
        return "result"
```

**Auto-discovery**: `core/loader.py` scans `tool/` directory for `handler.py` files, loads `Tool()` class, calls `validate()`.

**Dependency injection**: core injects `db` (Database), `send_file` callback, and `channel_id` into tools at startup or per-message.

**Format-agnostic**: each tool has `to_openai()` and `to_anthropic()` methods. Same tool works with both APIs.

**MCP tools**: `MCPManager` spawns MCP servers as subprocesses, discovers tools via MCP protocol, wraps them in `MCPToolWrapper` (duck-typed to match native tool interface). Hot-reload checks config every 30s.

### MCP On-Demand Loading

A key optimization: MCP tools are NOT loaded into the provider's tool list at startup. Instead:

1. At startup, only native tool schemas are sent to the AI (saves tokens)
2. MCP tool names are listed as hints in the system prompt
3. When the AI needs an MCP tool, it calls `mcp_server(action="use_tools", tools=[...])` to activate specific tools
4. Requested schemas are added to the provider's tool list on-demand for the current request only

This avoids sending 100+ MCP tool schemas on every API call, significantly reducing token usage.

### Model Rotation & Fallback

The `EndpointPool` manages multiple AI endpoints defined in `config/models.yaml`:

```yaml
models:
  - name: github-gpt4o
    protocol: openai
    base_url: https://models.inference.ai.azure.com
    api_key: ${GITHUB_TOKEN}
    model: gpt-4o
    tags: [large, coding]
    priority: 0
  - name: ollama-local
    protocol: openai
    base_url: http://localhost:11434
    model: llama3
    tags: [local]
    priority: 1
```

- **Tag-based routing**: request a specific capability (e.g., `large`, `coding`, `local`)
- **Round-robin rotation** within the same priority level
- **Rate-limit fallback**: on 429, mark endpoint as cooldown (respects `Retry-After` header), try next
- **Hot-reload**: config file changes detected every 30s, preserving cooldown state

### Shell Execution Safety

The `shell_exec` tool runs shell commands with multiple safety layers:

- **Dangerous command blacklist**: blocks `rm -rf /`, `mkfs`, `shutdown`, `sudo`, etc.
- **Configurable timeout**: 1–120 seconds per command
- **Output truncation**: results capped at 10,000 chars
- **Sandboxed working directory**: restricted to paths in `LOCAL_FILES_ALLOWED_PATHS`

## Comparison: OpenClaw vs Nanobot vs Synapulse

[OpenClaw](https://github.com/nicepkg/openclaw) is a mature, full-featured personal AI assistant. [Nanobot](https://github.com/HKUDS/nanobot) distills its core into "99% fewer lines of code". Synapulse is my attempt to learn from both and build a minimal personal assistant for my own use — it is far simpler and less capable than either, but the process of building it taught me a lot about how agent systems work under the hood. The comparison below is meant to document what I learned, not to suggest Synapulse is on the same level.

### Overview

| Aspect | OpenClaw | Nanobot | Synapulse |
|--------|----------|---------|-----------|
| **Language** | TypeScript | Python | Python |
| **Core Code** | ~400,000 lines | ~4,000 lines | ~2,000 lines |
| **Channels** | Multi-channel (Telegram, Discord, WhatsApp, etc.) | 10+ channels (Telegram, Discord, WhatsApp, Feishu, etc.) | Discord (channel layer is abstracted, more can be added) |
| **AI Providers** | Anthropic, OpenAI, Google, GitHub (via Pi SDK) | OpenRouter, Anthropic, OpenAI, DeepSeek, Ollama, etc. | OpenAI-compatible (GitHub Models, Ollama, custom) |
| **Deployment** | Multi-process, multi-agent | Single process, gateway mode | Single process |
| **MCP Support** | No (plugin system instead) | Yes, built-in | Yes, built-in + hot-reload |

### Agent Loop

The agent loop is the core mechanism that orchestrates LLM calls and tool execution.

| Aspect | OpenClaw | Nanobot | Synapulse |
|--------|----------|---------|-----------|
| **Loop owner** | Delegated to Pi agent SDK (closed-source) | Custom `AgentLoop` class | Custom `mention.py` handler |
| **Max rounds** | Controlled by Pi SDK | 40 | 10 |
| **Tool execution** | Streaming via Pi SDK subscription | Sequential, async | Sequential, async |
| **Error recovery** | Multi-layer: auth rotation → compaction → tool truncation → model fallback | Try/catch per tool | Try/catch per tool |
| **Rate-limit handling** | Auth profile rotation with cooldown | Provider retry | Endpoint pool rotation + 1s pause between rounds |

**OpenClaw**: the most sophisticated. The core delegates the agentic loop to a closed-source Pi SDK. It observes tool calls and results via subscription callbacks. On failure, it has a multi-layer recovery system — rotate auth profiles, auto-compact context on overflow (up to 3 attempts), truncate oversized tool results, and fall back to a different model.

**Nanobot**: runs up to 40 rounds. The `AgentLoop` class consumes messages from an async bus, calls `provider.chat_with_retry()`, executes tools via `self.tools.execute()`, and appends results. It tracks active tasks per session and uses locking for concurrency control.

**Synapulse**: much simpler by comparison. A plain `for` loop up to 10 rounds. Each round: call provider → check for tool calls → validate JSON Schema → execute → append result → sleep 1s. No retry, no fallback — errors are caught and returned as text. It gets the job done for personal use but lacks the robustness of the other two.

### Memory

| Aspect | OpenClaw | Nanobot | Synapulse |
|--------|----------|---------|-----------|
| **Storage format** | Binary session file (Pi SDK) | JSONL (append-only messages) + MEMORY.md + HISTORY.md | JSON files (conversations.json + summaries.json) |
| **Scope** | Per agent + session | Per session (workspace-based) | Per user + channel |
| **History loading** | Pi SDK loads from session file | Last N messages (memory_window, default 50) | Last 20 turns, capped at 3000 chars |
| **Summarization trigger** | Auto-compact on context overflow | When unconsolidated messages exceed threshold | When turns > 20 |
| **Summarization method** | Pi SDK compaction (opaque) | LLM call with `save_memory` tool → writes MEMORY.md + HISTORY.md | LLM call → cascading summary stored in summaries.json |
| **Inspectability** | Low (binary format) | High (MEMORY.md is human-readable, HISTORY.md is grep-searchable) | High (plain JSON files, easy to inspect/modify) |

**OpenClaw**: memory is deeply integrated into the Pi SDK's session manager. Compaction is triggered automatically when context overflows. The session file is a binary format, making it opaque to inspect or modify.

**Nanobot**: uses a two-layer memory system. `MEMORY.md` stores long-term facts (consolidated knowledge), and `HISTORY.md` stores a timestamped log of events (grep-searchable). Messages are append-only in JSONL format for LLM cache efficiency — consolidation writes to the markdown files but does NOT modify the message list.

**Synapulse**: the simplest approach. Per-turn save to JSON files. When turns exceed 20, old turns are summarized via an LLM call (cascading: new summary includes previous summary + new turns). Old turns deleted only after summarization succeeds. Compared to Nanobot's two-layer system, this is more naive — but the JSON format is trivially inspectable and editable, which helps during development.

### Tool System

| Aspect | OpenClaw | Nanobot | Synapulse |
|--------|----------|---------|-----------|
| **Discovery** | Hardcoded + plugin system | Default tools registered at startup + MCP | Auto-scan `tool/` folders + MCP |
| **Definition** | TypeScript tool factories, pre-compiled into Pi SDK | `Tool` ABC with `name`, `description`, `parameters`, `execute()` | `BaseTool` ABC with format mixins (`OpenAITool`, `AnthropicTool`) |
| **Validation** | Pi SDK handles | Built-in JSON Schema validation with type casting | JSON Schema validation via `jsonschema` library |
| **Multi-format** | Pi SDK abstracts provider differences | Single `to_schema()` outputs OpenAI format | `to_openai()` and `to_anthropic()` methods per tool |
| **MCP** | No (uses plugin system) | Yes, lazy-loaded | Yes, hot-reload every 30s |
| **Extension** | Write TypeScript plugin | Subclass `Tool`, place in tools directory | Create `tool/my_tool/handler.py`, auto-discovered on restart |

**OpenClaw**: tools are pre-compiled into the Pi SDK. Custom tools are added via a plugin system. The SDK owns tool execution — the core system only observes via callbacks.

**Nanobot**: tools are subclasses of a `Tool` ABC with `name`, `description`, `parameters` (JSON Schema), and `execute()`. Built-in tools include file operations, shell execution, web search, subagent spawning, and cron scheduling. The tool base class includes schema-driven type casting and recursive validation.

**Synapulse**: borrows the same pattern from Nanobot but adds format mixins. A tool inherits from `OpenAITool` and/or `AnthropicTool` to declare which LLM APIs it supports. Tools are auto-discovered by scanning directories. Dependencies (database, file sender) are injected by the core — a small design choice learned from studying the other two projects.

### Key Takeaways

**OpenClaw** is a full-featured, production-grade system with sophisticated error recovery, multi-channel support, and multi-agent orchestration. It is the most mature and capable of the three.

**Nanobot** delivers the core of OpenClaw in ~4K lines of Python. It supports 10+ channels, has a clean two-layer memory system, and adds subagent support. A remarkable achievement in code density.

**Synapulse** is a personal learning project (~2K lines). Compared to the other two, it lacks multi-channel support, subagent capability, and sophisticated error recovery. What it does have is simplicity — the entire codebase is small enough to read in one sitting, which was the whole point: to understand how agent systems work by building one from scratch.

## Configuration

### Environment Variables (`.env`)

| Variable | Required | Description |
|----------|----------|-------------|
| `DISCORD_TOKEN` | Yes | Discord bot token |
| `AI_PROVIDER` | No | `mock` (default), `copilot`, or `ollama` (fallback if no `models.yaml`) |
| `AI_MODEL` | No | Model name, e.g. `gpt-4o-mini` |
| `BRAVE_API_KEY` | For search | Brave Search API key |
| `OPENWEATHER_API_KEY` | For weather | OpenWeatherMap API key |
| `GITHUB_PAT` | For MCP GitHub | GitHub Personal Access Token (auto-detects owner identity) |
| `LOCAL_FILES_ALLOWED_PATHS` | For files/shell | Comma-separated sandboxed paths |

### Multi-Endpoint Rotation (`config/models.yaml`)

Multiple AI endpoints with tag-based routing, priority, and automatic rate-limit fallback. Hot-reloads every 30s.

### MCP Servers (`config/mcp.json`)

55 pre-configured MCP servers (all disabled by default). Enable by setting `"enabled": true`. Servers can also be added dynamically via Discord chat.

## Requirements

- Python 3.11+
- Discord bot token
- An LLM API endpoint (or use `mock` provider for testing)

## Source Code

- GitHub: [GOODDAYDAY/Synapulse](https://github.com/GOODDAYDAY/Synapulse)
- License: MIT
