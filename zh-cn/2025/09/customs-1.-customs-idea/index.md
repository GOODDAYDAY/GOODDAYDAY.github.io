# [Customs] 1. IntelliJ IDEA 配置与推荐插件


## 介绍

作为目前最强大的Java IDE之一，IntelliJ IDEA可以通过合理的配置和精心选择的插件得到显著增强。本指南提供了一套精选的必备插件和配置技巧，将彻底改变您的开发体验。

我们的目标是提供即用型配置和插件，立即提升开发效率、代码质量和开发工作流程。

## 必备插件

### 🔧 开发工具

#### CamelCase (3.0.12)
![CamelCase Plugin](/images/7.%20customs%20-%20idea/plugin/CamelCase%20(3.0.12).png)

**用途**: 变量名和字符串的快速大小写转换工具。

**功能特性**:
- 在camelCase、PascalCase、snake_case和SCREAMING_SNAKE_CASE之间转换
- 快捷键: `Shift + Alt + U`
- 重构和代码一致性的必备工具
- 支持多选进行批量转换

**使用场景**:
- 将数据库列名转换为Java字段名
- 适配不同编码标准之间的命名约定
- 代码评审期间快速文本格式化

#### Maven Helper (4.23.222.2964.0)
![Maven Helper](/images/7.%20customs%20-%20idea/plugin/Maven%20Helper%20(4.23.222.2964.0).png)

**用途**: 增强的Maven项目管理和依赖分析。

![Maven Helper Sample.gif](/images/7.%20customs%20-%20idea/plugin/Maven%20Helper%20Sample.gif)

**核心功能**:
- 可视化依赖树和冲突解决
- 轻松排除传递依赖
- 快速Maven目标执行
- 带搜索功能的依赖分析器

**优势**:
- 快速解决依赖冲突
- 理解项目依赖结构
- 通过识别未使用的依赖优化构建性能

#### RestfulToolkit-fix (2.0.8)
![RestfulToolkit](/images/7.%20customs%20-%20idea/plugin/RestfulToolkit-fix%20(2.0.8).png)

**用途**: RESTful API开发辅助工具。

**功能特性**:
- 快速导航到REST端点
- 从控制器方法生成HTTP请求
- API文档集成
- IDE内的请求/响应测试

**工作流程增强**:
- 从URL跳转到控制器方法
- 无需外部工具即可测试API端点
- 与代码同步维护API文档

### 🎨 视觉增强

#### Atom Material Icons
![Atom Material Icons](/images/7.%20customs%20-%20idea/plugin/atom-material-icons.png)

**用途**: 美观的文件和文件夹图标，改善视觉组织效果。

**功能特性**:
- 现代、色彩丰富的图标集
- 特定语言的文件图标
- 框架和库识别
- 可自定义图标主题

#### Pokemon Progress
![Pokemon Progress](/images/7.%20customs%20-%20idea/plugin/Pokemon%20Progress.png)

**用途**: 有趣的宝可梦主题进度条。

**功能特性**:
- 用宝可梦角色替换枯燥的进度条
- 提供多种宝可梦主题

### 🛠️ 生产力工具

#### Grep Console
![Grep Console](/images/7.%20customs%20-%20idea/plugin/Grep%20Console.png)

**用途**: 高级控制台输出过滤和高亮显示。

![Grep Console Sample.png](/images/7.%20customs%20-%20idea/plugin/Grep%20Console%20Sample.png)

**功能特性**:
- 使用正则表达式模式实时日志过滤
- 日志级别和模式的彩色编码
- 保存和重用过滤器配置
- 具有不同过滤器的多个控制台标签

### 🌐 API开发

#### Apipost
![Apipost](/images/7.%20customs%20-%20idea/plugin/apipost.png)

**用途**: 在IntelliJ IDEA内进行API测试和文档编写。

**功能特性**:
- 创建和执行HTTP请求

