+++
date = '2025-09-21T23:36:17+08:00'
draft = false
title = '[Java] 2. Unit Test Basic Usage'
categories = ["Java"]
tags = ["Java", "Unit Test"]
+++

# [Java] 2. Unit Test Basic Usage

## Mockito Basic Usage

In unit testing, many tests (except Util classes) need to mock some services to ensure only the current logic being tested is actually tested.

Specifically, you need to first mock an object, then mock the methods of this object, and then you can use the mocked methods to test the logic you want to test.

### Mock Objects

First, you need to declare the interfaces/implementation classes that need to be mocked in the Test class. For example:

```java
@MockBean
private IOssService ossService;
```

Sometimes, you also need to manually mock something directly, for example, when you need to mock Redis operations, you can:

```java
RSet<Long> redisSet = Mockito.mock(RSet.class);
```

Note: Don't mock primitive types like int, long, etc.

There's another way using `@SpyBean`. This will be skipped for now and introduced in later sections.

### Mock Methods

Assume there's an interface:

```java
public interface IUserService {

    Long add(UserDTO dto);

    void remove(Long userId);

    Optional<UserDTO> find(String username);

    Optional<UserDTO> find(Long userId);
}
```

With userService already mocked:

```java
@MockBean
private IUserService userService;
```

We can mock the add method so that any parameter passed will directly return 100.

```java
Mockito.doReturn(100L).when(userService).add(any());
```
You can also do it this way:

```java
Mockito.when(userService.add(any())).thenReturn(100L);
```

However, **for the same service, don't mix these two approaches, otherwise sometimes the second mock may become ineffective.**

When you find that your mocked methods are ineffective, or you encounter some mysterious errors, please use one mocking approach consistently. If it still doesn't work, try switching to the other approach.

When you need to mock a void method, you can:

```java
Mockito.doNothing().when(userService).remove(anyLong());
```

If you need to simulate error conditions, you can:

```java
Mockito.doThrow(...).when(userService).remove(anyLong());
```

When you need to mock specific data, like userId = 1 has a user, userId = 2 has no user, you can mock like this:

```java
Mockito.doReturn(Optional.of(UserDTO.builder().build())).when(userService).find(1L);
Mockito.doReturn(Optional.empty()).when(userService).find(2L);
```

Mock has more general approaches. If you want to return data when userId < 10, and not return data in other cases:

```java
Mockito.doAnswer(invocation -> {
    Long userId = (Long) invocation.getArguments()[0];
    if (userId < 10L) {
        return UserDTO.builder().id(userId).build();
    }
    return null;
}).when(userService).find(anyLong());
```
Or:

```java
Mockito.when(userService.find(anyLong())).thenAnswer(invocation -> {
    Long userId = (Long) invocation.getArguments()[0];
    if (userId < 10L) {
        return UserDTO.builder().build();
    }
    return null;
});
```

Note that doAnswer can also mock void return values. Suppose I now want to mock Redis operations:

```java
// Mock Redis get and set operations.
RAtomicLong mockValue = Mockito.mock(RAtomicLong.class);
doAnswer(invocation -> {
    Long newValue = (Long) (invocation.getArguments()[0]);
    doReturn(true).when(mockValue).isExists();
    doReturn(newValue).when(mockValue).get();
    return null;
}).when(mockValue).set(anyLong());
```
In this example, when calling Redis set, we also mock get to return the value that was just set. This simulates Redis operations.

When you mock overloaded methods, you may encounter errors, for example:

```java
Mockito.when(userService.find(any())).thenReturn(Optional.empty());
```
At this point, find(any()) can match both methods, which will cause problems. The solution is:

```java
Mockito.when(userService.find(anyLong())).thenReturn(Optional.empty());
Mockito.when(userService.find(anyString())).thenReturn(Optional.empty());
```

When using any(), be careful:
- Don't use any() to represent long, int values, otherwise you'll get NPE.
- You can specifically use any(class) for specific inputs, like any(LocalDateTime.class) can represent any LocalDateTime parameter.

