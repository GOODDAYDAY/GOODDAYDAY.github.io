# [Project] 6. 平行演化 — Skills 与 Harness 的 AI 协作实录


## 概述

从今年元旦结束、回来上课以来，开始高强度使用 AI（特别点名 Claude Code），帮助自己做了很多项目、写了很多软件。这么长时间以来，对计算机程序员如何使用 AI 的心路历程，算是走了一个又一个阶段。脑子里很多东西，希望能写下来帮助自己反思和总结。

### 心路历程的几个维度

这段时间对 AI 的理解有几条主线同时在演化：
- **方法层**：从手打 Prompt → skills 体系 → 编排者模式，逐渐形成可复用的开发工作流
- **工程层**：从"让 AI 帮我写代码"到"让 AI 自己改进自己的代码"，边界在持续外推
- **认知层**：越用越觉得这不是一个"工具"，更像一个需要持续协作、共同成长的伙伴

有了这些理解，我开始把想法一步步落地。第一个项目，就是 Skills 仓库。

## 项目一：Skills 仓库的演化

### 阶段一——手打 Prompt 时代

在这之前，每次使用 AI 都要手打一遍相似的 Prompt。工作流大致是：
1. 告诉 AI 项目背景
2. 告诉 AI 要做什么
3. 手动规定输出格式

每次都重复这些，既蠢又烦。这个阶段没有文档留存，因为根本没有"工具化"的意识，只是在使用。

比如当时的 Prompt 就是一个不断复制的模板：
```
项目背景：Java 17 + Spring Boot 3 + MySQL 8
代码路径：D:/project/my-app
编码规范：三层结构（Controller/Service/Repository），不用 Lombok
请实现：用户注册接口
输出格式：先写需求文档到 requirements/REQ-xxx/，
         再设计方案，最后编码。每步完成后等我确认。
```
每次新任务就复制一份改改描述，项目背景和约定照搬。更烦的是 **AI 没有跨会话记忆**，下次开新对话又得从头粘贴一遍。

意识到这个问题后，我决定把这些重复的 Prompt 固化下来。第一个尝试，就是把完整的工作流写成一个单体 skill。

### 阶段二——单体 req 的诞生

#### 初版结构

第一次正式提交 skills 仓库，初版包含：

```
req/SKILL.md               ← 编排器，6 阶段线性流程
req-1-analyze/SKILL.md     ← 需求分析
req-2-tech/SKILL.md        ← 技术设计
req-3-code/SKILL.md        ← 编码实现（含 java.md / python.md）
req-4-review/SKILL.md      ← 需求对比
req-5-verify/SKILL.md      ← 校验测试
req-6-done/SKILL.md        ← 归档完成
create-skill/SKILL.md      ← 辅助工具
_shared/plantuml.md        ← 共享约定
```

#### 六阶段线性流程

<img src="/images/mermaid/evolution-zh-1.svg" alt="六阶段线性流程" style="max-width:100%;">

**Figure 3.2 — 初版六阶段线性流程（固定顺序，每阶段等待用户确认）**

有了这个 skill，我再说"实现用户注册"就不用重复项目背景了。AI 会自动走完 6 个阶段：先写需求文档到 REQ-003，再设计方案，然后编码。每走完一阶段停下来等我确认。虽然流程是固定的，但**至少不用每次从头交代了**。

#### 自然语言编程的第一感

当第一次规定"每次都要在固定目录里按编号自增长写需求文档"，然后它真的每次都理解了这个约定——**第一次真正感受到自然语言编程和编程语言编程的区别**。

文档目录结构：
```
requirements/
├── index.md                ← 需求总览与状态跟踪
├── REQ-001-xxx/
│   ├── requirement.md      ← 需求文档
│   └── technical.md        ← 技术文档
└── REQ-002-xxx/
    └── ...
```

这个约定的价值在于：需求文档成为每个 REQ 的"合同"，后续任何迭代都可以回溯对比。

### 阶段三——多 req 拆分

#### 拆分的动机

