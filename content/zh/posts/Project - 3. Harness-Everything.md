+++
date = '2026-04-17T12:00:00+08:00'
draft = false
title = '[Project] 3. Harness-Everything — AI 自主代码改进 Harness'
categories = ["Project"]
tags = ["AI", "LLM", "Self-Improvement", "DeepSeek", "Anthropic", "CI/CD", "Python"]
featuredImage = "/images/Project%20-%203%20-%20Harness-Everything/cover.png"
+++


## 全局视图

<img src="/images/mermaid/harness-zh-1.svg" alt="diagram" style="max-width:100%;">

> **LLM 是大脑,Harness 是手脚,项目代码是被改的对象。LLM 从来没有直接碰过文件系统——它只说"我想做什么",你的代码去执行。**

## 本质：三句话说清楚

1. **LLM 是发动机**：把项目代码扔给大语言模型,让它分析、提改进、写代码。核心就是一个 while 循环不停问 LLM"还能怎么改"。
2. **工具是手脚**：LLM 不能直接读写文件,所以通过 Anthropic 的 tool_use 协议告诉你的代码"我想读这个文件"/"我想改这行代码",你的代码去执行,再把结果喂回来。只留一个 `bash` 工具也能跑。
3. **重启是关键**：Python 模块加载后就固化在内存里。LLM 改了自己的 `.py` 文件,运行中的进程还是用旧代码。必须重启进程,改进才生效。所以有了 push → tag → CI 部署 → 重启 的闭环。

---

## 从最简单到完整系统：每一层解决一个问题

### 最简版本（概念上）

```python
while True:
    代码 = 读取项目所有文件()
    回复 = LLM("这是代码,帮我改进:" + 代码)
    写回文件(回复)
```

这就能跑。但会遇到一堆问题。**下面每一层都是为了解决上一层的问题**：

<img src="/images/mermaid/harness-zh-2.svg" alt="diagram" style="max-width:100%;">

### 第 1 层：代码太多,上下文放不下

**问题**：项目一大,所有文件塞不进 LLM 的上下文窗口。

**解法**：不再一次性塞所有代码,而是给 LLM 工具让它自己选择看什么。

```
LLM: "我想看 harness/core/llm.py"
      ↓
你的代码: open("harness/core/llm.py").read() → 返回文件内容
      ↓
LLM: "我想搜索哪些文件引用了 _check_path"
      ↓  
你的代码: grep -r "_check_path" → 返回搜索结果
      ↓
LLM: "我要改这个文件的第 285 行"
      ↓
你的代码: 执行修改
```

这就是 **tool_use 机制** —— LLM 输出一段 JSON 说"我想调什么工具、传什么参数",你的 Python 代码去执行,把结果喂回来。LLM 从来没有直接碰过文件系统。

<img src="/images/mermaid/harness-zh-3.svg" alt="diagram" style="max-width:100%;">

**核心代码（`harness/core/llm.py` 的 `call_with_tools()`）只有 60 行**：

```python
for turn in range(max_turns):
    # 1. 问 LLM:"你想做什么?"
    response = await api.messages.create(messages=对话, tools=工具列表)
    
    # 2. 如果 LLM 没有要调工具 → 它说完了,退出
    if not response.tool_calls:
        return response.text
    
    # 3. LLM 要调工具 → 你的代码执行 → 把结果喂回去
    for call in response.tool_calls:
        result = await registry.execute(call.name, config, call.input)
    
    # 4. 结果追加到对话历史,继续循环
    对话.append(tool_results)
```

**就这些。这是整个项目最核心的 60 行。**

**转 — 但工具的代价是"记忆的复利"**

这 60 行代码简单，但隐藏了一个反直觉的成本模型。Anthropic API 是**无状态**的——每次调用都要把整个对话历史重发一遍。第一轮 LLM 调用 20K tokens，第五轮就 30K（多了 4 轮工具调用记录），第十轮 40K，第二十轮 60K。**对话越长，每一轮的花费越高，而且是指数级增长。**

这就是为什么 `max_tool_turns` 从 30 砍到 20 能省 40% 成本——砍掉的是最贵的那十几轮。但砍了轮次，agent 思考空间就小了。这是一个没有好答案的取舍，后续的对话剪枝、主动压缩、文件缓存都是在缓解这个根本矛盾。

