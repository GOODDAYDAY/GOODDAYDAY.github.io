# [Github] 3. Basic-Check：参数验证框架


# [Github] 3. Basic-Check：参数验证框架

## 引言

在日常的Java开发中，方法参数验证是一个常见且重要的需求。传统的参数验证通常需要在每个方法中编写大量的if-else判断代码，不仅冗余繁琐，还容易遗漏。Basic-Check-Java正是为了解决这一痛点而诞生的轻量级参数验证框架。

本文将深入介绍Basic-Check-Java的设计理念、核心特性以及实际应用，帮助开发者快速掌握这个实用的工具。

## Github

[basic-check-java-8](https://github.com/GOODDAYDAY/basic-check-java-8)

[basic-check-java-17](https://github.com/GOODDAYDAY/basic-check-java-17)


## 设计理念与核心特性

### 设计理念

Basic-Check-Java基于以下核心理念设计：

1. **简洁性**：通过注解声明式编程，减少样板代码
2. **灵活性**：支持多种返回策略，适应不同业务场景
3. **无侵入性**：基于AOP实现，对业务代码零侵入
4. **可扩展性**：支持自定义验证规则和处理逻辑

### 核心特性

#### 丰富的参数验证注解

Basic-Check-Java提供了六种常用的参数验证注解：

- `@CheckNull`：验证参数不为null
- `@CheckString`：验证字符串参数非空白
- `@CheckLong`：验证Long类型参数大于-1
- `@CheckCollection`：验证集合类型参数非空
- `@CheckMap`：验证Map类型参数非空
- `@CheckObject`：使用Bean Validation验证对象参数

#### 灵活的返回策略

通过`@BasicCheck`注解的`returnType`属性，支持三种验证失败时的处理策略：

- `EXCEPTION`（默认）：抛出IllegalArgumentException异常
- `EMPTY`：根据方法返回类型自动返回空值（空集合、空Map、Optional.empty()等）
- `NULL`：直接返回null

#### 基于Spring AOP的无侵入式实现

框架采用AspectJ注解和Spring AOP技术，通过切面编程在方法执行前进行参数验证，对业务代码完全无侵入。

## 技术架构深入分析

### 核心架构图

```
@BasicCheck注解方法
        ↓
NotNullAndPositiveAspect切面拦截
        ↓
遍历方法参数及其注解
        ↓
根据注解类型执行相应验证逻辑
        ↓
验证失败 → 根据returnType返回相应结果
验证成功 → 继续执行原方法
```

### 关键技术实现

#### 注解设计

以`@BasicCheck`为例，展示了优雅的注解设计：

```java
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface BasicCheck {
    ReturnType returnType() default ReturnType.EXCEPTION;

    enum ReturnType {
        EMPTY,    // 返回空集合/映射/可选值
        NULL,     // 返回null
        EXCEPTION // 抛出异常
    }
}
```

关键设计要点：
- `@Target(ElementType.METHOD)`：只能作用于方法级别
- `@Retention(RetentionPolicy.RUNTIME)`：运行时保留注解信息
- 提供了枚举类型的配置选项，保证类型安全

#### AOP切面实现

`NotNullAndPositiveAspect`是框架的核心组件，承担了参数验证的主要逻辑：

```java
@Around("handleBasicCheckPoint() && @annotation(basicCheck)")
public Object around(ProceedingJoinPoint point, BasicCheck basicCheck) throws Throwable {
    final Object[] args = point.getArgs();
    final MethodSignature signature = (MethodSignature) point.getSignature();
    final Method method = signature.getMethod();
    final Parameter[] parameters = method.getParameters();

    // 遍历所有参数进行验证
    for (int i = 0; i < parameters.length; i++) {
        // 根据不同注解类型执行相应验证逻辑
        if (parameters[i].isAnnotationPresent(CheckNull.class) && null == args[i]) {
            return this.getReturnObj(basicCheck, method);
        }
        // ... 其他验证逻辑
    }
    return point.proceed();
}
```

实现亮点：
1. **参数与注解映射**：通过反射获取方法参数和对应的注解信息
2. **验证逻辑解耦**：每种验证类型独立处理，便于维护和扩展
3. **智能返回处理**：根据方法返回类型和配置策略智能生成返回值

#### 智能返回值生成

框架的一个巧妙设计是根据方法返回类型自动生成合适的空值：

```java
private Object getReturnObj(BasicCheck annotation, Method method) {
    if (annotation.returnType() == BasicCheck.ReturnType.EMPTY) {
        Class<?> returnType = method.getReturnType();
        if (returnType == List.class) return Collections.emptyList();
        if (returnType == Set.class) return Collections.emptySet();
        if (returnType == Map.class) return Collections.emptyMap();
        if (returnType == Optional.class) return Optional.empty();
    }
    // ... 其他处理逻辑
}
```

这种设计避免了开发者手动处理不同返回类型的复杂性。

## 实际应用案例

### 基础使用示例

#### 简单参数验证

```java
@Service
public class UserService {

    @BasicCheck
    public void createUser(@CheckNull String username,
                          @CheckString String email,
                          @CheckLong Long age) {
        // 业务逻辑，无需手动验证参数
        userRepository.save(new User(username, email, age));
    }
}
```

#### 集合参数验证

```java
@BasicCheck
public void batchCreateUsers(@CheckCollection List<User> users,
                            @CheckMap Map<String, Object> config) {
    // 确保users集合和config映射都不为空
    users.forEach(user -> userRepository.save(user));
}
```

#### 返回空值策略

```java
@BasicCheck(returnType = BasicCheck.ReturnType.EMPTY)
public List<User> searchUsers(@CheckString String keyword) {
    // 如果keyword为空白字符串，自动返回空List
    return userRepository.findByKeyword(keyword);
}
```

### 高级应用场景

#### 复杂对象验证

```java
// 定义验证DTO
@Data
@Builder
public class UserCreateRequest {
    @NotNull
    @Min(1)
    private Integer id;

    @NotBlank
    private String name;

    @Valid
    @NotEmpty
    private List<@Valid ContactInfo> contacts;
}

// 使用@CheckObject验证复杂对象
@BasicCheck
public void createUserWithDetails(@CheckObject UserCreateRequest request) {
    // 框架会自动使用Bean Validation验证整个对象树
    userService.createUser(request);
}
```

#### 混合验证策略

```java
@BasicCheck(returnType = BasicCheck.ReturnType.NULL)
public void processOrder(@CheckLong Long orderId,
                        @CheckString String customerId,
                        @CheckCollection List<OrderItem> items,
                        @CheckObject OrderConfig config) {
    // 任一参数验证失败都返回null，适合void方法
    orderProcessor.process(orderId, customerId, items, config);
}
```

## 性能考量与最佳实践

### 性能分析

1. **反射开销**：框架使用反射获取方法参数信息，建议在高并发场景下进行性能测试
2. **AOP开销**：Spring AOP基于代理模式，会有轻微的性能开销
3. **Bean Validation**：对象验证会有一定的性能成本，但通常可以接受

### 最佳实践

#### 合理选择验证策略

```java
// 推荐：查询方法使用EMPTY策略
@BasicCheck(returnType = BasicCheck.ReturnType.EMPTY)
public List<User> findUsers(@CheckString String keyword) {
    return userRepository.findByKeyword(keyword);
}

// 推荐：创建/更新方法使用EXCEPTION策略
@BasicCheck
public void updateUser(@CheckLong Long id, @CheckObject UserUpdateRequest request) {
    userRepository.update(id, request);
}
```

#### 验证注解的组合使用

```java
// 组合使用多个验证注解
@BasicCheck
public void processUserData(@CheckNull @CheckString String username,
                           @CheckNull @CheckLong Long userId,
                           @CheckNull @CheckObject UserData data) {
    // 既检查null又检查业务规则
}
```

#### 自定义验证对象的设计

```java
@Data
public class ProductRequest {
    @NotNull(message = "产品ID不能为空")
    @Min(value = 1, message = "产品ID必须大于0")
    private Long productId;

    @NotBlank(message = "产品名称不能为空")
    @Size(max = 100, message = "产品名称长度不能超过100")
    private String productName;

    @Valid // 启用嵌套验证
    @NotNull(message = "产品配置不能为空")
    private ProductConfig config;
}
```

## Java 8 vs Java 17版本差异

### 核心差异：Validation API的命名空间变更

这是两个版本最重要的区别：

**Java 8版本**使用传统的`javax`命名空间：
```java
import javax.validation.Validation;
import javax.validation.Validator;
```

**Java 17版本**使用新的`jakarta`命名空间：
```java
import jakarta.validation.Validation;
import jakarta.validation.Validator;
```

### 完整依赖对比

**Java 8版本依赖**：
- Spring Boot 2.4.4
- Lombok 1.18.18
- `javax.validation:validation-api:2.0.1.Final`
- `org.hibernate:hibernate-validator:6.0.1.Final`
- `org.glassfish:javax.el:3.0.1-b09`

**Java 17版本依赖**：
- Spring Boot 3.5.5
- Lombok 1.18.38
- `org.hibernate.validator:hibernate-validator:8.0.1.Final`
- `org.glassfish:jakarta.el:4.0.2`

## 扩展与定制

### 自定义验证注解

框架采用开放式设计，支持添加自定义验证注解：

```java
// 1. 定义自定义验证注解
@Target(ElementType.PARAMETER)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface CheckEmail {
}

// 2. 在NotNullAndPositiveAspect中添加验证逻辑
if (parameters[i].isAnnotationPresent(CheckEmail.class) &&
    !isValidEmail((String) args[i])) {
    return this.getReturnObj(basicCheck, method);
}
```

### 自定义返回策略

可以扩展ReturnType枚举，添加更多的返回策略：

```java
public enum ReturnType {
    EMPTY,
    NULL,
    EXCEPTION,
    CUSTOM_DEFAULT // 自定义默认值策略
}
```

## 总结

Basic-Check-Java是一个设计精巧、功能实用的参数验证框架。它通过以下特点解决了Java开发中参数验证的痛点：

### 核心优势

1. **开发效率高**：减少80%的参数验证样板代码
2. **使用简单**：仅需添加注解即可享受完整的验证功能
3. **功能全面**：支持基本类型、集合、复杂对象的多层次验证
4. **灵活可配**：多种返回策略适应不同业务场景
5. **无侵入性**：基于AOP实现，对现有代码零影响

### 适用场景

- **Web应用**：Controller层参数验证
- **服务层**：Service方法参数校验
- **工具类**：通用工具方法的参数检查
- **API接口**：第三方接口调用前的参数预检

Basic-Check-Java体现了优秀框架的设计原则：简单易用、功能完整、性能可靠、易于扩展。它不仅能够显著提升开发效率，还能帮助开发者写出更加健壮和优雅的代码。

无论是新项目还是既有项目，Basic-Check-Java都能够快速集成并发挥价值，是Java开发者工具箱中不可缺少的利器。