随着对 skills 了解加深，醒悟过来：**为什么不把单体 skill 拆分？** 每个阶段有自己独立的规则、独立的输出要求。单体文件越来越臃肿，难以维护。一次大规模重构，新增 19 个文件，改动近千行。

#### 八阶段流程

拆分后的阶段如下：

<img src="/images/mermaid/evolution-zh-2.svg" alt="八阶段流程与双 Agent 辩论" style="max-width:100%;">

**Figure 3.3 — 八阶段流程与双 Agent 辩论机制**

#### 双 Agent 辩论实践

这一阶段在需求分析和技术方案里引入了**双 agent 对抗辩论**：
- **MVP Agent**：主张最小可行性产品，约束范围，快速交付
- **全功能 Agent**：主张完整特性，不留技术债
- **评判 Agent**：基于多轮辩论，综合产出融合方案

辩论机制下，每个技能文件的 prompt 开头会定义三套视角。拿 `req-1-analyze/SKILL.md` 来说，它会要求从 MVP 和全功能两个角度分别分析需求，再综合输出。实际跑起来就是三个 agent 并行调用——两轮辩论 + 一轮评判。

效果上，中大型需求的输出质量确实比单人决策好。但后来暴露了问题：**它慢，而且大多数小功能根本不需要辩论**。一个小改动也要加载三个 agent 的 prompt、等它们跑完、再汇总——overhead 远大于收益。

#### 共享规范文件的成型

这个阶段建立了 `_shared/` 目录，成为所有 skills 的公共约定：

<img src="/images/mermaid/evolution-zh-3.svg" alt="_shared 共享规范体系" style="max-width:100%;">

**Figure 3.4 — _shared 共享规范体系**

### 阶段四——编排者 req

#### 从固定流程到智能编排

这是最重要的一次进化。把 req 的角色从"严格按序执行的流水线"升级为"**根据任务内容做决策的编排者**"。

核心改变：**删除序号，删除固定编排顺序，让编排者基于任务内容自己判断跑哪些阶段**。

这是编排器 SKILL.md 里的实际分类逻辑（简化）：
```
场景 A — Trivial：          改个变量名、加行日志、改配置
→ 直接执行，不建 REQ

场景 B — New REQ：          实现登录、接入支付
→ 创建新 REQ-xxx，走完整流水线

场景 C — Amend 规格变更：   "改用 OAuth"、"TTL 改 7 天"
→ 定位到已有 REQ，amend 文档，重跑受影响阶段

场景 D — Amend Bug 修复：   token 解析失败、测试没通过
→ 定位到已有 REQ，回退到 code 阶段，重跑 verify

场景 E — 模糊判断：          已完成的登录 REQ 上再加"记住我"
→ 查 REQ 状态：还在开放就 amend，已完成就新建
```
每条规则都有明确的判断条件：先读 `requirements/index.md`，看有没有活跃的 REQ，判断输入是否引用已有 REQ 的代码或行为。**编排者不再是流水线工人，而是一个决策者。**

<img src="/images/mermaid/evolution-zh-4.svg" alt="编排者模式" style="max-width:100%;">

**Figure 3.5 — 编排者模式：classify → triage → plan → execute**

#### 任务分类机制

编排者首先把输入分为五类：

| 场景 | 描述 | 典型例子 | 处理方式 |
|:---|:---|:---|:---|
| **A — Trivial** | 小到不需要建 REQ | 改变量名、加日志、改配置 | 直接执行 |
| **B — New REQ** | 独立功能目标 | 实现登录、接入支付 | 创建新 REQ，完整流水线 |
| **C — Amend（规格变更）** | 同一目标但方向变了 | "改用 OAuth"、"TTL 改 7 天" | amend 现有 REQ |
| **D — Amend（Bug）** | 实现缺陷 | "token 解析失败" | amend → 回退到 code 阶段 |
| **E — Ambiguous** | 扩展还是新 REQ？ | 已完成的登录 REQ 上加"记住我" | 判断状态再决定 |

#### 阶段跳过机制

每个阶段有明确的"跳过条件"：