**合 — 这 60 行是发动机，后面六层都是安全网和方向盘**

发动机本身不复杂。复杂的是在它周围搭出足够聪明的控制体系，让它不会烧坏引擎、不会开错方向、不会忘了自己开过哪条路。后面每一层，都是为了添一个控制维度。

### 第 2 层：LLM 会改出 bug

**问题**：LLM 改的代码可能有语法错误,甚至会搞坏项目。

**解法**：每次改完代码,自动跑 `python -m py_compile` 检查语法。如果出错,把错误信息告诉 LLM,让它修。

```
LLM 改了代码 → py_compile 报错 → 错误信息喂回 LLM → LLM 再改 → 通过
```

这就是 `harness/pipeline/hooks.py` 里的 `SyntaxCheckHook`。

**转 — `py_compile` 抓得住逗号，抓不住糊涂**

语法检查是硬约束——括号没配对、缩进错了、import 拼错了，一抓一个准。但它只能告诉你"代码能跑"，不能告诉你"代码跑得对不对"。LLM 把 `if user.is_admin` 写成了 `if user.is_active`，语法完全正确，逻辑完全错误。而且更微妙的：LLM 看到编译错误后改代码，有时候越改越糟——为了修一个 `SyntaxError` 把整个函数的逻辑重写了。

**合 — 语法检查是底线，不是上限**

它的角色类似于"代码不允许编译不过"。但过线之后的好坏，需要更聪明的判断机制——这就是下一层要解决的问题。

### 第 3 层：不知道改得好不好

**问题**：LLM 改了一轮,改得好吗?怎么判断?

**解法**：用另一次 LLM 调用来评判。而且用两个独立的评判者（互相看不到对方的评分），从不同角度打分：

- **Basic evaluator**：找最关键的缺陷（安全漏洞、逻辑错误、代码质量）
- **Diffusion evaluator**：分析二阶效应（会不会破坏其他模块？会不会让上下文膨胀？）

```
LLM 改了代码
  ├── Basic evaluator:    "这个改动有安全问题" → 5 分
  └── Diffusion evaluator: "但不会影响其他模块" → 7 分
  
合计 12 分。跟其他方案比,选最高分的。
```

<img src="/images/mermaid/harness-zh-4.svg" alt="diagram" style="max-width:100%;">

这就是 `harness/evaluation/dual_evaluator.py`。

**转 — "让学生给自己的作业打分"，避不开**

让 LLM 评 LLM，本质上就是让学生给自己作业打分。两个评估者隔离了视角（basic 找缺陷，diffusion 看波及），但如果两个评估者共享同一个模型的底层偏好呢？对漂亮代码的偏好、对特定设计模式的偏好——这些是隔离不住的。

实际跑下来发现：**evaluator 的 prompt 质量远比 isolation 重要**。一个好的 prompt 能让两个评估者的分歧刚好够用；一个模糊的 prompt 会让两个评估者都打出 6-8 分的"安全区间"——什么都好，什么都不突出。

**合 — 双评估是镜子，不是尺子**

它帮你看到两面的倒影，但不能给你绝对坐标。绝对坐标需要客观指标（测试通过率、覆盖率、lint score）来校准——这是 V5 多轴评估想要解决的问题之一。

### 第 4 层：一次改一点,多轮迭代

**问题**：一次性让 LLM "把所有问题都修了" 效果很差。大改容易翻车。

**解法**：拆成多个阶段（phase），每个阶段专注一件事,一轮一轮迭代：

```
Outer Round 1:
  Phase 1: 分析代码,找问题（debate 模式,只看不改）
  Phase 2: 改进核心框架（implement 模式,用工具改文件）
  Phase 3: 安全加固 + 删死代码
  Phase 4: 整合工具 + 加测试
  Phase 5: 改善可追踪性

Outer Round 2:
  ...重复,但基于 Round 1 的改进继续
```

每个阶段内部还有**内层轮次**（inner rounds）：生成多个方案,评估器选最好的,然后合成。

<img src="/images/mermaid/harness-zh-5.svg" alt="diagram" style="max-width:100%;">

这就是 `harness/pipeline/pipeline_loop.py`（外层）和 `harness/pipeline/phase_runner.py`（阶段执行）。

**转 — 阶段越多，视野越窄**

