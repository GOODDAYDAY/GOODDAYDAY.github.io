# [Github] 2. MyBatis Generator Custom Plugins


# [Github] 2. MyBatis Generator Custom Plugins

> **🔗 Project Repository**: [mybatis-generator-custome-plugins](https://github.com/GOODDAYDAY/mybatis-generator-custome-plugins)

A powerful collection of MyBatis Generator custom plugins designed to enhance code generation capabilities with
MySQL-specific features, DTO layer generation, and automatic Service layer generation.

## 🚀 Features Overview

This plugin collection includes 6 custom plugins:

| Plugin Name                  | Description                           | Key Features                                         |
|------------------------------|---------------------------------------|------------------------------------------------------|
| `InsertIgnoreIntoPlugin`     | MySQL INSERT IGNORE statement support | Batch insert ignoring duplicate records              |
| `InsertOnDuplicateKeyPlugin` | MySQL ON DUPLICATE KEY UPDATE support | Auto update on insert conflicts                      |
| `ReplaceIntoPlugin`          | MySQL REPLACE INTO statement support  | Replace insert operations                            |
| `DtoGeneratorPlugin`         | DTO layer code generation             | Lombok annotations, Entity conversion methods        |
| `ServiceGeneratorPlugin`     | Service layer code generation         | Interface + Implementation, Complete CRUD operations |
| `CustomerMapperPlugin`       | Custom Mapper generation              | Extended native Mapper functionality                 |

## 📦 Dependency Analysis

### Core Dependencies

```xml
<!-- MyBatis Generator Core Dependency -->
<dependency>
  <groupId>org.mybatis.generator</groupId>
  <artifactId>mybatis-generator-core</artifactId>
  <version>1.4.2</version>
</dependency>

        <!-- MyBatis Dynamic SQL Support -->
<dependency>
<groupId>org.mybatis.dynamic-sql</groupId>
<artifactId>mybatis-dynamic-sql</artifactId>
<version>1.5.2</version>
</dependency>

        <!-- MyBatis Spring Boot Integration -->
<dependency>
<groupId>org.mybatis.spring.boot</groupId>
<artifactId>mybatis-spring-boot-starter</artifactId>
<version>3.0.5</version>
</dependency>
```

### Maven Plugin Configuration

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

## 🔧 Plugin Details

### MySQL Extension Plugins

#### InsertIgnoreIntoPlugin

- **Function**: Adds `INSERT IGNORE` statement support to Mapper
- **Generated Methods**: `insertIgnoreCustom()`, `insertIgnoreBatchCustom()`
- **Use Cases**: Ignore primary key conflicts during batch inserts

#### InsertOnDuplicateKeyPlugin

- **Function**: Adds `ON DUPLICATE KEY UPDATE` statement support to Mapper
- **Generated Methods**: `insertOnDuplicateKeyCustom()`, `insertOnDuplicateKeyBatchCustom()`
- **Use Cases**: Auto update records on duplicate key conflicts during insert

#### ReplaceIntoPlugin

- **Function**: Adds `REPLACE INTO` statement support to Mapper
- **Generated Methods**: `replaceIntoCustom()`, `replaceIntoBatchCustom()`
- **Use Cases**: Replace existing records or insert new ones

### DTO Layer Generation Plugin

#### DtoGeneratorPlugin

- **Function**: Automatically generates DTO classes
- **Features**:
  - Lombok annotation support (`@Data`, `@Builder`, `@AllArgsConstructor`, `@NoArgsConstructor`)
  - Auto-generated `fromEntity()` and `toEntity()` conversion methods
  - Package structure: `*.model.dto`

### Service Layer Generation Plugin

#### ServiceGeneratorPlugin

- **Function**: Automatically generates Service interfaces and implementation classes
- **Features**:
  - Complete CRUD operation methods
  - Support for single and composite primary keys
  - Spring annotation support (`@Service`, `@Autowired`)
  - Package structure: `*.service.interfaces` and `*.service.impl`

### Custom Mapper Plugin

#### CustomerMapperPlugin

- **Function**: Generates extended Mapper interfaces
- **Package structure**: `*.dao.customer`

## 💻 Usage Guide

### Step 1: Add Dependencies

Add the plugin to your project:

```xml

<dependency>
  <groupId>com.goody.utils</groupId>
  <artifactId>mybatis-generator-custome-plugins</artifactId>
  <version>1.0.0</version>
</dependency>
```

### Step 2: Configure generatorConfig.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE generatorConfiguration
        PUBLIC "-//mybatis.org//DTD MyBatis Generator Configuration 1.0//EN"
        "https://mybatis.org/dtd/mybatis-generator-config_1_0.dtd">

<generatorConfiguration>
  <classPathEntry
          location="${user.home}/.m2/repository/mysql/mysql-connector-java/8.0.28/mysql-connector-java-8.0.28.jar"/>

  <context id="dao" targetRuntime="MyBatis3DynamicSql">
    <property name="autoDelimitKeywords" value="true"/>
    <property name="beginningDelimiter" value="`"/>
    <property name="endingDelimiter" value="`"/>

    <!-- Standard Plugins -->
    <plugin type="org.mybatis.generator.plugins.SerializablePlugin"/>
    <plugin type="org.mybatis.generator.plugins.EqualsHashCodePlugin"/>
    <plugin type="org.mybatis.generator.plugins.ToStringPlugin"/>
    <plugin type="org.mybatis.generator.plugins.FluentBuilderMethodsPlugin"/>

    <!-- Custom Plugins -->
    <plugin type="com.goody.utils.mybatis.plugin.InsertIgnoreIntoPlugin"/>
    <plugin type="com.goody.utils.mybatis.plugin.InsertOnDuplicateKeyPlugin"/>
    <plugin type="com.goody.utils.mybatis.plugin.ReplaceIntoPlugin"/>
    <plugin type="com.goody.utils.mybatis.plugin.DtoGeneratorPlugin"/>
    <plugin type="com.goody.utils.mybatis.plugin.ServiceGeneratorPlugin"/>
    <plugin type="com.goody.utils.mybatis.plugin.CustomerMapperPlugin"/>

    <commentGenerator>
      <property name="addRemarkComments" value="true"/>
      <property name="suppressDate" value="true"/>
    </commentGenerator>

    <jdbcConnection driverClass="com.mysql.cj.jdbc.Driver"
                    connectionURL="jdbc:mysql://127.0.0.1:3306/your_database"
                    userId="your_username"
                    password="your_password">
      <property name="useSSL" value="false"/>
      <property name="serverTimezone" value="Asia/Shanghai"/>
      <property name="nullCatalogMeansCurrent" value="true"/>
    </jdbcConnection>

    <javaTypeResolver>
      <property name="forceBigDecimals" value="true"/>
      <property name="useJSR310Types" value="true"/>
    </javaTypeResolver>

    <javaModelGenerator targetPackage="com.yourpackage.model.entity"
                        targetProject="src/main/java">
      <property name="enableSubPackages" value="true"/>
      <property name="trimStrings" value="true"/>
    </javaModelGenerator>

    <javaClientGenerator type="ANNOTATEDMAPPER"
                         targetPackage="com.yourpackage.model.dao"
                         targetProject="src/main/java">
      <property name="enableSubPackages" value="true"/>
    </javaClientGenerator>

    <!-- Configure Tables to Generate -->
    <table schema="your_schema" tableName="your_table">
      <property name="useActualColumnNames" value="false"/>
    </table>

  </context>
</generatorConfiguration>
```

### Step 3: Execute Code Generation

```bash
mvn mybatis-generator:generate
```

![presentation.gif](/images/8.%20MyBatis%20Generator%20Custom%20Plugins/presentation.gif)

## 📝 Configuration Examples

### Single Primary Key Table Configuration

```xml

<table schema="toy" tableName="example_single_pk">
  <property name="useActualColumnNames" value="false"/>
</table>
```

### Composite Primary Key Table Configuration

```xml

<table schema="toy" tableName="example_double_pk">
  <property name="useActualColumnNames" value="false"/>
</table>
```

## 🏗️ Generated Code Analysis

The plugins generate a complete code structure for each table:

### File Structure

```
src/main/java/
├── com/yourpackage/model/
│   ├── entity/              # Entity Classes
│   │   ├── Example.java
│   │   └── ExampleDoublePk.java
│   ├── dao/                 # Standard Mapper Interfaces
│   │   ├── ExampleMapper.java
│   │   ├── ExampleDynamicSqlSupport.java
│   │   └── customer/        # Custom Mapper Interfaces
│   │       └── CustomerExampleMapper.java
│   └── dto/                 # DTO Classes
│       ├── ExampleDTO.java
│       └── ExampleDoublePkDTO.java
├── service/
│   ├── interfaces/          # Service Interfaces
│   │   ├── IExampleService.java
│   │   └── IExampleDoublePkService.java
│   └── impl/               # Service Implementations
│       ├── ExampleServiceImpl.java
│       └── ExampleDoublePkServiceImpl.java
```

### Core Code Snippet Analysis

#### MySQL Extension Methods (Mapper Layer)

```java

@Mapper
public interface ExampleMapper {
  // Standard generated methods...

  // INSERT IGNORE Support
  @Insert({"<script>" +
          " INSERT IGNORE INTO example" +
          " (`id`, `name`, `created`, `updated`)" +
          " VALUES" +
          " (#{item.id}, #{item.name}, #{item.created}, #{item.updated})" +
          "</script>"})
  void insertIgnoreCustom(@Param("item") Example record);

  // Batch INSERT IGNORE
  @Insert({"<script>" +
          " INSERT IGNORE INTO example" +
          " (`id`, `name`, `created`, `updated`)" +
          " VALUES" +
          " <foreach collection='items' item='item' separator=','>" +
          "   (#{item.id}, #{item.name}, #{item.created}, #{item.updated})" +
          " </foreach>" +
          "</script>"})
  void insertIgnoreBatchCustom(@Param("items") Collection<Example> records);

  // ON DUPLICATE KEY UPDATE Support
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

#### DTO Classes (Data Transfer Layer)

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

  // Entity to DTO conversion
  public static ExampleDTO fromEntity(Example entity) {
    if (entity == null) return null;

    return ExampleDTO.builder()
            .id(entity.getId())
            .name(entity.getName())
            .created(entity.getCreated())
            .updated(entity.getUpdated())
            .build();
  }

  // DTO to Entity conversion
  public Example toEntity() {
    return new Example()
            .withId(this.id)
            .withName(this.name)
            .withCreated(this.created)
            .withUpdated(this.updated);
  }
}
```

#### Service Interfaces (Service Layer Interface)

**Single Primary Key Service Interface**:

```java
public interface IExampleService {
  int save(ExampleDTO dto);

  int saveBatch(List<ExampleDTO> dtoList);

  int update(ExampleDTO dto);

  int deleteById(Long id);                    // Single parameter

  ExampleDTO findById(Long id);               // Single parameter

  List<ExampleDTO> findAll();
}
```

**Composite Primary Key Service Interface** (Plugin Fixed):

```java
public interface IExampleDoublePkService {
  int save(ExampleDoublePkDTO dto);

  int saveBatch(List<ExampleDoublePkDTO> dtoList);

  int update(ExampleDoublePkDTO dto);

  int deleteById(Long id, Long id2);          // Multi-parameter support

  ExampleDoublePkDTO findById(Long id, Long id2);  // Multi-parameter support

  List<ExampleDoublePkDTO> findAll();
}
```

#### Service Implementation (Service Layer Implementation)

**Core Improvement for Composite Primary Key Handling**:

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
    // Correctly calls composite primary key method
    return exampleDoublePkMapper.deleteByPrimaryKey(id, id2);
  }

  @Override
  public ExampleDoublePkDTO findById(Long id, Long id2) {
    if (id == null || id2 == null) {
      return null;
    }
    // Correctly calls composite primary key method
    ExampleDoublePk entity = exampleDoublePkMapper
            .selectByPrimaryKey(id, id2).orElse(null);
    return entity != null ? ExampleDoublePkDTO.fromEntity(entity) : null;
  }
}
```

### Key Feature Analysis

#### Composite Primary Key Support

- **Issue**: Previous version incorrectly attempted to use single primary key type
- **Solution**: Auto-detects primary key column count, generates multi-parameter methods for composite keys
- **Implementation**: `List<IntrospectedColumn> primaryKeyColumns`

#### MySQL-Specific Features

- **INSERT IGNORE**: Ignores duplicate key errors, continues inserting other records
- **ON DUPLICATE KEY UPDATE**: Auto updates specified fields on insert conflicts
- **REPLACE INTO**: MySQL's replace insert operation

#### Automation Level

- **Dependency Injection**: Auto-generates Spring `@Autowired` annotations
- **Null Checks**: Auto-generates parameter null validation
- **Conversion Methods**: Automatic conversion between DTO and Entity

## 🏗️ Project Structure

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
├── src/test/                        # Generated code examples
└── pom.xml
```

## 🎯 Usage Recommendations

1. **Development Workflow**: Design database table structure first, then use plugins to generate complete layered code
2. **Composite Primary Keys**: Plugin perfectly supports composite primary keys, no manual modification of generated
   code needed
3. **Extensibility**: Can inherit generated Service interfaces to add complex business logic
4. **MySQL Optimization**: Properly use INSERT IGNORE and ON DUPLICATE KEY features to improve performance

## 🔍 Source Code Analysis

*This section provides deep insights into the implementation details of each plugin for developers interested in understanding or extending the functionality.*

### Plugin Architecture Overview

All plugins extend `PluginAdapter` and follow MyBatis Generator's plugin lifecycle:

```java
public abstract class PluginAdapter implements Plugin {
    // Validation phase
    public boolean validate(List<String> warnings);

    // Code generation hooks
    public boolean clientGenerated(Interface interfaze, IntrospectedTable introspectedTable);
    public List<GeneratedJavaFile> contextGenerateAdditionalJavaFiles(IntrospectedTable introspectedTable);
}
```

### InsertIgnoreIntoPlugin Implementation Analysis

#### Core Method Generation Strategy

The plugin uses a sophisticated approach to generate SQL templates dynamically:

```java
private Method insertIgnoreIntoOne(Interface interfaze, IntrospectedTable introspectedTable) {
    // Dynamic column mapping using Stream API
    final String columnNames = introspectedTable.getAllColumns()
            .stream()
            .map(column -> String.format("`%s`", column.getActualColumnName()))
            .collect(Collectors.joining(", "));

    // Parameter binding with MyBatis syntax
    final String columnValueNames = introspectedTable.getAllColumns()
            .stream()
            .map(column -> String.format("#{item.%s}", column.getJavaProperty()))
            .collect(Collectors.joining(", "));

    // Template-based annotation generation
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

#### Key Technical Innovations

1. **Stream-based Field Transformation**: Efficiently converts database schema to Java method parameters
2. **Dynamic SQL Template Generation**: Creates parameterized SQL with proper escaping
3. **Batch Processing Support**: Automatic `<foreach>` loop generation for batch operations

### DtoGeneratorPlugin Implementation Analysis

#### Package Resolution Algorithm

```java
private TopLevelClass generateDtoClass(IntrospectedTable introspectedTable) {
    // Intelligent package transformation
    String entityFullType = introspectedTable.getBaseRecordType();
    String entityPackage = entityFullType.substring(0, entityFullType.lastIndexOf('.'));
    String dtoFullPackage = entityPackage.replace(".entity", "." + DTO_PACKAGE);

    // Type-safe class instantiation
    FullyQualifiedJavaType dtoType = new FullyQualifiedJavaType(dtoFullPackage + "." + dtoClassName);
    TopLevelClass dtoClass = new TopLevelClass(dtoType);
}
```

#### Field Generation with Metadata Preservation

```java
// Column-to-field conversion with comment preservation
for (IntrospectedColumn column : allColumns) {
    Field field = new Field(column.getJavaProperty(), column.getFullyQualifiedJavaType());
    field.setVisibility(JavaVisibility.PRIVATE);

    // Preserve database column comments
    if (column.getRemarks() != null && !column.getRemarks().trim().isEmpty()) {
        field.addJavaDocLine("/**");
        field.addJavaDocLine(" * " + column.getRemarks());
        field.addJavaDocLine(" */");
    }

    dtoClass.addField(field);
}
```

### ServiceGeneratorPlugin Implementation Analysis

#### Composite Primary Key Resolution

The most sophisticated feature is intelligent composite primary key handling:

```java
// Dynamic primary key analysis
List<IntrospectedColumn> primaryKeyColumns = introspectedTable.getPrimaryKeyColumns();

// Adaptive method signature generation
for (IntrospectedColumn column : primaryKeyColumns) {
    String paramName = column.getJavaProperty();
    method.addParameter(new Parameter(column.getFullyQualifiedJavaType(), paramName));
}

// Dynamic method call construction
StringBuilder methodCall = new StringBuilder("return " + mapperFieldName + ".deleteByPrimaryKey(");
for (int i = 0; i < primaryKeyColumns.size(); i++) {
    if (i > 0) methodCall.append(", ");
    methodCall.append(primaryKeyColumns.get(i).getJavaProperty());
}
methodCall.append(");");
```

#### Service Implementation Pattern

```java
// Null-safe parameter validation
for (IntrospectedColumn column : primaryKeyColumns) {
    method.addBodyLine("if (" + column.getJavaProperty() + " == null) {");
    method.addBodyLine("    return 0;");
    method.addBodyLine("}");
}
```

### Advanced Patterns and Techniques

#### Type Safety Enforcement

```java
// Generic type preservation
FullyQualifiedJavaType listType = new FullyQualifiedJavaType("List<" + dtoClassName + ">");
Parameter batchParameter = new Parameter(listType, "dtoList");

// Import resolution
serviceInterface.addImportedType(new FullyQualifiedJavaType("java.util.List"));
```

#### SQL Injection Prevention

All generated SQL uses parameterized queries:

```java
// Safe: Parameterized query
"INSERT IGNORE INTO " + tableName + " VALUES (#{item.id}, #{item.name})"

// Unsafe: String concatenation (never used)
"INSERT IGNORE INTO " + tableName + " VALUES (" + item.getId() + ", '" + item.getName() + "')"
```

#### Memory-Efficient Generation

```java
// Lazy evaluation pattern for large codebases
public List<GeneratedJavaFile> contextGenerateAdditionalJavaFiles(IntrospectedTable introspectedTable) {
    List<GeneratedJavaFile> files = new ArrayList<>();

    // Generate only when needed
    if (shouldGenerateService(introspectedTable)) {
        files.add(createServiceInterface(introspectedTable));
        files.add(createServiceImplementation(introspectedTable));
    }

    return files;
}
```

### Extension Points for Custom Development

#### Custom Plugin Template

```java
public class CustomPlugin extends PluginAdapter {
    @Override
    public boolean validate(List<String> warnings) {
        // Plugin validation logic
        return true;
    }

    @Override
    public boolean clientGenerated(Interface interfaze, IntrospectedTable introspectedTable) {
        // Add methods to existing Mapper interfaces
        interfaze.addMethod(createCustomMethod(introspectedTable));
        return super.clientGenerated(interfaze, introspectedTable);
    }

    private Method createCustomMethod(IntrospectedTable table) {
        // Custom method generation logic
        Method method = new Method("customMethod");
        method.setVisibility(JavaVisibility.PUBLIC);
        method.setAbstract(true);
        return method;
    }
}
```

#### Configuration-Driven Behavior

```java
@Override
public boolean validate(List<String> warnings) {
    // Read plugin properties
    String enableFeature = getProperties().getProperty("enableCustomFeature");
    if ("false".equals(enableFeature)) {
        // Skip plugin execution
        return false;
    }
    return true;
}
```

This deep source code analysis reveals the sophisticated engineering behind each plugin, showcasing advanced Java code generation techniques and MyBatis Generator's extensibility framework.

---

*This technical deep dive was created to provide comprehensive insights into the MyBatis Generator Custom Plugins architecture and implementation.*

