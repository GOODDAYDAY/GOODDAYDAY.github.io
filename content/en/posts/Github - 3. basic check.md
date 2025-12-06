+++
date = '2025-09-26T22:27:17+08:00'
draft = false
title = '[Github] 3. Basic-Check: Validation Framework'
categories = ["Github", "Efficiency"]
tags = ["Github", "Efficiency"]
+++

## Introduction

Parameter validation is a common and crucial requirement in daily Java development. Traditional parameter validation typically requires writing extensive if-else conditional code in each method, which is not only redundant and tedious but also prone to omissions. Basic-Check-Java was born to solve this pain point as a lightweight parameter validation framework.

This article will provide an in-depth introduction to Basic-Check-Java's design philosophy, core features, and practical applications, helping developers quickly master this practical tool.

## Github

[basic-check-java-8](https://github.com/GOODDAYDAY/basic-check-java-8)

[basic-check-java-17](https://github.com/GOODDAYDAY/basic-check-java-17)

## Design Philosophy and Core Features

### Design Philosophy

Basic-Check-Java is designed based on the following core principles:

1. **Simplicity**: Reduce boilerplate code through annotation-driven declarative programming
2. **Flexibility**: Support multiple return strategies to adapt to different business scenarios
3. **Non-intrusive**: Based on AOP implementation with zero intrusion on business code
4. **Extensibility**: Support custom validation rules and processing logic

### Core Features

#### Rich Parameter Validation Annotations

Basic-Check-Java provides six commonly used parameter validation annotations:

- `@CheckNull`: Validates that parameter is not null
- `@CheckString`: Validates that string parameter is not blank
- `@CheckLong`: Validates that Long parameter is greater than -1
- `@CheckCollection`: Validates that collection parameter is not empty
- `@CheckMap`: Validates that Map parameter is not empty
- `@CheckObject`: Validates object parameters using Bean Validation

#### Flexible Return Strategies

Through the `returnType` attribute of the `@BasicCheck` annotation, three handling strategies are supported when validation fails:

- `EXCEPTION` (default): Throws IllegalArgumentException
- `EMPTY`: Automatically returns empty values based on method return type (empty collections, empty Map, Optional.empty(), etc.)
- `NULL`: Returns null directly

#### Non-intrusive Implementation Based on Spring AOP

The framework uses AspectJ annotations and Spring AOP technology to perform parameter validation before method execution through aspect-oriented programming, with complete non-intrusion on business code.

## In-depth Technical Architecture Analysis

### Core Architecture Diagram

```
@BasicCheck annotated method
        ↓
NotNullAndPositiveAspect intercepts
        ↓
Iterate through method parameters and their annotations
        ↓
Execute corresponding validation logic based on annotation type
        ↓
Validation fails → Return corresponding result based on returnType
Validation succeeds → Continue executing original method
```

### Key Technical Implementation

#### Annotation Design

Using `@BasicCheck` as an example, demonstrating elegant annotation design:

```java
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface BasicCheck {
    ReturnType returnType() default ReturnType.EXCEPTION;

    enum ReturnType {
        EMPTY,    // Return empty collection/map/optional
        NULL,     // Return null
        EXCEPTION // Throw exception
    }
}
```

Key design points:
- `@Target(ElementType.METHOD)`: Can only be applied at method level
- `@Retention(RetentionPolicy.RUNTIME)`: Retain annotation information at runtime
- Provides enum-type configuration options ensuring type safety

#### AOP Aspect Implementation

`NotNullAndPositiveAspect` is the core component of the framework, handling the main parameter validation logic:

```java
@Around("handleBasicCheckPoint() && @annotation(basicCheck)")
public Object around(ProceedingJoinPoint point, BasicCheck basicCheck) throws Throwable {
    final Object[] args = point.getArgs();
    final MethodSignature signature = (MethodSignature) point.getSignature();
    final Method method = signature.getMethod();
    final Parameter[] parameters = method.getParameters();

    // Iterate through all parameters for validation
    for (int i = 0; i < parameters.length; i++) {
        // Execute corresponding validation logic based on different annotation types
        if (parameters[i].isAnnotationPresent(CheckNull.class) && null == args[i]) {
            return this.getReturnObj(basicCheck, method);
        }
        // ... other validation logic
    }
    return point.proceed();
}
```

Implementation highlights:
1. **Parameter-Annotation Mapping**: Obtain method parameters and corresponding annotation information through reflection
2. **Decoupled Validation Logic**: Each validation type is handled independently, facilitating maintenance and extension
3. **Intelligent Return Handling**: Intelligently generate return values based on method return type and configuration strategy

#### Intelligent Return Value Generation

A clever design of the framework is automatically generating appropriate empty values based on method return type:

```java
private Object getReturnObj(BasicCheck annotation, Method method) {
    if (annotation.returnType() == BasicCheck.ReturnType.EMPTY) {
        Class<?> returnType = method.getReturnType();
        if (returnType == List.class) return Collections.emptyList();
        if (returnType == Set.class) return Collections.emptySet();
        if (returnType == Map.class) return Collections.emptyMap();
        if (returnType == Optional.class) return Optional.empty();
    }
    // ... other processing logic
}
```

This design avoids the complexity of developers manually handling different return types.

## Practical Application Examples

### Basic Usage Examples

#### Simple Parameter Validation

```java
@Service
public class UserService {

    @BasicCheck
    public void createUser(@CheckNull String username,
                          @CheckString String email,
                          @CheckLong Long age) {
        // Business logic, no need for manual parameter validation
        userRepository.save(new User(username, email, age));
    }
}
```

#### Collection Parameter Validation

```java
@BasicCheck
public void batchCreateUsers(@CheckCollection List<User> users,
                            @CheckMap Map<String, Object> config) {
    // Ensure both users collection and config map are not empty
    users.forEach(user -> userRepository.save(user));
}
```

#### Empty Return Strategy

```java
@BasicCheck(returnType = BasicCheck.ReturnType.EMPTY)
public List<User> searchUsers(@CheckString String keyword) {
    // If keyword is blank string, automatically return empty List
    return userRepository.findByKeyword(keyword);
}
```

### Advanced Application Scenarios

#### Complex Object Validation

```java
// Define validation DTO
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

// Use @CheckObject to validate complex objects
@BasicCheck
public void createUserWithDetails(@CheckObject UserCreateRequest request) {
    // Framework automatically uses Bean Validation to validate entire object tree
    userService.createUser(request);
}
```

#### Mixed Validation Strategies

```java
@BasicCheck(returnType = BasicCheck.ReturnType.NULL)
public void processOrder(@CheckLong Long orderId,
                        @CheckString String customerId,
                        @CheckCollection List<OrderItem> items,
                        @CheckObject OrderConfig config) {
    // Return null if any parameter validation fails, suitable for void methods
    orderProcessor.process(orderId, customerId, items, config);
}
```

## Performance Considerations and Best Practices

### Performance Analysis

1. **Reflection Overhead**: Framework uses reflection to obtain method parameter information, performance testing recommended for high-concurrency scenarios
2. **AOP Overhead**: Spring AOP is based on proxy pattern with slight performance overhead
3. **Bean Validation**: Object validation has certain performance cost but is generally acceptable

### Best Practices

#### Reasonable Validation Strategy Selection

```java
// Recommended: Query methods use EMPTY strategy
@BasicCheck(returnType = BasicCheck.ReturnType.EMPTY)
public List<User> findUsers(@CheckString String keyword) {
    return userRepository.findByKeyword(keyword);
}

// Recommended: Create/update methods use EXCEPTION strategy
@BasicCheck
public void updateUser(@CheckLong Long id, @CheckObject UserUpdateRequest request) {
    userRepository.update(id, request);
}
```

#### Combined Use of Validation Annotations

```java
// Combine multiple validation annotations
@BasicCheck
public void processUserData(@CheckNull @CheckString String username,
                           @CheckNull @CheckLong Long userId,
                           @CheckNull @CheckObject UserData data) {
    // Check both null and business rules
}
```

#### Custom Validation Object Design

```java
@Data
public class ProductRequest {
    @NotNull(message = "Product ID cannot be null")
    @Min(value = 1, message = "Product ID must be greater than 0")
    private Long productId;

    @NotBlank(message = "Product name cannot be blank")
    @Size(max = 100, message = "Product name length cannot exceed 100")
    private String productName;

    @Valid // Enable nested validation
    @NotNull(message = "Product configuration cannot be null")
    private ProductConfig config;
}
```

## Java 8 vs Java 17 Version Differences

### Core Difference: Validation API Namespace Change

This is the most important difference between the two versions:

**Java 8 version** uses traditional `javax` namespace:
```java
import javax.validation.Validation;
import javax.validation.Validator;
```

**Java 17 version** uses new `jakarta` namespace:
```java
import jakarta.validation.Validation;
import jakarta.validation.Validator;
```

### Complete Dependency Comparison

**Java 8 Version Dependencies**:
- Spring Boot 2.4.4
- Lombok 1.18.18
- `javax.validation:validation-api:2.0.1.Final`
- `org.hibernate:hibernate-validator:6.0.1.Final`
- `org.glassfish:javax.el:3.0.1-b09`

**Java 17 Version Dependencies**:
- Spring Boot 3.5.5
- Lombok 1.18.38
- `org.hibernate.validator:hibernate-validator:8.0.1.Final`
- `org.glassfish:jakarta.el:4.0.2`

## Extension and Customization

### Custom Validation Annotations

The framework adopts an open design, supporting addition of custom validation annotations:

```java
// 1. Define custom validation annotation
@Target(ElementType.PARAMETER)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface CheckEmail {
}

// 2. Add validation logic in NotNullAndPositiveAspect
if (parameters[i].isAnnotationPresent(CheckEmail.class) &&
    !isValidEmail((String) args[i])) {
    return this.getReturnObj(basicCheck, method);
}
```

### Custom Return Strategies

ReturnType enum can be extended to add more return strategies:

```java
public enum ReturnType {
    EMPTY,
    NULL,
    EXCEPTION,
    CUSTOM_DEFAULT // Custom default value strategy
}
```

## Conclusion

Basic-Check-Java is an elegantly designed and practically useful parameter validation framework. It solves the pain points of parameter validation in Java development through the following characteristics:

### Core Advantages

1. **High Development Efficiency**: Reduces 80% of parameter validation boilerplate code
2. **Simple to Use**: Only need to add annotations to enjoy complete validation functionality
3. **Comprehensive Features**: Supports multi-level validation of basic types, collections, and complex objects
4. **Flexible Configuration**: Multiple return strategies adapt to different business scenarios
5. **Non-intrusive**: Based on AOP implementation with zero impact on existing code

### Applicable Scenarios

- **Web Applications**: Controller layer parameter validation
- **Service Layer**: Service method parameter validation
- **Utility Classes**: Parameter checking for general utility methods
- **API Interfaces**: Parameter pre-checking before third-party interface calls

Basic-Check-Java embodies excellent framework design principles: simple to use, feature-complete, reliable performance, and easy to extend. It not only significantly improves development efficiency but also helps developers write more robust and elegant code.

Whether for new projects or existing projects, Basic-Check-Java can be quickly integrated and deliver value, making it an indispensable tool in the Java developer's toolkit.