拆阶段的代价是**连贯性丢失**。Phase 2 的 LLM 不知道 Phase 1 分析了什么；Phase 3 改了 Phase 2 刚改的东西又改回去了。每个阶段在自己的上下文里做最优决策，但合在一起可能互相抵消。

这还是**固定阶段顺序**的锅。不管你扔给它一个安全审计任务还是一个加日志的需求，它都走同样的 bug_fix → features → polish 流水线。安全审计对小脚本毫无意义，但每次都跑。后来 R3 砍掉了固定辩论、加了 skip 规则和 falsifiable_criterion，才让 agent 有了按需调度的能力。

**合 — 编排的智慧不在"分几阶段"，在"知道什么时候跳过"**

真正让多阶段系统好用的不是阶段设计本身，而是**跳过规则**。一个阶段的存在价值不体现在它被执行的次数，而体现在执行它的每一次都确实改变了结果。如果一个阶段 80% 的时候都给出相同的结论——它应该被跳过。

### 第 5 层：改了不生效

**问题**：LLM 在 Round 3 改了 `harness/core/llm.py`,但运行中的进程还在用 Round 1 加载的旧代码。改了等于没改。

**解法**：你设计的重启闭环。

```
服务器跑 10 轮 → git commit + push → 打 tag → push tag
                                                 ↓
GitHub Actions 看到 tag → SSH 到服务器 → 部署新代码 → 重启进程
                                                         ↓
                                              新代码生效,再跑 10 轮...
```

**这是你做的最核心的架构决策。** 没有这个循环,自我优化就是假的——LLM 以为自己改了代码,但改动永远不会执行。

**转 — 但重启是有代价的**

每 10 轮才重启一次，意味着这 10 轮里 agent 一直在"用旧的身体执行新的想法"。Round 5 改进了 `llm.py` 的重试逻辑，但 Round 6-10 的 agent 还是用旧的重试逻辑跑——新代码躺在磁盘上等重启，旧代码在内存里继续跑。10 轮足够 agent 产生依赖新行为的代码——如果那个新行为还没生效，后续改动就可能基于错误假设。

这没有完美的解法，只能通过在每次 restart 后让 agent 先"审计自己改过的核心模块"来部分缓解。**批处理重启是一个工程权衡：你想多久看到改进生效，以及你能容忍多久的身体与大脑不同步。**

### 第 6 层：循环别断了

**问题**：各种情况会让循环意外停止。

| 问题 | 解法 |
|---|---|
| 代码太多上下文爆了 | 给 LLM 工具,让它按需读 |
| LLM 改出 bug | 语法检查 hook 自动验证 |
| 不知道改得好不好 | 双重评估器打分,选最高的 |
| 改了不生效 | push → tag → CI → 重启进程 |
| 连续几轮没进步 → 早停 → 没打 tag | `auto_tag_at_end` 强制每次退出都打 tag |
| 崩溃 3 次 systemd 放弃 | 心跳 cron 每 30 分钟检查并重启 |
| 用户推 commit 导致 push 冲突 | `git pull --rebase` 自动合并 |
| LLM 把部署脚本改坏了 | prompt 里的 PROTECTION 黑名单 |
| 部署了坏代码 | CI 烟测 + 回滚到 harness-last-good |
| 磁盘满 | 清理 cron 每天删旧数据 |

**转 — 安全网齐了，但"判断力"没有跟着涨**

这些安全网解决了"循环不会意外死掉"的问题，但没有解决"循环往哪里走"的问题。第 3 层的双重评估给了 agent 一轮内的判断力，但它没有跨轮次的记忆、没有方向感、没有能力质疑自己的评判标准。而且随着代码越来越规范，**评判信号越来越弱**——agent 把所有明显的缺陷都修了，剩下的都是需要品味和远见的改进，这些恰恰是单一分数搞不定的。

**合 — 前六层让循环能跑，第七层让循环能"思考"**

V4 之前，Harness 是一台越来越不会死的执行机器。V5 要解决的问题不同：不是"别死"，而是"知道往哪跑"。这就是第七层。

### 第 7 层（V5）：评判趋平、没有记忆、不会探索、改不了自己

**起 — 繁荣之下的隐忧**

V4 跑了 67 个 cycle，测试从零涨到 2700+，工具系统稳定运转。表面繁荣，但底下藏着四个结构性瓶颈：

