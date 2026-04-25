# [Project] 1. ChromePilot — 用自然语言控制任何网页


<div align="center">
<img src="/images/Project%20-%201%20-%20ChromePilot/chromepilot-icon.png" alt="ChromePilot" width="128">
</div>

## 概述

ChromePilot 是一个 Chrome 扩展，让你用自然语言控制任何网页。输入 "点击登录按钮" 或 "在搜索框输入 hello"，ChromePilot 就会自动执行——点击、输入、滚动、导航，说什么做什么。

- 结合 AI（Claude）辅助开发：**3 小时完成初版原型，5 小时优化到 v1.0**
- 当前状态：**v1.0** — 功能可用，仍有优化空间
- GitHub：[GOODDAYDAY/ChromePilot](https://github.com/GOODDAYDAY/ChromePilot)

## 功能特点

| 功能 | 说明 |
|------|------|
| **自然语言控制** | 输入 "点击提交按钮"、"在搜索框输入 hello world" 即可执行 |
| **多步连续操作** | 支持复杂任务链："打开 Habitica 然后完成所有每日任务" |
| **智能导航** | 说 "打开百度"、"去 YouTube" 即可跳转 |
| **结果提取** | 问 "用谷歌翻译翻译 hello"，直接在聊天框返回翻译结果 |
| **全局侧边栏** | 切换标签页后面板依然保留（Chrome Side Panel API） |
| **多 LLM 支持** | 支持 OpenAI、Anthropic Claude、GitHub Copilot、Ollama（本地）等 |
| **调试模式** | 可视化页面上所有被检测到的交互元素及其编号 |
| **教学模式** | 录制用户操作并保存为示范 |
| **操作预览与确认** | 执行前以可视化高亮预览计划操作；可输入反馈让 AI 重新分析 |
| **自动执行模式** | 开启后跳过确认，直接执行操作 |

## 演示

### 基础操作 — 重复点击

> 命令：*"drink water 10 times"*

![基础操作演示](/images/Project%20-%201%20-%20ChromePilot/1.%20drink%20water%2010%20times.gif)

ChromePilot 识别目标按钮并自动点击 10 次。

### 页内导航 — 多步连续任务

> 命令：*"go to tasks and drink water 10 times"*

![页内导航演示](/images/Project%20-%201%20-%20ChromePilot/2.%20go%20to%20tasks%20and%20drink%20water%2010%20times.gif)

ChromePilot 先在页面内导航到任务区域，再执行重复点击操作。

### 跨页导航 — 打开网址 & 提取结果

> 命令：*"go to Google Translate and translate 'what is surprise' to Chinese"*

![跨页导航演示](/images/Project%20-%201%20-%20ChromePilot/3.%20go%20to%20google%20translator%20and%20translat%20what%20is%20superpise%20to%20chinese.gif)

ChromePilot 打开 Google 翻译，输入文本，并将翻译结果提取回聊天面板。

### 跨站自动化 — 导航到其他网站并操作

> 命令：*"go to my GitHub homepage and star the repository ChromePilot"*

![跨站自动化演示](/images/Project%20-%201%20-%20ChromePilot/4.%20go%20to%20my%20github%20homepage%20and%20star%20the%20repository%20ChromePilot.gif)

ChromePilot 导航到 GitHub，找到仓库，点击 Star 按钮。

### 调试模式 — 可视化检测到的元素

> 点击眼睛按钮查看页面上所有被检测到的交互元素及其编号。

![调试模式演示](/images/Project%20-%201%20-%20ChromePilot/5.%20click%20button%2054.gif)

调试模式展示 ChromePilot 检测到的每个交互元素，每个元素都标有索引编号。你可以直接输入 "click button 54" 与指定元素交互。

### 操作预览与确认 — 执行前审查

> 操作以编号标签高亮显示。确认后执行，或输入反馈让 AI 重新分析。

![操作预览演示](/images/Project%20-%201%20-%20ChromePilot/6.%20show%20batch%20actions%20with%20confirm%20first.gif)

### 自动执行模式 — 跳过确认

> 开启 "Auto-run" 后，操作将直接执行，不再预览。

![自动执行演示](/images/Project%20-%201%20-%20ChromePilot/7.%20show%20the%20auto-run.gif)

## 架构

### 技术栈

| 组件 | 技术 |
|------|------|
| **平台** | Chrome 扩展（Manifest V3） |
| **语言** | 原生 JavaScript（ES2022+） |
| **UI** | Chrome Side Panel API |
| **AI 集成** | 多 Provider LLM 客户端（Anthropic、OpenAI 兼容） |
| **构建** | 无（纯文件直接加载） |

### 项目结构

```
src/
├── manifest.json              # Chrome MV3 清单文件
├── background/
│   ├── service-worker.js      # 调度器：DOM → LLM → Actions 循环
│   └── llm-client.js          # 多 Provider LLM 客户端
├── content/
│   ├── content-script.js      # 网页消息处理
│   ├── dom-extractor.js       # 提取交互元素
│   ├── action-executor.js     # 模拟 click/type/scroll/read
│   ├── action-previewer.js    # 预览覆盖层（红色边框 + 步骤标签）
│   └── action-recorder.js     # 教学模式（录制操作）
├── sidepanel/
│   ├── sidepanel.html         # 聊天界面（Chrome Side Panel API）
│   ├── sidepanel.js           # 面板逻辑 & 设置
│   └── sidepanel.css          # 样式
├── options/                   # LLM 配置页面
├── lib/utils.js               # 公共工具函数
└── icons/                     # 扩展图标
```

### 核心循环

核心执行流程遵循 **DOM → LLM → Action** 循环：

1. 用户在侧边栏输入命令
2. Service Worker 提取当前标签页的交互元素
3. 元素列表 + 命令发送给配置的 LLM
4. LLM 返回操作列表（`click`、`type`、`scroll`、`navigate`、`read`）
5. 以红色高亮和步骤标签预览操作（除非开启了自动执行模式）
6. 用户确认执行，或输入反馈让 AI 重新分析
7. 确认后按顺序在页面上逐个执行操作
8. 如果任务未完成（`done: false`），从第 2 步重新开始，使用更新后的 DOM 上下文

### DOM 提取

`dom-extractor.js` 模块通过多个阶段识别页面上的交互元素：

- **阶段 1**：收集匹配标准交互选择器的元素（按钮、输入框、链接、ARIA 角色）
- **阶段 2**：通过 `cursor:pointer` CSS 启发式方法查找框架渲染的可点击元素
- **阶段 3**：过滤噪声（空 SVG、隐藏元素），去除父子重叠
- **对话框检测**：通过原生 `<dialog>`、ARIA 角色或 CSS 启发式方法（fixed/absolute 定位 + 高 z-index）检测模态框

每个元素带索引返回：
```
[1] <button>点击我</button> (in: 头部区域)
[2] <input type="text" placeholder="搜索..."> (in: 导航栏)
```

### LLM 集成

`llm-client.js` 通过统一接口支持多个 Provider：

| Provider | 地址 | 认证方式 |
|----------|------|----------|
| OpenAI | `https://api.openai.com` | `Authorization: Bearer` |
| Anthropic Claude | `https://api.anthropic.com` | `x-api-key` |
| GitHub Copilot | `https://models.inference.ai.azure.com` | `Authorization: Bearer` |
| Ollama（本地） | `http://localhost:11434` | 无 |
| 自定义 | 任何 OpenAI 兼容接口 | `Authorization: Bearer` |

系统提示词指示 LLM 以结构化 JSON 响应：
```json
{
  "actions": [
    {"type": "click", "elementIndex": 5},
    {"type": "type", "elementIndex": 12, "text": "hello"}
  ],
  "done": false,
  "summary": "点击了搜索按钮并输入了查询内容"
}
```

### 操作执行

`action-executor.js` 模拟真实用户交互：

| 操作 | 行为 |
|------|------|
| `click` | 派发 MouseEvent，先将元素滚动到可视区域 |
| `type` | 聚焦输入框，清除现有值，通过 input 事件设置新值 |
| `scroll` | 按指定方向滚动页面 |
| `navigate` | 在当前标签页或新标签页打开 URL |
| `read` | 提取目标元素的 textContent |
| `repeat` | 以可配置的延迟点击同一元素 N 次 |

交互时提供视觉反馈：每个元素被操作时会闪烁红色边框。

## 开发难点

### 难点 1：噪声元素过滤

网页包含的 DOM 元素远比自动化需要的多。把所有元素都喂给 LLM 会浪费 token 并干扰模型判断。核心问题：**如何只保留有用的元素？**

**噪声来源**：
- 按钮内的 SVG 图标——每个 `<svg>`、`<path>`、`<circle>` 都是独立元素，但都不可交互
- 框架（React/Vue）生成的空 `<div>` 和 `<span>` 包裹层——没有文本、没有 label、没有 role，纯粹是结构性的
- 不可见元素：`display: none`、`visibility: hidden`、`opacity: 0`，或边界框尺寸为零
- 父子重复：一个 `<div role="button">` 包裹一个 `<a>` 标签——两个都会被收集，但列表里只需要一个
- `cursor: pointer` 启发式误报：装饰性元素被样式化为可点击，但实际没有交互功能

**过滤策略（三阶段）**：

1. **可见性检查**：排除 `display: none`、`visibility: hidden`、`opacity: 0` 或边界框尺寸为零的元素。`position: fixed/sticky` 元素没有 `offsetParent`，需要特殊处理
2. **噪声排除**：跳过所有 SVG 元素；跳过没有文本内容、没有 `aria-label`、没有 `id`、没有 `role` 的 `<div>`/`<span>`
3. **父子去重**：如果一个元素已经有交互祖先在集合中，只保留祖先。例外：原生交互元素（`<a>`、`<button>`、`<input>`、`<textarea>`、`<select>`）无论祖先关系一律保留

最终效果：一个包含 500+ 原始 DOM 元素的典型页面会被缩减到 50–150 个有意义的交互元素，LLM 可以有效地推理这些元素。

### 难点 2：弹窗感知

DOM 提取器按 DOM 顺序收集交互元素，上限为 150 个（`DEFAULT_MAX_ELEMENTS = 150`）。这在普通页面上工作正常，但在弹窗出现时完全失效：

- 弹窗通常 append 在 `<body>` 的末尾
- 页面主体内容的 150 个元素先占满配额
- 弹窗内的按钮——恰恰是用户想要操作的元素——被截断

例如在 Habitica 上，点击角色属性会弹出一个带操作按钮的模态框。但背后的页面已经有 150+ 个交互元素（导航链接、任务按钮、侧边栏项目）。模态框的按钮在 DOM 末尾，根本进不了元素列表。LLM 看不到它们，自然也无法操作。

还有一个额外的复杂性：框架渲染的弹窗（Vue/React）经常用普通 `<div>` + `@click` 处理器代替语义化的 `<button>` 或 ARIA 角色。这些元素没有 `role`、没有 `tabindex`、没有 `cursor:pointer`——提取器的阶段 1（选择器匹配）和阶段 2（cursor 启发式）都捞不到。

**核心洞察**：弹窗本身很小。一个典型的弹窗包含 5–20 个交互元素——远小于 150 的上限。没有理由限制它们。

解决方案将提取重构为**弹窗优先**策略：

1. **检测活跃弹窗**，三层策略：
   - 原生 `<dialog[open]>`
   - ARIA 属性：`[role="dialog"]`、`[role="alertdialog"]`、`[aria-modal="true"]`
   - CSS 启发式兜底：`position: fixed/absolute` + `z-index >= 100` + 合理尺寸 + 包含交互元素

2. **将元素分为两组**：弹窗元素和页面背景元素

3. **弹窗元素优先排列，不设上限**：弹窗很小，全部从索引 `[1]` 开始加入

4. **弹窗内宽松过滤**：扫描弹窗容器内的所有子元素，不局限于交互选择器。只要可见元素有直接文本内容、`aria-label` 或 `role`，一律收录。这样可以捕获缺少语义标记的框架渲染按钮

5. **页面元素随后，保留原有 150 上限**：背景页面仍然获得完整配额

6. **上下文标注**：弹窗内元素标注为 `(in: dialog: {标题})`，元素列表头部增加 `⚠ Active dialog detected — dialog elements listed first` 提示

这样无论背景页面有多少元素，弹窗按钮都一定会被 LLM 看到。

## 配置

### LLM Provider 设置

1. 右键 ChromePilot 图标 → **选项**
2. 选择 Provider 预设或输入自定义端点
3. 填入 API Key 和模型名称
4. 点击 **Test Connection** 测试连接

### 面板设置

| 设置 | 选项 | 默认值 | 说明 |
|------|------|--------|------|
| 当前页跳转 | 开 / 关 | 关 | 导航时在当前标签页打开而非新标签页 |
| 自动执行 | 开 / 关 | 关 | 跳过操作预览，直接执行 |
| 最大步数 | 5 / 10 / 20 / 50 / 无限 | 10 | 每条命令最多执行的 LLM 轮次 |
| 操作间隔 | 0s – 5s | 0.5s | 每个操作之间的等待时间 |

## 系统要求

- Chrome 114+（需要 Side Panel API）
- 一个 LLM API 端点（云端或本地均可）

## 源代码

- GitHub：[GOODDAYDAY/ChromePilot](https://github.com/GOODDAYDAY/ChromePilot)
- 许可证：MIT

