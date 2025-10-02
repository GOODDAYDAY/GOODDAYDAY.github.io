# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Hugo-based bilingual static blog site hosted on GitHub Pages. The site uses the LoveIt theme with full support for both English and Chinese content.

## Architecture

- **Hugo Static Site Generator**: Uses latest extended version with SASS support
- **LoveIt Theme**: Git submodule at `themes/LoveIt` (pinned to v0.3.0)
- **Bilingual Content Structure**:
  - English posts: `content/en/posts/`
  - Chinese posts: `content/zh/posts/`
  - Non-English posts: `content/posts/` (legacy structure)
- **Deployment**: GitHub Actions workflow automatically builds and deploys to GitHub Pages
- **Configuration**: Single `hugo.toml` file with multilingual configuration for both English and Chinese

## Common Development Commands

### Local Development

```bash
# Start local development server
hugo server --buildDrafts --disableFastRender

# Start server for production preview
hugo server --minify --disableFastRender --environment production

# Build site for production
hugo --minify
```

### Content Management

```bash
# Create new English blog post
hugo new en/posts/post-title.md

# Create new Chinese blog post
hugo new zh/posts/post-title.md

# Build site and check output
hugo --buildDrafts
```

### Deployment

- Automatic deployment via GitHub Actions on push to `master` branch
- Manual workflow trigger available in GitHub Actions tab
- Deployment target: `gh-pages` branch

## File Structure

```
├── content/
│   ├── en/posts/           # English blog posts
│   ├── zh/posts/           # Chinese blog posts (简体中文)
│   └── posts/              # Legacy posts (non-English/non-Chinese)
├── static/
│   └── images/             # Blog post images organized by post title
├── layouts/
│   ├── partials/           # Custom partial templates
│   └── shortcodes/         # Custom Hugo shortcodes
├── themes/LoveIt/          # Theme submodule
├── .github/workflows/      # GitHub Actions deployment workflow
├── hugo.toml              # Main configuration file (multilingual setup)
└── public/                # Generated site (git-ignored)
```

## Configuration Notes

### Hugo Configuration (`hugo.toml`)

- **Base URL**: `https://gooddayday.github.io`
- **Theme**: LoveIt with light default theme
- **Languages**:
  - English (en): Primary language at `/en/`, contentDir: `content/en`
  - Chinese (zh-cn): Secondary language at `/zh-cn/`, contentDir: `content/zh`
  - Both languages have separate Algolia search indexes
- **Features**: Git info enabled, search via Algolia, comments via giscus
- **Menu Items**: Posts, Tags, Categories, Docs, About, GitHub (for both languages)

### Theme Customization

- Custom partials in `layouts/partials/` for extending theme functionality
- Custom shortcodes in `layouts/shortcodes/` for reusable content components
- Social links configured for GitHub and LinkedIn
- Search functionality configured for Algolia with separate indexes per language
- Comment system using giscus (GitHub Discussions-based)

### Deployment Configuration

- GitHub Actions workflow in `.github/workflows/deploy.yaml`
- Uses Hugo extended version with caching for performance
- Deploys to `gh-pages` branch using `TOKEN_GITHUB` secret
- Minification enabled for production builds

## Content Guidelines

### Blog Post Structure

Posts should include frontmatter with:

```toml
+++
date = '2025-09-10T22:11:17+08:00'
draft = false
title = 'Post Title'
categories = ["category1", "category2"]
tags = ["tag1", "tag2", "tag3"]
+++
```

### Bilingual Content Workflow

- **Creating Posts**: Always create both English and Chinese versions with matching filenames
  - English: `content/en/posts/filename.md`
  - Chinese: `content/zh/posts/filename.md`
- **Translations**: When translating content, maintain the same frontmatter structure and file numbering

### Asset Management

- Images stored in `static/images/` directory, organized by post title
- Reference images with absolute paths: `/images/post-title/filename.png` or `/images/post-title/filename.svg`
- Supports both raster images (PNG, JPG) and vector graphics (SVG)
- Icons and favicons in `static/` root

## Development Workflow

1. **Local Development**: Use `hugo server --buildDrafts --disableFastRender` for live preview with drafts
2. **Content Creation**:
   - Create English post: `hugo new en/posts/filename.md`
   - Create Chinese post: `hugo new zh/posts/filename.md`
   - Or manually create both language versions
3. **Testing**: Build locally with `hugo --buildDrafts` before committing
4. **Deployment**: Push to `master` branch triggers automatic deployment via GitHub Actions
5. **Verification**: Check GitHub Actions workflow status and live site at `https://gooddayday.github.io`

## Important Notes

- The `public/` directory is git-ignored as it's generated during deployment
- Theme is pinned to LoveIt v0.3.0 for stability (git submodule)
- **Language URL Structure**: `defaultContentLanguageInSubdir = true` means all languages have URL prefixes (`/en/`, `/zh-cn/`)
- **Algolia Search**: Configured with separate search indexes for English (`index.en`) and Chinese (`index.zh-cn`)
- **Comments**: Using giscus connected to GitHub Discussions (repo: `GOODDAYDAY/GOODDAYDAY.github.io`)
- GitHub token (`TOKEN_GITHUB`) must be configured in repository secrets for deployment
- Theme submodule must be initialized: `git submodule update --init --recursive`