1. **评判趋平** — 单一分数（0-10）区分度越来越差。一个改变量名的 commit 和一个重构 AST 工具的 commit，得分都是 7 分左右。agent 分不清"还行"和"真好"，优化方向模糊。
2. **没有跨周期记忆** — `memory.jsonl` 存了每一轮"做了什么"，但没有提炼。71 号 cycle 犯的错，73 号还会再犯。agent 每一轮都是失忆状态。
3. **只会小步优化** — exploitation 是唯一模式。agent 永远在已有结构里打磨——补测试、删死代码、合并重复逻辑——但永远不会说"这个架构不对劲，推了重来"。没有 exploration，就在局部最优附近打转。
4. **改不了自己** — evaluator 的 prompt 和评估权重硬编码在 Python 文件里。agent 可以改任何代码，唯独改不了"评判自己的标准"。失去了最重要的自我修正能力。

**承 — 四个模块，各破一个瓶颈**

```
瓶颈 1（评判趋平）      → MultiAxisEvaluator（5 维向量评估）
瓶颈 2（无跨周期学习）  → ExperienceStore（结构化经验记忆）
瓶颈 3（纯 exploitation）→ Exploration Mode（探索机制）
瓶颈 4（无法自修改）    → EvalConfig 热重载 + MetaAgent（策略层）
```

<img src="/images/mermaid/harness-zh-10.svg" alt="V5 架构总览" style="max-width:100%;">

**1. 多轴评估 — 5 维向量替代一个数字**

旧（V4）：evaluator 输出 `"SCORE: 7.5"` —— 一个数字，区分度低。
新（V5）：evaluator 输出 5 维向量 `[correctness, code_quality, arch_health, novelty, alignment]`，加权平均得最终分数。

五个维度独立评分（0-10），两个评估视角（basic + diffusion）并行跑：

| 维度 | 默认权重 | 衡量什么 |
|---|---|---|
| correctness（正确性） | 35% | 编译/测试通过，没有引入安全问题 |
| code_quality（代码质量）| 25% | lint 干净，复杂度可控，命名清晰 |
| arch_health（架构健康）| 15% | 耦合度、内聚度、模块边界 |
| novelty（新颖度） | 10% | 与已有代码的差异度，是否尝试了新方向 |
| alignment（策略一致性）| 15% | 是否符合当前 MetaAgent 设定的优化目标 |

权重存在 `harness/config/eval_weights.json`，每次评估前从磁盘热加载。这意味着改权重文件→下次评估立刻用新权重，不用重启进程。

**2. 结构化经验记忆 — 不只是"做了什么"，还有"学到了什么"**

```
旧（V4 memory.jsonl）:
  {"cycle": 5, "score": 7.2, "proposal": "改了一堆东西..."}
  → 流水账，没有提炼，没有检索，没有复用

新（V5 ExperienceStore）:
  Experience(
    cycle=5,
    eval_vector=[8,7,6,5,9],          # 多轴向量
    action_summary="合并两个 AST 工具减少重复",
    reflection="共享的 boilerplate 提取为 _ast_utils 是正确的……",  # LLM 的自我反思
    abstraction="当多个工具共享超过 30% 代码时，提取公共模块到 core/",  # 提炼出可复用的模式
    tags=["tool_merge", "dedup", "ast"],
    was_reverted=false,
  )
```

四个核心接口：
- `record(exp)` — 每轮结束后记录经验
- `query(["evaluator", "scoring"])` — 按标签检索相关历史
- `compress(ratio)` — 合并相似经验，提炼更抽象的规则
- `format_context(max_entries)` — 格式化给 LLM 和 MetaAgent 读

**3. 探索机制 — 不只是打磨，还要冒险**

```
正常轮（exploitation，默认）:
  权重: correctness 0.35, code_quality 0.25, arch 0.15, novelty 0.10, alignment 0.15
  → 小步优化，稳妥为主

探索轮（exploration，每 N 轮插入一次）:
  权重: correctness 0.15, code_quality 0.10, arch 0.10, novelty 0.50, alignment 0.15
  → 新颖度权重从 10% 提到 50%，鼓励大胆尝试
  → 放松 gate（允许编译失败），范围限定在单一模块，防止炸毁全局
  → 每 3 轮（可在 pipeline JSON 里配置 exploration_interval）插入一次
```

**4. 策略层 + 热重载 — agent 终于能改自己的评判标准了**

