# [Github] 1. Deploy GitHub Blog Site


# [Github] 1. Deploy GitHub Blog Site

## 1. intro

- GitHub Pages is a static site hosting service that takes HTML, CSS, and JavaScript files straight from a repository on GitHub, optionally runs the files through a build process, and publishes a website.

## 2. pre-work

### 2.1 create a repository

- Create a repository named `your_github_username.github.io`, where `your_github_username` is your GitHub username. For example, if your GitHub username is `octocat`, the repository name should be `octocat.github.io`.

### 2.2 hugo install

- Download the latest version of Hugo from the [official Hugo releases page](https://gohugo.io/installation/)

## 3. create a blog site

### 3.1 [hugo init site](https://gohugo.io/getting-started/quick-start/)

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

### 3.2 [add a theme](https://themes.gohugo.io/)

```bash
# add a theme, here we use LoveIt theme.
git submodule add https://github.com/dillonzq/LoveIt.git themes/LoveIt
# now, there should be a .gitmodules file in your directory. if not, you need to run `git init` first.
# copy the exampleSite config file to the root directory
cp themes/LoveIt/exampleSite/hugo.toml .
```

### 3.3 modify the config file

- modify the config file hugo.toml

#### 3.3.1 bashURL

```toml
baseURL = "https://gooddayday.github.io"
```

#### 3.3.2 themes directory

```toml
# themes directory
# 主题目录
themesDir = "./themes"
```

#### 3.3.3 website title

```toml
# website title
# 网站标题
title = "GoodyHao's Blog"
```

#### 3.3.4 website images

```toml
# website images for Open Graph and Twitter Cards
# 网站图片, 用于 Open Graph 和 Twitter Cards
images = ["/logo.jpg"]
```

#### 3.3.5 website icon

- put icon file in the `static` directory

## 4. github deploy

### 4.1 create a workflow file

- create a file `.github/workflows/deploy.yaml`, and add the following content:

```yaml
name: Deploy Hugo to GitHub Pages
on:
  push:  # 触发条件：推送代码到master分支
    branches:
      - master
jobs:
  build-and-deploy:
    runs-on: ubuntu-latest  # 使用Ubuntu环境
    steps:
      # 1. 检出仓库代码（递归拉取主题submodule）
      - uses: actions/checkout@v4
        with:
          submodules: true
      
      # 2. 安装Hugo（使用extended版本，支持SASS）
      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: 'latest'  # 或指定版本（如'0.147.2'）
          extended: true
      
      # 3. 缓存依赖（加快后续构建速度）
      - uses: actions/cache@v3
        with:
          path: |
            resources/_gen
            public
          key: ${{ runner.os }}-hugo-${{ hashFiles('**/go.sum') }}
          restore-keys: |
            ${{ runner.os }}-hugo-
      
      # 4. 构建Hugo站点（开启压缩）
      - name: Build Hugo site
        run: hugo --minify
      
      # 5. 部署到GitHub Pages（自动推送public目录到gh-pages分支）
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v4
        with:
          github_token: ${{ secrets.GITHUB_TOKEN  }}  # GitHub自动提供的Token（无需手动创建）
          publish_dir: ./public  # 指向Hugo生成的静态文件目录
          force_orphan: true  # 强制创建新提交（避免分支历史混乱）
```

- github repository settings -> pages -> source -> select `gh-pages` branch and `/ (root)` folder -> save

![github-page-setting.png](/images/1.%20deploy%20github%20blog%20site.md/github-page-setting.png)

- no need to create token, github will create a token named `GITHUB_TOKEN` automatically.

### 4.2 push code to github

```bash
# add all files
git add .
# commit
git commit -m "first commit"
# push to github
git push -u origin master
```