| 阶段 | 跳过条件 |
|:---|:---|
| analyze | 用户已提供完整规格（罕见） |
| tech | 改动方向明确且机械化（删除/移动/重命名） |
| security | 无新攻击面：纯重构、删除、内部配置 |
| cleanup | 改动本身就是清理，或总范围 ≤ 3 文件 |
| review | 范围 ≤ 3 文件且无功能性需求变更 |
| verify | 纯重构/删除，现有测试已足够 |
| **code / done** | **从不跳过** |

#### 轻量 task skill 的诞生

同期（04-02）新增 `task` skill：为不需要完整 req 流程的小任务提供轻量工作流。

<img src="/images/mermaid/evolution-zh-5.svg" alt="task skill" style="max-width:100%;">

**Figure 3.6 — task skill：在对话中完成分析，复用 req 子技能执行**

这次还添加了：
- **per-stage git tags**（`REQ-xxx-analyzed/designed/coded`）
- **TDD 优先**（req-3-code 里先写验收测试再实现）
- **并行 sub-agent** 支持（独立模块并行开发）
- **批量归档** req-archive skill

#### 结构对比

<img src="/images/mermaid/evolution-zh-6.svg" alt="固定流水线 vs 智能编排器" style="max-width:100%;">

**Figure 3.7 — 固定流水线 vs 智能编排器**

### 阶段五——现状与反思

#### 为什么用得少了

最近自己都不常用 req 了。主要原因：

比如一个简单的"给接口加行日志"，早期版本的流程从不跳过任何阶段：analyze → tech → code → security → cleanup → review → verify → done。每个阶段都得走一遍，即使 analyze 和 tech 对这个任务毫无意义。

后来编排者版本加的跳过规则才解决了这个问题：
```
analyze  → 用户已提供完整规格时跳过
tech     → 改动方向明确且机械化时跳过（重命名、删除）
security → 无新攻击面时跳过（纯重构、内部配置）
cleanup  → 改动本身就是清理时跳过
review   → 范围 ≤ 3 文件且无功能变更时跳过
verify   → 纯重构/删除且测试已足够时跳过
code/done → 永不跳过
```
换句话说，早期版本的慢不是辩论本身的错，而是"没有按需跳过"的错。

**慢在哪——多 Agent 辩论的 overhead**

完整流程慢的核心瓶颈是 **双 Agent 辩论**。需求分析和技术设计两个阶段默认都会走 MVP vs 全功能的对抗辩论，每一轮都要 launch 多个 sub-agent、等它们跑完、汇总、用户选择。对于一个大功能这很值，但大部分日常需求其实只需要"分析一下，直接出方案"。

真正的解法应该是**意图识别 + 分级处理**：

<img src="/images/mermaid/evolution-zh-7.svg" alt="意图识别 + 分级处理决策树" style="max-width:100%;">

**Figure 3.8 — 意图识别 + 分级处理决策树**

- **大功能 / 方向不确定** → 走辩论，多 Agent 探索不同方案
- **小功能 / 方向明确** → 直接分析，不走辩论
- **纯机械改动（改名、删文件、改配置）** → 甚至不走 req，直接用 task

现在的 `req-analyze` 和 `req-tech` 里其实已经加了 triage（快速通道 vs 深度通道），但早期版本没有。回头想，如果一开始就按任务大小分级，而不是一刀切全辩论，"慢"的感受会轻很多。

**公司 AI 工具的局限**

公司提供的 AI 工具对 sub-agent 的支持不够好：sub-agent 不会回调感知进度，用户看不到执行顺序，多个 agent 并行时像在黑箱里跑。这导致复杂编排在公司环境里体验打折扣，自然而然地用得少了。

#### skills 的长期价值

尽管如此，还是强烈推荐大家维护一套属于自己的 skills：

- **可复用**：写一次，到处用，不用每次手打
- **随你成长**：skills 会随着对 AI 的理解提高而持续演化
- **是你 AI 理解力的侧面体现**：一个人的 skills 文件质量，几乎直接反映了他对 AI 协作的理解深度

