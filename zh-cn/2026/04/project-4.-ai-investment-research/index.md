# [Project] 4. 多智能体 AI 投资研究系统 — 16 个 Agent 的牛熊辩论与量化裁判



## 一句话介绍

用 16 个专业 AI Agent 对股票进行全方位分析：宏观、行业、基本面、技术面、舆情、新闻、公告,然后让两个 Agent 进行牛熊辩论,最后综合给出买入/持有/卖出建议。支持 A 股、港股、美股。

## 系统全景

<img src="/images/mermaid/invest-zh-1.svg" alt="diagram" style="max-width:100%;">

## 核心设计：为什么需要 16 个 Agent？

一个 LLM 直接问"这只股票能买吗",答案会怎样？

- **幻觉**：编造不存在的财务数据
- **片面**：只看技术面不看基本面,或反过来
- **无法验证**：没有数字依据,不知道对不对

所以拆成 16 个专业 Agent,每个只干一件事,**用真实数据而不是 LLM 编的数据**：

| Agent | 数据来源 | 用 LLM？ |
|---|---|---|
| 行情数据 | yfinance API | 否 |
| 宏观环境 | 沪深300/恒生指数 | 否 |
| 行业分析 | akshare 板块排名 | 否 |
| 新闻采集 | yfinance + DuckDuckGo | 否 |
| 公告收集 | akshare 财新/东财 | 否 |
| 社交舆情 | 东方财富股吧评分 | 否 |
| 情感分析 | 上面的新闻数据 | **是** |
| 基本面分析 | 上面的财务数据 | **是** |
| 动量分析 | 多周期收益率 | 否 |
| **量化信号** | MA/RSI/MACD/布林/ATR/OBV | **否（纯数学）** |
| 网格策略 | 波动率 + 费率模型 | 否 |
| 牛方辩手 | 上面所有数据 | **是** |
| 熊方辩手 | 上面所有数据 | **是** |
| 辩论裁判 | 辩论内容 | **是** |
| 风险评估 | 上面所有数据 | **是** |
| 投资建议 | 上面所有数据 | **是** |

**16 个 Agent 中只有 6 个用 LLM,其余全是确定性计算。** LLM 的角色是"分析师",不是"数据源"。

## 亮点 1：牛熊辩论引擎

不是让一个 LLM 说"看好"或"看空",而是**让两个 LLM 互相对辩**：

<img src="/images/mermaid/invest-zh-2.svg" alt="diagram" style="max-width:100%;">

**关键约束**：双方必须引用量化 Agent 的真实数据（RSI、MACD、估值等），不能空谈。裁判会检查论据质量,质量不够就要求追加轮次。

## 亮点 2：纯数学量化裁判

量化 Agent **完全不调用 LLM**,用经典技术分析指标做纯数学计算：

```
综合信号 = MA趋势(25%) + RSI(15%) + MACD(20%) + 布林带(10%)
           + ATR波动(10%) + KDJ随机(10%) + OBV量能(10%)

输出: -100 到 +100 的分数
```

这个分数是**不可被 LLM 幻觉污染的硬数据**。投资建议 Agent 在综合时,如果 LLM 的判断跟量化分数严重冲突,会触发**数值纠偏**：

```python
if quant_score > 60 and llm_says == "卖出":
    advisory = "数学信号强烈看多,但 LLM 建议卖出。请注意分歧。"
```

## 亮点 3：网格交易策略

自动计算 4 种网格策略的可行性和预期收益：

| 策略 | 网格间距 | 适合场景 |
|---|---|---|
| 短线网格 | ATR × 0.3 | 日内震荡 |
| 中线网格 | ATR × 0.8 | 周级别波段 |
| 长线网格 | ATR × 1.5 | 月级别布局 |
| 定投网格 | ATR × 2.0 | 底部积累 |

计算考虑 A 股真实费率（印花税 0.05% + 佣金 0.025%），以 100 股为最小交易单位,给出月化收益估算。

## 亮点 4：可解释性

每个 Agent 的推理过程都记录在 `reasoning_chain` 中,用户可以看到完整的决策路径：

<img src="/images/mermaid/invest-zh-3.svg" alt="diagram" style="max-width:100%;">

所有数字（PEG、DCF、量化分、动量）都是可复算的——不是 LLM 编的,是从真实数据算出来的。

## 数据源：全免费,国内可用

| 数据源 | 覆盖 | 用途 |
|---|---|---|
| **yfinance** | 全球（美/港/A股） | K线、财务数据、新闻 |
| **akshare** | A 股专用 | 东财公告、股吧舆情、板块排名 |
| **DuckDuckGo** | 全球 | 新闻搜索 |
| **DeepSeek** | LLM | 分析推理（Anthropic 兼容 API） |

不需要 Wind、Bloomberg 等付费终端。

## 安全设计

<img src="/images/mermaid/invest-zh-4.svg" alt="diagram" style="max-width:100%;">

- 输入端：长度限制、控制字符清理、Prompt 注入检测
- 输出端：PII 脱敏、系统提示泄露过滤、可疑 URL 拦截
- 审计：每个安全事件记录 AuditKind（INPUT_BLOCKED / OUTPUT_FILTERED）

## 部署

| 平台 | 方式 | 一行命令 |
|---|---|---|
| Windows | 双击 run.bat | 自动装 uv + Python + 依赖 |
| Linux | install_linux.sh | systemd 服务 + 定时器 |
| 邮件报告 | QQ 邮箱 SMTP | 每天定时发送分析报告 |

## 技术栈

```
语言:        Python 3.11+
Agent 编排:  LangGraph (StateGraph, 条件边, 自循环)
LLM:         DeepSeek (deepseek-chat)
行情数据:    yfinance + akshare
UI:          Streamlit
邮件:        QQ SMTP_SSL (端口 465)
数据校验:    Pydantic v2
包管理:      uv
测试:        pytest (真实 API 调用,不 mock)
部署:        systemd / Windows Task Scheduler
```

## 项目结构

```
backend/
  agents/           # 16 个 Agent 子包
    orchestrator/    # 意图分类 + 安全过滤
    market_data/     # 行情数据 (yfinance)
    quant/           # 量化信号 (纯数学)
    debate/          # 牛熊辩论
    debate_judge/    # 辩论裁判
    advisory/        # 投资建议 + 数值纠偏
    ...
  security/          # 输入消毒 / PII / 输出过滤
  observability/     # Token 追踪 / 审计日志
  graph.py           # LangGraph StateGraph 构建
  state.py           # ResearchState + Pydantic 模型
  llm_client.py      # DeepSeek 封装
frontend/
  app.py             # Streamlit 聊天界面
deploy/
  install_linux.sh   # 一键 Linux 部署
scripts/
  run.bat            # 零依赖 Windows 启动
  scheduled_analysis.py  # 定时任务入口
```

## 一段话总结

> 一个 16 Agent 的投资研究系统。6 路并行采集真实市场数据（不靠 LLM 编数据），纯数学量化 Agent 提供不可被幻觉污染的信号,牛熊辩论引擎让两个 LLM 互相对辩并由裁判控制质量,最后投资建议 Agent 综合所有维度给出建议——如果 LLM 判断与数学信号冲突,自动触发数值纠偏。全链路可解释,每个数字可复算。

