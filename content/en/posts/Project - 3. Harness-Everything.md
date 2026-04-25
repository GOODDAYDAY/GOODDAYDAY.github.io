+++
date = '2026-04-17T12:00:00+08:00'
draft = false
title = '[Project] 3. Harness-Everything — Autonomous AI Code Improvement Harness'
categories = ["Project"]
tags = ["AI", "LLM", "Self-Improvement", "DeepSeek", "Anthropic", "CI/CD", "Python"]
featuredImage = "/images/Project%20-%203%20-%20Harness-Everything/cover.png"
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

**Turn — The hidden cost: "compound interest" on memory**

These 60 lines are simple, but they hide a counterintuitive cost model. The Anthropic API is **stateless** — every call resends the full conversation history. Turn 1 is ~20K tokens. Turn 5 with 4 rounds of tool calls is ~30K. Turn 10 is ~40K. Turn 20 is ~60K. **The longer the conversation, the more expensive each additional turn — and the growth is exponential.**

That's why cutting `max_tool_turns` from 30 to 20 saves ~40% in cost — you're removing the most expensive turns. But fewer turns means less thinking space for the agent. There's no perfect tradeoff; subsequent mitigation measures (conversation pruning, proactive compaction, file-read cache) all chip away at this fundamental tension.

**Resolution — These 60 lines are the engine; the next six layers are safety nets and a steering wheel**

The engine itself isn't complicated. What's hard is building a control system around it — one that prevents it from overheating, from driving in the wrong direction, from forgetting which roads it's already traveled. Every layer that follows adds one dimension of control.

### Layer 2: LLM Introduces Bugs

**Problem**: LLM-generated code may have syntax errors or break the project.

**Solution**: Automatically run `python -m py_compile` after every code change. If it fails, feed the error back to the LLM to fix.

```
LLM edits code → py_compile error → error fed back to LLM → LLM fixes → passes
```

This is `SyntaxCheckHook` in `harness/pipeline/hooks.py`.

**Turn — `py_compile` catches commas, not confusion**

Syntax check is a hard constraint — mismatched brackets, wrong indentation, mis-imported names — it catches all of them. But it can only tell you "this code runs," not "this code is correct." The LLM can change `if user.is_admin` to `if user.is_active` — perfectly valid syntax, completely wrong logic. And worse: when the LLM sees a compilation error, sometimes it over-corrects, rewriting an entire function just to fix a missing colon.

**Resolution — Syntax check is the floor, not the ceiling**

Its role is: "the code must not fail to compile." But once it passes, determining quality requires smarter judgment — which is what the next layer addresses.

### Layer 3: Can't Tell if Changes Are Good

**Problem**: The LLM made changes — are they actually good?

**Solution**: Use two separate LLM calls to judge, running in parallel with isolated perspectives:

- **Basic evaluator**: Find the most critical defect (security holes, logic errors, code quality)
- **Diffusion evaluator**: Analyze second-order effects (will it break other modules? cause context bloat?)

<img src="/images/mermaid/harness-en-4.svg" alt="diagram" style="max-width:100%;">

This is `harness/evaluation/dual_evaluator.py`.

**Turn — "Letting students grade their own homework" is unavoidable**

Having an LLM evaluate another LLM is, at its core, letting students grade their own homework. Isolating two evaluator perspectives (basic finds defects, diffusion analyzes ripple effects) helps — but if both evaluators share the same model's latent preferences? A taste for elegant code, a bias toward certain design patterns — these are impossible to isolate away.

In practice: **evaluator prompt quality matters far more than isolation**. A good prompt creates just enough divergence between the two evaluators. A vague prompt pushes both into the 6-8 "safe zone" — everything is good, nothing stands out.

**Resolution — Dual evaluation is a mirror, not a ruler**

It shows you two reflections of your work, but it can't give you absolute coordinates. Absolute coordinates need objective metrics (test pass rate, coverage, lint scores) for calibration — which is part of what V5's multi-axis evaluation aims to solve.

### Layer 4: Small Steps, Many Rounds

**Problem**: Asking the LLM to "fix everything at once" produces poor results. Big changes break things.

**Solution**: Split into multiple phases, each focused on one thing, iterating round by round:

<img src="/images/mermaid/harness-en-5.svg" alt="diagram" style="max-width:100%;">

This is `harness/pipeline/pipeline_loop.py` (outer loop) and `harness/pipeline/phase_runner.py` (phase execution).

**Turn — More phases, narrower vision**

The cost of splitting into phases is **loss of coherence**. Phase 2's LLM doesn't know what Phase 1 analyzed. Phase 3 might undo what Phase 2 just built. Each phase makes locally optimal decisions within its own context window, but they can cancel each other out when combined.

