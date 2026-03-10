+++
date = '2026-03-10T22:00:00+08:00'
draft = false
title = '[Project] 1. ChromePilot — Control Any Webpage with Natural Language'
categories = ["Project"]
tags = ["Chrome Extension", "LLM", "Browser Automation", "Natural Language Processing"]
+++

<div align="center">
<img src="/images/Project%20-%201%20-%20ChromePilot/chromepilot-icon.png" alt="ChromePilot" width="128">
</div>

## Overview

ChromePilot is a Chrome extension that lets you control any webpage using natural language. Type a command like "click the login button" or "fill in my email", and ChromePilot executes it automatically — clicking, typing, scrolling, and navigating on your behalf.

- Built with AI (Claude) assistance: **3 hours for the initial prototype, 5 hours to polish into v1.0**
- Current status: **v1.0** — functional and usable, with room for further optimization
- GitHub: [GOODDAYDAY/ChromePilot](https://github.com/GOODDAYDAY/ChromePilot)

## Features

| Feature | Description |
|---------|-------------|
| **Natural Language Control** | Type commands like "click the submit button" or "type hello in the search box" |
| **Multi-step Automation** | Chain complex tasks: "Go to Habitica and complete all my daily tasks" |
| **URL Navigation** | Say "open YouTube" or "go to google.com" to navigate anywhere |
| **Smart Result Extraction** | Ask "translate 'hello' on Google Translate" and get the answer in the chat |
| **Persistent Side Panel** | Panel stays open across tab switches (Chrome Side Panel API) |
| **Multi-provider LLM Support** | Works with OpenAI, Anthropic Claude, GitHub Copilot, Ollama (local), or any OpenAI-compatible API |
| **Debug Overlay** | Visualize all detected interactive elements with index numbers |
| **Teach Mode** | Record user actions and save as demonstrations |

## Demo

### Basic Actions — Click Repetition

> Command: *"drink water 10 times"*

![Basic actions demo](/images/Project%20-%201%20-%20ChromePilot/1.%20drink%20water%2010%20times.gif)

ChromePilot identifies the target button and clicks it 10 times automatically.

### In-page Navigation — Multi-step Tasks

> Command: *"go to tasks and drink water 10 times"*

![In-page navigation demo](/images/Project%20-%201%20-%20ChromePilot/2.%20go%20to%20tasks%20and%20drink%20water%2010%20times.gif)

ChromePilot first navigates to the tasks section within the page, then performs the repeated clicking.

### Cross-page Navigation — Open URLs & Extract Results

> Command: *"go to Google Translate and translate 'what is surprise' to Chinese"*

![Cross-page navigation demo](/images/Project%20-%201%20-%20ChromePilot/3.%20go%20to%20google%20translator%20and%20translat%20what%20is%20superpise%20to%20chinese.gif)

ChromePilot opens Google Translate, types the text, and extracts the translation result back to the chat panel.

### Cross-site Automation — Navigate & Interact

> Command: *"go to my GitHub homepage and star the repository ChromePilot"*

![Cross-site automation demo](/images/Project%20-%201%20-%20ChromePilot/4.%20go%20to%20my%20github%20homepage%20and%20star%20the%20repository%20ChromePilot.gif)

ChromePilot navigates to GitHub, finds the repository, and clicks the star button.

### Debug Overlay — Inspect Detected Elements

> Use the eye button to visualize all detected interactive elements with their index numbers.

![Debug overlay demo](/images/Project%20-%201%20-%20ChromePilot/5.%20click%20button%2054.gif)

The debug overlay shows every interactive element ChromePilot detected, each labeled with an index number. You can directly command "click button 54" to interact with a specific element.

## Architecture

### Tech Stack

| Component | Technology |
|-----------|-----------|
| **Platform** | Chrome Extension (Manifest V3) |
| **Language** | Vanilla JavaScript (ES2022+) |
| **UI** | Chrome Side Panel API |
| **AI Integration** | Multi-provider LLM client (Anthropic, OpenAI-compatible) |
| **Build** | None (plain files loaded directly by Chrome) |

### Project Structure

```
src/
├── manifest.json              # Chrome MV3 manifest
├── background/
│   ├── service-worker.js      # Orchestrator: DOM → LLM → Actions loop
│   └── llm-client.js          # Multi-provider LLM client
├── content/
│   ├── content-script.js      # Message handler on web pages
│   ├── dom-extractor.js       # Extracts interactive elements
│   ├── action-executor.js     # Simulates click/type/scroll/read
│   └── action-recorder.js     # Teach mode (recording actions)
├── sidepanel/
│   ├── sidepanel.html         # Chat UI (Chrome Side Panel API)
│   ├── sidepanel.js           # Panel logic & settings
│   └── sidepanel.css          # Styles
├── options/                   # LLM provider configuration page
├── lib/utils.js               # Shared helpers
└── icons/                     # Extension icons
```

### Core Loop

The core execution follows a **DOM → LLM → Action** loop:

1. User types a command in the side panel
2. Service worker extracts interactive elements from the active tab
3. Elements + command are sent to the configured LLM
4. LLM returns a list of actions (`click`, `type`, `scroll`, `navigate`, `read`)
5. Actions are executed sequentially on the page
6. If the task is not done (`done: false`), repeat from step 2 with updated DOM context

### DOM Extraction

The `dom-extractor.js` module identifies interactive elements on the page through multiple phases:

- **Phase 1**: Collect elements matching standard interactive selectors (buttons, inputs, links, ARIA roles)
- **Phase 2**: Find framework-rendered clickable elements via `cursor:pointer` CSS heuristic
- **Phase 3**: Filter noise (empty SVGs, hidden elements), deduplicate parent/child overlaps
- **Dialog Detection**: Detects modals via native `<dialog>`, ARIA roles, or CSS heuristics (fixed/absolute positioning + high z-index)

Each element is returned with an index:
```
[1] <button>Click me</button> (in: Header section)
[2] <input type="text" placeholder="Search..."> (in: Navigation)
```

### LLM Integration

The `llm-client.js` supports multiple providers through a unified interface:

| Provider | Base URL | Auth Header |
|----------|----------|-------------|
| OpenAI | `https://api.openai.com` | `Authorization: Bearer` |
| Anthropic Claude | `https://api.anthropic.com` | `x-api-key` |
| GitHub Copilot | `https://models.inference.ai.azure.com` | `Authorization: Bearer` |
| Ollama (Local) | `http://localhost:11434` | None |
| Custom | Any OpenAI-compatible endpoint | `Authorization: Bearer` |

The system prompt instructs the LLM to respond with structured JSON:
```json
{
  "actions": [
    {"type": "click", "elementIndex": 5},
    {"type": "type", "elementIndex": 12, "text": "hello"}
  ],
  "done": false,
  "summary": "Clicked the search button and typed the query"
}
```

### Action Execution

The `action-executor.js` simulates real user interactions:

| Action | Behavior |
|--------|----------|
| `click` | Dispatches MouseEvent, scrolls element into view first |
| `type` | Focuses input, clears existing value, sets new value with input events |
| `scroll` | Scrolls page in specified direction |
| `navigate` | Opens URL in current tab or new tab |
| `read` | Extracts textContent from target element |
| `repeat` | Clicks same element N times with configurable delay |

Visual feedback is provided: a red border flashes on each element as it is interacted with.

## Development Challenges

### Challenge 1: Noise Element Filtering

A webpage contains far more DOM elements than are useful for automation. Feeding all of them to the LLM wastes tokens and confuses the model. The core question: **how to keep only the elements that matter?**

**Sources of noise**:
- SVG icons inside buttons — each `<svg>`, `<path>`, `<circle>` is a separate element, but none are interactive
- Empty wrapper `<div>` and `<span>` from frameworks (React/Vue) — no text, no label, no role, purely structural
- Invisible elements: `display: none`, `visibility: hidden`, `opacity: 0`, or zero-size bounding boxes
- Parent-child duplication: a `<div role="button">` wrapping an `<a>` tag — both get collected, but only one should be in the list
- `cursor: pointer` heuristic false positives: decorative elements styled as clickable but serving no interactive purpose

**Filtering strategy (three phases)**:

1. **Visibility check**: reject elements with `display: none`, `visibility: hidden`, `opacity: 0`, or zero-size bounding rect. Special case for `position: fixed/sticky` elements which have no `offsetParent`
2. **Noise rejection**: skip all SVG elements; skip `<div>`/`<span>` that have no text content, no `aria-label`, no `id`, and no `role`
3. **Parent-child deduplication**: if an element has an interactive ancestor already in the set, keep only the ancestor. Exception: native interactive elements (`<a>`, `<button>`, `<input>`, `<textarea>`, `<select>`) are always kept regardless of ancestry

The result: a typical page with 500+ raw DOM elements is reduced to 50–150 meaningful interactive elements that the LLM can reason about effectively.

### Challenge 2: Dialog Awareness

The DOM extractor collects interactive elements in DOM order, capped at 150 elements (`DEFAULT_MAX_ELEMENTS = 150`). This works well for regular pages, but breaks completely when a dialog appears:

- Dialogs are typically appended to the end of `<body>` in the DOM
- The 150 elements from the main page content fill up the quota first
- Dialog buttons — the very elements the user wants to interact with — get truncated

For example, on Habitica, clicking a character stat opens a modal with action buttons. But the page behind it already has 150+ interactive elements (navigation links, task buttons, sidebar items). The modal's buttons, sitting at the end of the DOM, never make it into the element list. The LLM cannot see them, so it cannot operate them.

An additional complication: framework-rendered dialogs (Vue/React) often use plain `<div>` with `@click` handlers instead of semantic `<button>` or ARIA roles. These elements have no `role`, no `tabindex`, no `cursor:pointer` — they are invisible to both Phase 1 (selector matching) and Phase 2 (cursor heuristic) of the extractor.

**Key insight**: dialogs are small. A typical dialog contains 5–20 interactive elements — far less than the 150 cap. There is no reason to limit them.

The solution restructures extraction into a **dialog-first** strategy:

1. **Detect active dialogs** using a three-layer approach:
   - Native `<dialog[open]>`
   - ARIA attributes: `[role="dialog"]`, `[role="alertdialog"]`, `[aria-modal="true"]`
   - CSS heuristic fallback: `position: fixed/absolute` + `z-index >= 100` + reasonable size + contains interactive elements

2. **Separate elements into two groups**: dialog elements and page background elements

3. **Dialog elements go first with no cap**: since dialogs are small, include all of them starting from index `[1]`

4. **Relaxed filtering inside dialogs**: scan all child elements in the dialog container, not just those matching interactive selectors. Include any visible element with direct text content, `aria-label`, or `role`. This catches framework-rendered buttons that lack semantic markup

5. **Page elements follow with the original 150 cap**: the background page still gets its full quota

6. **Context annotation**: dialog elements are labeled with `(in: dialog: {title})`, and the element list header includes `⚠ Active dialog detected — dialog elements listed first`

This approach ensures dialog buttons are always visible to the LLM, regardless of how many elements the background page has.

## Configuration

### LLM Provider Setup

1. Right-click the ChromePilot icon → **Options**
2. Select a provider preset or enter a custom endpoint
3. Enter the API key and model name
4. Click **Test Connection** to verify

### Panel Settings

| Setting | Options | Default | Description |
|---------|---------|---------|-------------|
| Same Tab Navigation | On / Off | Off | Navigate in current tab instead of opening new tabs |
| Max Steps | 5 / 10 / 20 / 50 / Unlimited | 10 | Maximum LLM rounds per command |
| Action Delay | 0s – 5s | 0.5s | Delay between each action execution |

## Requirements

- Chrome 114+ (for Side Panel API support)
- An LLM API endpoint (cloud or local)

## Source Code

- GitHub: [GOODDAYDAY/ChromePilot](https://github.com/GOODDAYDAY/ChromePilot)
- License: MIT
