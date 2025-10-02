# [Github] 4. Value-Checker-Java: Customizable AOP Validation Framework


# [Github] 4. Value-Checker-Java: Customizable AOP Validation Framework

## Introduction

Value-Checker-Java is essentially a **customizable AOP pointcut framework**. It allows developers to insert custom validation logic before method execution, and this validation logic can be arbitrarily complex business rules.

However, if it merely provides an AOP pointcut, that wouldn't be very meaningful. **The core value of Value-Checker-Java lies in its thread-safe context management mechanism**. Without this context management, data queried in the first validator cannot be used in subsequent validators, forcing each validator to re-query data, which defeats the purpose of validation chains.

It is precisely because of `ValueCheckerReentrantThreadLocal`, this thread-safe context manager, that multiple validators can share data and form truly meaningful validation chains.

## Basic Usage

### Validator Configuration

```java
// From TargetService.java
@ValueCheckers(checkers = {
    @ValueCheckers.ValueChecker(method = "verify", keys = {"#id", "#name"}, handler = SampleCheckerHandlerImpl.class),
    @ValueCheckers.ValueChecker(method = "verify", keys = "#id", handler = SampleCheckerHandlerImpl.class),
    @ValueCheckers.ValueChecker(method = "verify", keys = "#name", handler = SampleCheckerHandlerImpl.class)
})
public void checker(Long id, String name) {
    // Will execute 3 validators in sequence
}
```

### Validator Implementation

