+++
date = '2026-04-17T12:00:00+08:00'
draft = false
title = '[Project] 3. Harness-Everything — Autonomous AI Code Improvement Harness'
categories = ["Project"]
tags = ["AI", "LLM", "Self-Improvement", "DeepSeek", "Anthropic", "CI/CD", "Python"]
+++

## Big Picture

<img src="/images/mermaid/harness-en-1.svg" alt="diagram" style="max-width:100%;">

> **The LLM is the brain, the Harness is the hands, the project code is what gets modified. The LLM never directly touches the filesystem — it only says "I want to do X", and your code executes it.**

## The Essence: Three Sentences

1. **The LLM is the engine**: Feed project code to a language model, let it analyze, suggest improvements, and write code. At its core, it's just a while loop asking the LLM "what else can be improved?"
2. **Tools are the hands**: The LLM can't directly read or write files. It uses Anthropic's tool_use protocol to tell your code "I want to read this file" / "I want to edit this line", and your code executes it. You could run the whole thing with just a `bash` tool.
3. **Process restart is the key**: Python modules are loaded once at startup and stay frozen in memory. When the LLM modifies its own `.py` files, the running process still uses the old code. A process restart is the only way to apply improvements. That's why we have the push → tag → CI deploy → restart loop.

---

## From Simplest to Complete System: Each Layer Solves One Problem

### Simplest Version (Conceptual)

```python
while True:
    code = read_all_project_files()
    response = LLM("Here's the code, improve it:" + code)
    write_back(response)
```

This works. But it runs into problems. **Each layer below solves the previous layer's problem**:

<img src="/images/mermaid/harness-en-2.svg" alt="diagram" style="max-width:100%;">

### Layer 1: Code Too Large for Context

**Problem**: When the project gets big, all files don't fit in the LLM context window.

**Solution**: Give the LLM tools to choose what to read, instead of stuffing everything in.

<img src="/images/mermaid/harness-en-3.svg" alt="diagram" style="max-width:100%;">

**The core code (`harness/core/llm.py` `call_with_tools()`) is only 60 lines**:

```python
for turn in range(max_turns):
    # 1. Ask LLM: "What do you want to do?"
    response = await api.messages.create(messages=conversation, tools=tool_list)
    
    # 2. If LLM didn't request any tool → it's done, exit
    if not response.tool_calls:
        return response.text
    
    # 3. LLM wants a tool → your code executes → feed result back
    for call in response.tool_calls:
        result = await registry.execute(call.name, config, call.input)
    
    # 4. Append results to conversation history, continue loop
    conversation.append(tool_results)
```

**That's it. This is the most important 60 lines in the entire project.**

### Layer 2: LLM Introduces Bugs

**Problem**: LLM-generated code may have syntax errors or break the project.

**Solution**: Automatically run `python -m py_compile` after every code change. If it fails, feed the error back to the LLM to fix.

```
LLM edits code → py_compile error → error fed back to LLM → LLM fixes → passes
```

This is `SyntaxCheckHook` in `harness/pipeline/hooks.py`.

### Layer 3: Can't Tell if Changes Are Good

**Problem**: The LLM made changes — are they actually good?

**Solution**: Use two separate LLM calls to judge, running in parallel with isolated perspectives:

- **Basic evaluator**: Find the most critical defect (security holes, logic errors, code quality)
- **Diffusion evaluator**: Analyze second-order effects (will it break other modules? cause context bloat?)

<img src="/images/mermaid/harness-en-4.svg" alt="diagram" style="max-width:100%;">

This is `harness/evaluation/dual_evaluator.py`. It's the LLM judging itself, but the **isolated dual perspective** reduces self-congratulation.

### Layer 4: Small Steps, Many Rounds

**Problem**: Asking the LLM to "fix everything at once" produces poor results. Big changes break things.

**Solution**: Split into multiple phases, each focused on one thing, iterating round by round:

<img src="/images/mermaid/harness-en-5.svg" alt="diagram" style="max-width:100%;">

This is `harness/pipeline/pipeline_loop.py` (outer loop) and `harness/pipeline/phase_runner.py` (phase execution).

### Layer 5: Changes Don't Take Effect

**Problem**: The LLM modified `harness/core/llm.py` in Round 3, but the running process still uses the version loaded at Round 1. The improvement is invisible.

**Solution**: The restart loop.

