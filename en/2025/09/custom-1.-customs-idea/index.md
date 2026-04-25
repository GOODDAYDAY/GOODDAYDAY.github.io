# [Customs] 1. IntelliJ IDEA Configuration & Recommended Plugins


## Introduction

As one of the most powerful Java IDEs available, IntelliJ IDEA can be significantly enhanced through proper configuration and carefully selected plugins. This guide presents a curated collection of essential plugins and configuration skills that will transform your development experience.

The goal is to provide ready-to-use configurations and plugins that immediately improve productivity, code quality, and development workflow.

## Essential Plugins

### 🔧 Development Tools

#### CamelCase (3.0.12)
![CamelCase Plugin](/images/7.%20customs%20-%20idea/plugin/CamelCase%20(3.0.12).png)

**Purpose**: Quick text case conversion for variable names and strings.

**Features**:
- Convert between camelCase, PascalCase, snake_case, and SCREAMING_SNAKE_CASE
- Keyboard shortcut: `Shift + Alt + U`
- Essential for refactoring and code consistency
- Supports multiple selection for batch conversions

**Use Cases**:
- Converting database column names to Java field names
- Adapting naming conventions between different coding standards
- Quick text formatting during code reviews

#### Maven Helper (4.23.222.2964.0)
![Maven Helper](/images/7.%20customs%20-%20idea/plugin/Maven%20Helper%20(4.23.222.2964.0).png)

**Purpose**: Enhanced Maven project management and dependency analysis.

![Maven Helper Sample.gif](/images/7.%20customs%20-%20idea/plugin/Maven%20Helper%20Sample.gif)

**Key Features**:
- Visual dependency tree with conflict resolution
- Easy exclusion of transitive dependencies
- Quick Maven goal execution
- Dependency analyzer with search functionality

**Benefits**:
- Resolve dependency conflicts quickly
- Understand project dependency structure
- Optimize build performance by identifying unused dependencies

#### RestfulToolkit-fix (2.0.8)
![RestfulToolkit](/images/7.%20customs%20-%20idea/plugin/RestfulToolkit-fix%20(2.0.8).png)

**Purpose**: RESTful API development assistance.

**Features**:
- Navigate to REST endpoints quickly
- Generate HTTP requests from controller methods
- API documentation integration
- Request/response testing within IDE

**Workflow Enhancement**:
- Jump to controller methods from URLs
- Test API endpoints without external tools
- Maintain API documentation alongside code

### 🎨 Visual Enhancement

#### Atom Material Icons
![Atom Material Icons](/images/7.%20customs%20-%20idea/plugin/atom-material-icons.png)

**Purpose**: Beautiful file and folder icons for better visual organization.

**Features**:
- Modern, colorful icon set
- Language-specific file icons
- Framework and library recognition
- Customizable icon themes

#### Pokemon Progress
![Pokemon Progress](/images/7.%20customs%20-%20idea/plugin/Pokemon%20Progress.png)

**Purpose**: Fun Pokemon-themed progress bars.

**Features**:
- Replace boring progress bars with Pokemon characters
- Multiple Pokemon themes available

### 🛠️ Productivity Tools

#### Grep Console
![Grep Console](/images/7.%20customs%20-%20idea/plugin/Grep%20Console.png)

**Purpose**: Advanced console output filtering and highlighting.

![Grep Console Sample.png](/images/7.%20customs%20-%20idea/plugin/Grep%20Console%20Sample.png)

**Features**:
- Real-time log filtering with regex patterns
- Color-coded log levels and patterns
- Save and reuse filter configurations
- Multiple console tabs with different filters

### 🌐 API Development

#### Apipost
![Apipost](/images/7.%20customs%20-%20idea/plugin/apipost.png)

**Purpose**: API testing and documentation within IntelliJ IDEA.

**Features**:
- Create and execute HTTP requests

**Tips**:
- Only use for temporary testing
- Still recommend Postman for complex API testing