<img src="/images/mermaid/evolution-zh-8.svg" alt="Skills 仓库的完整演化状态图" style="max-width:100%;">

**Figure 3.9 — Skills 仓库的完整演化状态图**

- GitHub: [GOODDAYDAY/my-skills](GitHub - GOODDAYDAY/my-skills: A centralized repository for personal skills and context definitions.)
- 详细介绍：[Project 5. My Skills — 将企业级开发流程变成 Claude Code 的可执行技能](https://gooddayday.github.io/zh-cn/2026/04/project-5.-my-skills/)

Skills 这边一直在迭代，但同一时间，我其实还在做另一个项目——**Harness-Everything**。它的目标和 Skills 完全不同：Skills 管的是"AI 怎么帮我写代码"，Harness 管的是"AI 能不能自己改进自己的代码"。两个项目独立推进，互不干扰。直到某天回头看，才发现它们走出了惊人相似的轨迹。

## 项目二：Harness-Everything

- GitHub: [GOODDAYDAY/Harness-Everything](https://github.com/GOODDAYDAY/Harness-Everything)
- 详细介绍：[Project 3. Harness-Everything — Autonomous AI Code Improvement Harness](https://gooddayday.github.io/en/2026/04/project-3.-harness-everything/)

### 核心思想：一句话说清楚

> 把项目代码喂给 LLM，让它分析、改进、写代码；用工具读写文件；另一个 LLM 调用判断质量；多轮迭代，每轮都在上一轮改好的代码基础上继续。因为 Python 模块加载一次就冻结在内存里，每 N 轮必须重启进程才能让改进生效——这个重启由 git tag 触发 CI/CD 完成，形成无人值守的自我改进循环。

整个系统可以用这个分层模型理解：

<img src="/images/mermaid/evolution-zh-9.svg" alt="每一层解决上一层的问题" style="max-width:100%;">

**Figure 4.1 — 每一层解决上一层的问题**

### 阶段一——最简初版

#### 诞生背景

第一个快照包含完整的初版架构：

```
harness/
├── llm.py              ← 工具调用核心循环（最重要的 60 行）
├── config.py           ← 配置管理
├── dual_evaluator.py   ← 双评估器
├── phase.py            ← 阶段定义
├── phase_runner.py     ← 阶段执行器
├── pipeline.py         ← 流水线管理
├── hooks.py            ← 语法检查 + git commit
├── tools/              ← 30+ 工具集
│   ├── base.py         ← 路径安全（_check_path）
│   ├── bash.py
│   ├── directory.py
│   └── ...
└── prompts/            ← LLM 指令模板
```

核心的 `llm.py` 就是驱动 LLM 调用循环的代码，其中一段真实的配置是这样的：
```python
# 可重试的异常类型：过载、限流、网络超时
_RETRYABLE_EXCEPTIONS = (
    OverloadedError,           # HTTP 529 — 模型过载
    RateLimitError,            # HTTP 429 — 限流
    InternalServerError,       # HTTP 500 — 临时服务端错误
    APIConnectionError,        # 网络层面失败
    APITimeoutError,           # SDK 超时
)

_MAX_RETRIES: int = 4          # 最多重试 4 次
_INITIAL_DELAY: float = 2.0    # 首次重试前等待
_BACKOFF_FACTOR: float = 2.0   # 每次等待翻倍
_MAX_DELAY: float = 60.0       # 最长等待 1 分钟
```
每回合 LLM 调用 API → 拿到工具调用指令 → 执行 → 结果送回 LLM → 继续。等到超过 max_tool_turns 就停止，选出最优方案。

没有 pipeline JSON，没有 phase 概念，就是一个简单的 for 循环。

#### 能装入全部代码的黄金时代

初版最大的特点：**代码小，能全部装进 LLM 的 Context**。

这是一个短暂的黄金状态——LLM 可以一次性看到整个项目，理解全局，做出系统性改进。这让第一版的输出质量相当不错。

<img src="/images/mermaid/evolution-zh-10.svg" alt="初版完整数据流" style="max-width:100%;">

**Figure 4.2 — 初版完整数据流：从配置到代码提交**

### 阶段二——固定编排（R1/R2）

#### 三阶段固定流程

第一轮（R1）和第二轮（R2）采用固定的三阶段流程：

<img src="/images/mermaid/evolution-zh-11.svg" alt="R1/R2 固定三阶段编排" style="max-width:100%;">

**Figure 4.3 — R1/R2 固定三阶段编排**

commit 记录的阶段格式清晰：
```
harness: R1 bug_fix
harness: R1 new_tools_and_features
harness: R1 quality_polish
harness: R2 bug_fix
harness: R2 new_tools_and_features
...
```

#### 为什么开始"瞎搞"

R1/R2 的流水线用代码定义就是三个 `PhaseConfig` 按顺序串起来：
```python
@dataclass
class PhaseConfig:
    name: str                      # bug_fix / features / polish
    index: int                     # 阶段序号，固定顺序
    system_prompt: str             # LLM 指令模板
    mode: "debate" | "implement"   # debate=出方案, implement=直接改代码
    skip_after_round: int | None   # 跑几轮后跳过这个阶段
    run_tests: bool = False        # 改完后要不要跑测试
```

- **LLM 不知道整体目标**，只知道当前阶段的名字
- **三个阶段的分工模糊**：`quality_polish` 和 `bug_fix` 的边界说不清
- **代码越来越大**，装不进 Context，LLM 开始对着片段修改，缺乏全局视野
- **改动之间缺乏连贯性**：前一个阶段的决策，下一个阶段的 LLM 不知道

这个阶段最典型的问题：LLM 在 R2 把某个文件重构了，但 R3 的 LLM 不知道，重复改了同一块逻辑，还改回去了。

这些问题的根源在于固定编排太死板了。我意识到，与其给 LLM 规定"先做 bug_fix 再做 polish"，不如让它自己看代码、自己决定改什么。于是有了 R3 的架构重构。

### 阶段三——自我编排（R3 至 cycle 67，后进入阶段四）

#### 架构重构

4 月 16 日的 R3 是一次重大重构（单次 commit 删除 1489 行，新增 169 行）：

<img src="/images/mermaid/evolution-zh-12.svg" alt="R3 架构重构" style="max-width:100%;">

**Figure 4.4 — R3 架构重构：从大文件混合到职责分离**

#### 砍掉 Debate，让 Agent 自己思考

R3 同时砍掉了内置的辩论机制，改为让 agent 自己决定改什么：

<img src="/images/mermaid/evolution-zh-13.svg" alt="从固定辩论到 Agent 自由编排" style="max-width:100%;">

**Figure 4.5 — 从固定辩论到 Agent 自由编排**

不再有人告诉 agent "这轮你要修 bug"还是"这轮你要加功能"。这是真实的一次 cycle 提交的 diff：
```diff
commit 052c651 — harness: R5 traceability_and_structure [score=3.8]
Tool usage: read_file=10, grep_search=9, glob_search=1

--- a/tests/unit/tools/test_file_read_security.py
+++ b/tests/unit/tools/test_file_read_security.py
@@ -37,13 +37,13 @@ async def test_readfile_atomic_open_prevents_symlink_swap():
 
-        # Test 1: Reading through a symlink should work (following symlinks)
+        # Test 1: Reading through a symlink should fail with O_NOFOLLOW
         result = await tool.execute(config, path=str(symlink_path))
-        assert not result.is_error
-        assert "public content" in result.output
+        assert result.is_error
+        assert "symlink" in result.error.lower() or "ELOOP" in str(result.error)
 
         # Test 2: Replace symlink target after validation would occur
-        # should prevent this.
+        # should prevent this by rejecting symlinks entirely.
         symlink_path.unlink()
         symlink_path.symlink_to(secret_file)
 
-        # Attempt read - should still work because we follow symlinks
+        # Attempt read - should fail because symlinks are rejected
         result = await tool.execute(config, path=str(symlink_path))
-        assert not result.is_error
-        assert "secret content" in result.output
+        assert result.is_error
+        assert "symlink" in result.error.lower() or "ELOOP" in str(result.error)
```
agent 自己发现路径安全检查不够严格（跟随了符号链接），自己把测试从"跟随符号链接应该正常工作"改成了"应该拒绝符号链接"。没有人在前面告诉它要改什么——它自己读代码、自己发现的漏洞、自己修的。
没有人在前面指挥它——它自己看的代码、自己做的判断。

从 4 月 23 日的 cycle 记录可以看到自我编排的成熟：
- 67 次 cycle，每次 agent 自己决定改哪里
- 测试从初版自动增长到 2700+（agent 自己写的）
- 代码经过持续优化，架构越来越清晰

#### 自我进化的效果与边界

**效果还行的方面**：
- 测试覆盖率显著提升（每轮都在补测试）
- 代码质量持续优化（lint clean，重复逻辑合并）
- 工具系统从 30 个扩展到 35 个专用工具

**做不到的事情**：
- **真正的自我演化**：LLM 能改代码，但无法改变自己的"思维方式"
- **架构级创新**：改的都是已有结构内的优化，无法自发设计出全新架构
- **跨版本连贯性**：每次 cycle 的 LLM 都是独立的，缺乏跨轮次的记忆

#### 迭代慢的根因分析

现在跑起来最大的感受是：**迭代越来越慢**。表面看是代码趋于稳定，但根因不在这里。

两个核心问题：
- **评判机制不够**：dual evaluator 给的分数越来越平，无法区分"还行"和"真的好"。没有好的评判信号，agent 就不知道往哪里优化，只能在已有结构里反复打磨
- **没有新业务驱动**：纯粹让 agent 自由改进，它只会做减法（优化、清理、补测试）；做不出加法（新功能、新能力）。没有业务需求驱动，改进空间自然越来越窄

### 阶段四——指标驱动

针对上面提到的两个核心问题，最近在代码里落地了第一批指标驱动的组件：

#### 已落地的组件

<img src="/images/mermaid/evolution-zh-14.svg" alt="方向驱动 + 指标闭环" style="max-width:100%;">

**Figure 4.6 — 方向驱动 + 指标闭环**

已落地的组件：

| 模块 | 作用 |
|:---|:---|
| `harness/pipeline/intel_metrics.py` | 跨 cycle 的智能指标收集与分析 |
| `harness/agent/cycle_metrics.py` | 每个 cycle 的细粒度指标（上下文质量、记忆&学习等维度） |
| `benchmarks/evaluator_calibration/` | 评估器校准基准——用不同质量等级的提案验证 evaluator 打分是否准确 |

核心思路：不让 agent 自己决定"改什么"，而是：
1. **人给方向**：先给出业务方向和大致方案，让 agent 去实现
2. **生成指标**：实现后产生可量化的指标（测试覆盖、质量分、性能数据）
3. **指标闭环**：根据指标去提升和维护，评判机制有了真实的锚点

以 `cycle_metrics.py` 里的工具分类为例，这段代码就是指标系统的一部分：
```python
# 只读工具——收集上下文，不改代码
_READ_TOOLS = {
    "read_file", "grep_search", "glob_search",
    "list_directory", "tree", "symbol_extractor",
    "git_status", "git_diff", "git_log",
}

# 写工具——实际修改代码
_WRITE_TOOLS = {
    "edit_file", "write_file", "delete_file",
    "move_file", "file_patch", "find_replace",
}
```
每轮 cycle 结束后，系统会根据 agent 用了哪些工具、改了多少文件、测试覆盖率变化，生成结构化指标。有了这些，evaluator 不再凭空打分，agent 也能看到自己"做对了什么"。

### 阶段五——V5 结构化演进（2026-04-24）

#### 四个瓶颈，四个模块

阶段四暴露的问题在 V5 中得到了针对性的解决——不是修修补补，而是用四个新模块重构了评判、记忆、探索和策略四个维度：

| 瓶颈 | V5 模块 | 核心变化 |
|:---|:---|:---|
| 评判趋平（单一分数区分度低） | `multi_axis.py` | 5 维向量（正确性/代码质量/架构健康/新颖度/策略一致性）替代 0-10 单分 |
| 无跨周期记忆（每轮失忆） | `experience.py` | 结构化经验：不只记"做了什么"，还记录 LLM 的自我反思和提炼出的可复用模式 |
| 纯 exploitation（只会打磨） | Exploration Mode | 每 N 轮插入一次探索轮，新颖度权重从 10% 提到 50%，鼓励大胆尝试 |
| 无法自修改（改不了评判标准） | `eval_config.py` + `meta_agent.py` | EvalConfig 热重载 + MetaAgent 策略层：agent 能改自己的 evaluator prompt 和权重 |

#### 最有意思的变化：MetaAgent

V5 最值得讲的不是多轴评估本身——维度拆分是自然演进——而是 MetaAgent。它每 5-10 轮运行一次，不写代码，只读 ExperienceStore 里的经验趋势，然后输出策略调整：

```
MetaAgent 看到: "最近 5 轮，正确性从 6 涨到 8，但新颖度从 5 跌到 2"
MetaAgent 决定:  把新颖度权重从 10% 调到 30%，探索频率从每 5 轮调到每 2 轮
MetaAgent 的决策 → 写到 eval_weights.json → 下次评估热加载 → 不重启生效
```

这是 agent 第一次能改变"评判自己的标准"。之前所有版本里，evaluator prompt 和权重是人写死、人调整的；V5 把这个权力交了一部分给 agent 自己。

但落地的过程中也发现冷启动问题：MetaAgent 依赖 ExperienceStore 里的高质量经验做决策，而高质量经验又依赖校准好的 evaluator。解决方式是在前几轮用保守默认权重跑出一批基线经验，再激活 MetaAgent。

#### V5 为止的完整演化

作为对照，下面是 cycle 67 时的能力分布——新指标体系的目标就是把这些点往右上角推：

<img src="/images/mermaid/evolution-zh-15.svg" alt="Harness 能力分布象限图" style="max-width:100%;">

**Figure 4.7 — Harness 在不同任务类型上的自我改进能力分布（cycle 67 基准线）**

### 五个版本的演化对比

<img src="/images/mermaid/evolution-zh-16.svg" alt="Harness 五个版本演化时间线" style="max-width:100%;">

**Figure 4.8 — Harness 五个版本演化时间线**

Harness 走完了五个阶段，Skills 也走完了五个阶段。看上去是两个独立的技术故事，没什么特别的。但把两个项目的时间线叠在一起，我发现了让自己都没想到的事。

## 两条线的交汇

### 惊人的平行轨迹

Skills 和 Harness 是两个独立启动的项目，解决的问题也不同——一个管开发流程，一个管代码自我改进。但把它们的演化阶段摆在一起看：

| 阶段 | Skills | Harness |
|:---|:---|:---|
| **初版** | 固定 6 阶段流水线，硬编码顺序 | 固定 3 阶段流水线（bug_fix → features → polish） |
| **拆分** | 拆成 8 个独立子 skill，每个有独立规则 | 拆成职责分离的模块（phase_runner / evaluator / pipeline） |
| **编排升级** | 去序号，编排者观察文件系统按需调度 | 砍掉固定辩论，让 Agent 自行决定改什么 |
| **指标驱动** | 稳定使用，持续迭代 | intel_metrics / cycle_metrics / benchmarks 落地，评估信号增强 |
| **结构化演进** | —（Skills 暂无对应阶段） | V5：多轴评估 + 经验记忆 + 探索机制 + MetaAgent 策略层 |

两个项目在互不知情的情况下走出了几乎相同的路径：

<img src="/images/mermaid/evolution-zh-17.svg" alt="Skills 和 Harness 经历了相同的演化阶段" style="max-width:100%;">

**Figure 5.1 — Skills 和 Harness 经历了相同的演化阶段**

### 这个模式说明了什么

**编排者模式不是某个项目的特定设计，而是一个通用范式。**

不管是编排开发流程还是编排代码改进，核心结构是一样的：有一个观察者读取当前状态，有一个决策者判断下一步做什么，然后调度执行单元去完成。Skills 的 req 编排器观察文件系统，Harness 的 pipeline 观察代码仓库；Skills 的子 skill 是需求分析/技术设计/编码，Harness 的执行单元是工具调用/代码修改。**抽象层不同，模式相同。**

这个模式不是设计出来的，是迭代出来的。两个项目都是从固定流水线起步，因为硬编码走不远才自然演变成编排者模式。这说明一件事：**如果你做一个需要持续迭代的项目，它的架构会自己"长出来"，不需要一开始就设计完美。**

### 为什么要有一个自己一直迭代的项目

这是整个文档最想说的建议：

**拥有一个长期维护的个人项目，是你对 AI 理解力的标尺。**

原因有三：

1. **认知会沉淀成代码**——你关于"AI 应该怎么做 X"的每一次思考，都可以写进 skill 或者工具里。三个月前的模糊感觉，变成了三个月后可执行的指令。没有项目承载，这些认知就停留在脑子里，慢慢忘掉。

2. **模式会在迭代中自己浮现**——Skills 和 Harness 的平行演化不是巧合。如果你只做一个项目，你可能觉得"我的架构就这样"。做两个，才会发现背后有共通的规律。这种洞察只有长期迭代才能给你。

3. **项目本身成为协作史**——翻 git log 就能看到你和 AI 的协作怎么演化的：一开始 AI 只负责写代码片段，后来能写完整模块，再后来能自己改进自己的代码。这个记录比任何总结文章都有说服力。

Skills 仓库里有一份 `docs/evolution.md`，就是这个演化过程的书面记录。写它的目的不是给别人看，是给自己回头看——三个月前的自己是怎么想 AI 的，现在有没有进步。

### 开放问题

两条线的交汇也留下了一些还没想通的问题：

- **编排者的天花板在哪里**？Skills 和 Harness 都走到了"编排者按需调度"这个模式，但也都碰到了边界。编排者模式本身是不是也有适用上限？
- **跨项目模式复用**：Skills 总结出的模式（固定流程→拆分→编排），能不能主动用到下一个项目里，而不只是事后发现？
- **个人项目 vs 团队项目**：个人项目可以自由迭代、随便重构。团队项目有兼容性负担。个人项目上验证出的 AI 协作模式，怎么平移到大团队？

## 个人心得总结

### AI 时代对程序员的要求更高

一个容易误解的观点是"AI 让程序员更容易了"。实际感受恰恰相反：
- AI 的上限是你的上限——你想不清楚的，AI 帮你想错的概率更大
- **理解力要求更高**：你需要快速判断 AI 的输出是否正确，这需要扎实的基础
- **表达能力要求更高**：Prompt 写得模糊，AI 就猜；猜错了还是你的锅
- **系统设计能力更重要**：AI 能写函数，但拆不出好的模块边界——那是你的工作

AI 是乘数，不是加法。基础差，乘出来的还是差。

### 选公司也要看 AI 资源

最后一点实用建议：**一定要去一个能无限制提供高质量 AI token 的公司**。

AI 工具的体验有极大的差异：
- 有 token 限制 vs 无限制：工作流完全不同
- 高质量模型 vs 低质量模型：输出质量天壤之别
- 支持 sub-agent vs 不支持：能不能做复杂编排

如果公司的 AI 资源受限，会严重拖慢上述所有工作方式的落地效率。在选择工作机会时，AI 工具的质量和限制，值得认真考量。

### 当前阶段的一些开放问题

还在思考中、还没有答案的问题：

- **Skills 的边界在哪里**？什么时候 skill 太重，应该换成更轻量的对话？
- **指标驱动能走多远**：intel_metrics / cycle_metrics / benchmarks 刚起步，能不能持续打破天花板，还是会遇到新的瓶颈？
- **自然语言编程的成熟度**：什么时候可以完全不写代码，只写 Prompt？
- **团队协作中的 AI**：Skills 和 Prompt 工程的团队化、标准化怎么做？

