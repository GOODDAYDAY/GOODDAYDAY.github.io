+++
date = '2026-03-10T23:00:00+08:00'
draft = false
title = '[Project] 2. Synapulse — 自托管的个人 AI 助手'
categories = ["Project"]
tags = ["AI Assistant", "Discord Bot", "LLM", "MCP", "Python"]
+++

<div align="center">
<img src="/images/Project%20-%202%20-%20Synapulse/synapulse-logo.jpeg" alt="Synapulse" width="128">
</div>

## 概述

Synapulse（Synapse + Pulse）是一个自托管的个人 AI 助手，运行在你的 Discord 服务器中。灵感来自 [OpenClaw](https://github.com/nicepkg/openclaw)——看到它的能力后，我决定动手做一直想做的个人助手：轻量、透明、完全可控。

- GitHub：[GOODDAYDAY/Synapulse](https://github.com/GOODDAYDAY/Synapulse)

## 功能特点

| 功能 | 说明 |
|------|------|
| **AI 聊天** | 在 Discord 中 @机器人即可对话，支持多种 AI 提供商 |
| **工具调用** | 多轮 AI 工具调用循环（最多 10 轮），工具启动时自动发现，支持 token 压缩 |
| **持久记忆** | 对话自动保存和摘要，跨会话记忆 |
| **任务管理** | 支持优先级和截止日期的待办事项，AI 主动感知待办任务 |
| **备忘录** | 通过自然语言保存和搜索个人笔记 |
| **提醒** | 自然语言提醒，支持循环提醒 |
| **邮件监控** | 后台任务通过 IMAP 监控 Gmail、Outlook、QQ 邮箱，推送摘要到 Discord |
| **MCP 集成** | 连接 55+ 预配置 MCP 服务器（GitHub、Notion、文件系统、数据库等），按需加载节省 token |
| **模型轮转** | 多端点 YAML 配置，支持标签路由、优先级和自动限流回退 |
| **文件 & Shell** | 读写本地文件、执行 Shell 命令（带安全黑名单和超时控制） |
| **通知交互** | 回复机器人的任何消息，AI 自动获取原始内容作为上下文 |
| **热重载配置** | 运行时编辑任务调度、提示词、MCP 服务器、模型端点，无需重启 |

## 架构

### 技术栈

| 组件 | 技术 |
|------|------|
| **语言** | Python 3.11+ |
| **通道** | Discord（discord.py） |
| **AI 提供商** | OpenAI 兼容（GitHub Models、Ollama、自定义端点） |
| **存储** | JSON 文件（每种数据类型一个文件） |
| **工具扩展** | MCP（Model Context Protocol）+ 原生自动发现 |
| **后台任务** | 异步定时任务，用于邮件监控、提醒检查 |

### 项目结构

```
apps/bot/
├── main.py                    # 入口
├── config/                    # 配置、提示词、任务配置、模型配置
├── core/
│   ├── handler.py             # 启动引导：通过依赖注入连接所有组件
│   ├── loader.py              # 自动发现工具和任务
│   ├── mention.py             # 工具调用循环、记忆加载/保存、摘要生成
│   └── reminder.py            # 后台提醒检查
├── provider/
│   ├── base.py                # OpenAIProvider、AnthropicProvider
│   ├── endpoint.py            # EndpointPool：轮转、限流回退
│   └── copilot/auth.py        # GitHub OAuth 设备流
├── channel/
│   └── discord/client.py      # Discord 机器人集成
├── tool/                      # 原生工具（自动发现）
│   ├── base.py                # BaseTool、OpenAITool、AnthropicTool
│   ├── brave_search/          # 网络搜索
│   ├── local_files/           # 读写本地文件（沙盒化）
│   ├── memo/                  # 备忘录管理
│   ├── task/                  # 待办事项
│   ├── reminder/              # 提醒
│   ├── weather/               # 天气查询（OpenWeatherMap）
│   ├── shell_exec/            # Shell 命令（带安全黑名单）
│   └── mcp_server/            # 通过聊天管理 MCP 连接
├── job/                       # 后台任务（自动发现）
│   ├── cron.py                # 定时任务基类，支持热重载
│   ├── gmail/                 # Gmail 监控
│   ├── outlook/               # Outlook 监控
│   └── qqmail/                # QQ 邮箱监控
├── mcp/
│   └── client.py              # MCPManager：启动、发现、路由
└── memory/
    └── database.py            # JSON 文件持久化
```

### 核心循环

`core/mention.py` 中的工具调用循环：

1. **加载记忆**：从数据库加载对话历史（最近 20 轮）+ 摘要
2. **加载任务**：待办事项注入系统提示词
3. **构建提示词**：系统提示词（工具提示 + 记忆 + 任务）+ 用户提示词（存储历史 + 频道历史 + 引用消息 + 当前消息）
4. **调用 AI**：发送消息给提供商
5. **工具调用循环**（最多 10 轮）：
   - 如果 AI 返回文本 → 保存到数据库，可能触发摘要，返回文本
   - 如果 AI 请求工具调用：
     - 压缩旧工具结果以节省 token
     - 通过 JSON Schema 验证参数
     - 执行工具（原生或 MCP）
     - 将结果追加到消息中
     - 等待 1 秒（限流保护）
     - 继续循环
6. 如果达到最大轮数 → 返回 "陷入循环" 消息

### 记忆系统

**存储**：JSON 文件 — `conversations.json`、`summaries.json`、`memos.json`、`reminders.json`、`tasks.json`

**记忆流程**：

| 阶段 | 操作 |
|------|------|
| **AI 调用前** | 加载最近 20 轮 + 摘要，历史上限 3000 字符 |
| **系统提示词** | 注入记忆摘要 + 待办任务（上限 1000 字符） |
| **AI 回复后** | 保存用户消息 + AI 回复 + 使用的工具名称 |
| **自动摘要** | 轮数 > 20 时：通过 LLM 摘要旧轮次，保留最近 5 轮 |

**摘要策略**：级联式——新摘要包含上一次摘要 + 新对话。旧轮次仅在摘要成功后才删除。

### 工具系统

工具继承 `BaseTool` 并使用格式混入：

```python
class Tool(OpenAITool, AnthropicTool):
    name = "my_tool"
    description = "工具功能说明"
    parameters = {...}  # JSON Schema
    usage_hint = "系统提示词中的简短路由提示"

    async def execute(self, **kwargs) -> str:
        return "结果"
```

**自动发现**：`core/loader.py` 扫描 `tool/` 目录下的 `handler.py` 文件，加载 `Tool()` 类，调用 `validate()`。

**依赖注入**：核心在启动时或每条消息时注入 `db`（数据库）、`send_file` 回调和 `channel_id`。

**格式无关**：每个工具有 `to_openai()` 和 `to_anthropic()` 方法，同一工具兼容两种 API。

**MCP 工具**：`MCPManager` 以子进程启动 MCP 服务器，通过 MCP 协议发现工具，包装为 `MCPToolWrapper`（鸭子类型匹配原生工具接口）。每 30 秒检查配置变更实现热重载。

### MCP 按需加载

一个关键优化：MCP 工具在启动时不会加载到 Provider 的工具列表中。取而代之：

1. 启动时只将原生工具的 schema 发送给 AI（节省 token）
2. MCP 工具名称作为提示列在系统提示词中
3. 当 AI 需要 MCP 工具时，调用 `mcp_server(action="use_tools", tools=[...])` 激活特定工具
4. 请求的 schema 按需加入 Provider 的工具列表，仅对当前请求生效

这避免了每次 API 调用都发送 100+ 个 MCP 工具 schema，显著减少 token 消耗。

### 模型轮转与回退

`EndpointPool` 管理 `config/models.yaml` 中定义的多个 AI 端点：

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

- **标签路由**：请求特定能力（如 `large`、`coding`、`local`）
- **同优先级轮转**：Round-robin 方式在相同优先级端点间轮转
- **限流回退**：收到 429 时标记端点冷却（遵循 `Retry-After` 头），尝试下一个
- **热重载**：每 30 秒检测配置变更，保留冷却状态

### Shell 执行安全

`shell_exec` 工具在多层安全措施下运行 Shell 命令：

- **危险命令黑名单**：拦截 `rm -rf /`、`mkfs`、`shutdown`、`sudo` 等
- **可配置超时**：每个命令 1–120 秒
- **输出截断**：结果上限 10,000 字符
- **沙盒工作目录**：限制在 `LOCAL_FILES_ALLOWED_PATHS` 指定的路径内

## 对比：OpenClaw vs Nanobot vs Synapulse

[OpenClaw](https://github.com/nicepkg/openclaw) 是一个成熟的、功能完备的个人 AI 助手。[Nanobot](https://github.com/HKUDS/nanobot) 将其核心精简为 "比 OpenClaw 少 99% 的代码"。Synapulse 是我学习这两个项目后，为自己做的一个极简个人助手——功能和完善程度远不如前两者，但构建的过程让我深入理解了 Agent 系统底层的运作方式。以下对比是为了记录学习心得，并非将 Synapulse 放在同等高度。

### 总览

| 维度 | OpenClaw | Nanobot | Synapulse |
|------|----------|---------|-----------|
| **语言** | TypeScript | Python | Python |
| **核心代码量** | ~400,000 行 | ~4,000 行 | ~2,000 行 |
| **通道** | 多通道（Telegram、Discord、WhatsApp 等） | 10+ 通道（Telegram、Discord、WhatsApp、飞书等） | Discord（通道层已抽象，可扩展） |
| **AI 提供商** | Anthropic、OpenAI、Google、GitHub（通过 Pi SDK） | OpenRouter、Anthropic、OpenAI、DeepSeek、Ollama 等 | OpenAI 兼容（GitHub Models、Ollama、自定义） |
| **部署** | 多进程、多 Agent | 单进程，网关模式 | 单进程 |
| **MCP 支持** | 无（使用插件系统） | 有，内置 | 有，内置 + 热重载 |

### Agent 循环

Agent 循环是编排 LLM 调用和工具执行的核心机制。

| 维度 | OpenClaw | Nanobot | Synapulse |
|------|----------|---------|-----------|
| **循环所有者** | 委托给 Pi agent SDK（闭源） | 自定义 `AgentLoop` 类 | 自定义 `mention.py` 处理器 |
| **最大轮数** | 由 Pi SDK 控制 | 40 | 10 |
| **工具执行** | 通过 Pi SDK 订阅流式执行 | 顺序异步执行 | 顺序异步执行 |
| **错误恢复** | 多层：认证轮转 → 压缩 → 工具截断 → 模型回退 | 逐工具 try/catch | 逐工具 try/catch |
| **限流处理** | 认证配置轮转 + 冷却 | Provider 重试 | 端点池轮转 + 每轮间隔 1 秒 |

**OpenClaw**：最复杂。核心将 Agent 循环委托给闭源的 Pi SDK，通过订阅回调观察工具调用和结果。失败时有多层恢复系统——轮转认证配置、上下文溢出时自动压缩（最多 3 次）、截断过大的工具结果、回退到其他模型。

**Nanobot**：最多运行 40 轮。`AgentLoop` 类从异步总线消费消息，调用 `provider.chat_with_retry()`，通过 `self.tools.execute()` 执行工具，追加结果。它按会话跟踪活跃任务，使用锁进行并发控制。

**Synapulse**：相比之下简单很多。一个普通的 `for` 循环，最多 10 轮。每轮：调用 Provider → 检查工具调用 → JSON Schema 验证 → 执行 → 追加结果 → 等待 1 秒。无重试、无回退——错误被捕获并作为文本返回。个人使用够用，但健壮性远不及前两者。

### 记忆

| 维度 | OpenClaw | Nanobot | Synapulse |
|------|----------|---------|-----------|
| **存储格式** | 二进制会话文件（Pi SDK） | JSONL（只追加消息）+ MEMORY.md + HISTORY.md | JSON 文件（conversations.json + summaries.json） |
| **作用域** | 按 Agent + 会话 | 按会话（基于工作区） | 按用户 + 频道 |
| **历史加载** | Pi SDK 从会话文件加载 | 最近 N 条消息（memory_window，默认 50） | 最近 20 轮，上限 3000 字符 |
| **摘要触发** | 上下文溢出时自动压缩 | 未整理消息超过阈值时 | 轮数 > 20 时 |
| **摘要方式** | Pi SDK 压缩（不透明） | LLM 调用 `save_memory` 工具 → 写入 MEMORY.md + HISTORY.md | LLM 调用 → 级联摘要存入 summaries.json |
| **可检查性** | 低（二进制格式） | 高（MEMORY.md 人类可读，HISTORY.md 可 grep 搜索） | 高（纯 JSON 文件，易于检查和修改） |

**OpenClaw**：记忆深度集成在 Pi SDK 的会话管理器中。上下文溢出时自动触发压缩。会话文件是二进制格式，不透明，难以检查或修改。

**Nanobot**：使用双层记忆系统。`MEMORY.md` 存储长期事实（整理后的知识），`HISTORY.md` 存储带时间戳的事件日志（可 grep 搜索）。消息在 JSONL 文件中只追加，以提高 LLM 缓存效率——整理过程写入 Markdown 文件但不修改消息列表。

**Synapulse**：最朴素的方案。每轮保存到 JSON 文件。轮数超过 20 时，旧轮次通过 LLM 调用生成摘要（级联式：新摘要包含上一次摘要 + 新对话）。旧轮次仅在摘要成功后才删除。相比 Nanobot 的双层系统更简陋，但 JSON 格式方便开发时检查和调试。

### 工具系统

| 维度 | OpenClaw | Nanobot | Synapulse |
|------|----------|---------|-----------|
| **发现方式** | 硬编码 + 插件系统 | 启动时注册默认工具 + MCP | 自动扫描 `tool/` 文件夹 + MCP |
| **定义方式** | TypeScript 工具工厂，预编译到 Pi SDK | `Tool` 抽象基类：`name`、`description`、`parameters`、`execute()` | `BaseTool` 抽象基类 + 格式混入（`OpenAITool`、`AnthropicTool`） |
| **参数验证** | Pi SDK 处理 | 内置 JSON Schema 验证 + 类型转换 | 通过 `jsonschema` 库验证 |
| **多格式支持** | Pi SDK 抽象 Provider 差异 | 单一 `to_schema()` 输出 OpenAI 格式 | `to_openai()` 和 `to_anthropic()` 方法 |
| **MCP** | 无（使用插件系统） | 有，懒加载 | 有，每 30 秒热重载 |
| **扩展方式** | 编写 TypeScript 插件 | 继承 `Tool`，放入 tools 目录 | 创建 `tool/my_tool/handler.py`，重启自动发现 |

**OpenClaw**：工具预编译到 Pi SDK 中。自定义工具通过插件系统添加。SDK 拥有工具执行权——核心系统只能通过回调观察。

**Nanobot**：工具是 `Tool` 抽象基类的子类，包含 `name`、`description`、`parameters`（JSON Schema）和 `execute()`。内置工具包括文件操作、Shell 执行、网络搜索、子 Agent 启动和定时调度。工具基类包含基于 Schema 的类型转换和递归验证。

**Synapulse**：借鉴了 Nanobot 的模式，增加了格式混入。工具继承 `OpenAITool` 和/或 `AnthropicTool` 来声明支持的 LLM API。工具通过目录扫描自动发现。依赖由核心注入——这是研究前两个项目后学到的一个小设计。

### 核心总结

**OpenClaw** 是功能完备的生产级系统，有复杂的错误恢复、多通道支持和多 Agent 编排。三者中最成熟、最强大。

**Nanobot** 用 ~4K 行 Python 实现了 OpenClaw 的核心功能。支持 10+ 通道，有干净的双层记忆系统，还支持子 Agent。代码密度令人印象深刻。

**Synapulse** 是个人学习项目（~2K 行）。相比前两者，缺少多通道支持、子 Agent 能力和复杂的错误恢复。它有的只是简单——整个代码库小到可以一口气读完，而这正是目的：通过从零构建一个 Agent 系统来理解它的运作原理。

## 配置

### 环境变量（`.env`）

| 变量 | 必需 | 说明 |
|------|------|------|
| `DISCORD_TOKEN` | 是 | Discord 机器人 Token |
| `AI_PROVIDER` | 否 | `mock`（默认）、`copilot` 或 `ollama`（无 `models.yaml` 时的回退） |
| `AI_MODEL` | 否 | 模型名称，如 `gpt-4o-mini` |
| `BRAVE_API_KEY` | 搜索功能需要 | Brave Search API Key |
| `OPENWEATHER_API_KEY` | 天气功能需要 | OpenWeatherMap API Key |
| `GITHUB_PAT` | MCP GitHub 需要 | GitHub Personal Access Token（自动检测仓库所有者身份） |
| `LOCAL_FILES_ALLOWED_PATHS` | 文件/Shell 需要 | 逗号分隔的沙盒路径 |

### 多端点轮转（`config/models.yaml`）

多个 AI 端点支持基于标签的路由、优先级和自动限流回退。每 30 秒热重载。

### MCP 服务器（`config/mcp.json`）

55 个预配置 MCP 服务器（默认全部禁用）。设置 `"enabled": true` 即可启用。也可以通过 Discord 聊天动态添加服务器。

## 系统要求

- Python 3.11+
- Discord 机器人 Token
- 一个 LLM API 端点（或使用 `mock` 提供商进行测试）

## 源代码

- GitHub：[GOODDAYDAY/Synapulse](https://github.com/GOODDAYDAY/Synapulse)
- 许可证：MIT