This is compounded by **fixed phase ordering**. Whether you throw a security audit or a "add one log line" task at it, it runs the same bug_fix → features → polish pipeline. A security audit for a tiny script is meaningless, but it runs every time. Later (R3), removing the fixed debate mechanism, adding skip rules and falsifiable criteria gave the agent the ability to schedule on demand.

**Resolution — Orchestration wisdom isn't in "how many phases," it's in "knowing when to skip"**

What makes a multi-phase system great isn't the phase design itself — it's the **skip rules**. A phase's value isn't measured by how many times it runs, but by whether each run actually changed the outcome. If a phase gives the same conclusion 80% of the time — it should be skipped.

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

**Turn — But restart has a cost**

Restarting every 10 rounds means that for those 10 rounds, the agent runs on "old body, new mind." Round 5 improves `llm.py`'s retry logic, but Rounds 6-10 still use the old retry logic — new code sits on disk waiting for restart while old code keeps running in memory. Ten rounds is enough for the agent to produce code that depends on new behavior — and if that new behavior hasn't taken effect yet, subsequent changes may be built on false assumptions.

There's no perfect solution, only partial mitigation: after each restart, have the agent audit the core modules it modified in the previous chunk. **Batched restart is an engineering tradeoff: how soon do you want improvements to take effect, and how much body-mind desynchronization can you tolerate?**

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

**Turn — Safety nets are in place, but "judgment" hasn't kept pace**

These safety nets solve "the loop won't die unexpectedly." They don't solve "where should the loop go?" Layer 3's dual evaluation gives the agent judgment within a single round, but it has no cross-round memory, no directional sense, no ability to question its own evaluation criteria. And as the codebase becomes more polished, **the evaluation signal keeps weakening** — all the obvious defects are fixed; what remains requires taste and foresight, which a single score can't capture.

**Resolution — The first six layers keep the loop alive; the seventh layer teaches it to think**

Before V5, Harness was an execution machine that was getting better at not dying. V5 tackles a different problem: not "stay alive," but "know which way to run." This is Layer 7.

### Layer 7 (V5): Flat Scores, No Memory, No Exploration, Can't Self-Modify

**Set-up — Hidden cracks beneath the surface**

V4 ran 67 cycles, grew tests from zero to 2700+, and stabilized the tool system. On the surface, everything was thriving. But four structural bottlenecks lurked underneath:

1. **Flat evaluation scores** — A single 0-10 score couldn't distinguish "fine" from "genuinely good." A variable rename and an AST tool refactor both scored ~7. The agent couldn't tell incremental polish from breakthrough improvements.
2. **No cross-cycle memory** — `memory.jsonl` logged what happened each round but extracted no lessons. The mistake from cycle 71 would be repeated in cycle 73. Every round, the agent started with amnesia.
3. **Pure exploitation** — The agent only polished. It would add tests, delete dead code, merge duplicates — but it would never say "this architecture is wrong, let's rebuild." Without exploration, it circled local optima.
4. **Can't modify itself** — Evaluator prompts and weights were hardcoded in Python files. The agent could modify any code except the standard by which it was judged. The most important self-correction capability was missing.

**Development — Four modules, each breaking one bottleneck**

```
Bottleneck 1 (flat scores)         → MultiAxisEvaluator (5-dim vector evaluation)
Bottleneck 2 (no cross-cycle memory) → ExperienceStore (structured experience memory)
Bottleneck 3 (pure exploitation)    → Exploration Mode (novelty-weighted exploration)
Bottleneck 4 (can't self-modify)    → EvalConfig hot-reload + MetaAgent (strategy layer)
```

<img src="/images/mermaid/harness-en-10.svg" alt="V5 Architecture Overview" style="max-width:100%;">

**1. Multi-Axis Evaluation — 5-dim vector replaces single number**

Old (V4): evaluator outputs `"SCORE: 7.5"` — one number, low differentiation.
New (V5): evaluator outputs 5-dim vector `[correctness, code_quality, arch_health, novelty, alignment]`, weighted average produces final score.

Five dimensions, independently scored (0-10), two evaluator perspectives (basic + diffusion) run in parallel:

| Dimension | Default Weight | Measures |
|---|---|---|
| correctness | 35% | Compiles, tests pass, no security holes introduced |
| code_quality | 25% | Lint-clean, manageable complexity, clear naming |
| arch_health | 15% | Coupling, cohesion, module boundaries |
| novelty | 10% | Difference from existing code, willingness to try new directions |
| alignment | 15% | Consistency with MetaAgent's current optimization target |

