+++
date = '2025-09-10T22:11:17+08:00'
draft = false
title = '[Github] 1. Deploy GitHub Blog Site'
categories = ["github", "deploy"]
tags = ["github", "deploy", "hugo", "blog", "site"]
+++

## intro

- GitHub Pages is a static site hosting service that takes HTML, CSS, and JavaScript files straight from a repository on GitHub, optionally runs the files through a build process, and publishes a website.

## pre-work

### create a repository

- Create a repository named `your_github_username.github.io`, where `your_github_username` is your GitHub username. For example, if your GitHub username is `octocat`, the repository name should be `octocat.github.io`.

### hugo install

- Download the latest version of Hugo from the [official Hugo releases page](https://gohugo.io/installation/)

## create a blog site

### [hugo init site](https://gohugo.io/getting-started/quick-start/)

```bash
# create directory
mkdir your_github_username.github.io
# cd to directory
cd your_github_username.github.io
# init site
hugo new site .
# git init, make sure it's a git repository
git init
```

### [add a theme](https://themes.gohugo.io/)

```bash
# add a theme, here we use LoveIt theme.
git submodule add https://github.com/dillonzq/LoveIt.git themes/LoveIt
# now the git is main branch which is not stable, we need to checkout to the latest stable version.
cd themes/LoveIt
git checkout v0.3.0
cd ../..
# now, there should be a .gitmodules file in your directory. if not, you need to run `git init` first.
# copy the exampleSite config file to the root directory
cp themes/LoveIt/exampleSite/hugo.toml .
```

### modify the config file

- modify the config file hugo.toml

#### bashURL

```toml
baseURL = "https://gooddayday.github.io"
```

#### themes directory

```toml
# themes directory
# 主题目录
themesDir = "./themes"
```

#### website title

```toml
# website title
# 网站标题
title = "GoodyHao's Blog"
```

#### website images

```toml
# website images for Open Graph and Twitter Cards
# 网站图片, 用于 Open Graph 和 Twitter Cards
images = ["/logo.jpg"]
```

#### website icon

- put icon file in the `static` directory

#### gitRepo

- modify the gitRepo to your public git repo url

```bash
# public git repo url only then enableGitInfo is true
# 公共 git 仓库路径，仅在 enableGitInfo 设为 true 时有效
gitRepo = "https://github.com/GOODDAYDAY/GOODDAYDAY.github.io"
```

## github deploy

### create a workflow file

- create a file `.github/workflows/deploy.yaml`, and add the following content:

```yaml
name: Deploy Hugo to GitHub Pages
on:
  push:  # Trigger condition: push code to master branch
    branches:
      - master
jobs:
  build-and-deploy:
    runs-on: ubuntu-latest  # Use Ubuntu environment
    steps:
      # 1. Check out repository code (recursively pull theme submodule)
      - uses: actions/checkout@v4
        with:
          submodules: true

      # 2. Install Hugo (use extended version, supports SASS)
      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: 'latest'  # Or specify version (e.g., '0.147.2')
          extended: true

      # 3. Cache dependencies (speed up subsequent builds)
      - uses: actions/cache@v3
        with:
          path: |
            resources/_gen
            public
          key: ${{ runner.os }}-hugo-${{ hashFiles('**/go.sum') }}
          restore-keys: |
            ${{ runner.os }}-hugo-

      # 4. Build Hugo site (enable compression)
      - name: Build Hugo site
        run: hugo --minify

      # 5. Deploy to GitHub Pages (automatically push public directory to gh-pages branch)
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v4
        with:
          github_token: ${{ secrets.GITHUB_TOKEN  }}  # GitHub automatically provided Token (no manual creation needed)
          publish_dir: ./public  # Point to Hugo generated static files directory
          force_orphan: true  # Force create new commit (avoid branch history confusion)
```

- github repository settings -> pages -> source -> select `gh-pages` branch and `/ (root)` folder -> save
  - if gh-pages branch not exist, need to push code to github first

![1. github-page-setting.png](/images/1.%20deploy%20github%20blog%20site.md/1.%20github-page-setting.png)

- need to set token

![2. github-generate-token-setting-1.png](/images/1.%20deploy%20github%20blog%20site.md/2.%20github-generate-token-setting-1.png)

- generate new token with `repo` and `workflow` permissions

![2. github-generate-token-setting-2.png](/images/1.%20deploy%20github%20blog%20site.md/2.%20github-generate-token-setting-2.png)

- add token to github secrets with name `TOKEN_GITHUB`

![3. github-token-setting.png](/images/1.%20deploy%20github%20blog%20site.md/3.%20github-token-setting.png)

### push code to github

```bash
# add all files
git add .
# commit
git commit -m "first commit"
# push to github
git push -u origin master
```

### check the workflow

- check the workflow in github actions

![4. github-workflow-check.png](/images/1.%20deploy%20github%20blog%20site.md/4.%20github-workflow-check.png)


## access the blog site

- access the blog site with `https://your_github_username.github.io`, for example, `https://gooddayday.github.io`

## others

### add new post

```bash
# create a new post
hugo new posts/first-post.md
# edit the post
vim content/posts/first-post.md
# after edit, need to set the post as published
# set draft = false
# then commit and push to github
git add .
git commit -m "add first post"
git push
```

- if you want to add images to the post, need to put the images in the `static` directory, for example, `static/images/first-post-image.png`, then you can access the image with `/images/first-post-image.png` in the post.

### gitignore

- create a `.gitignore` file in the root directory, and add the following content:

```aiignore
public/*
```

- we don't need to push the `public` directory to github, because it will be generated by hugo in the workflow.

### tag & category generate

- tag and category will be generated automatically by hugo, no need to create them manually.
- But if no index.html shown below, you need to add templates.

![5. github-display-indexhtml.png](/images/1.%20deploy%20github%20blog%20site.md/5.%20github-display-indexhtml.png)

- just copy the `themes/LoveIt/layouts/taxonomy/list.html` to the different path and rename it to `layouts/taxonomy/tag.html` and `layouts/taxonomy/category.html`

![6. github-taxonomy-tempaltes.png](/images/1.%20deploy%20github%20blog%20site.md/6.%20github-taxonomy-tempaltes.png)

- and then, run hugo server to check if the result has index.html like the picture below:

![5. github-display-indexhtml.png](/images/1.%20deploy%20github%20blog%20site.md/5.%20github-display-indexhtml.png)

### setup comment system with giscus

- By default, the LoveIt theme uses Valine comment system, but we recommend using Giscus which is based on GitHub Discussions. Giscus is free, stable, and stores comment data in your own GitHub repository.

#### disable other comment systems

- First, make sure other comment systems are disabled in `hugo.toml`:

```toml
# Disable Valine
[params.page.comment.valine]
enable = false

# Disable Disqus
[params.page.comment.disqus]
enable = false

# Disable Gitalk
[params.page.comment.gitalk]
enable = false
```

#### enable GitHub Discussions

- Go to your GitHub repository settings: `https://github.com/your-username/your-username.github.io/settings`
- Navigate to **Features** section
- Check the **Discussions** checkbox to enable it

![7. github-setting-discussions.png](/images/1.%20deploy%20github%20blog%20site.md/7.%20github-setting-discussions.png)

#### configure giscus

- Visit [giscus.app](https://giscus.app/) to generate configuration
- Fill in the repository field: `your-username/your-username.github.io`
- Click `The giscus app is installed, otherwise visitors will not be able to comment and react.` and install giscus to your repository.

![8. github-giscus-homepage.png](/images/1.%20deploy%20github%20blog%20site.md/8.%20github-giscus-homepage.png)

#### update hugo.toml

- Add the giscus configuration to your `hugo.toml`:

```toml
[params.page.comment.giscus]
enable = true
repo = "your-username/your-username.github.io"
repoId = "your-repo-id-from-giscus"
category = "General"  # or your chosen category
categoryId = "your-category-id-from-giscus"
lang = ""  # empty for auto-detection
mapping = "pathname"
reactionsEnabled = "1"
emitMetadata = "0"
inputPosition = "bottom"
lazyLoading = false
lightTheme = "light"
darkTheme = "dark"
```

- data like `repoId` and `categoryId` can be found in the giscus configuration you generated earlier.

![9. github-giscus-output-script.png](/images/1.%20deploy%20github%20blog%20site.md/9.%20github-giscus-output-script.png)

### language switch settings

- With the AI development, it is easy to translate the blog content to different languages. Here we use English and Chinese as an example.
- Firstly, we need to create two directories in the `content` directory: `en` and `zh`, then put the corresponding language content in the respective directory.

![10. github-multi-language-display.png](/images/1.%20deploy%20github%20blog%20site.md/10.%20github-multi-language-display.png)

- The name of different language file should be the same, for example, `content/en/posts/1.deploy-github-blog-site.md` and `content/zh/posts/1.deploy-github-blog-site.md`
  - if not, the hugo will treat them as different posts, and show them in the different language list.

- Then, we need to modify the `hugo.toml` file to enable multi-language support:

```toml
# determines default content language ["en", "zh-cn", "fr", "pl", ...]
# 设置默认的语言 ["en", "zh-cn", "fr", "pl", ...]
defaultContentLanguage = "en"
# whether to include default language in URL path
# 是否在URL路径中包含默认语言 (设为true让所有语言都有前缀，设为false让默认语言无前缀)
defaultContentLanguageInSubdir = true

....

# 是否包括中日韩文字
hasCJKLanguage = false
hasCJKLanguage = true

...

# Multilingual
# 多语言
[languages]
[languages.en]
weight = 1
languageCode = "en"
languageName = "English"
hasCJKLanguage = false
copyright = "This work is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License."
contentDir = "content"
contentDir = "content/en"

...

[languages.zh-cn]
weight = 2
languageCode = "zh-CN"
languageName = "简体中文"
hasCJKLanguage = true
copyright = "This work is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License."
contentDir = "content/zh"
```

### language switch display customization

- By default, the language switch button is displayed in the top right corner of the website. If you want to switch the language, you need to click twice and people may not notice there has another language.
- So, as to me, I want to display the language switch button in the header menu, so that people can easily find it and switch the language.
- To achieve this, we need to copy the `themes/LoveIt/layouts/partials/header.html` file to `layouts/partials/header.html`.
- Then, we need to modify the `layouts/partials/header.html` file to add the language switch button in the header menu.

- before

```html
    {{- if hugo.IsMultilingual -}}
    <a href="javascript:void(0);" class="menu-item language" title="{{ T "selectLanguage" }}">
        <i class="fa fa-globe fa-fw" aria-hidden="true"></i>                      
        <select class="language-select" id="language-select-desktop" onchange="location = this.value;">
            {{- if eq .Kind "404" -}}
                {{- /* https://github.com/dillonzq/LoveIt/issues/378 */ -}}
                {{- range .Sites -}}
                    {{- $link := printf "%v/404.html" .LanguagePrefix -}}
                    <option value="{{ $link }}"{{ if eq . $.Site }} selected{{ end }}>
                        {{- .Language.LanguageName -}}
                    </option>
                {{- end -}}
            {{- else -}}
                {{- range .AllTranslations -}}
                    <option value="{{ .RelPermalink }}"{{ if eq .Lang $.Lang }} selected{{ end }}>
                        {{- .Language.LanguageName -}}
                    </option>
                {{- end -}}
            {{- end -}}
        </select>
    </a>
{{- end -}}
```

- after

```html
{{- /* 直接切换语言按钮 */ -}}
{{- if hugo.IsMultilingual -}}
    {{- if eq .Kind "404" -}}
        {{- /* https://github.com/dillonzq/LoveIt/issues/378 */ -}}
        {{- range .Sites -}}
            {{- if ne . $.Site -}}
                <a class="menu-item" href="{{ printf "%v/404.html" .LanguagePrefix }}" title="{{ .Language.LanguageName }}">
                    {{- if eq .Language.LanguageCode "zh-CN" -}}
                        中文
                    {{- else -}}
                        English
                    {{- end -}}
                </a>
            {{- end -}}
        {{- end -}}
    {{- else -}}
        {{- range .AllTranslations -}}
            {{- if ne .Lang $.Lang -}}
                <a class="menu-item" href="{{ .RelPermalink }}" title="{{ .Language.LanguageName }}">
                    {{- if eq .Language.LanguageCode "zh-CN" -}}
                        中文
                    {{- else -}}
                        English
                    {{- end -}}
                </a>
            {{- end -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
```

- result display as below:  

![11. github-language-switch-display.gif](/images/1.%20deploy%20github%20blog%20site.md/11.%20github-language-switch-display.gif)