```
┌─────────────────────────────────────────────────────┐
│ MetaAgent（每 5-10 轮运行一次，不写代码，只出策略）    │
│                                                     │
│ 输入:                                                │
│   • ExperienceStore 里最近 20 条经验的格式化上下文      │
│   • 各维度分数趋势（正确性在涨但新颖度在下滑？）        │
│   • 当前评估权重                                      │
│                                                     │
│ 输出 (结构化的策略调整):                               │
│   • focus_axis: "novelty"（接下来重点优化哪个维度）     │
│   • adjust_weights: {"novelty": 0.3, ...}（调整权重）  │
│   • exploration_frequency: 2（调整探索频率）            │
│   • reasoning: "代码越来越规范但缺乏新方向，增加..."     │
│                                                     │
│ MetaAgent 的决策 → 写入 eval_weights.json → 下次评估   │
│ 热加载新权重 → 不重启就生效                             │
└─────────────────────────────────────────────────────┘
```

配合 `GetSelfConfigTool`——注册给 agent 的自感知工具——agent 可以查询"我的配置文件在哪"，然后自己修改 evaluator prompt 和权重。agent 第一次能改变评判自己的标准。

**转 — 权重不是魔法，prompt 才是瓶颈**

V5 落地后，两个发现让原有假设受到了挑战：

第一，**改权重远不如改 prompt 有效**。把 novelty 从 10% 调到 50%，的确让 agent 更愿意尝试新方向，但如果 evaluator prompt 里没有清晰定义"什么叫好的新颖度"，agent 就会在随机改变量名和实质性重构之间打转。**权重量化了"多重要"，但 prompt 定义了"是什么"**。

第二，**MetaAgent 自身也有决策质量问题**。它从 ExperienceStore 读经验、看趋势、出策略——但如果 ExperienceStore 里存的经验本身质量不高（前几个 cycle 的评估是不准的），MetaAgent 的决策就会偏。这是一个**冷启动问题**：没有好经验→策略不准→产出差经验→策略更不准。解法是在前几轮用保守默认权重跑出一批高质量经验，再启动 MetaAgent。

**合 — V5 的意义不在于"又一个版本"**

V5 之前，Harness 是一个**执行器**——它跑得很快，改得很好，但"往哪跑"和"怎么评判跑得好不好"是人设定的。V5 之后，它开始有了**方向感**——它记得跑过的路，知道哪些方向值得再试，能看出自己在原地打转，偶尔还会冒险走一条新路。

但最终，**谁来定义"好"**——这个问题 V5 只是推远了一步，没有解决。MetaAgent 可以调整权重，但权重依附于人类设计的五个维度。哪天 agent 能自己提出第六个维度——那才是真正的转折点。

**V5 新增文件**：

| 文件 | 职责 | 替代了谁 |
|---|---|---|
| `harness/evaluation/multi_axis.py` | 5 维向量评估器 | dual_evaluator（向下兼容，仍可用） |
| `harness/core/experience.py` | 结构化经验记忆 | memory.py（JSONL 流水账） |
| `harness/pipeline/meta_agent.py` | 策略层：分析趋势，调整方向 | 无（全新能力） |
| `harness/core/eval_config.py` | 热重载配置：prompt + 权重从磁盘读 | 无（替代硬编码 import） |
| `harness/tools/self_config.py` | Agent 自感知工具 | 无（全新能力） |

---

## 工具系统：不是核心,是优化

如果只有一个 `bash` 工具,LLM 会这么干：

```
bash("cat harness/core/llm.py")           → 读文件
bash("grep -rn '_check_path' harness/")   → 搜索
bash("sed -i 's/old/new/' file.py")       → 改文件
bash("python3 -m py_compile file.py")     → 检查语法
```

完全能跑。那为什么还搞 30 个专用工具？

| 用 bash | 用专用工具 | 为什么换 |
|---|---|---|
| `cat /etc/passwd` | `read_file` 会拒绝 | **安全**：路径检查限制在 workspace 内 |
| `grep` 输出 10 万行 | `grep_search` 自动截断 | **省 token**：不会撑爆上下文 |
| `sed` 改错了没法回退 | `edit_file` 精确替换 | **可控**：替换失败会报错,不会静默改坏 |
| LLM 编造参数 | registry 参数校验 | **容错**：未知参数直接拦截 |

