+++
date = '2026-04-25T12:00:00+08:00'
draft = false
title = '[Project] 6. Parallel Evolution — A Record of AI Collaboration Between Skills and Harness'
featuredImage = "/images/Project%20-%206%20-%20Parallel%20Evolution/cover.png"
categories = ["Project"]
tags = ["AI", "Claude Code", "Workflow", "Self-Improvement", "DeepSeek", "Anthropic", "Architecture"]
+++

## Overview

Since the start of this year, I've been using AI intensively (Claude Code in particular) to help with many projects and write a lot of software. Over this time, my understanding of how a programmer should work with AI has gone through stage after stage. There's a lot in my head, and I want to write it down to help myself reflect and synthesize.

### Dimensions of the Journey

Several parallel threads have been evolving in my understanding of AI:
- **Methodology**: From manual prompting → a skills system → an orchestrator pattern, gradually forming a reusable development workflow
- **Engineering**: From "let AI help me write code" to "let AI improve its own code" — the boundary keeps expanding
- **Cognition**: The more I use it, the less it feels like a "tool" and more like a partner that needs continuous collaboration and mutual growth

## Background

### The Moment

Before this year, I had been using AI to help with various things — honestly, just keeping up with the field, knowing a bit about everything. It was when OpenClaw took off that I realized what I had always wanted to do was finally here — or rather, someone had built the prototype.

What I wanted was simple: **put project information, personal preferences, and shared conventions into a single base file, and have it automatically injected into the context every time I use AI**. I'd never been able to make this happen before — the barrier was too high, I couldn't push it through at work. When Claude Code introduced skills and commands, I realized: this is exactly it.

### Claude Code's UX Leap

The experience upgrade from Claude Code was undeniable:
- Self-orchestration capabilities — it could do holistic analysis
- Smarter context management
- Sub-agent support made parallel tasks truly usable

Everyone who used it agreed. And it became the foundation for everything that followed.

With this foundation, I started bringing my ideas to life step by step. The first project was the Skills repository.

## Project One: The Skills Repository

### Phase 1 — The Manual Prompt Era

Before this, every AI interaction meant typing similar prompts by hand. The workflow was:
1. Tell AI the project background
2. Tell AI what to do
3. Manually specify output format

Repeating this every time was both stupid and tedious. This phase generated no documentation — there wasn't even an awareness of "tooling." I was just using.

Once I realized the problem, I decided to codify these repetitive prompts. The first attempt was to write the entire workflow as a single monolithic skill.

### Phase 2 — The Monolithic `req` Is Born

#### First Version Structure

The first formal commit of the skills repository included:

```
req/SKILL.md               ← Orchestrator, 6-stage linear flow
req-1-analyze/SKILL.md     ← Requirement analysis
req-2-tech/SKILL.md        ← Technical design
req-3-code/SKILL.md        ← Implementation (with java.md / python.md)
req-4-review/SKILL.md      ← Requirement review
req-5-verify/SKILL.md      ← Verification
req-6-done/SKILL.md        ← Archive
create-skill/SKILL.md      ← Utility tool
_shared/plantuml.md        ← Shared conventions
```

#### Six-Stage Linear Flow

<img src="/images/mermaid/evolution-en-1.svg" alt="Six-stage linear flow" style="max-width:100%;">

**Figure 3.2 — First version six-stage linear flow (fixed order, user confirmation at each stage)**

#### The First Taste of Natural Language Programming

The first time I specified "always write requirement documents in a fixed directory, auto-numbered," and it actually understood and followed the convention every time — **that was the first time I truly felt the difference between natural language programming and traditional programming**.

Document structure:
```
requirements/
├── index.md                ← Overview and status tracking
├── REQ-001-xxx/
│   ├── requirement.md      ← Requirement document
│   └── technical.md        ← Technical document
└── REQ-002-xxx/
    └── ...
```

The value of this convention: requirement documents become the "contract" for each REQ, enabling traceable comparisons across any future iteration.

