+++
date = '2026-04-17T13:00:00+08:00'
draft = false
title = '[Project] 4. Multi-Agent AI Investment Research — 16 Agents with Bull-vs-Bear Debate'
categories = ["Project"]
tags = ["AI", "LLM", "Multi-Agent", "LangGraph", "DeepSeek", "Investment", "Quant", "Python"]
+++

## One-Line Summary

16 specialized AI agents analyze a stock from every angle — macro, sector, fundamentals, technicals, sentiment, news, filings — then two agents debate bullish vs bearish cases while a judge moderates. Final buy/hold/sell recommendation backed by recomputable numbers. Supports Chinese A-shares, Hong Kong, and US equities.

## System Overview

{{< mermaid >}}
graph TD
    USER[User Query<br/>natural language] --> ORCH[Orchestrator<br/>intent classification + security]
    
    ORCH --> PARALLEL["Parallel Data Collection (6 paths)"]
    
    PARALLEL --> MD[Market Data<br/>yfinance]
    PARALLEL --> MACRO[Macro Environment<br/>CSI 300 / Hang Seng]
    PARALLEL --> SECTOR[Sector Analysis<br/>industry rankings]
    PARALLEL --> NEWS[News Collector<br/>multi-source dedup]
    PARALLEL --> ANN[Announcements<br/>akshare filings]
    PARALLEL --> SOCIAL[Social Sentiment<br/>Eastmoney forums]
    
    MD --> ANALYSIS[Sequential Analysis]
    MACRO --> ANALYSIS
    SECTOR --> ANALYSIS
    NEWS --> ANALYSIS
    ANN --> ANALYSIS
    SOCIAL --> ANALYSIS
    
    ANALYSIS --> SENT[Sentiment Analysis<br/>LLM per-article scoring]
    SENT --> FUND[Fundamental Analysis<br/>PEG / DCF valuation]
    FUND --> MOM[Momentum Analysis<br/>multi-horizon returns]
    MOM --> QUANT[Quant Signals<br/>pure math, no LLM]
    QUANT --> GRID[Grid Strategy<br/>fee-aware calculator]
    
    QUANT --> DEBATE[Bull vs Bear Debate]
    GRID --> DEBATE
    
    DEBATE --> JUDGE{Debate Judge<br/>quality sufficient?}
    JUDGE -->|continue| DEBATE
    JUDGE -->|sufficient| RISK[Risk Assessment]
    
    RISK --> ADV[Advisory Agent<br/>synthesis + numeric override]
    ADV --> FILTER[Output Security Filter<br/>audit trail]
    FILTER --> RESULT[Buy / Hold / Sell<br/>+ full reasoning chain]
    
    style ORCH fill:#4A90D9,color:white,stroke:none
    style QUANT fill:#50C878,color:white,stroke:none
    style DEBATE fill:#E74C3C,color:white,stroke:none
    style JUDGE fill:#FF8C42,color:white,stroke:none
    style ADV fill:#9B59B6,color:white,stroke:none
{{< /mermaid >}}

## Core Design: Why 16 Agents?

Ask a single LLM "should I buy this stock?" and you get:

- **Hallucination**: Made-up financial data
- **Tunnel vision**: Only technical analysis, or only fundamentals
- **Unverifiable**: No numeric evidence behind the claim

So we split into 16 specialized agents, each doing one thing, **using real data instead of LLM-generated data**:

| Agent | Data Source | Uses LLM? |
|---|---|---|
| Market Data | yfinance API | No |
| Macro Environment | CSI 300 / Hang Seng index | No |
| Sector Analysis | akshare sector rankings | No |
| News Collector | yfinance + DuckDuckGo | No |
| Announcements | akshare Caixin/Eastmoney | No |
| Social Sentiment | Eastmoney forum scores | No |
| Sentiment Analysis | News from above | **Yes** |
| Fundamental Analysis | Financial data from above | **Yes** |
| Momentum Analysis | Multi-horizon returns | No |
| **Quant Signals** | MA/RSI/MACD/Bollinger/ATR/OBV | **No (pure math)** |
| Grid Strategy | Volatility + fee model | No |
| Bull Debater | All data from above | **Yes** |
| Bear Debater | All data from above | **Yes** |
| Debate Judge | Debate content | **Yes** |
| Risk Assessment | All data from above | **Yes** |
| Advisory | All data from above | **Yes** |

**Only 6 of 16 agents use LLM calls. The rest are deterministic.** The LLM's role is "analyst", not "data source".

## Highlight 1: Bull-vs-Bear Debate Engine

Instead of one LLM saying "bullish" or "bearish", **two LLMs argue against each other**:

{{< mermaid >}}
sequenceDiagram
    participant Bull as Bull Agent
    participant Bear as Bear Agent
    participant Judge as Debate Judge

    Note over Bull,Bear: Round 1: Opening statements
    Bull->>Judge: 3 bullish arguments + data evidence
    Bear->>Judge: 3 bearish arguments + data evidence
    
    Judge->>Judge: Assess: argument quality sufficient?
    
    Note over Bull,Bear: Round 2: Cross-rebuttals
    Bull->>Judge: Rebut Bear's points + additional evidence
    Bear->>Judge: Rebut Bull's points + additional evidence
    
    Judge->>Judge: Assess: ready for conclusion
    Judge-->>Bear: Stop debate
    
    Note over Judge: Output: Bull strength 65% / Bear strength 35%
{{< /mermaid >}}

**Key constraint**: Both sides must cite real data from the Quant agent (RSI, MACD, valuations) — no abstract arguments allowed. The judge checks argument quality and demands additional rounds if insufficient.

## Highlight 2: Pure-Math Quant Referee