### 📊 Diagram & Design Tools

#### PlantUML
![PlantUML](/images/7.%20customs%20-%20idea/plugin/PlantUML.png)

**Purpose**: Professional UML diagram creation using text-based syntax.

**Key Features**:
- Real-time diagram preview with instant updates
- Comprehensive diagram types: sequence, class, activity, use case, component, deployment, state, and more
- Export to multiple formats (PNG, SVG, PDF, LaTeX)
- Integration with code documentation and comments
- Version control friendly (text-based source)

#### Excalidraw
![Excalidraw](/images/7.%20customs%20-%20idea/plugin/excalidraw.png)

**Purpose**: Hand-drawn style diagrams for brainstorming and creative design.

**Key Features**:
- Intuitive drag-and-drop interface
- Hand-drawn aesthetic for approachable diagrams
- Real-time collaborative whiteboarding
- Extensive shape and element library
- Export to various formats (PNG, SVG, JSON)

## Essential IDE Skills & Configurations

### 🚀 Automation Settings

#### Commit-Time Code Formatting

![commit to format.png](/images/7.%20customs%20-%20idea/skill/commit%20to%20format%20goody.png)

**Configuration**: Enable automatic code formatting on commit

**Setup Path**: `VCS → Git → Enable "Reformat code" and "Optimize imports"`

#### Local Variable Final Enhancement
![Local Variable Final](/images/7.%20customs%20-%20idea/skill/local%20variable%20final.png)

**Configuration**: Automatic final modifier for local variables

![local variable final sample.gif](/images/7.%20customs%20-%20idea/skill/local%20variable%20final%20sample.gif)

**Setup**: `Editor → Inspections → Java → Code Style → Local variable or parameter can be final`

### ⌨️ Productivity Shortcuts

#### Advanced Cursor Operations
![Cursor Operations](/images/7.%20customs%20-%20idea/skill/cursor.png)

**Essential Shortcuts**:
- `Alt + Click`: Add cursor at click position
- `Alt + Shift + Click`: Create rectangular selection
- `Ctrl + Alt + Shift + J`: Select all occurrences
- `Alt + J`: Select next occurrence

**Workflow Enhancement**:
- Multi-line editing efficiency
- Bulk text replacements
- Simultaneous code modifications

#### Custom Live Templates
![postfix str.png](/images/7.%20customs%20-%20idea/skill/postfix%20str.png)

**Popular Custom Templates**:
- `.str` → `String.valueOf($VAR$)`
- `.not` → `!$VAR$`
- `.nn` → `if ($VAR$ != null)`
- `.null` → `if ($VAR$ == null)`

![postfix str.gif](/images/7.%20customs%20-%20idea/skill/postfix%20str.gif)

**Setup Path**: `Editor → Live Templates → Create new template group`

**Productivity Benefits**:
- Faster common code patterns
- Reduced typing and syntax errors
- Consistent coding patterns across team

### 🎯 Code Quality Settings

#### Import Optimization
**Configuration**: Prevent wildcard imports

**Setup Path**: `Editor → Code Style → Java → Imports`
- Set "Class count to use import with '*'" to 999
- Set "Names count to use static import with '*'" to 999

**Benefits**:
- Explicit import declarations
- Avoid naming conflicts
- Smaller JAR file sizes
- Better IDE performance

#### File Header Templates
**Configuration**: Automatic file headers with author and date

**Template Example**:
```java
/**
 * TODO: Add class description
 *
 * @author ${USER}
 * @version 1.0, ${DATE}
 * @since 1.0.0
 */
```

**Setup Path**: `Editor → File and Code Templates → Includes`

#### Line Ending Consistency
**Configuration**: Ensure files end with line breaks

**Setup Path**: `Editor → General → On Save → "Ensure every saved file ends with a line break"`

**Benefits**:
- Consistent file endings across operating systems
- Better compatibility with command-line tools
- Cleaner git diffs