```python
# At process startup
import harness.core.llm  # loaded into memory, never changes after this

# Round 5: LLM edits llm.py on disk
edit_file("harness/core/llm.py", ...)  # disk changes

# Round 6: process still uses the old in-memory version
# Python doesn't auto-reimport

# Only a process restart picks up the new code
```

**This is the most important architectural decision.** Without this restart loop, self-improvement is fake — the LLM thinks it changed the code, but the changes never execute.

### Layer 6: Keep the Loop Alive

**Problem**: Many situations can silently kill the loop.

| Problem | Solution |
|---|---|
| Context overflow | Give LLM tools to read on demand |
| LLM introduces bugs | Syntax check hook auto-validates |
| Can't tell good from bad | Dual evaluator scores, pick highest |
| Changes don't take effect | push → tag → CI → restart process |
| Early stop → no tag → loop dies | `auto_tag_at_end` forces tag on every exit |
| 3 crashes → systemd gives up | Heartbeat cron resets and restarts every 30min |
| User push causes conflict | `git pull --rebase` auto-merges |
| LLM breaks deploy scripts | `SELF-IMPROVEMENT LOOP PROTECTION` blocklist in prompts |
| Bad code deployed | CI smoke test + rollback to `harness-last-good` |
| Disk full | Cleanup cron deletes old data daily |

---

## Tool System: Optimization, Not Core

With just a single `bash` tool, the LLM would do:

```
bash("cat harness/core/llm.py")           → read file
bash("grep -rn '_check_path' harness/")   → search
bash("sed -i 's/old/new/' file.py")       → edit file
bash("python3 -m py_compile file.py")     → check syntax
```

This works. So why 30 specialized tools?

| bash only | Specialized tool | Why switch |
|---|---|---|
| `cat /etc/passwd` | `read_file` rejects it | **Security**: path check restricts to workspace |
| `grep` outputs 100K lines | `grep_search` auto-truncates | **Cost**: won't blow up context |
| `sed` silently corrupts | `edit_file` exact match | **Control**: mismatch = explicit error |
| LLM invents params | Registry validates | **Fault tolerance**: unknown params blocked |

<img src="/images/mermaid/harness-en-6.svg" alt="diagram" style="max-width:100%;">

**Tools are safety gloves for the LLM, not superpowers.**

### Tool Categories (30+)

```
File ops:    read_file, write_file, edit_file, delete_file, move_file, copy_file
Directory:   list_directory, create_directory, tree
Search:      glob_search, grep_search
Git:         git_status, git_diff, git_log
Execution:   bash, python_eval, test_runner
Analysis:    code_analysis, symbol_extractor, cross_reference, ...
Optional:    web_search (must be explicitly enabled)
```

### Path Security (`_check_path`)

Every file-accessing tool passes a security check before execution:

```python
resolved = os.path.realpath(path)  # resolve symlinks
# Check: null bytes, Unicode homoglyphs, path traversal
if path not in allowed_paths:
    reject
```

LLM says "read /etc/passwd" → blocked. "read ../../etc/passwd" → realpath resolves it → still blocked.

---

## Cost Model

The Anthropic API is **stateless**. Every call resends the full conversation history. So each turn in the tool loop costs more than the last:

```
Turn  1: send [system prompt + file context + user instruction]  ≈ 20K tokens
Turn  5: send [above + 4 rounds of tool calls and results]      ≈ 30K tokens
Turn 10: send [above + 9 rounds]                                ≈ 40K tokens
Turn 20: send [above + 19 rounds]                               ≈ 60K tokens  ← most expensive
```

<img src="/images/mermaid/harness-en-7.svg" alt="diagram" style="max-width:100%;">

**The later turns cost exponentially more per marginal tool call.** That's why cutting `max_tool_turns` from 30 to 20 saves 40% — you're removing the most expensive turns.

### Mitigation Measures

| Mechanism | File | How it works |
|---|---|---|
| Conversation pruning | `llm.py` | Truncate old tool results when total chars > 150K |
| Proactive compaction | `llm.py` | After turn 6, replace old tool results with one-line summaries |
| File-read cache | `llm.py` | Cache `read_file` results within a tool loop; writes invalidate cache |
| Context injection budget | `phase_runner.py` | Only inject the most relevant 30K chars of source code |

### DeepSeek Cost Estimate