The Quant agent makes **zero LLM calls** — classical technical analysis computed deterministically:

```
Composite = MA_trend(25%) + RSI(15%) + MACD(20%) + Bollinger(10%)
            + ATR_volatility(10%) + Stochastic(10%) + OBV_volume(10%)

Output: score from -100 to +100
```

This score is **immune to LLM hallucination**. The Advisory agent applies **numeric override** when LLM judgment conflicts with the math:

```python
if quant_score > 60 and llm_says == "sell":
    advisory = "Strong bullish math signal, but LLM suggests sell. Note the divergence."
```

## Highlight 3: Grid Trading Strategy

Automatically calculates feasibility and expected returns for 4 grid variants:

| Strategy | Grid Spacing | Scenario |
|---|---|---|
| Short-term | ATR x 0.3 | Intraday oscillation |
| Medium-term | ATR x 0.8 | Weekly swing trading |
| Long-term | ATR x 1.5 | Monthly positioning |
| Accumulation | ATR x 2.0 | Bottom accumulation |

Calculations include **real A-share fees** (stamp tax 0.05% + broker commission 0.025%), 100-share lot sizing (regulatory minimum), and monthly return estimates based on volatility-driven cycle frequency.

## Highlight 4: Explainability

Every agent's reasoning is captured in `reasoning_chain`. Users see the full decision path:

{{< mermaid >}}
graph LR
    R1[Market Data<br/>+12% in 20 days] --> R2[Momentum<br/>broke 60-day MA]
    R2 --> R3[Quant Signal<br/>composite +45]
    R3 --> R4[Fundamentals<br/>PEG=0.8 undervalued]
    R4 --> R5[Bull wins<br/>strength 65%]
    R5 --> R6[Risk: moderate<br/>4/10]
    R6 --> R7[Recommendation: Buy<br/>confidence 72%]
    
    style R3 fill:#50C878,color:white,stroke:none
    style R7 fill:#4A90D9,color:white,stroke:none
{{< /mermaid >}}

Every number (PEG, DCF, quant score, momentum) is recomputable from raw data — not LLM-generated, but calculated from real market data.

## Data Sources: All Free, China-Accessible

| Source | Coverage | Usage |
|---|---|---|
| **yfinance** | Global (US/HK/A-shares) | OHLCV, financials, news |
| **akshare** | Chinese A-shares | Filings, forum sentiment, sector rankings |
| **DuckDuckGo** | Global | News search |
| **DeepSeek** | LLM | Analysis reasoning (Anthropic-compatible API) |

No Bloomberg, Wind, or paid terminals required.

## Security Architecture

{{< mermaid >}}
graph LR
    INPUT[User Input] --> SAN[Input Sanitizer<br/>length cap + injection detection]
    SAN --> PII[PII Redactor<br/>phone/ID/credit card]
    PII --> AGENTS[16 Agents process]
    AGENTS --> OUTF[Output Filter<br/>remove system prompt leaks + suspicious URLs]
    OUTF --> AUDIT[Audit Log<br/>AuditKind enum]
    AUDIT --> UI[User Interface]
    
    style SAN fill:#E74C3C,color:white,stroke:none
    style PII fill:#E74C3C,color:white,stroke:none
    style OUTF fill:#E74C3C,color:white,stroke:none
{{< /mermaid >}}

- **Input**: Length limits, control character stripping, prompt injection detection
- **Output**: PII redaction, system prompt leak filtering, suspicious URL blocking
- **Audit**: Every security event logged with AuditKind (INPUT_BLOCKED / OUTPUT_FILTERED)
- Token usage tracking per request for cost visibility

## Deployment

| Platform | Method | One command |
|---|---|---|
| Windows | Double-click `run.bat` | Auto-installs uv + Python + deps |
| Linux | `bash deploy/install_linux.sh` | systemd service + daily timer |
| Email reports | QQ SMTP | Scheduled analysis to watchlist |

## Tech Stack

```
Language:        Python 3.11+
Agent framework: LangGraph (StateGraph, conditional edges, self-loops)
LLM:             DeepSeek (deepseek-chat) via OpenAI-compatible API
Market data:     yfinance + akshare
UI:              Streamlit
Email:           QQ SMTP_SSL (port 465)
Validation:      Pydantic v2
Package manager: uv (Rust-based)
Testing:         pytest (real API calls, no mocks)
Deployment:      systemd / Windows Task Scheduler
```

## Project Structure

```
backend/
  agents/           # 16 agent sub-packages
    orchestrator/    # intent classification + security
    market_data/     # market data (yfinance)
    quant/           # quant signals (pure math)
    debate/          # bull vs bear debate
    debate_judge/    # debate quality control
    advisory/        # final recommendation + numeric override
    ...
  security/          # input sanitizer / PII / output filter
  observability/     # token tracker / audit trail
  graph.py           # LangGraph StateGraph builder
  state.py           # ResearchState + Pydantic models
  llm_client.py      # DeepSeek wrapper
frontend/
  app.py             # Streamlit chat UI
deploy/
  install_linux.sh   # one-click Linux deployment
scripts/
  run.bat            # zero-dependency Windows launcher
  scheduled_analysis.py  # scheduled task entry
```

## One-Paragraph Summary

> A 16-agent investment research system. Six parallel collectors fetch real market data (no LLM-generated data), a pure-math Quant agent provides hallucination-immune signals, a Bull-vs-Bear debate engine forces two LLMs to argue with evidence while a judge controls quality, and the Advisory agent synthesizes all dimensions into a recommendation — with automatic numeric override when LLM judgment conflicts with math signals. The entire chain is explainable: every number is recomputable from raw data, and every decision step is traceable.
