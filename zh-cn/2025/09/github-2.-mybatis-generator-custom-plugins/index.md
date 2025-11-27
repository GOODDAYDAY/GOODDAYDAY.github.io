# [Github] 2. MyBatis Generator 自定义插件


# [Github] 2. MyBatis Generator 自定义插件

> **🔗 项目地址**: [mybatis-generator-custome-plugins](https://github.com/GOODDAYDAY/mybatis-generator-custome-plugins)

为 MyBatis Generator 设计的强大自定义插件集合，专门针对 MySQL 数据库特性，提供 DTO 层生成、Service 层自动生成等功能。

## 🚀 功能概览

本插件集合包含以下6个自定义插件：

| 插件名称                         | 功能描述                            | 核心特性                |
|------------------------------|---------------------------------|---------------------|
| `InsertIgnoreIntoPlugin`     | MySQL INSERT IGNORE语句支持         | 批量插入忽略重复记录          |
| `InsertOnDuplicateKeyPlugin` | MySQL ON DUPLICATE KEY UPDATE支持 | 插入冲突时自动更新           |
| `ReplaceIntoPlugin`          | MySQL REPLACE INTO语句支持          | 替换插入操作              |
| `DtoGeneratorPlugin`         | DTO层代码生成                        | Lombok注解，Entity转换方法 |
| `ServiceGeneratorPlugin`     | Service层代码生成                    | 接口+实现，完整CRUD操作      |
| `CustomerMapperPlugin`       | 自定义Mapper生成                     | 扩展原生Mapper功能        |

## 📦 依赖分析

### 核心依赖

```xml
<!-- MyBatis Generator核心依赖 -->
<dependency>
    <groupId>org.mybatis.generator</groupId>
    <artifactId>mybatis-generator-core</artifactId>
    <version>1.4.2</version>
</dependency>

<!-- MyBatis Dynamic SQL支持 -->
<dependency>
    <groupId>org.mybatis.dynamic-sql</groupId>
    <artifactId>mybatis-dynamic-sql</artifactId>
    <version>1.5.2</version>
</dependency>

<!-- MyBatis Spring Boot集成 -->
<dependency>
    <groupId>org.mybatis.spring.boot</groupId>
    <artifactId>mybatis-spring-boot-starter</artifactId>
    <version>3.0.5</version>
</dependency>
```

### Maven插件配置

```xml
<plugin>
    <groupId>org.mybatis.generator</groupId>
    <artifactId>mybatis-generator-maven-plugin</artifactId>
    <version>1.4.2</version>
    <configuration>
        <verbose>true</verbose>
        <overwrite>true</overwrite>
    </configuration>
    <dependencies>
        <dependency>
            <groupId>com.goody.utils</groupId>
            <artifactId>mybatis-generator-custome-plugins</artifactId>
            <version>1.0.0</version>
        </dependency>
    </dependencies>
</plugin>
```

## 🔧 插件详述

### MySQL扩展插件

#### InsertIgnoreIntoPlugin

- **功能**: 为Mapper添加`INSERT IGNORE`语句支持
- **生成方法**: `insertIgnoreCustom()`, `insertIgnoreBatchCustom()`
- **应用场景**: 批量插入时忽略主键冲突记录

#### InsertOnDuplicateKeyPlugin

- **功能**: 为Mapper添加`ON DUPLICATE KEY UPDATE`语句支持
- **生成方法**: `insertOnDuplicateKeyCustom()`, `insertOnDuplicateKeyBatchCustom()`
- **应用场景**: 插入时遇到重复键则更新记录

#### ReplaceIntoPlugin

- **功能**: 为Mapper添加`REPLACE INTO`语句支持
- **生成方法**: `replaceIntoCustom()`, `replaceIntoBatchCustom()`
- **应用场景**: 存在则替换，不存在则插入

### DTO层生成插件

#### DtoGeneratorPlugin

- **功能**: 自动生成DTO类
- **特性**:
    - Lombok注解支持(`@Data`, `@Builder`, `@AllArgsConstructor`, `@NoArgsConstructor`)
    - 自动生成`fromEntity()`和`toEntity()`转换方法
    - 包结构: `*.model.dto`

### Service层生成插件

#### ServiceGeneratorPlugin

- **功能**: 自动生成Service接口和实现类
- **特性**:
    - 完整CRUD操作方法
    - 支持单主键和联合主键
    - Spring注解支持(`@Service`, `@Autowired`)
    - 包结构: `*.service.interfaces` 和 `*.service.impl`

### 自定义Mapper插件

#### CustomerMapperPlugin

- **功能**: 生成扩展Mapper接口
- **包结构**: `*.dao.customer`

## 💻 使用方法

### 步骤1: 添加依赖

将插件添加到你的项目中：

```xml
<dependency>
    <groupId>com.goody.utils</groupId>
    <artifactId>mybatis-generator-custome-plugins</artifactId>
    <version>1.0.0</version>
</dependency>
```

### 步骤2: 配置generatorConfig.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE generatorConfiguration
    PUBLIC "-//mybatis.org//DTD MyBatis Generator Configuration 1.0//EN"
    "https://mybatis.org/dtd/mybatis-generator-config_1_0.dtd">

<generatorConfiguration>
    <classPathEntry location="${user.home}/.m2/repository/mysql/mysql-connector-java/8.0.28/mysql-connector-java-8.0.28.jar"/>

    <context id="dao" targetRuntime="MyBatis3DynamicSql">
        <property name="autoDelimitKeywords" value="true"/>
        <property name="beginningDelimiter" value="`"/>
        <property name="endingDelimiter" value="`"/>

        <!-- 标准插件 -->
        <plugin type="org.mybatis.generator.plugins.SerializablePlugin" />
        <plugin type="org.mybatis.generator.plugins.EqualsHashCodePlugin" />
        <plugin type="org.mybatis.generator.plugins.ToStringPlugin" />
        <plugin type="org.mybatis.generator.plugins.FluentBuilderMethodsPlugin" />

        <!-- 自定义插件 -->
        <plugin type="com.goody.utils.mybatis.plugin.InsertIgnoreIntoPlugin" />
        <plugin type="com.goody.utils.mybatis.plugin.InsertOnDuplicateKeyPlugin" />
        <plugin type="com.goody.utils.mybatis.plugin.ReplaceIntoPlugin" />
        <plugin type="com.goody.utils.mybatis.plugin.DtoGeneratorPlugin"/>
        <plugin type="com.goody.utils.mybatis.plugin.ServiceGeneratorPlugin"/>
        <plugin type="com.goody.utils.mybatis.plugin.CustomerMapperPlugin"/>

        <commentGenerator>
            <property name="addRemarkComments" value="true" />
            <property name="suppressDate" value="true"/>
        </commentGenerator>

        <jdbcConnection driverClass="com.mysql.cj.jdbc.Driver"
                        connectionURL="jdbc:mysql://127.0.0.1:3306/your_database"
                        userId="your_username"
                        password="your_password">
            <property name="useSSL" value="false" />
            <property name="serverTimezone" value="Asia/Shanghai" />
            <property name="nullCatalogMeansCurrent" value="true" />
        </jdbcConnection>

        <javaTypeResolver >
            <property name="forceBigDecimals" value="true" />
            <property name="useJSR310Types" value="true" />
        </javaTypeResolver>

        <javaModelGenerator targetPackage="com.yourpackage.model.entity"
                           targetProject="src/main/java">
            <property name="enableSubPackages" value="true" />
            <property name="trimStrings" value="true" />
        </javaModelGenerator>

        <javaClientGenerator type="ANNOTATEDMAPPER"
                           targetPackage="com.yourpackage.model.dao"
                           targetProject="src/main/java">
            <property name="enableSubPackages" value="true" />
        </javaClientGenerator>

        <!-- 配置要生成的表 -->
        <table schema="your_schema" tableName="your_table">
            <property name="useActualColumnNames" value="false"/>
        </table>

    </context>
</generatorConfiguration>
```

### 步骤3: 执行代码生成

```bash
mvn mybatis-generator:generate
```

![presentation.gif](/images/8.%20MyBatis%20Generator%20Custom%20Plugins/presentation.gif)

## 📝 配置示例

### 单主键表配置

```xml
<table schema="toy" tableName="example_single_pk">
    <property name="useActualColumnNames" value="false"/>
</table>
```

### 联合主键表配置

```xml
<table schema="toy" tableName="example_double_pk">
    <property name="useActualColumnNames" value="false"/>
</table>
```

## 🏗️ 生成代码分析

插件会为每个表生成完整的代码结构：

### 文件结构

```
src/main/java/
├── com/yourpackage/model/
│   ├── entity/              # Entity实体类
│   │   ├── Example.java
│   │   └── ExampleDoublePk.java
│   ├── dao/                 # 标准Mapper接口
│   │   ├── ExampleMapper.java
│   │   ├── ExampleDynamicSqlSupport.java
│   │   └── customer/        # 自定义Mapper接口
│   │       └── CustomerExampleMapper.java
│   └── dto/                 # DTO类
│       ├── ExampleDTO.java
│       └── ExampleDoublePkDTO.java
├── service/
│   ├── interfaces/          # Service接口
│   │   ├── IExampleService.java
│   │   └── IExampleDoublePkService.java
│   └── impl/               # Service实现
│       ├── ExampleServiceImpl.java
│       └── ExampleDoublePkServiceImpl.java
```

### 核心代码片段分析

#### MySQL扩展方法 (Mapper层)

```java
@Mapper
public interface ExampleMapper {
    // 标准生成的方法...

    // INSERT IGNORE支持
    @Insert({"<script>" +
            " INSERT IGNORE INTO example" +
            " (`id`, `name`, `created`, `updated`)" +
            " VALUES" +
            " (#{item.id}, #{item.name}, #{item.created}, #{item.updated})" +
        "</script>"})
    void insertIgnoreCustom(@Param("item") Example record);

    // 批量INSERT IGNORE
    @Insert({"<script>" +
            " INSERT IGNORE INTO example" +
            " (`id`, `name`, `created`, `updated`)" +
            " VALUES" +
            " <foreach collection='items' item='item' separator=','>" +
            "   (#{item.id}, #{item.name}, #{item.created}, #{item.updated})" +
            " </foreach>" +
        "</script>"})
    void insertIgnoreBatchCustom(@Param("items") Collection<Example> records);

    // ON DUPLICATE KEY UPDATE支持
    @Insert({"<script>" +
            " INSERT INTO example" +
            " (`id`, `name`, `created`, `updated`)" +
            " VALUES" +
            " (#{item.id}, #{item.name}, #{item.created}, #{item.updated})" +
            " AS r" +
            " ON DUPLICATE KEY UPDATE" +
            "   name = r.name, updated = r.updated" +
        "</script>"})
    void insertOnDuplicateKeyCustom(@Param("item") Example record);
}
```

#### DTO类 (数据传输层)

```java
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class ExampleDTO {
    private Long id;
    private String name;
    private LocalDateTime created;
    private LocalDateTime updated;

    // Entity转DTO
    public static ExampleDTO fromEntity(Example entity) {
        if (entity == null) return null;

        return ExampleDTO.builder()
            .id(entity.getId())
            .name(entity.getName())
            .created(entity.getCreated())
            .updated(entity.getUpdated())
            .build();
    }

    // DTO转Entity
    public Example toEntity() {
        return new Example()
            .withId(this.id)
            .withName(this.name)
            .withCreated(this.created)
            .withUpdated(this.updated);
    }
}
```

#### Service接口 (服务层接口)

**单主键Service接口**:

```java
public interface IExampleService {
    int save(ExampleDTO dto);
    int saveBatch(List<ExampleDTO> dtoList);
    int update(ExampleDTO dto);
    int deleteById(Long id);                    // 单参数
    ExampleDTO findById(Long id);               // 单参数
    List<ExampleDTO> findAll();
}
```

**联合主键Service接口** (插件已修复):

```java
public interface IExampleDoublePkService {
    int save(ExampleDoublePkDTO dto);
    int saveBatch(List<ExampleDoublePkDTO> dtoList);
    int update(ExampleDoublePkDTO dto);
    int deleteById(Long id, Long id2);          // 多参数支持
    ExampleDoublePkDTO findById(Long id, Long id2);  // 多参数支持
    List<ExampleDoublePkDTO> findAll();
}
```

#### Service实现 (服务层实现)

**联合主键处理的核心改进**:

```java
@Service
public class ExampleDoublePkServiceImpl implements IExampleDoublePkService {

    @Autowired
    private ExampleDoublePkMapper exampleDoublePkMapper;

    @Override
    public int deleteById(Long id, Long id2) {
        if (id == null || id2 == null) {
            return 0;
        }
        // 正确调用联合主键方法
        return exampleDoublePkMapper.deleteByPrimaryKey(id, id2);
    }

    @Override
    public ExampleDoublePkDTO findById(Long id, Long id2) {
        if (id == null || id2 == null) {
            return null;
        }
        // 正确调用联合主键方法
        ExampleDoublePk entity = exampleDoublePkMapper
            .selectByPrimaryKey(id, id2).orElse(null);
        return entity != null ? ExampleDoublePkDTO.fromEntity(entity) : null;
    }
}
```

### 关键特性分析

#### 联合主键支持

- **问题**: 之前版本错误地尝试使用单一主键类型
- **解决**: 自动检测主键列数量，为联合主键生成多参数方法
- **实现**: `List<IntrospectedColumn> primaryKeyColumns`

#### MySQL特有功能

- **INSERT IGNORE**: 忽略重复键错误，继续插入其他记录
- **ON DUPLICATE KEY UPDATE**: 插入冲突时自动更新指定字段
- **REPLACE INTO**: MySQL的替换插入操作

#### 自动化程度

- **依赖注入**: 自动生成Spring `@Autowired`注解
- **空值检查**: 自动生成参数空值验证
- **转换方法**: DTO与Entity之间的自动转换

## 🏗️ 项目结构

```
mybatis-generator-custome-plugins/
├── src/main/java/com/goody/utils/mybatis/plugin/
│   ├── CustomerMapperPlugin.java
│   ├── DtoGeneratorPlugin.java
│   ├── InsertIgnoreIntoPlugin.java
│   ├── InsertOnDuplicateKeyPlugin.java
│   ├── ReplaceIntoPlugin.java
│   └── ServiceGeneratorPlugin.java
├── src/main/resources/
│   └── generatorConfig.xml
├── src/test/                        # 生成代码示例
└── pom.xml
```

## 🎯 使用建议

1. **开发流程**: 先设计数据库表结构，然后使用插件生成完整的分层代码
2. **联合主键**: 插件已完美支持联合主键，无需手动修改生成代码
3. **扩展性**: 可以继承生成的Service接口，添加复杂业务逻辑
4. **MySQL优化**: 合理使用INSERT IGNORE和ON DUPLICATE KEY功能提升性能

## 🔍 源码深度分析

*此部分为开发者提供插件实现细节的深入洞察，适合希望理解或扩展插件功能的开发者阅读。*

### 插件架构概览

所有插件都继承 `PluginAdapter` 并遵循MyBatis Generator的插件生命周期：

```java
public abstract class PluginAdapter implements Plugin {
    // 验证阶段
    public boolean validate(List<String> warnings);

    // 代码生成钩子
    public boolean clientGenerated(Interface interfaze, IntrospectedTable introspectedTable);
    public List<GeneratedJavaFile> contextGenerateAdditionalJavaFiles(IntrospectedTable introspectedTable);
}
```

### InsertIgnoreIntoPlugin 实现分析

#### 核心方法生成策略

插件使用精巧的方法动态生成SQL模板：

```java
private Method insertIgnoreIntoOne(Interface interfaze, IntrospectedTable introspectedTable) {
    // 使用Stream API进行动态列映射
    final String columnNames = introspectedTable.getAllColumns()
            .stream()
            .map(column -> String.format("`%s`", column.getActualColumnName()))
            .collect(Collectors.joining(", "));

    // MyBatis语法的参数绑定
    final String columnValueNames = introspectedTable.getAllColumns()
            .stream()
            .map(column -> String.format("#{item.%s}", column.getJavaProperty()))
            .collect(Collectors.joining(", "));

    // 基于模板的注解生成
    String insertIgnore = String.format("@Insert({" +
            "\"<script>\" +\n" +
            "            \" INSERT IGNORE INTO %s\" +\n" +
            "              \" (%s)\" +\n" +
            "            \" VALUES\" +\n" +
            "              \"(%s)\" +\n" +
            "        \"</script>\"" +
            "})", tableName, columnNames, columnValueNames);
}
```

#### 关键技术创新

1. **基于Stream的字段转换**: 高效地将数据库模式转换为Java方法参数
2. **动态SQL模板生成**: 创建带适当转义的参数化SQL
3. **批量处理支持**: 为批量操作自动生成 `<foreach>` 循环

### DtoGeneratorPlugin 实现分析

#### 包名解析算法

```java
private TopLevelClass generateDtoClass(IntrospectedTable introspectedTable) {
    // 智能包名转换
    String entityFullType = introspectedTable.getBaseRecordType();
    String entityPackage = entityFullType.substring(0, entityFullType.lastIndexOf('.'));
    String dtoFullPackage = entityPackage.replace(".entity", "." + DTO_PACKAGE);

    // 类型安全的类实例化
    FullyQualifiedJavaType dtoType = new FullyQualifiedJavaType(dtoFullPackage + "." + dtoClassName);
    TopLevelClass dtoClass = new TopLevelClass(dtoType);
}
```

#### 带元数据保留的字段生成

```java
// 带注释保留的列到字段转换
for (IntrospectedColumn column : allColumns) {
    Field field = new Field(column.getJavaProperty(), column.getFullyQualifiedJavaType());
    field.setVisibility(JavaVisibility.PRIVATE);

    // 保留数据库列注释
    if (column.getRemarks() != null && !column.getRemarks().trim().isEmpty()) {
        field.addJavaDocLine("/**");
        field.addJavaDocLine(" * " + column.getRemarks());
        field.addJavaDocLine(" */");
    }

    dtoClass.addField(field);
}
```

### ServiceGeneratorPlugin 实现分析

#### 联合主键解析

最精妙的功能是智能联合主键处理：

```java
// 动态主键分析
List<IntrospectedColumn> primaryKeyColumns = introspectedTable.getPrimaryKeyColumns();

// 自适应方法签名生成
for (IntrospectedColumn column : primaryKeyColumns) {
    String paramName = column.getJavaProperty();
    method.addParameter(new Parameter(column.getFullyQualifiedJavaType(), paramName));
}

// 动态方法调用构建
StringBuilder methodCall = new StringBuilder("return " + mapperFieldName + ".deleteByPrimaryKey(");
for (int i = 0; i < primaryKeyColumns.size(); i++) {
    if (i > 0) methodCall.append(", ");
    methodCall.append(primaryKeyColumns.get(i).getJavaProperty());
}
methodCall.append(");");
```

#### Service实现模式

```java
// 空值安全的参数验证
for (IntrospectedColumn column : primaryKeyColumns) {
    method.addBodyLine("if (" + column.getJavaProperty() + " == null) {");
    method.addBodyLine("    return 0;");
    method.addBodyLine("}");
}
```

### 高级模式和技术

#### 类型安全强化

```java
// 泛型类型保留
FullyQualifiedJavaType listType = new FullyQualifiedJavaType("List<" + dtoClassName + ">");
Parameter batchParameter = new Parameter(listType, "dtoList");

// 导入解析
serviceInterface.addImportedType(new FullyQualifiedJavaType("java.util.List"));
```

#### SQL注入防护

所有生成的SQL都使用参数化查询：

```java
// 安全：参数化查询
"INSERT IGNORE INTO " + tableName + " VALUES (#{item.id}, #{item.name})"

// 不安全：字符串拼接（从不使用）
"INSERT IGNORE INTO " + tableName + " VALUES (" + item.getId() + ", '" + item.getName() + "')"
```

#### 内存高效生成

```java
// 大型代码库的延迟求值模式
public List<GeneratedJavaFile> contextGenerateAdditionalJavaFiles(IntrospectedTable introspectedTable) {
    List<GeneratedJavaFile> files = new ArrayList<>();

    // 仅在需要时生成
    if (shouldGenerateService(introspectedTable)) {
        files.add(createServiceInterface(introspectedTable));
        files.add(createServiceImplementation(introspectedTable));
    }

    return files;
}
```

### 自定义开发扩展点

#### 自定义插件模板

```java
public class CustomPlugin extends PluginAdapter {
    @Override
    public boolean validate(List<String> warnings) {
        // 插件验证逻辑
        return true;
    }

    @Override
    public boolean clientGenerated(Interface interfaze, IntrospectedTable introspectedTable) {
        // 向现有Mapper接口添加方法
        interfaze.addMethod(createCustomMethod(introspectedTable));
        return super.clientGenerated(interfaze, introspectedTable);
    }

    private Method createCustomMethod(IntrospectedTable table) {
        // 自定义方法生成逻辑
        Method method = new Method("customMethod");
        method.setVisibility(JavaVisibility.PUBLIC);
        method.setAbstract(true);
        return method;
    }
}
```

#### 配置驱动行为

```java
@Override
public boolean validate(List<String> warnings) {
    // 读取插件属性
    String enableFeature = getProperties().getProperty("enableCustomFeature");
    if ("false".equals(enableFeature)) {
        // 跳过插件执行
        return false;
    }
    return true;
}
```

这种深入的源码分析揭示了每个插件背后的精妙工程，展示了先进的Java代码生成技术和MyBatis Generator的可扩展性框架。

---

*本技术深度解析旨在为MyBatis Generator自定义插件的架构和实现提供全面的洞察。*