Weights are stored in `harness/config/eval_weights.json` and hot-loaded from disk before every evaluation. Change the file → next evaluation uses new weights, no restart needed.

**2. Structured Experience Memory — Not just "what happened," but "what was learned"**

```
Old (V4 memory.jsonl):
  {"cycle": 5, "score": 7.2, "proposal": "changed a bunch of stuff..."}
  → Logbook entries, no extraction, no retrieval, no reuse

New (V5 ExperienceStore):
  Experience(
    cycle=5,
    eval_vector=[8,7,6,5,9],              # Multi-axis vector
    action_summary="Merged two AST tools, reducing duplication",
    reflection="Extracting shared boilerplate into _ast_utils was correct…",  # LLM self-reflection
    abstraction="When multiple tools share >30% code, extract common module into core/",  # Reusable pattern
    tags=["tool_merge", "dedup", "ast"],
    was_reverted=false,
  )
```

Four core interfaces:
- `record(exp)` — Record experience after each round
- `query(["evaluator", "scoring"])` — Retrieve relevant history by tag
- `compress(ratio)` — Merge similar experiences, extract more abstract rules
- `format_context(max_entries)` — Format for LLM and MetaAgent consumption

**3. Exploration Mode — Not just polishing, but venturing**

```
Normal round (exploitation, default):
  Weights: correctness 0.35, code_quality 0.25, arch 0.15, novelty 0.10, alignment 0.15
  → Small-step optimization, stability-first

Exploration round (injected every N rounds):
  Weights: correctness 0.15, code_quality 0.10, arch 0.10, novelty 0.50, alignment 0.15
  → Novelty weight jumps from 10% to 50%, encouraging bold attempts
  → Relaxed gating (compilation failures allowed), scope locked to single module
  → Configurable via exploration_interval in pipeline JSON (default: every 3 rounds)
```

**4. Strategy Layer + Hot-Reload — The agent can finally change its own evaluation criteria**

```
┌─────────────────────────────────────────────────────┐
│ MetaAgent (runs every 5-10 rounds, outputs strategy,  │
│            does not write code)                      │
│                                                     │
│ Input:                                               │
│   • Formatted context of last 20 experiences          │
│   • Score trends across axes (correctness rising      │
│     but novelty falling?)                             │
│   • Current evaluation weights                        │
│                                                     │
│ Output (structured strategy adjustment):              │
│   • focus_axis: "novelty"                             │
│   • adjust_weights: {"novelty": 0.3, ...}             │
│   • exploration_frequency: 2                          │
│   • reasoning: "Code is increasingly standardized     │
│     but lacks new direction, increasing..."           │
│                                                     │
│ MetaAgent decisions → written to eval_weights.json →  │
│ next evaluation hot-loads new weights → takes effect  │
│ without restart                                       │
└─────────────────────────────────────────────────────┘
```

With `GetSelfConfigTool` — a tool registered for agent use — the agent can query "where are my config files?" and then modify its own evaluator prompts and weights. For the first time, the agent can change the standards by which it is judged.

**Turn — Weights aren't magic; prompts are the bottleneck**

After V5 landed, two findings challenged the original assumptions:

First, **changing weights is far less effective than changing prompts**. Bumping novelty from 10% to 50% does make the agent more willing to try new directions, but if the evaluator prompt doesn't clearly define "what makes good novelty," the agent oscillates between randomly renaming variables and genuinely restructuring modules. **Weights quantify "how important," but prompts define "what it is."**

