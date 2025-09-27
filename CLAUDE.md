# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Hugo-based static blog site hosted on GitHub Pages. The site uses the LoveIt theme and is configured for
English content with Chinese/bilingual support capability.

## Architecture

- **Hugo Static Site Generator**: Version-agnostic Hugo setup with extended features
- **LoveIt Theme**: Git submodule at `themes/LoveIt` (pinned to v0.3.0)
- **Content Structure**: Markdown posts in `content/posts/` with frontmatter metadata
- **Deployment**: GitHub Actions workflow automatically builds and deploys to GitHub Pages
- **Configuration**: Single `hugo.toml` file with comprehensive theme and site settings

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
# Create new blog post
hugo new posts/post-title.md

# Build site and check output
hugo --buildDrafts
```

### Deployment

- Automatic deployment via GitHub Actions on push to `master` branch
- Manual workflow trigger available in GitHub Actions tab
- Deployment target: `gh-pages` branch

## File Structure

```
├── content/posts/           # Blog posts in Markdown
├── static/                  # Static assets (images, icons)
├── layouts/taxonomy/        # Custom taxonomy templates (tags, categories)
├── themes/LoveIt/          # Theme submodule
├── .github/workflows/      # GitHub Actions deployment
├── hugo.toml              # Main configuration file
└── public/                # Generated site (excluded from git)
```

## Configuration Notes

### Hugo Configuration (`hugo.toml`)

- **Base URL**: `https://gooddayday.github.io`
- **Theme**: LoveIt with light default theme
- **Language**: English primary, Chinese support available but commented out
- **Features**: Git info enabled, search via Algolia, comments via Valine
- **Content**: Blog-focused with posts, tags, categories, and documentation sections

### Theme Customization

- Custom taxonomy templates in `layouts/taxonomy/` for proper tag/category pages
- Social links configured for GitHub profile
- Search functionality configured for Algolia
- Comment system using Valine with specific app configuration

### Deployment Configuration

- GitHub Actions workflow in `.github/workflows/deploy.yaml`
- Uses Hugo extended version with caching for performance
- Deploys to `gh-pages` branch using `TOKEN_GITHUB` secret
- Minification enabled for production builds

## Content Guidelines

### Blog Post Structure

Posts should include frontmatter with:

```yaml
date = '2025-09-10T22:11:17+08:00'
draft = false
title = 'Post Title'
categories = ["category1", "category2"]
tags = ["tag1", "tag2", "tag3"]
```

### Asset Management

- Images stored in `static/images/` directory
- Reference images with absolute paths: `/images/filename.png`
- Icons and favicons in `static/` root

## Development Workflow

1. **Local Development**: Use `hugo server --buildDrafts` for live preview
2. **Content Creation**: Create posts with `hugo new posts/filename.md`
3. **Testing**: Build locally with `hugo --buildDrafts` before committing
4. **Deployment**: Push to `master` branch triggers automatic deployment
5. **Verification**: Check GitHub Actions for build status and live site

## Important Notes

- The `public/` directory is git-ignored as it's generated during deployment
- Theme is pinned to LoveIt v0.3.0 for stability
- Chinese language support is available but currently disabled in configuration
- Custom taxonomy templates are required for proper tag/category page generation
- GitHub token (`TOKEN_GITHUB`) must be configured in repository secrets for deployment