<img src="/images/mermaid/harness-zh-6.svg" alt="diagram" style="max-width:100%;">

**工具是给 LLM 戴的安全手套,不是给它的超能力。**

### 30 个工具分类

```
文件操作:    read_file, write_file, edit_file, delete_file, move_file, copy_file
目录操作:    list_directory, create_directory, tree
搜索:       glob_search, grep_search
Git:        git_status, git_diff, git_log
执行:       bash, python_eval, test_runner
分析:       code_analysis, symbol_extractor, cross_reference, ...
可选:       web_search (需要显式开启)
```

### 工具安全边界（`_check_path`）

每个文件操作工具在执行前都要过安全检查：

```python
resolved = os.path.realpath(path)  # 解析符号链接
# 检查 null bytes、Unicode 伪装字符、路径越界
if path 不在 allowed_paths 内:
    拒绝执行
```

LLM 说"读 /etc/passwd" → 被拦截。说"读 ../../etc/passwd" → realpath 解析后还是被拦截。

---

## 工具循环的成本模型

Anthropic API 是**无状态**的。每次调用都要重发完整对话历史。所以工具循环的每一轮都比上一轮贵：

```
Turn  1: 发送 [系统提示 + 文件上下文 + 用户指令]       ≈ 20K tokens
Turn  5: 发送 [上面 + 4 轮工具调用和结果]               ≈ 30K tokens
Turn 10: 发送 [上面 + 9 轮]                             ≈ 40K tokens
Turn 20: 发送 [上面 + 19 轮]                            ≈ 60K tokens  ← 最贵

一个 20-turn 循环总共: ≈ 0.5M input tokens
```

<img src="/images/mermaid/harness-zh-7.svg" alt="diagram" style="max-width:100%;">

**后半程每多一轮,花的钱比前半程多得多。** 这就是为什么 `max_tool_turns` 从 30 砍到 20 能省 40% —— 砍掉的是最贵的那几轮。

### 缓解措施

| 机制 | 文件 | 原理 |
|---|---|---|
| 对话剪枝 | `llm.py` | 总字符超 150K 时,截断旧的工具结果 |
| 主动压缩 | `llm.py` | turn >= 6 后,旧工具结果替换为一行摘要 |
| 文件读取缓存 | `llm.py` | 同一循环内 read_file 结果缓存,写操作使缓存失效 |
| 代码注入预算 | `phase_runner.py` | 只注入最相关的 30K 字符源码,不是全部 |

### DeepSeek 成本估算

```
Cache miss: $0.28 / 百万 input tokens
Cache hit:  $0.028 / 百万 input tokens (缓存命中率约 90%)
Output:     $0.42 / 百万 output tokens

一个 chunk (6-10 轮 × 4-5 阶段):
  Input:  ~30M tokens → ~$3
  Output: ~1M tokens  → ~$0.4
  合计:   ~$3.5 / chunk
```

---

## Pipeline 架构详解

### 整体结构

```
PipelineLoop.run()
│
├── for outer in range(10):                    ← 外层: 10 轮
│   │
│   ├── _run_outer_round()
│   │   │
│   │   └── for phase in [分析, 改进, 安全, 整合, 追踪]:  ← 5 个阶段
│   │       │
│   │       └── PhaseRunner.run_phase()
│   │           │
│   │           ├── 注入代码上下文 (最相关的 30K 字符)
│   │           │
│   │           ├── for inner in range(2):       ← 2 次尝试
│   │           │   │
│   │           │   ├── debate 模式: 并行,只分析不改
│   │           │   └── implement 模式: 顺序,用工具改文件
│   │           │       └── call_with_tools()    ← 工具循环 (最多 20 轮)
│   │           │
│   │           ├── DualEvaluator.evaluate()      ← 双重评估,选最好的
│   │           ├── Synthesis                     ← 合成最佳方案
│   │           └── Hooks: 语法检查 + git commit  ← 验证 + 提交
│   │
│   ├── auto_push (git pull --rebase + push)     ← 每轮推到 GitHub
│   ├── patience 检查 (连续 5 轮没进步 → 早停)
│   └── 优雅关闭检查 (收到 SIGTERM → 干完当前阶段退出)
│
├── auto_tag_at_end → 打 tag + push tag          ← 触发 CI 部署
└── 写 summary.json
```