**使用建议**:
- 仅用于临时测试
- 复杂API测试仍建议使用Postman

### 📊 图表与设计工具

#### PlantUML
![PlantUML](/images/7.%20customs%20-%20idea/plugin/PlantUML.png)

**用途**: 使用基于文本的语法创建专业UML图表。

**核心功能**:
- 具有即时更新的实时图表预览
- 全面的图表类型：序列图、类图、活动图、用例图、组件图、部署图、状态图等
- 导出为多种格式(PNG、SVG、PDF、LaTeX)
- 与代码文档和注释集成
- 版本控制友好(基于文本的源码)

#### Excalidraw
![Excalidraw](/images/7.%20customs%20-%20idea/plugin/excalidraw.png)

**用途**: 手绘风格图表，用于头脑风暴和创意设计。

**核心功能**:
- 直观的拖放界面
- 手绘美学效果，图表更易接受
- 实时协作白板功能
- 丰富的形状和元素库
- 导出为多种格式(PNG、SVG、JSON)

## 必备IDE技巧与配置

### 🚀 自动化设置

#### 提交时代码格式化

![commit to format.png](/images/7.%20customs%20-%20idea/skill/commit%20to%20format%20goody.png)

**配置**: 在提交时启用自动代码格式化

**设置路径**: `VCS → Git → 启用"重新格式化代码"和"优化导入"`

#### 局部变量Final增强
![Local Variable Final](/images/7.%20customs%20-%20idea/skill/local%20variable%20final.png)

**配置**: 局部变量的自动final修饰符

![local variable final sample.gif](/images/7.%20customs%20-%20idea/skill/local%20variable%20final%20sample.gif)

**设置**: `Editor → Inspections → Java → Code Style → Local variable or parameter can be final`

### ⌨️ 生产力快捷键

#### 高级光标操作
![Cursor Operations](/images/7.%20customs%20-%20idea/skill/cursor.png)

**基本快捷键**:
- `Alt + Click`: 在点击位置添加光标
- `Alt + Shift + Click`: 创建矩形选择
- `Ctrl + Alt + Shift + J`: 选择所有出现的地方
- `Alt + J`: 选择下一个出现的地方

**工作流程增强**:
- 多行编辑效率
- 批量文本替换
- 同时修改代码

#### 自定义动态模板
![postfix str.png](/images/7.%20customs%20-%20idea/skill/postfix%20str.png)

**热门自定义模板**:
- `.str` → `String.valueOf($VAR$)`
- `.not` → `!$VAR$`
- `.nn` → `if ($VAR$ != null)`
- `.null` → `if ($VAR$ == null)`

![postfix str.gif](/images/7.%20customs%20-%20idea/skill/postfix%20str.gif)

**设置路径**: `Editor → Live Templates → 创建新模板组`

**生产力优势**:
- 更快的常用代码模式
- 减少输入和语法错误
- 团队间一致的编码模式

### 🎯 代码质量设置

#### 导入优化
**配置**: 防止通配符导入

**设置路径**: `Editor → Code Style → Java → Imports`
- 将"使用'*'导入的类数量"设置为999
- 将"使用静态'*'导入的名称数量"设置为999

**优势**:
- 明确的导入声明
- 避免命名冲突
- 更小的JAR文件大小
- 更好的IDE性能

#### 文件头模板
**配置**: 带有作者和日期的自动文件头

**模板示例**:
```java
/**
 * TODO: 添加类描述
 *
 * @author ${USER}
 * @version 1.0, ${DATE}
 * @since 1.0.0
 */
```

**设置路径**: `Editor → File and Code Templates → Includes`

#### 行尾一致性
**配置**: 确保文件以换行符结尾

**设置路径**: `Editor → General → On Save → "确保每个保存的文件都以换行符结尾"`

**优势**:
- 跨操作系统的一致文件结尾
- 与命令行工具更好的兼容性
- 更清晰的git差异显示

