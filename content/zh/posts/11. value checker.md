+++
date = '2025-09-26T23:27:17+08:00'
draft = false
title = '[Github] 4. Value-Checker-Java：可自定义的AOP验证框架'
categories = ["Github", "Efficiency"]
tags = ["Github", "Efficiency"]
+++

# [Github] 4. Value-Checker-Java：可自定义的AOP验证框架

## 引言

Value-Checker-Java本质上是一个**可自定义的AOP切入点框架**。它允许开发者在方法执行前插入自定义的验证逻辑，而这些验证逻辑可以是任意复杂的业务规则。

但是，如果仅仅是提供一个AOP切入点，那意义并不大。**Value-Checker-Java的核心价值在于它提供了线程安全的上下文管理机制**。如果没有这个上下文管理，在第一个验证器中查询的数据就无法在后续的验证器中使用，每个验证器都必须重新查询数据，这样就失去了验证链的意义。

正是因为有了`ValueCheckerReentrantThreadLocal`这个线程安全的上下文管理器，多个验证器才能够共享数据，形成真正有意义的验证链条。

## Github

[value-checker-java-8](https://github.com/GOODDAYDAY/value-checker-java-8)

[value-checker-java-17](https://github.com/GOODDAYDAY/value-checker-java-17)

## 基本使用

### 验证器配置

```java
// 来自TargetService.java
@ValueCheckers(checkers = {
    @ValueCheckers.ValueChecker(method = "verify", keys = {"#id", "#name"}, handler = SampleCheckerHandlerImpl.class),
    @ValueCheckers.ValueChecker(method = "verify", keys = "#id", handler = SampleCheckerHandlerImpl.class),
    @ValueCheckers.ValueChecker(method = "verify", keys = "#name", handler = SampleCheckerHandlerImpl.class)
})
public void checker(Long id, String name) {
    // 会按顺序执行3个验证器
}
```

### 验证器实现

```java
// 来自SampleCheckerHandlerImpl.java
@Service
public class SampleCheckerHandlerImpl implements IValueCheckerHandler {
    public static final Long CORRECT_ID = 2L;
    public static final String CORRECT_NAME = "correctName";

    public void verify(Long id, String name) {
        if (!CORRECT_ID.equals(id) || !CORRECT_NAME.equals(name)) {
            throw new ValueIllegalException("error");
        }
    }

    public void verify(Long id) {
        if (!CORRECT_ID.equals(id)) {
            throw new ValueIllegalException("error");
        }
    }

    public void verify(String name) {
        if (!CORRECT_NAME.equals(name)) {
            throw new ValueIllegalException("error");
        }
    }
}
```

### 关键技术实现

#### 注解设计

`@ValueCheckers`采用了嵌套注解的设计模式：

```java
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface ValueCheckers {
    ValueChecker[] checkers();

    @interface ValueChecker {
        Class<? extends IValueCheckerHandler> handler();
        String method() default "verify";
        String[] keys() default "";
    }
}
```

设计亮点：
- **数组配置**：支持多个验证器的组合
- **类型安全**：Handler必须实现IValueCheckerHandler接口
- **灵活方法映射**：可指定任意的验证方法名
- **参数化配置**：通过keys数组传递验证所需参数

#### SpEL表达式引擎

`SeplUtil`类提供了强大的参数提取能力：

```java
public static Object[] getValue(ProceedingJoinPoint point, String[] keys) {
    MethodSignature methodSignature = (MethodSignature) point.getSignature();
    String[] params = methodSignature.getParameterNames();
    Object[] args = point.getArgs();

    EvaluationContext context = new StandardEvaluationContext();
    for (int len = 0; len < params.length; len++) {
        context.setVariable(params[len], args[len]);
    }

    Object[] values = new Object[keys.length];
    for (int i = 0; i < keys.length; i++) {
        Expression expression = SPEL_PARSER.parseExpression(keys[i]);
        values[i] = expression.getValue(context, Object.class);
    }
    return values;
}
```

技术特点：
- **动态参数映射**：运行时获取方法参数名
- **表达式解析**：支持复杂的SpEL表达式
- **类型安全**：自动处理类型转换
- **性能优化**：复用SpEL解析器实例

#### 智能方法调用机制

`ValueCheckerAspect`中的方法调用机制具有以下特性：

```java
private void methodInvoke(Object instance, String method, Object[] paras) {
    // 生成方法签名缓存键
    final String parasName = objectTypeName(paras);
    final String objectMethodName = String.format(OBJECT_METHOD_FORMAT,
        instanceClass.getSimpleName(), method, parasName);

    // 优先使用缓存的方法
    if (OBJECT_METHOD_MAP.containsKey(objectMethodName)) {
        final Method pointMethod = OBJECT_METHOD_MAP.get(objectMethodName);
        pointMethod.invoke(instance, paras);
        return;
    }

    // 首次调用时进行方法匹配和缓存
    for (Method subMethod : instanceClass.getMethods()) {
        // 方法名匹配 + 参数长度匹配 + 参数类型匹配
        if (subMethod.getName().equals(method) &&
            subMethod.getParameterTypes().length == paras.length &&
            parasName.equals(methodTypeName(subMethod.getParameterTypes()))) {

            OBJECT_METHOD_MAP.put(objectMethodName, subMethod);
            subMethod.invoke(instance, paras);
            return;
        }
    }
}
```

核心优势：
- **性能优化**：方法反射结果缓存，避免重复查找
- **精确匹配**：支持方法重载的准确识别
- **类型安全**：严格的参数类型匹配

#### 可重入ThreadLocal设计

`ValueCheckerReentrantThreadLocal`是框架的创新设计：

```java
public static void init() {
    final AtomicInteger counter = VALUE_CHECKER_THREAD_LOCAL_COUNTER.get();
    if (null == counter) {
        VALUE_CHECKER_THREAD_LOCAL.set(new ConcurrentHashMap<>());
        VALUE_CHECKER_THREAD_LOCAL_COUNTER.set(new AtomicInteger());
        return;
    }
    counter.addAndGet(1);
}

public static void clear() {
    final AtomicInteger counter = VALUE_CHECKER_THREAD_LOCAL_COUNTER.get();
    if (null == counter || counter.get() <= 0) {
        VALUE_CHECKER_THREAD_LOCAL.remove();
        VALUE_CHECKER_THREAD_LOCAL_COUNTER.remove();
        return;
    }
    counter.addAndGet(-1);
}
```

设计精髓：
- **引用计数**：使用AtomicInteger实现可重入计数
- **线程安全**：ConcurrentHashMap保证并发安全
- **自动清理**：最外层调用结束时自动清理资源
- **嵌套支持**：完美支持验证器的嵌套调用

## ThreadLocal上下文管理

**这是框架可以使用的核心之一**。

### 数据存储和获取

```java
// 存储数据到ThreadLocal
public void verifyPutThreadValue(String name) {
    ValueCheckerReentrantThreadLocal.getOrDefault(String.class, name);
    if (!ValueCheckerReentrantThreadLocal.getOrDefault(String.class, "").equals(name)) {
        throw new ValueIllegalException("error");
    }
}

// 从ThreadLocal获取数据
public void verifyGetRightThreadValue(String name) {
    if (!ValueCheckerReentrantThreadLocal.getOrDefault(String.class, name).equals(name)) {
        throw new ValueIllegalException("error");
    }
}
```

### 为什么重要

**没有ThreadLocal**：
```java
public void validateUser(Long userId) {
    User user = userRepository.findById(userId);  // 第1次查询
}

public void validateUserPermission(Long userId) {
    User user = userRepository.findById(userId);  // 第2次查询，重复！
}
```

**有了ThreadLocal**：
```java
public void validateUser(Long userId) {
    User user = userRepository.findById(userId);  // 只查询1次
    ValueCheckerReentrantThreadLocal.put(user);
}

public void validateUserPermission(Long userId) {
    User user = ValueCheckerReentrantThreadLocal.get(User.class, () -> null);  // 直接获取
}
```

## 可重入性支持

### 测试场景

```java
// 来自TargetService.java
@ValueCheckers(checkers = {
    @ValueCheckers.ValueChecker(method = "verifyPutThreadValue", keys = "#name", handler = SampleCheckerHandlerImpl.class)
})
public void checkerReentrant(String name) {
    // 第1层AOP：存储数据到ThreadLocal
    this.targetService.checkerGetThreadValue(name);      // 第2层AOP
    this.targetService.checkerGetWrongThreadValue("");   // 第3层AOP
}
```

### 可重入计数器

```java
// ValueCheckerReentrantThreadLocal.java
public static void init() {
    final AtomicInteger counter = VALUE_CHECKER_THREAD_LOCAL_COUNTER.get();
    if (null == counter) {
        // 首次调用：初始化ThreadLocal
        VALUE_CHECKER_THREAD_LOCAL.set(new ConcurrentHashMap<>());
        VALUE_CHECKER_THREAD_LOCAL_COUNTER.set(new AtomicInteger());
    } else {
        // 嵌套调用：计数器+1
        counter.addAndGet(1);
    }
}

public static void clear() {
    final AtomicInteger counter = VALUE_CHECKER_THREAD_LOCAL_COUNTER.get();
    if (null == counter || counter.get() <= 0) {
        // 最外层调用：真正清理ThreadLocal
        VALUE_CHECKER_THREAD_LOCAL.remove();
        VALUE_CHECKER_THREAD_LOCAL_COUNTER.remove();
    } else {
        // 内层调用：计数器-1
        counter.addAndGet(-1);
    }
}
```

**举例**：
```java
// ValueCheckerAspectTest.java - 测试注释说明了整个流程
// aop1 - 1.1 counter = 0    init ThreadLocal
// aop1 - 1.2 counter = 0    set RIGHT_VALUE to ThreadLocal

// aop2 - 2.1 counter = 1    init ThreadLocal
// aop2 - 2.2 counter = 1    try to set RIGHT_VALUE to ThreadLocal (success)
// aop2 - 2.3 counter = 0    clear ThreadLocal (if not reentrant, RIGHT_VALUE will be clear)

// aop3 - 3.1 counter = 1    init ThreadLocal
// aop3 - 3.2 counter = 1    try to set WRONG_VALUE to ThreadLocal (fail)
// aop3 - 3.3 counter = 0    clear ThreadLocal

// aop1 - 1.3 counter = null clear ThreadLocal
```

如果没有可重入性支持，第二层和第三层AOP调用会清空第一层存储的ThreadLocal数据，导致验证失败。

## 核心架构

### AOP切面的try-finally结构

```java
// ValueCheckerAspect.java - 关键的try-finally实现
@Around("handleValueCheckerPoint() && @annotation(valueCheckers)")
public Object around(ProceedingJoinPoint point, ValueCheckers valueCheckers) throws Throwable {
    try {
        // init ThreadLocal, if init in sub ValueChecker, ThreadLocal will counter++
        ValueCheckerReentrantThreadLocal.init();
        for (ValueCheckers.ValueChecker checker : valueCheckers.checkers()) {
            valueCheck(checker, point);
        }
        return point.proceed();
    } finally {
        // clear ThreadLocal, if clear in sub ValueChecker, ThreadLocal will counter--
        ValueCheckerReentrantThreadLocal.clear();
    }
}
```

### 执行流程

```
@ValueCheckers注解方法
        ↓
ValueCheckerAspect拦截
        ↓
try {
    init ThreadLocal (可重入计数)
    ↓
    遍历checkers数组
    ↓
    SpEL提取参数 → 反射调用Handler
    ↓
    验证失败抛异常 / 验证成功继续
    ↓
    所有验证通过执行原方法
} finally {
    clear ThreadLocal (可重入计数)
}
```

**try-finally的关键作用**：
- **保证资源清理**：无论验证成功还是失败，都会清理ThreadLocal
- **可重入计数管理**：通过计数器确保嵌套调用时ThreadLocal正确管理
- **防止内存泄漏**：确保ThreadLocal在方法结束时被正确清理

## 性能优化设计

### 方法缓存机制

```java
// ValueCheckerAspect.java - 基于性能考虑的方法缓存
private static final ConcurrentHashMap<String, Method> OBJECT_METHOD_MAP = new ConcurrentHashMap<>();

private void methodInvoke(Object instance, String method, Object[] paras) {
    // 生成缓存键
    final String objectMethodName = String.format(OBJECT_METHOD_FORMAT,
        instanceClass.getSimpleName(), method, objectTypeName(paras));

    // 优先使用缓存
    if (OBJECT_METHOD_MAP.containsKey(objectMethodName)) {
        final Method pointMethod = OBJECT_METHOD_MAP.get(objectMethodName);
        pointMethod.invoke(instance, paras);
        return;
    }

    // 首次调用：遍历方法并缓存
    for (Method subMethod : instanceClass.getMethods()) {
        if (subMethod.getName().equals(method) &&
            subMethod.getParameterTypes().length == paras.length &&
            objectTypeName(paras).equals(methodTypeName(subMethod.getParameterTypes()))) {

            OBJECT_METHOD_MAP.put(objectMethodName, subMethod);  // 缓存结果
            subMethod.invoke(instance, paras);
            return;
        }
    }
}
```

### 性能考虑点

1. **反射开销优化**：
    - 首次调用遍历所有方法进行匹配
    - 后续调用直接从ConcurrentHashMap获取Method对象
    - 避免重复的反射查找操作

2. **SpEL表达式性能**：
    - 复用SpEL解析器实例：`private static final ExpressionParser SPEL_PARSER`
    - 运行时参数映射，支持复杂表达式但有性能成本

3. **ThreadLocal开销**：
    - ThreadLocal操作本身轻量
    - 可重入计数器使用AtomicInteger，线程安全且高效

4. **验证链执行**：
    - 多个验证器串行执行
    - 总耗时 = 各验证器耗时之和
    - 通过数据共享减少重复查询

## Java 8 vs Java 17

**核心差异**：SpEL参数名获取

**Java 17需要额外配置**：
```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-compiler-plugin</artifactId>
    <configuration>
        <parameters>true</parameters>  <!-- 保留参数名 -->
    </configuration>
</plugin>
```

**依赖版本**：
- Java 8：Spring Boot 2.5.13
- Java 17：Spring Boot 3.5.5

## 总结

Value-Checker-Java解决的核心问题：**验证器间数据共享**。

- **本质**：可自定义AOP + ThreadLocal上下文
- **价值**：避免重复查询，让验证链有意义
- **关键**：可重入ThreadLocal支持嵌套调用
- **场景**：多步验证需要共享查询结果的业务