### 每一层做什么

**外层轮次** (`pipeline_loop.py`):
- 编排所有阶段的执行顺序
- 跟踪分数趋势（3 连降警告）
- 决定是否早停（patience）
- 决定是否推送（auto_push）
- 决定是否打 tag（auto_tag）

**阶段执行** (`phase_runner.py`):
- 按关键词 + 修改时间 + 文件大小排序,注入最相关的源码
- debate 模式：LLM 只分析不改,并行跑多个方案,快
- implement 模式：LLM 用工具改文件,顺序跑（因为会改文件,不能并行）
- 评估：两个独立 LLM 调用并行打分
- 合成：从多个方案中提取最佳元素
- 验证：语法检查 + git commit

**工具循环** (`llm.py`):
- LLM 说"我要调这个工具" → 你的代码执行 → 结果喂回来 → 循环
- 每轮都重发完整对话（API 无状态）
- 自动剪枝防止上下文爆炸
- 最多 20 轮（成本控制）

### 关键数据流

```
prior_best (上一轮最佳方案)
    ↓
Phase 1 (分析) → synthesis → 传给 Phase 2
    ↓
Phase 2 (改进) → 改文件 → commit → synthesis → 传给 Phase 3
    ↓
Phase 3 (安全) → 改文件 → commit → synthesis → 传给 Phase 4
    ↓
...每个 phase 的合成结论传给下一个 phase 作为 prior_best
    ↓
Round 结束 → 最终 prior_best 传给下一个 Round
```

---

## 自改进循环（服务器部署）

### 架构图

<img src="/images/mermaid/harness-zh-8.svg" alt="diagram" style="max-width:100%;">

### 为什么需要重启

```python
# 进程启动时
import harness.core.llm  # 加载到内存,之后不再变

# Round 5: LLM 改了磁盘上的 llm.py
edit_file("harness/core/llm.py", ...)  # 磁盘变了

# Round 6: 进程还是用内存里的旧版本
# Python 不会自动重新 import

# 只有重启进程,新代码才生效
```

### 操作手册

| 想做什么 | 怎么做 |
|---|---|
| 看实时日志 | `ssh server "tail -f ~/harness-everything/logs/harness.log"` |
| 看 commit 进度 | `git log --oneline -20` |
| 推一个修复（不停服务） | 直接 `git push`,harness 会 `pull --rebase` 自动合并 |
| 改配置 | 改 `config/pipeline_example_self_improve_server.json`,push,下次部署自动生效 |
| 跑完这轮就停 | `ssh server "touch ~/.config/harness/STOP_AFTER_CHUNK"` |
| 恢复循环 | `ssh server "systemctl --user start harness.service"` |
| 立刻停 | `ssh server "systemctl --user stop harness.service"` |
| 彻底关闭 | stop + disable + 清 cron |

---

## 核心数据结构

```
PipelineConfig                     # 顶层配置
├── harness: HarnessConfig         #   模型/API/workspace/工具
│   ├── model: "deepseek-chat"
│   ├── base_url: "https://api.deepseek.com/anthropic"
│   ├── workspace: "/home/ubuntu/harness-everything"
│   ├── allowed_paths: [workspace]
│   └── max_tool_turns: 20
├── phases: [PhaseConfig]          #   阶段列表
│   ├── name, mode (debate/implement)
│   ├── system_prompt (含 $file_context 等模板变量)
│   └── glob_patterns (注入哪些文件)
├── outer_rounds: 10               #   每个 chunk 跑几轮
├── patience: 5                    #   几轮没进步就早停
├── auto_push_interval: 1          #   每轮 push
├── auto_tag_at_end: true          #   退出必打 tag
├── evaluation_engine: "multi_axis"# V5 评估引擎（"dual" 或 "multi_axis"）
├── exploration_interval: 3        # V5 探索轮频率（0=禁用）
├── meta_agent_interval: 5         # V5 策略层频率（0=禁用）
└── eval_weights: {correctness:0.35,...} # V5 多轴权重

EvalVector (V5)                    # 多轴评估向量
├── correctness: float             #   正确性（0-10）
├── code_quality: float            #   代码质量（0-10）
├── arch_health: float             #   架构健康（0-10）
├── novelty: float                 #   新颖度（0-10）
└── alignment: float               #   策略一致性（0-10）

Experience (V5)                    # 结构化经验条目
├── eval_vector: [float]           #   多轴评估向量
├── action_summary: str            #   做了什么
├── reflection: str                #   LLM 的自我反思
├── abstraction: str               #   提炼出的可复用模式
├── tags: [str]                    #   可检索标签
└── was_reverted: bool             #   是否被回滚

MetaStrategy (V5)                  # MetaAgent 输出
├── focus_axis: str                #   重点优化维度
├── adjust_weights: dict           #   权重调整
├── exploration_frequency: int     #   探索频率建议
└── reasoning: str                 #   策略推理过程

InnerResult                        # 单次尝试的结果
├── proposal: str                  #   LLM 的提案或改动
├── eval_vector: EvalVector (V5)   #   多轴评估（V4 为 dual_score）
│   ├── basic: (score, critique)   #     缺陷评估（V4 legacy）
│   └── diffusion: (score, critique)#    波及效应（V4 legacy）
└── tool_call_log: [dict]          #   工具调用记录

PhaseResult                        # 阶段结果
├── synthesis: str                 #   合成后的最终方案
├── best_score: float              #   最高分（加权平均）
└── inner_results: [InnerResult]   #   所有尝试
```