### Phase 3 — Multi-REQ Modularization

#### The Motivation to Split

As I learned more about skills, I woke up: **why keep the monolithic skill?** Each stage has its own rules and output requirements. The single file was getting bloated and hard to maintain. A major refactor followed: 19 new files, nearly a thousand lines changed.

#### Eight-Stage Pipeline

The split resulted in this structure:

<img src="/images/mermaid/evolution-en-2.svg" alt="Eight-stage flow with dual-agent debate" style="max-width:100%;">

**Figure 3.3 — Eight-stage flow with dual-agent debate mechanism**

#### Dual-Agent Debate in Practice

This phase introduced **dual-agent adversarial debate** for requirement analysis and technical design:
- **MVP Agent**: Argues for minimum viable product — constrain scope, ship fast
- **Full-Feature Agent**: Argues for complete features — no technical debt
- **Judge Agent**: Synthesizes the best of both after multi-round debate

The synthesized proposals were often genuinely good. But this pattern later revealed its problem: **it's slow, and most small features don't need debate at all**.

#### Shared Standards Directory

This phase established the `_shared/` directory, which became the shared convention for all skills:

<img src="/images/mermaid/evolution-en-3.svg" alt="_shared shared conventions" style="max-width:100%;">

**Figure 3.4 — _shared conventions system**

### Phase 4 — The Orchestrator `req`

#### From Fixed Pipeline to Intelligent Orchestration

This was the most important evolution. The `req` role upgraded from a "strict sequential pipeline" to a **"decision-maker that chooses what to do based on the task"**.

The core change: **remove all stage numbers, remove the fixed execution order, let the orchestrator decide which stages to run based on the task**.

<img src="/images/mermaid/evolution-en-4.svg" alt="Orchestrator pattern" style="max-width:100%;">

**Figure 3.5 — Orchestrator pattern: classify → triage → plan → execute**

#### Task Classification

The orchestrator first classifies input into five categories:

| Scenario | Description | Typical Example | Handling |
|:---|:---|:---|:---|
| **A — Trivial** | Too small for a REQ | Rename variable, add logging, change config | Execute directly |
| **B — New REQ** | Independent feature | Implement login, integrate payments | Create new REQ, full pipeline |
| **C — Amend (Spec Change)** | Same goal, different direction | "Switch to OAuth", "Change TTL to 7 days" | Amend existing REQ |
| **D — Amend (Bug)** | Implementation defect | "Token parsing fails" | Amend → fall back to code stage |
| **E — Ambiguous** | Extension or new REQ? | Add "remember me" to completed login REQ | Check status, then decide |

#### Stage Skip Conditions

Each stage has clear skip criteria:

| Stage | Skip Condition |
|:---|:---|
| analyze | User already provided complete spec (rare) |
| tech | Change direction is purely mechanical (delete/move/rename) |
| security | No new attack surface: pure refactor, deletion, internal config |
| cleanup | The change itself IS cleanup, or total scope ≤ 3 files |
| review | Scope ≤ 3 files and no functional change |
| verify | Pure refactor/deletion, existing tests sufficient |
| **code / done** | **Never skipped** |

#### The Lightweight Task Skill

Around April 2, I added the `task` skill — a lightweight workflow for tasks that don't need the full REQ pipeline.

<img src="/images/mermaid/evolution-en-5.svg" alt="Task skill" style="max-width:100%;">

**Figure 3.6 — Task skill: analysis happens in conversation, reuses req sub-skills for execution**

This phase also added:
- **Per-stage git tags** (`REQ-xxx-analyzed/designed/coded`)
- **TDD-first** (write acceptance tests before implementation in req-code)
- **Parallel sub-agent** support (independent modules, parallel development)
- **Batch archive** via req-archive skill

#### Structural Comparison

<img src="/images/mermaid/evolution-en-6.svg" alt="Fixed pipeline vs Smart orchestrator" style="max-width:100%;">