Second, **the MetaAgent itself has decision quality problems**. It reads experiences from the ExperienceStore, analyzes trends, and outputs strategy — but if the experiences stored in early cycles are low-quality (because the evaluator wasn't calibrated yet), the MetaAgent's decisions will be biased. This is a **cold-start problem**: no good experiences → bad strategy → produces bad experiences → worse strategy. The mitigation: run the first several rounds with conservative default weights to build a foundation of quality experiences, then activate the MetaAgent.

**Resolution — V5's significance isn't "another version"**

Before V5, Harness was an **executor** — it ran fast, modified well, but "which direction" and "how to judge" were set by humans. After V5, it begins to have a **sense of direction** — it remembers the roads it's traveled, knows which directions are worth revisiting, can see when it's circling the same spot, and occasionally ventures down a new path.

But ultimately, **who defines "good"** — V5 only pushes this question one step further, it doesn't answer it. The MetaAgent can adjust weights, but weights are attached to five dimensions that humans designed. The day the agent proposes a sixth dimension on its own — that's the real inflection point.

**New V5 files**:

| File | Role | Replaces |
|---|---|---|
| `harness/evaluation/multi_axis.py` | 5-dim vector evaluator | dual_evaluator (backward-compatible) |
| `harness/core/experience.py` | Structured experience memory | memory.py (JSONL logbook) |
| `harness/pipeline/meta_agent.py` | Strategy layer: analyze trends, adjust direction | None (entirely new capability) |
| `harness/core/eval_config.py` | Hot-reload config: prompts + weights from disk | None (replaces hardcoded imports) |
| `harness/tools/self_config.py` | Agent self-awareness tool | None (entirely new capability) |

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
├── auto_tag_at_end: true          #   Force tag on every exit
├── evaluation_engine: "multi_axis"# V5 Evaluation engine ("dual" or "multi_axis")
├── exploration_interval: 3        # V5 Exploration round frequency (0=off)
├── meta_agent_interval: 5         # V5 Strategy layer frequency (0=off)
└── eval_weights: {correctness:0.35,...} # V5 Multi-axis weights

EvalVector (V5)                    # Multi-axis evaluation vector
├── correctness: float             #   Correctness (0-10)
├── code_quality: float            #   Code quality (0-10)
├── arch_health: float             #   Architecture health (0-10)
├── novelty: float                 #   Novelty vs prior code (0-10)
└── alignment: float               #   Strategic alignment (0-10)

Experience (V5)                    # Structured experience entry
├── eval_vector: [float]           #   Multi-axis evaluation vector
├── action_summary: str            #   What was done
├── reflection: str                #   LLM self-reflection
├── abstraction: str               #   Extracted reusable pattern
├── tags: [str]                    #   Searchable tags
└── was_reverted: bool             #   Whether the change was rolled back

MetaStrategy (V5)                  # MetaAgent output
├── focus_axis: str                #   Priority optimization dimension
├── adjust_weights: dict           #   Weight adjustments
├── exploration_frequency: int     #   Exploration frequency recommendation
└── reasoning: str                 #   Strategy reasoning

InnerResult                        # Single attempt result
├── proposal: str                  #   LLM's proposal or changes
├── eval_vector: EvalVector (V5)   #   Multi-axis evaluation (V4: dual_score)
│   ├── basic: (score, critique)   #     Defect evaluation (V4 legacy)
│   └── diffusion: (score, critique)#    Ripple effects (V4 legacy)
└── tool_call_log: [dict]          #   Tool call records

PhaseResult                        # Phase result
├── synthesis: str                 #   Synthesized final proposal
├── best_score: float              #   Highest score (weighted average)
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
| `harness/evaluation/dual_evaluator.py` | Quality gate | Two LLMs score in parallel, pick the best proposal (V4) |
| `harness/evaluation/multi_axis.py` | **V5 Multi-axis eval** | 5-dim vector replaces single score |
| `harness/core/experience.py` | **V5 Experience memory** | Structured memory: record + reflect + abstract + retrieve |
| `harness/pipeline/meta_agent.py` | **V5 Strategy layer** | Every N rounds, analyzes trends, adjusts weights & exploration frequency |
| `harness/core/eval_config.py` | **V5 Hot-reload** | Evaluator prompts + weights loaded from disk every call |
| `harness/tools/self_config.py` | **V5 Self-awareness** | Lets the agent discover its own config file paths |
| `harness/tools/registry.py` | Tool dispatch | Registration, param validation, exception wrapping |
| `harness/tools/base.py` | Tool security | `_check_path` workspace boundary enforcement |
| `harness/pipeline/hooks.py` | Verification | Syntax check + git commit (rich metadata) |
| `deploy/harness.service` | Deployment | systemd user service definition |
| `.github/workflows/deploy.yml` | CI/CD | Tag-triggered: smoke test → deploy → restart/rollback |
| `deploy/heartbeat.sh` | Keepalive | Restart after 3-strike systemd failure |

---

## One-Paragraph Summary

> Feed project code to an LLM, let it analyze and improve, using tools to read and edit files. A separate LLM call judges the quality; only the best proposals get committed. Multiple rounds iterate, each building on the improved code from the previous round. Because Python modules are loaded once at startup and frozen in memory, the process must restart every N rounds for improvements to take effect. Restart is driven by git tags triggering a GitHub Actions workflow that SSH-deploys and restarts the service — forming an unattended self-improvement loop. V5 introduces multi-axis evaluation (5-dim vector replacing a single score), structured experience memory (not just logging what happened, but distilling what was learned), an exploration mechanism (occasionally venturing bold new directions), and a strategy layer (MetaAgent periodically analyzes trends, adjusts evaluation weights and exploration frequency — the agent can, for the first time, change the standards by which it is judged). The tool system (30+ file/search/execution tools) is essentially safety gloves for the LLM — a single `bash` tool could do everything, but it would be less safe and more expensive.