```java
// From SampleCheckerHandlerImpl.java
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

### Key Technical Implementation

#### Annotation Design

`@ValueCheckers` adopts a nested annotation design pattern:

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

Design highlights:
- **Array configuration**: Supports multiple validator combinations
- **Type safety**: Handler must implement IValueCheckerHandler interface
- **Flexible method mapping**: Can specify any validation method name
- **Parameterized configuration**: Pass required parameters through keys array

#### SpEL Expression Engine

`SeplUtil` class provides powerful parameter extraction capabilities:

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

Technical features:
- **Dynamic parameter mapping**: Runtime acquisition of method parameter names
- **Expression parsing**: Supports complex SpEL expressions
- **Type safety**: Automatic type conversion handling
- **Performance optimization**: Reuses SpEL parser instances

#### Intelligent Method Invocation Mechanism

The method invocation mechanism in `ValueCheckerAspect` has the following characteristics:

```java
private void methodInvoke(Object instance, String method, Object[] paras) {
    // Generate method signature cache key
    final String parasName = objectTypeName(paras);
    final String objectMethodName = String.format(OBJECT_METHOD_FORMAT,
        instanceClass.getSimpleName(), method, parasName);

    // Prioritize cached methods
    if (OBJECT_METHOD_MAP.containsKey(objectMethodName)) {
        final Method pointMethod = OBJECT_METHOD_MAP.get(objectMethodName);
        pointMethod.invoke(instance, paras);
        return;
    }

    // First call: perform method matching and caching
    for (Method subMethod : instanceClass.getMethods()) {
        // Method name + parameter length + parameter type matching
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

Core advantages:
- **Performance optimization**: Method reflection result caching, avoiding repeated lookups
- **Precise matching**: Supports accurate identification of method overloading
- **Type safety**: Strict parameter type matching

#### Reentrant ThreadLocal Design

`ValueCheckerReentrantThreadLocal` is an innovative design of the framework:

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

Design essence:
- **Reference counting**: Uses AtomicInteger to implement reentrant counting
- **Thread safety**: ConcurrentHashMap ensures concurrent safety
- **Automatic cleanup**: Automatically cleans up resources when outermost call ends
- **Nested support**: Perfect support for nested validator calls

## ThreadLocal Context Management

**This is one of the core capabilities of the framework**.

### Data Storage and Retrieval

```java
// Store data to ThreadLocal
public void verifyPutThreadValue(String name) {
    ValueCheckerReentrantThreadLocal.getOrDefault(String.class, name);
    if (!ValueCheckerReentrantThreadLocal.getOrDefault(String.class, "").equals(name)) {
        throw new ValueIllegalException("error");
    }
}

// Retrieve data from ThreadLocal
public void verifyGetRightThreadValue(String name) {
    if (!ValueCheckerReentrantThreadLocal.getOrDefault(String.class, name).equals(name)) {
        throw new ValueIllegalException("error");
    }
}
```

### Why It's Important

**Without ThreadLocal**:
```java
public void validateUser(Long userId) {
    User user = userRepository.findById(userId);  // 1st query
}

public void validateUserPermission(Long userId) {
    User user = userRepository.findById(userId);  // 2nd query, duplicate!
}
```

**With ThreadLocal**:
```java
public void validateUser(Long userId) {
    User user = userRepository.findById(userId);  // Only query once
    ValueCheckerReentrantThreadLocal.put(user);
}

public void validateUserPermission(Long userId) {
    User user = ValueCheckerReentrantThreadLocal.get(User.class, () -> null);  // Direct retrieval
}
```

## Reentrant Support

### Test Scenario

```java
// From TargetService.java
@ValueCheckers(checkers = {
    @ValueCheckers.ValueChecker(method = "verifyPutThreadValue", keys = "#name", handler = SampleCheckerHandlerImpl.class)
})
public void checkerReentrant(String name) {
    // 1st layer AOP: store data to ThreadLocal
    this.targetService.checkerGetThreadValue(name);      // 2nd layer AOP
    this.targetService.checkerGetWrongThreadValue("");   // 3rd layer AOP
}
```

### Reentrant Counter

```java
// ValueCheckerReentrantThreadLocal.java
public static void init() {
    final AtomicInteger counter = VALUE_CHECKER_THREAD_LOCAL_COUNTER.get();
    if (null == counter) {
        // First call: initialize ThreadLocal
        VALUE_CHECKER_THREAD_LOCAL.set(new ConcurrentHashMap<>());
        VALUE_CHECKER_THREAD_LOCAL_COUNTER.set(new AtomicInteger());
    } else {
        // Nested call: counter+1
        counter.addAndGet(1);
    }
}

public static void clear() {
    final AtomicInteger counter = VALUE_CHECKER_THREAD_LOCAL_COUNTER.get();
    if (null == counter || counter.get() <= 0) {
        // Outermost call: actually clean ThreadLocal
        VALUE_CHECKER_THREAD_LOCAL.remove();
        VALUE_CHECKER_THREAD_LOCAL_COUNTER.remove();
    } else {
        // Inner call: counter-1
        counter.addAndGet(-1);
    }
}
```

**Example**:
```java
// ValueCheckerAspectTest.java - Test comments explain the entire flow
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

Without reentrant support, the second and third layer AOP calls would clear ThreadLocal data stored by the first layer, causing validation failure.

## Core Architecture

### AOP Aspect try-finally Structure

```java
// ValueCheckerAspect.java - Key try-finally implementation
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

### Execution Flow

```
@ValueCheckers annotated method
        ↓
ValueCheckerAspect intercepts
        ↓
try {
    init ThreadLocal (reentrant counting)
    ↓
    iterate checkers array
    ↓
    SpEL parameter extraction → reflection call Handler
    ↓
    validation fails throw exception / validation succeeds continue
    ↓
    all validations pass execute original method
} finally {
    clear ThreadLocal (reentrant counting)
}
```

**Key roles of try-finally**:
- **Guaranteed resource cleanup**: ThreadLocal is cleaned regardless of validation success or failure
- **Reentrant count management**: Ensures proper ThreadLocal management in nested calls through counter
- **Memory leak prevention**: Ensures ThreadLocal is properly cleaned when method ends

## Performance Optimization Design

### Method Caching Mechanism

```java
// ValueCheckerAspect.java - Method caching based on performance considerations
private static final ConcurrentHashMap<String, Method> OBJECT_METHOD_MAP = new ConcurrentHashMap<>();

private void methodInvoke(Object instance, String method, Object[] paras) {
    // Generate cache key
    final String objectMethodName = String.format(OBJECT_METHOD_FORMAT,
        instanceClass.getSimpleName(), method, objectTypeName(paras));

    // Prioritize cache usage
    if (OBJECT_METHOD_MAP.containsKey(objectMethodName)) {
        final Method pointMethod = OBJECT_METHOD_MAP.get(objectMethodName);
        pointMethod.invoke(instance, paras);
        return;
    }

    // First call: traverse methods and cache
    for (Method subMethod : instanceClass.getMethods()) {
        if (subMethod.getName().equals(method) &&
            subMethod.getParameterTypes().length == paras.length &&
            objectTypeName(paras).equals(methodTypeName(subMethod.getParameterTypes()))) {

            OBJECT_METHOD_MAP.put(objectMethodName, subMethod);  // Cache result
            subMethod.invoke(instance, paras);
            return;
        }
    }
}
```

### Performance Considerations

1. **Reflection overhead optimization**:
   - First call traverses all methods for matching
   - Subsequent calls directly get Method object from ConcurrentHashMap
   - Avoids repeated reflection lookup operations

2. **SpEL expression performance**:
   - Reuses SpEL parser instance: `private static final ExpressionParser SPEL_PARSER`
   - Runtime parameter mapping, supports complex expressions but has performance cost

3. **ThreadLocal overhead**:
   - ThreadLocal operations themselves are lightweight
   - Reentrant counter uses AtomicInteger, thread-safe and efficient

4. **Validation chain execution**:
   - Multiple validators execute serially
   - Total time = sum of individual validator times
   - Reduces duplicate queries through data sharing

## Java 8 vs Java 17

**Core difference**: SpEL parameter name acquisition

**Java 17 requires additional configuration**:
```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-compiler-plugin</artifactId>
    <configuration>
        <parameters>true</parameters>  <!-- Preserve parameter names -->
    </configuration>
</plugin>
```

**Dependency versions**:
- Java 8: Spring Boot 2.5.13
- Java 17: Spring Boot 3.5.5

## Summary

Value-Checker-Java solves the core problem: **data sharing between validators**.

- **Essence**: Customizable AOP + ThreadLocal context
- **Value**: Avoid duplicate queries, make validation chains meaningful
- **Key**: Reentrant ThreadLocal supports nested calls
- **Scenario**: Multi-step validation that needs to share query results