**Figure 3.7 — Fixed pipeline vs Smart orchestrator**

### Phase 5 — Current State and Reflection

#### Why I Use It Less Now

Recently, I haven't been using `req` as much myself. The main reasons:

**Where it's slow — Dual-agent debate overhead**

The core bottleneck of the full pipeline is **dual-agent debate**. Both requirement analysis and technical design default to MVP vs full-feature adversarial debate. Each round launches multiple sub-agents, waits for them to finish, aggregates, and asks the user to choose. For a major feature this is well worth it, but most daily tasks just need "analyze it and produce a plan."

The real solution is **intent recognition + tiered processing**:

<img src="/images/mermaid/evolution-en-7.svg" alt="Intent recognition + tiered decision tree" style="max-width:100%;">

**Figure 3.8 — Intent recognition + tiered processing decision tree**

- **Large feature / uncertain direction** → debate mode, multi-agent exploration
- **Small feature / clear direction** → direct analysis, no debate
- **Pure mechanical changes (rename, delete, config)** → don't even use req, just the task skill

The current `req-analyze` and `req-tech` stages already have triage (fast path vs deep path), but the early versions didn't. In hindsight, if I'd tiered by task size from the start instead of forcing debate on everything, the "slowness" perception would be much milder.

**Company AI tool limitations**

The AI tools provided at work don't support sub-agents well: sub-agents can't report progress back, users can't see the execution order, and running multiple agents in parallel feels like working in a black box. This makes complex orchestration a worse experience in the corporate environment, so naturally I use it less there.

#### The Long-Term Value of Skills

Nevertheless, I strongly recommend everyone maintain their own set of skills:

- **Reusable**: Write once, use everywhere — no more manual prompting
- **Evolves with you**: Skills keep improving as your understanding of AI deepens
- **A reflection of your AI literacy**: The quality of a person's skills files almost directly reflects their depth of understanding about AI collaboration

<img src="/images/mermaid/evolution-en-8.svg" alt="Complete evolution state diagram of Skills repository" style="max-width:100%;">

**Figure 3.9 — Complete evolution of the Skills repository**