When using mock, you can also use `doCallRealMethod()` or `thenCallRealMethod()` to call the original implementation, but I personally don't recommend this approach as it generally causes various problems. Specific solutions will be covered later.

### Testing Results

Generally, after you've mocked all called methods and used assert tools to verify the output, the program is basically running as expected.

```java
public interface IUserBizService {
    UserDTO reg(UserDTO dto);
}
```
For example, if you're testing this reg method, Mockito tools can verify whether `userService.add()` method was actually called once:

```java
Mockito.verify(userService, times(1)).add(any());
```

However, sometimes you need to check other things, like the call parameters of your mocked methods. This is when you need Mockito tools:

```java
ArgumentCaptor<UserDTO> captor = ArgumentCaptor.forClass(UserDTO.class);
Mockito.verify(userService, times(1)).add(captor.capture());
List<UserDTO> users = captor.getAllValues();
// Here you can verify the content of users
assertEquals(......);
```
There's also a simpler approach:

```java
Mockito.verify(userService, times(1)).add((UserDTO) argThat(u -> {
    assertEquals(userId, t.getId());
    ...
    return true;
}));
```

### SpyBean Example

In the above examples, we used MockBean, which is the most widely used mocking approach. But sometimes, tests need to go deep into implementation classes, modify some logic, and then test. This is when SpyBean is needed.

MockBean is equivalent to completely mocking a class, where all methods in this class are mocked and cannot be called directly without first mocking them.
SpyBean is equivalent to taking a real implementation and then only mocking part of its methods.

For example, suppose in the IUserService implementation, there's this code:

```java
public class UserServiceImpl implements IUserService {
    @Override
    public void remove(Long userId) {
        Optional<UserDTO> dto = this.find(userId); // Note this line
        if (!dto.isPresent()) {
            throw new Error(404);
        }
        ...
    }
}
```
At this point, the remove method calls the find method. If you want to test this remove method, mocking the entire implementation class is obviously not feasible. If you don't mock, the return value of this find method is uncontrollable.
If you directly put data in the database, that's not a complete unit test because you're using external services.

This is when SpyBean should be used. You can mock only the find method, then directly call remove to execute the test.

```java
@SpyBean
private IUserService userService;
```

Similarly, there are some logic that's not easy to test, like:

```java
public void doJob() {
    while(true) {
        if (xxx) {
            break;
        }
        doWork();
        sleep();
    }
}

public void sleep() {
    try {
        Thread.sleep(2000);
    } catch (...) { ... }
}
```
You need to test that this while loop runs according to your logic, but this sleep method will actually sleep, making the entire test extremely troublesome. Using SpyBean solves this well.

```java
doNothing().when(xxxService).sleep();
xxxService.doJob();
verify(xxxService, times(1)).sleep();
verify(xxxService, times(1)).doWork();
```

Similarly, when you need to test some time-related operations, this logic is critical but closely related to current time, SpyBean is also needed.

```java
public void doJob() {
    LocalDateTime now = getNow();
    ...
}

public LocalDateTime getNow() {
    return DateUtil.now();
}
```
Mock operation:

```java
doReturn(LocalDateTime.of(2021, 10, 1)).when(xxxService).getNow();
xxxService.doJob();
```

## Test Case Specifications

### Test Case Naming Rules

For method startTask under test, there might be the following test cases:

- startTask_noPerm
- startTask_banned
- startTask_succeed
- startTask_limited
- ...

[javaguide.html#s5.2.3-method-names](https://google.github.io/styleguide/javaguide.html#s5.2.3-method-names)

### Test Case Comment Rules

- 1 Test scenario description
- 2 Expected results, actual results

### Test Scope Rules

- Use Mockito to isolate test boundaries
- Use Postman for integration testing
- Controller layer should also have test cases

### Code Coverage

- Maximize code coverage

### Test Case Specifications

- Build test data
- Use test data to build mock methods
- Execute methods
- Verify mock results

**Key Points**
1. Unit test cases should embody the concept of `unit`. When building test data, attention should be paid to sufficient unit isolation between `build data`
2. Simply put, unit test code also needs to be elegant enough with high extensibility, so that when business modifications occur later, testing can be better extended