---

## 关键文件索引

| 文件 | 核心职责 | 一句话 |
|---|---|---|
| `main.py` | 入口 | 解析参数,启动循环 |
| `harness/core/llm.py` | **最核心** | 工具循环:LLM 说 → 你执行 → 反馈 → 重复 |
| `harness/core/config.py` | 配置 | JSON → 配置对象,路径安全验证 |
| `harness/pipeline/pipeline_loop.py` | 外层循环 | 轮次编排、push、tag、早停、关闭 |
| `harness/pipeline/phase_runner.py` | 阶段执行 | 代码注入、内层轮次、评估、合成、hooks |
| `harness/evaluation/dual_evaluator.py` | 质量把关 | 两个 LLM 并行打分,选最好的方案（V4） |
| `harness/evaluation/multi_axis.py` | **V5 多轴评估** | 5 维向量（correctness/code_quality/arch_health/novelty/alignment）替代单一分数 |
| `harness/core/experience.py` | **V5 经验记忆** | 结构化经验存储：记录 + 反思 + 抽象 + 检索 |
| `harness/pipeline/meta_agent.py` | **V5 策略层** | 每 N 轮分析趋势，调整评估权重和探索频率 |
| `harness/core/eval_config.py` | **V5 热重载** | Evaluator prompt + 权重从磁盘热加载，改文件即生效 |
| `harness/tools/self_config.py` | **V5 自感知** | 让 agent 查询自己的配置文件路径 |
| `harness/tools/registry.py` | 工具分发 | 工具注册、参数校验、异常封装 |
| `harness/tools/base.py` | 工具安全 | `_check_path` 路径边界检查 |
| `harness/pipeline/hooks.py` | 验证 | 语法检查 + git commit（富信息） |
| `deploy/harness.service` | 部署 | systemd 服务定义 |
| `.github/workflows/deploy.yml` | CI/CD | tag 触发 → 烟测 → 部署 → 重启/回滚 |
| `deploy/heartbeat.sh` | 保活 | 崩溃后自动重启 |

---

## 完整数据流：从 JSON 配置到代码提交

<img src="/images/mermaid/harness-zh-9.svg" alt="diagram" style="max-width:100%;">

---

## 一段话总结

> 把项目代码扔给 LLM,让它分析、提改进方案、用工具改代码。用另一个 LLM 调用评判改得好不好,选最好的方案 commit。多轮迭代,每轮都比上一轮基于更好的代码。因为 Python 模块加载后就固化在内存里,所以每 10 轮重启一次进程让改进生效。重启通过 git tag 触发 GitHub Actions 自动部署实现,形成无人值守的自改进循环。V5 引入了多轴评估（5 维向量替代单一分数）、结构化经验记忆（不只记做了什么,还提炼"学到了什么"）、探索机制（偶尔冒险尝试新方向）和策略层（MetaAgent 定期分析趋势、调整评估权重和探索频率——agent 第一次能改变评判自己的标准）。工具系统（30 个文件/搜索/执行工具）本质上只是给 LLM 戴的安全手套——只留一个 bash 也能跑,但更危险、更费 token。