- GitHub: [GOODDAYDAY/my-skills](https://github.com/GOODDAYDAY/my-skills)
- Detailed post: [Project 5. My Skills — Enterprise Development Workflows as Executable Claude Code Skills](https://gooddayday.github.io/en/2026/04/project-5.-my-skills/)

While Skills was evolving, I was actually working on another project on the side — **Harness-Everything**. Its goal was completely different: Skills was about "how AI helps me write code," while Harness was about "can AI improve its own code." Two independent projects, running in parallel without interfering with each other. Until one day I looked back and realized they had traced strikingly similar paths.

## Project Two: Harness-Everything

- GitHub: [GOODDAYDAY/Harness-Everything](https://github.com/GOODDAYDAY/Harness-Everything)
- Detailed post: [Project 3. Harness-Everything — Autonomous AI Code Improvement Harness](https://gooddayday.github.io/en/2026/04/project-3.-harness-everything/)

### Core Idea in One Sentence

> Feed project code to an LLM, let it analyze, improve, and write code; use tools to read and write files; another LLM call judges quality; iterate multiple rounds, each building on the improved code from the previous round. Because Python modules are loaded once in memory and frozen, the process must restart every N rounds for improvements to take effect — triggered by git tags via CI/CD, forming an unattended self-improvement loop.

This layered model captures the system:

<img src="/images/mermaid/evolution-en-9.svg" alt="Each layer solves the previous layer's problem" style="max-width:100%;">

**Figure 4.1 — Each layer solves the previous layer's problem**

### Phase 1 — Minimal First Version

#### Origin

The first snapshot contained the complete initial architecture:

```
harness/
├── llm.py              ← Tool call core loop (the critical 60 lines)
├── config.py           ← Configuration management
├── dual_evaluator.py   ← Dual evaluator
├── phase.py            ← Phase definitions
├── phase_runner.py     ← Phase executor
├── pipeline.py         ← Pipeline management
├── hooks.py            ← Syntax check + git commit
├── tools/              ← 30+ tools
│   ├── base.py         ← Path security (_check_path)
│   ├── bash.py
│   ├── directory.py
│   └── ...
└── prompts/            ← LLM instruction templates
```

#### The Golden Age When All Code Fit in Context

The first version's biggest advantage: **the codebase was small enough to fit entirely in an LLM's context window**.

This was a brief golden age — the LLM could see the entire project at once, understand the big picture, and make systemic improvements. This is why the first version's output quality was quite good.

<img src="/images/mermaid/evolution-en-10.svg" alt="First version complete data flow" style="max-width:100%;">

**Figure 4.2 — First version data flow: from config to code commit**

### Phase 2 — Fixed Orchestration (R1/R2)

#### Three-Stage Fixed Pipeline

Rounds 1 and 2 used a fixed three-stage pipeline:

<img src="/images/mermaid/evolution-en-11.svg" alt="R1/R2 fixed three-stage orchestration" style="max-width:100%;">

**Figure 4.3 — R1/R2 fixed three-stage orchestration**

The commit log shows the clear pattern:
```
harness: R1 bug_fix
harness: R1 new_tools_and_features
harness: R1 quality_polish
harness: R2 bug_fix
harness: R2 new_tools_and_features
...
```

#### Why It Started Going Wrong

The fixed orchestration's problems emerged quickly:
- **The LLM didn't know the overall goal**, only the current stage's name
- **Blurry boundaries between stages**: `quality_polish` and `bug_fix` blurred together
- **Code kept growing**, no longer fitting in context — the LLM worked on fragments without global awareness
- **No coherence between rounds**: decisions from one stage were unknown to the next

The most emblematic problem: the LLM refactored a file in R2, but R3's LLM didn't know about it, refactored the same logic differently, and reverted the improvement.

The root cause was that fixed orchestration was too rigid. I realized that instead of telling the LLM "do bug_fix first, then polish," I should let it read the code itself and decide what to improve. That's what drove the R3 architecture refactoring.

### Phase 3 — Self-Orchestration (R3 through cycle 67)

#### Architecture Refactoring

On April 16, R3 was a major restructuring (single commit: 1489 lines deleted, 169 lines added):

<img src="/images/mermaid/evolution-en-12.svg" alt="R3 architecture refactoring" style="max-width:100%;">

**Figure 4.4 — R3 architecture refactoring: from monolithic files to separated concerns**

#### Removing Debate, Letting the Agent Think

R3 also removed the built-in debate mechanism, letting the agent decide what to improve:

<img src="/images/mermaid/evolution-en-13.svg" alt="From fixed debate to self-directed orchestration" style="max-width:100%;">

**Figure 4.5 — From fixed debate to self-directed orchestration**

The cycle log from April 23 shows the maturity of self-orchestration:
- 67 cycles, each where the agent decided what to change
- Tests grown automatically from zero to 2700+ (written by the agent itself)
- Continuous code optimization with increasingly clean architecture

#### What Worked and Where It Hit a Ceiling

**What worked well**:
- Test coverage improved significantly (every round added tests)
- Code quality continuously increased (lint-clean, deduplication)
- Tool system grew from 30 to 35 specialized tools

**What it couldn't do**:
- **True self-evolution**: the LLM could modify code, but couldn't change its own "way of thinking"
- **Architectural innovation**: changes were always optimizations within existing structures, never spontaneous new architectures
- **Cross-iteration coherence**: each cycle's LLM was independent, with no memory across rounds

#### Root Cause Analysis of Slow Iteration

The biggest feeling running it now: **iteration keeps getting slower**. On the surface it looks like code stabilization, but the root cause is elsewhere.

Two core problems:
- **Inadequate evaluation signals**: the dual evaluator's scores became flat, unable to distinguish "okay" from "genuinely good." Without good evaluation signals, the agent doesn't know where to optimize, so it just polishes within existing structures
- **No new business driving it**: when the agent just improves freely, it only does subtraction (optimize, clean, add tests). It can't do addition (new features, new capabilities). Without business requirements driving it, the improvement space naturally narrows

### Phase 4 — Metrics-Driven

Addressing the two core problems just mentioned, the first batch of metrics-driven components has been landed:

#### Components Built

<img src="/images/mermaid/evolution-en-14.svg" alt="Direction-driven + metrics closed loop" style="max-width:100%;">

**Figure 4.6 — Direction-driven with metrics closed loop**

Components landed:

| Module | Purpose |
|:---|:---|
| `harness/pipeline/intel_metrics.py` | Cross-cycle intelligence metrics collection and analysis |
| `harness/agent/cycle_metrics.py` | Per-cycle granular metrics (context quality, memory & learning, etc.) |
| `benchmarks/evaluator_calibration/` | Evaluator calibration benchmarks — test evaluator accuracy with proposals of varying quality |

Core idea: don't let the agent decide "what to improve" in a vacuum:
1. **Human gives direction**: define the business goal and approach first, let the agent implement
2. **Generate metrics**: the implementation produces quantifiable indicators (test coverage, quality score, performance data)
3. **Metrics closed loop**: use the metrics to drive ongoing improvement — the evaluation now has real anchor points

With this, the evaluator has concrete targets to judge against, and the agent gets concrete feedback on what it did right — rather than free-improving in a vacuum.

For reference, here's the capability distribution at cycle 67 — the metrics system aims to push all points toward the upper right:

<img src="/images/mermaid/evolution-en-15.svg" alt="Harness capability quadrant chart" style="max-width:100%;">

**Figure 4.7 — Harness self-improvement capability distribution across task types (cycle 67 baseline)**

### Four-Version Evolution Timeline

<img src="/images/mermaid/evolution-en-16.svg" alt="Harness four-version evolution timeline" style="max-width:100%;">

**Figure 4.8 — Harness four-version evolution timeline**

Harness had gone through four phases, Skills had gone through five. On the surface, they look like two unrelated technical stories — nothing special. But when I laid the timelines side by side, I found something I never expected.

## The Convergence

### The Strikingly Parallel Trajectory

Skills and Harness are two projects started independently to solve different problems — one manages development workflow, the other manages code self-improvement. But when you lay their evolutionary stages side by side:

| Stage | Skills | Harness |
|:---|:---|:---|
| **First version** | Fixed 6-stage pipeline, hardcoded order | Fixed 3-stage pipeline (bug_fix → features → polish) |
| **Modular split** | Split into 8 independent sub-skills, each with its own rules | Split into separated-concern modules (phase_runner / evaluator / pipeline) |
| **Orchestration upgrade** | Removed numbering, orchestrator observes filesystem and dispatches | Removed fixed debate, let the agent decide what to change |
| **Current** | Stable, continuously iterating | Metrics-driven: intel_metrics, cycle_metrics, benchmarks landed |

Two projects, without knowing about each other's design, walked almost the same path:

<img src="/images/mermaid/evolution-en-17.svg" alt="Skills and Harness evolved through the same stages" style="max-width:100%;">

**Figure 5.1 — Skills and Harness experienced the same evolutionary stages**

### What This Pattern Reveals

**The orchestrator pattern isn't a project-specific design. It's a universal paradigm.**

Whether orchestrating a development workflow or a code improvement loop, the core structure is the same: an observer reads current state, a decision-maker determines what to do next, and executors carry it out. Skills' req orchestrator observes the filesystem; Harness' pipeline observes the code repository. Skills' sub-skills are requirement analysis, technical design, coding; Harness' execution units are tool calls and code modifications. **Different abstraction layers, the same pattern.**

This pattern wasn't designed — it emerged from iteration. Both projects started with fixed pipelines because that's the fastest way to get running, and only evolved into orchestrators when hardcoding stopped working. Which tells you something: **if you have a project that needs continuous iteration, its architecture will grow itself. You don't need to design it perfectly upfront.**

### Why You Need a Long-Term Personal Project

This is the single most important suggestion in this entire document:

**Having a long-term personal project is the measure of your AI understanding.**

Three reasons:

1. **Insights crystallize into code** — every thought about "how AI should do X" can be written into a skill or a tool. Vague intuition from three months ago becomes executable instructions three months later. Without a project to carry them, those insights stay in your head and gradually fade.

2. **Patterns emerge through iteration** — the parallel evolution of Skills and Harness isn't coincidence. If you only build one project, you think "that's just how my architecture turned out." Build two, and you see the underlying law. This kind of insight only comes from long-term iteration.

3. **The project becomes a collaboration history** — scroll through git log and you can see how your AI collaboration evolved: at first the AI only wrote code snippets, then entire modules, then it started improving its own code. This record is more convincing than any summary article.

The Skills repository has a `docs/evolution.md` file — a written record of this evolutionary process. Its purpose isn't for others to read; it's for me to look back at — to see how I thought about AI three months ago, and whether I've improved since.

### Open Questions

The convergence of these two lines also leaves some questions I haven't figured out:

- **Where's the orchestrator ceiling?** Both Skills and Harness reached the "orchestrator dispatches on demand" pattern, and both hit boundaries. Does the orchestrator pattern itself have a fundamental upper limit?
- **Cross-project pattern reuse**: the pattern Skills revealed (fixed pipeline → split → orchestration) — can it be proactively applied to the next project, rather than discovered after the fact?
- **Personal vs team projects**: a personal project can iterate freely and refactor aggressively. Team projects have compatibility burdens. How do AI collaboration patterns validated on personal projects scale to large teams?

## Personal Reflections

### Maintain Your Own Skills

I strongly recommend every long-term Claude Code user maintain their own skills repository:
- **No more manual typing**: once a skill is written, everything after is just invocation
- **Grows with you**: as your technical understanding improves, your skills upgrade with it
- **A reflection of your AI literacy**: the quality of a person's skills almost directly reflects their depth of AI collaboration understanding
- **Shareable**: well-written skills can be shared and become team assets

### AI Demands More from Programmers, Not Less

A common misconception is that "AI makes programming easier." My actual experience is the opposite:
- AI's ceiling is your ceiling — if you can't think clearly, AI is more likely to think wrongly on your behalf
- **You need stronger comprehension**: you must quickly judge whether AI output is correct — this requires solid fundamentals
- **You need stronger articulation**: a fuzzy prompt means the AI guesses; when it guesses wrong, it's still your fault
- **System design matters more**: AI can write functions, but it can't decompose good module boundaries — that's your job

AI is a multiplier, not an adder. If your foundation is weak, multiplying it still leaves you weak.

### Choose Your Employer for AI Resources

One final practical suggestion: **make sure you join a company that provides unrestricted access to quality AI**.

The AI tooling experience varies dramatically:
- Token limits vs unlimited: completely different workflows
- High-quality vs low-quality models: the output quality gap is enormous
- Sub-agent support vs none: the difference between being able to do complex orchestration or not

If your company's AI resources are constrained, it severely hampers the kind of workflow evolution described above. When evaluating job opportunities, the quality and availability of AI tooling deserves serious consideration.

### Current Open Questions

Questions I'm still thinking about, with no answers yet:

- **Where's the boundary for skills?** When does a skill become too heavy, and should be replaced by a lighter-weight conversation?
- **How far can metrics-driven go?** intel_metrics, cycle_metrics, benchmarks — just getting started. Will they break through the ceiling or hit new limits?
- **Natural language programming maturity**: when can we write zero code and only prompts?
- **AI in team collaboration**: how do you standardize skills and prompt engineering across a team?
