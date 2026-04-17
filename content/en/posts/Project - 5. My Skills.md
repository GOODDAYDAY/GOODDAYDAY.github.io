+++
date = '2026-04-17T14:00:00+08:00'
draft = false
title = '[Project] 5. My Skills — Enterprise Development Workflows as Executable Claude Code Skills'
categories = ["Project"]
tags = ["AI", "Claude Code", "Workflow", "DevOps", "TDD", "Security", "Multi-Agent"]
featuredImage = "/images/Project%20-%205%20-%20My%20Skills/cover.png"
+++


## One-Line Summary

A complete requirement-driven development framework that turns the full software lifecycle — requirement analysis, technical design, coding, security audit, cleanup, compliance review, verification, and archival — into 8 executable skills for Claude Code, with checkpoint recovery and formal change management.

## Why This Exists

The biggest problem with AI-generated code isn't that it "can't write code" — it's that **it writes without discipline**:
- Starts coding before understanding requirements
- Makes a bunch of changes but can't tell if they're correct
- Interruptions mean starting over
- Security vulnerabilities go unchecked
- Requirements drift silently

This framework turns **software development best practices** into executable AI skills. Claude Code follows a structured process instead of winging it.

## 8-Stage Workflow

<img src="/images/mermaid/skills-en-1.svg" alt="diagram" style="max-width:100%;">

| Stage | Skill | What it does |
|---|---|---|
| 1. Requirement Analysis | `/req-analyze` | Break loose ideas into formal specs |
| 2. Technical Design | `/req-tech` | Architecture, module decomposition, PlantUML diagrams |
| 3. Implementation | `/req-code` | TDD + parallel agents + per-module commits |
| 4. Security Review | `/req-security` | 6-dimension vulnerability scanning |
| 5. Code Cleanup | `/req-cleanup` | Structural optimization without behavior changes |
| 6. Compliance Review | `/req-review` | Item-by-item requirement verification |
| 7. Verification | `/req-verify` | Build + test suite + E2E |
| 8. Archive | `/req-done` | Mark complete, generate milestone summary |

A central `/req` orchestrator routes work through the pipeline. Each stage can also run independently.

## Highlight 1: Diverge-Converge Decision Pattern

For complex design decisions, instead of one agent deciding, **three agents explore different directions in parallel**:

<img src="/images/mermaid/skills-en-2.svg" alt="diagram" style="max-width:100%;">

Three perspectives:
- **A (MVP)**: Cut to minimum viable, ship fast
- **B (Product)**: Think long-term, cover edge cases
- **C (Challenger)**: Identify the fundamental tension between A and B

Users see real tradeoffs instead of one agent's "I think we should do this".

## Highlight 2: Checkpoint Recovery

What happens when development is interrupted (shutdown, task switch, next day)?

```
/req REQ-003

System auto-checks:
  ✅ requirement.md exists → skip requirement analysis
  ✅ technical.md exists → skip technical design  
  ⚠️ src/ partially exists → resume coding, skip completed modules
  ❌ security review not done → continue from here
```

No starting over. Partial progress is preserved.

## Highlight 3: Formal Change Management

Documents **cannot be edited directly**. Changes go through a formal process:

<img src="/images/mermaid/skills-en-3.svg" alt="diagram" style="max-width:100%;">

- Declare affected scope **before** editing
- System auto-diffs to catch undeclared modifications (mismod detection)
- Changelog grows monotonically — each version adds a row, old rows never change

Most teams lack this rigor. If you've managed requirement changes on large projects, you know why it matters.

## Highlight 4: TDD is Built-In, Not Optional

The coding stage workflow:

```
1. Generate test cases from requirement acceptance criteria (tests first)
2. Implement code module by module (make tests pass)
3. Commit each module separately
4. All tests pass → proceed to security review
```

Tests aren't "something you add after coding". They're the **precondition** for coding.

## Highlight 5: Security Review is a Formal Stage

Not a code review comment. Not a linting tool. A **dedicated stage** scanning 6 dimensions:

| Dimension | What's checked |
|---|---|
| Injection | SQL, XSS, command injection |
| Auth & AuthZ | Permission checks, session management |
| Data Protection | Encryption, PII handling |
| Dependencies | Known CVEs, supply chain risks |
| Configuration | Hardcoded secrets, debug endpoints |
| Logging & Audit | Sensitive data leaking to logs |

Critical/High findings are fixed immediately. Medium/Low are presented to the user. Results documented and committed.

## Orchestration Architecture

<img src="/images/mermaid/skills-en-4.svg" alt="diagram" style="max-width:100%;">

**Key design**: The orchestrator owns all routing logic. Sub-skills are stateless executors — read context, do work, write results, return. This makes the system predictable and auditable.

## Project Structure

```
skills/
├── _shared/                # Shared standards (state machine, recovery, commits)
├── req/                    # Orchestrator — 8-stage workflow
├── req-analyze/            # Stage 1: Requirement analysis (diverge-converge)
├── req-tech/               # Stage 2: Technical design
├── req-code/               # Stage 3: Coding (TDD + parallel agents)
│   ├── python.md           # Python coding conventions
│   └── java.md             # Java coding conventions
├── req-security/           # Stage 4: Security review (6 dimensions)
├── req-cleanup/            # Stage 5: Code cleanup
├── req-review/             # Stage 6: Compliance review
├── req-verify/             # Stage 7: Build + test
├── req-done/               # Stage 8: Archive
├── req-amend/              # Formal change management
├── req-archive/            # Batch archive + milestone summaries
├── task/                   # Lightweight pipeline (no formal docs)
├── write-doc/              # Structured document authoring
├── create-skill/           # Guide for creating new skills
└── puml2svg/               # PlantUML to SVG converter
```

## One-Paragraph Summary

> An 8-stage development workflow turned into executable Claude Code skills, coordinated by a central orchestrator. Complex decisions use a diverge-converge pattern (three agents explore MVP, completionist, and challenger perspectives in parallel). Document changes go through formal change management with automatic out-of-scope modification detection. Interruptions are handled by checkpoint recovery that detects partial progress and resumes without redoing work. Tests are written before code, not after. Security is a formal stage, not a comment. The result: AI writes code with discipline instead of winging it.