```
Cache miss: $0.28 / million input tokens
Cache hit:  $0.028 / million input tokens (typical hit rate ~90%)
Output:     $0.42 / million output tokens

Per chunk (6-10 rounds x 4-5 phases):
  Input:  ~30M tokens → ~$3
  Output: ~1M tokens  → ~$0.4
  Total:  ~$3.5 / chunk
```

---

## Self-Improvement Loop (Server Deployment)

<img src="/images/mermaid/harness-en-8.svg" alt="diagram" style="max-width:100%;">

### Operations Quick Reference

| Goal | Command |
|---|---|
| Live logs | `ssh server "tail -f ~/harness-everything/logs/harness.log"` |
| Commit progress | `git log --oneline -20` |
| Push a fix (no restart needed) | `git push` — harness auto-rebases |
| Change config | Edit `config/pipeline_example_self_improve_server.json`, push |
| Stop after current chunk | `ssh server "touch ~/.config/harness/STOP_AFTER_CHUNK"` |
| Resume loop | `ssh server "systemctl --user start harness.service"` |
| Emergency stop | `ssh server "systemctl --user stop harness.service"` |
| Full shutdown | stop + disable + clear cron |

---

## Complete Data Flow: From Config to Code Commit

<img src="/images/mermaid/harness-en-9.svg" alt="diagram" style="max-width:100%;">

---

## Core Data Structures

```
PipelineConfig                     # Top-level config
├── harness: HarnessConfig         #   Model/API/workspace/tools
│   ├── model: "deepseek-chat"
│   ├── base_url: "https://api.deepseek.com/anthropic"
│   ├── workspace: "/home/ubuntu/harness-everything"
│   ├── allowed_paths: [workspace]
│   └── max_tool_turns: 20
├── phases: [PhaseConfig]          #   Phase list
│   ├── name, mode (debate/implement)
│   ├── system_prompt (with $file_context template vars)
│   └── glob_patterns (which files to inject)
├── outer_rounds: 10               #   Rounds per chunk
├── patience: 5                    #   Early stop after N stale rounds
├── auto_push_interval: 1          #   Push every round
└── auto_tag_at_end: true          #   Force tag on every exit

InnerResult                        # Single attempt result
├── proposal: str                  #   LLM's proposal or changes
├── dual_score                     #   Dual scores
│   ├── basic: (score, critique)   #     Defect evaluation
│   └── diffusion: (score, critique)#    Ripple effects
└── tool_call_log: [dict]          #   Tool call records

PhaseResult                        # Phase result
├── synthesis: str                 #   Synthesized final proposal
├── best_score: float              #   Highest score
└── inner_results: [InnerResult]   #   All attempts
```

---

## Key File Index

| File | Role | One-liner |
|---|---|---|
| `main.py` | Entry point | Parse args, start the loop |
| `harness/core/llm.py` | **Most critical** | Tool loop: LLM speaks → you execute → feedback → repeat |
| `harness/core/config.py` | Config | JSON → config object, path security validation |
| `harness/pipeline/pipeline_loop.py` | Outer loop | Round orchestration, push, tag, early stop, shutdown |
| `harness/pipeline/phase_runner.py` | Phase execution | Context injection, inner rounds, evaluation, synthesis, hooks |
| `harness/evaluation/dual_evaluator.py` | Quality gate | Two LLMs score in parallel, pick the best proposal |
| `harness/tools/registry.py` | Tool dispatch | Registration, param validation, exception wrapping |
| `harness/tools/base.py` | Tool security | `_check_path` workspace boundary enforcement |
| `harness/pipeline/hooks.py` | Verification | Syntax check + git commit (rich metadata) |
| `deploy/harness.service` | Deployment | systemd user service definition |
| `.github/workflows/deploy.yml` | CI/CD | Tag-triggered: smoke test → deploy → restart/rollback |
| `deploy/heartbeat.sh` | Keepalive | Restart after 3-strike systemd failure |

---

## One-Paragraph Summary

> Feed project code to an LLM, let it analyze and improve, using tools to read and edit files. A separate LLM call judges the quality; only the best proposals get committed. Multiple rounds iterate, each building on the improved code from the previous round. Because Python modules are loaded once at startup and frozen in memory, the process must restart every N rounds for improvements to take effect. Restart is driven by git tags triggering a GitHub Actions workflow that SSH-deploys and restarts the service — forming an unattended self-improvement loop. The tool system (30+ file/search/execution tools) is essentially safety gloves for the LLM — a single `bash` tool could do everything, but it would be less safe and more expensive.
