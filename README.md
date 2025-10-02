# GoodyHao's Blog

A bilingual (English/Chinese) technical blog built with Hugo and the LoveIt theme, hosted on GitHub Pages.

🌐 **Live Site**: [https://gooddayday.github.io](https://gooddayday.github.io)

## 📖 Overview

This is a static blog site featuring:
- **Bilingual Support**: Full English and Chinese content with seamless language switching
- **Modern Hugo Setup**: Using Hugo extended version with SASS support
- **LoveIt Theme**: Clean, elegant theme with extensive customization
- **Automated Deployment**: GitHub Actions workflow for CI/CD
- **Rich Features**: Search (Algolia), comments (giscus), auto-numbering, and more

## 🚀 Quick Start

### Prerequisites

- [Hugo Extended](https://gohugo.io/installation/) (latest version)
- Git

### Local Development

1. **Clone the repository with theme submodule**:
   ```bash
   git clone https://github.com/GOODDAYDAY/GOODDAYDAY.github.io.git
   cd GOODDAYDAY.github.io
   git submodule update --init --recursive
   ```

2. **Start local development server**:
   ```bash
   # Development mode with drafts
   hugo server --buildDrafts --disableFastRender

   # Production preview
   hugo server --minify --disableFastRender --environment production
   ```

3. **Visit**: http://localhost:1313

### Build for Production

```bash
hugo --minify
```

The generated site will be in the `public/` directory.

## ✍️ Writing Blog Posts

### Creating New Posts

**English Post**:
```bash
hugo new en/posts/your-post-title.md
```

**Chinese Post**:
```bash
hugo new zh/posts/your-post-title.md
```

### Post Frontmatter Template

```toml
+++
date = '2025-10-02T10:23:17+08:00'
draft = false
title = 'Your Post Title'
categories = ["Technology", "Programming"]
tags = ["Hugo", "Web", "Development"]
+++

# Your Post Title

Your content here...
```

### Bilingual Content Best Practices

1. **Matching Filenames**: Use the same filename for both language versions
   - English: `content/en/posts/14. Spring Async ThreadPool and Thread Reuse.md`
   - Chinese: `content/zh/posts/14. Spring Async ThreadPool and Thread Reuse.md`

2. **Consistent Frontmatter**: Keep the same date, categories, and tags structure

3. **Image References**: Use absolute paths
   ```markdown
   ![Description](/images/post-title/image-name.svg)
   ```

### Managing Images

- **Location**: Store images in `static/images/` organized by post title
- **Structure**:
  ```
  static/images/
  ├── post-title-1/
  │   ├── diagram.svg
  │   └── screenshot.png
  └── post-title-2/
      └── photo.jpg
  ```
- **Reference in posts**: `/images/post-title/image-name.ext`

## 🎨 Customizations

### Custom CSS: Auto-Numbering

**Location**: `assets/css/auto-numbering.css`

This custom CSS automatically numbers all headings (H2-H6) in blog posts and the table of contents.

**Features**:
- H1 (article title) is not numbered
- H2 starts with "1. ", H3 with "1.1 ", etc.
- Synced numbering in both content and TOC
- Dark mode compatible
- Can be disabled per post with `.no-numbering` class

**How it works**:
- Configured in `hugo.toml` under `[params.page.library.css]`
- Uses CSS counters for automatic hierarchical numbering
- Applied to `.single .content` and `.page .content` sections

**To disable for a specific post**, wrap content in:
```html
<div class="no-numbering">

## Your heading without numbers

</div>
```

### Custom CSS: SVG Full Width Display

**Location**: `assets/css/svg-fullwidth.css`

Automatically displays all SVG images at 100% width in blog posts for better visual presentation.

**Features**:
- All SVG images display at full content width
- **Height constraint**: Max 600px on desktop, 500px on tablet, 400px on mobile
- Maintains aspect ratio with `object-fit: contain`
- Responsive design for mobile devices
- Works with images in `<p>`, `<a>`, and `<figure>` tags
- Dark mode compatible
- Optional shadow effects (commented out by default)

**How it works**:
- Configured in `hugo.toml` under `[params.page.library.css]`
- Targets all images with `.svg` extension
- Auto-centers images with proper margins

**Configuration** in `hugo.toml`:
```toml
[params.page.library.css]
svgFullWidth = "css/svg-fullwidth.css"
```

**Usage**: Just insert SVG images normally in markdown:
```markdown
![Diagram](/images/post-title/diagram.svg)
```
The CSS automatically applies 100% width styling.

### Custom Header Partial

**Location**: `layouts/partials/header.html`

Overrides the default theme header to provide:
- **Simplified Language Switcher**: Shows "中文" / "English" instead of full language names
- **Cleaner UI**: Direct language switching without dropdown menu
- **Mobile Support**: Same simplified switcher on mobile devices

**Customization example** (lines 67-71, 78-83):
```html
{{- if eq .Language.LanguageCode "zh-CN" -}}
    中文
{{- else -}}
    English
{{- end -}}
```

### Adding Custom CSS

1. Create your CSS file in `assets/css/`:
   ```bash
   touch assets/css/my-custom-style.css
   ```

2. Reference it in `hugo.toml`:
   ```toml
   [params.page.library.css]
   myCustomStyle = "css/my-custom-style.css"
   ```

### Adding Custom Shortcodes

Create shortcode files in `layouts/shortcodes/`:

**Example**: `layouts/shortcodes/note.html`
```html
<div class="custom-note">
    {{ .Inner | markdownify }}
</div>
```

**Usage in posts**:
```markdown
{{< note >}}
This is a custom note!
{{< /note >}}
```

## 🔧 Configuration

### Key Configuration Files

| File | Purpose |
|------|---------|
| `hugo.toml` | Main Hugo configuration (multilingual, theme, features) |
| `assets/css/auto-numbering.css` | Custom heading numbering styles |
| `layouts/partials/header.html` | Custom header with simplified language switcher |
| `.github/workflows/deploy.yaml` | GitHub Actions deployment workflow |

### Important Hugo Settings

**Multilingual Setup** (`hugo.toml`):
```toml
defaultContentLanguage = "en"
defaultContentLanguageInSubdir = true  # All languages have URL prefix

[languages.en]
  weight = 1
  contentDir = "content/en"

[languages.zh-cn]
  weight = 2
  contentDir = "content/zh"
```

**Search Configuration** (Algolia):
```toml
[params.search]
  enable = true
  type = "algolia"

[languages.en.params.search.algolia]
  index = "index.en"
  appID = "PASDMWALPK"

[languages.zh-cn.params.search.algolia]
  index = "index.zh-cn"
  appID = "PASDMWALPK"
```

**Comments** (giscus):
```toml
[params.page.comment.giscus]
  enable = true
  repo = "GOODDAYDAY/GOODDAYDAY.github.io"
  repoId = "R_kgDOPtWtCQ"
  category = "Announcements"
  categoryId = "DIC_kwDOPtWtCc4CvteQ"
```

## 🚢 Deployment

### Automatic Deployment

Every push to the `master` branch triggers automatic deployment via GitHub Actions:

1. Checks out repository with theme submodule
2. Installs Hugo extended version
3. Builds site with minification
4. Deploys to `gh-pages` branch

**Workflow file**: `.github/workflows/deploy.yaml`

### Manual Deployment

You can also trigger deployment manually from the GitHub Actions tab.

### Required Secrets

- `TOKEN_GITHUB`: GitHub personal access token with repo permissions
  - Set in repository Settings → Secrets and variables → Actions

## 📁 Project Structure

```
.
├── content/
│   ├── en/posts/              # English blog posts
│   ├── zh/posts/              # Chinese blog posts (简体中文)
│   └── posts/                 # Legacy posts
├── static/
│   └── images/                # Blog post images organized by title
├── layouts/
│   ├── partials/
│   │   └── header.html        # Custom header with language switcher
│   └── shortcodes/            # Custom Hugo shortcodes
├── assets/
│   └── css/
│       └── auto-numbering.css # Custom heading numbering styles
├── themes/
│   └── LoveIt/                # Theme submodule (v0.3.0)
├── .github/
│   └── workflows/
│       └── deploy.yaml        # GitHub Actions deployment
├── hugo.toml                  # Main configuration
├── CLAUDE.md                  # AI assistant guidance
└── public/                    # Generated site (git-ignored)
```

## 🔍 Search Setup (Algolia)

This blog uses Algolia for search functionality with separate indexes for each language:
- English: `index.en`
- Chinese: `index.zh-cn`

To update search indexes, you'll need to configure Algolia indexing (not automated in this setup).

## 💬 Comments Setup (giscus)

Comments are powered by GitHub Discussions via giscus:
- Connected to this repository's Discussions
- Requires users to have GitHub accounts
- Comments are stored as GitHub Discussions in the "Announcements" category

## 🎯 Development Tips

### Drafts

Create draft posts with `draft = true` in frontmatter:
```toml
+++
draft = true
title = "Work in Progress"
+++
```

View drafts locally: `hugo server --buildDrafts`

### Live Reload

Use `--disableFastRender` for more reliable live reload during development.

### Testing Multilingual

- English content: http://localhost:1313/en/
- Chinese content: http://localhost:1313/zh-cn/

### Checking Build

```bash
# Build with drafts to check for errors
hugo --buildDrafts

# Build for production
hugo --minify
```

## 📝 License

This blog content is licensed under [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/).

## 🤝 Contributing

This is a personal blog, but suggestions and corrections are welcome via issues.

## 🔗 Links

- **Live Site**: https://gooddayday.github.io
- **GitHub Repository**: https://github.com/GOODDAYDAY/GOODDAYDAY.github.io
- **Hugo Documentation**: https://gohugo.io/documentation/
- **LoveIt Theme**: https://github.com/dillonzq/LoveIt
