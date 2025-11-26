+++
date = '2025-09-21T23:36:17+08:00'
draft = false
title = '[Java] 2. Unit Test 基本用法'
categories = ["Java"]
tags = ["Java", "Unit Test"]
+++

# [Java] 2. Unit Test 基本用法

## Mocikto基本用法

在单元测试里,很多测试(除Util类)都需要mock掉一些服务来保证只测试当前想测的内容.

具体使用时,需要先mock一个对象,然后再mock此对象的方法,然后就可以使用mock的方法去测想测的逻辑了.

### Mock对象

首先,需要在Test类里声明需要mock的接口/实现类. 如

```java
@MockBean
private IOssService ossService;
```

有时候,也需要直接手动mock一个东西出来,比如,当需要mock掉redis的操作时,可以

```java
RSet<Long> redisSet = Mockito.mock(RSet.class);
```

注意此操作不要去mock基本类型,如int,long等.

还有一种方式是使用`@SpyBean`. 此处先略过,后面的部分会介绍.

### Mock方法

假定有一个接口

```java
public interface IUserService {

    Long add(UserDTO dto);

    void remove(Long userId);

    Optional<UserDTO> find(String username);

    Optional<UserDTO> find(Long userId);
}
```

在已经mock掉userService的情况下

```java
@MockBean
private IUserService userService;
```

我们可以mock掉add这个方法,使得任意参数传过来都直接返回100.

```java
Mockito.doReturn(100L).when(userService).add(any());
```
也可以这样

```java
Mockito.when(userService.add(any())).thenReturn(100L);
```

但是, **对同一service, 这两种方式不要混用, 否则有时会出现第二种mock无效的情况.**

当你发现mock的方法无效,或者有些莫名其妙的错误时,请统一使用一种mock的方式. 如果还不行,请切换到另一种方式.

当你需要mock掉void的方法时,可以

```java
Mockito.doNothing().when(userService).remove(anyLong());
```

如果你需要模拟出错的情况,可以

```java
Mockito.doThrow(...).when(userService).remove(anyLong());
```

当你需要对一些特殊数据mock,如userId = 1,有用户, userId = 2, 没有用户,你可以这样mock:

```java
Mockito.doReturn(Optional.of(UserDTO.builder().build())).when(userService).find(1L);
Mockito.doReturn(Optional.empty()).when(userService).find(2L);
```

mock还有更泛用的方式,如果你想要在userId < 10的时候返回数据,其他情况不返回:

```java
Mockito.doAnswer(invocation -> {
    Long userId = (Long) invocation.getArguments()[0];
    if (userId < 10L) {
        return UserDTO.builder().id(userId).build();
    }
    return null;
}).when(userService).find(anyLong());
```
或者

```java
Mockito.when(userService.find(anyLong())).thenAnswer(invocation -> {
    Long userId = (Long) invocation.getArguments()[0];
    if (userId < 10L) {
        return UserDTO.builder().build();
    }
    return null;
});
```

需要注意的是,doAnswer也可以mock掉void返回值,假如我现在要mock掉redis的操作:

```java
// mock redis的get和set操作.
RAtomicLong mockValue = Mockito.mock(RAtomicLong.class);
doAnswer(invocation -> {
    Long newValue = (Long) (invocation.getArguments()[0]);
    doReturn(true).when(mockValue).isExists();
    doReturn(newValue).when(mockValue).get();
    return null;
}).when(mockValue).set(anyLong());
```
这个例子里,在调用redis的set时,我们把get也给mock掉了,而且返回的是他刚刚set的值. 这样就可以模拟redis的操作.


当你mock一些有重载的方法时,会有出错的情况,比如

```java
Mockito.when(userService.find(any())).thenReturn(Optional.empty());
```
此时的find(any())可以把两个方法都匹配上, 这个时候就会有问题. 解决方法就是

```java
Mockito.when(userService.find(anyLong())).thenReturn(Optional.empty());
Mockito.when(userService.find(anyString())).thenReturn(Optional.empty());
```

在使用any()时一定要注意
- 不要用any()去代表long,int这种值,否则会有NPE.
- 可具体用any(class)去对应具体的输入,如any(LocalDateTime.class)即可代表任意LocalDateTime的参数.

在使用mock时,你还可以`doCallRealMethod()`或者`thenCallRealMethod()`调用原来的实现,但我个人并不推荐这么搞,一般情况都会有各种各样的问题. 具体解决方案会在后面写.


### 测试结果

一般在你mock了所有调用的方法,然后使用assert工具验证了输出时,程序基本就是按照预想的方式在跑了.

```java
public interface IUserBizService {
    UserDTO reg(UserDTO dto);
}
```
比如你正在测试这个reg方法,Mockito工具可以验证是否真的调用了一次`userService.add()`方法:

```java
Mockito.verify(userService, times(1)).add(any());
```

然而有些时候,你还需要检查一些其他的东西,比如你mock掉的方法的调用参数. 这个时候就需要用到Mockito的工具了

```java
ArgumentCaptor<UserDTO> captor = ArgumentCaptor.forClass(UserDTO.class);
Mockito.verify(userService, times(1)).add(captor.capture());
List<UserDTO> users = captor.getAllValues();
// 此处即可验证users的内容
assertEquals(......);
```
还有一种简单写法

```java
Mockito.verify(userService, times(1)).add((UserDTO) argThat(u -> {
    assertEquals(userId, t.getId());
    ...
    return true;
}));
```

### SpyBean示例

在上面的例子里,都是使用的MockBean,这种mock的方式用处最广. 但有些时候,测试需要深入到实现类里,修改一些逻辑,然后再测,这时候就需要用到SpyBean了.

MockBean相当于你完完全全的mock了一个类,这个类里所有的方法都是你mock的,都没办法直接调用,必须先mock
SpyBean相当于你拿了个真的实现出来,然后你可以只mock其中的一部分方法.

举个例子,比如在IUserService的实现里,有这样一段

```java
public class UserServiceImpl implements IUserService {
    @Override
    public void remove(Long userId) {
        Optional<UserDTO> dto = this.find(userId); // 注意这一行
        if (!dto.isPresent()) {
            throw new Error(404);
        }
        ...
    }
}
```
此时remove方法调用了find方法,如果你想测试这个remove方法, mock掉整个实现类显然是不可行的, 而如果你不mock, 这个find的方法返回值就不可控.
如果你直接往数据库里放数据,那又不是完全意义上的单元测试,因为你使用了外部的服务.

此时就该使用SpyBean了. 你可以只mock掉find,然后直接调用remove,就可以执行测试.

```java
@SpyBean
private IUserService userService;
```

同样的,还有一些不是很好测试的逻辑,如

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
你需要测试这个while循环在按照你的思路运行,但这个sleep方法会真的sleep,这会让整个测试变得巨麻烦. 这时候用SpyBean就很好解决.

```java
doNothing().when(xxxService).sleep();
xxxService.doJob();
verify(xxxService, times(1)).sleep();
verify(xxxService, times(1)).doWork();
```

同理,当你需要测试一些和时间相关的操作,这部分逻辑很关键,但和当前时间紧密相关, 这时候也需要用SpyBean.

```java
public void doJob() {
    LocalDateTime now = getNow();
    ...
}

public LocalDateTime getNow() {
    return DateUtil.now();
}
```
mock操作:

```java
doReturn(LocalDateTime.of(2021, 10, 1)).when(xxxService).getNow();
xxxService.doJob();
```

## 测试用例规范

### 测试用例命名规则

待测试方法startTask，则可能存在以下测试用例

- startTask_noPerm
- startTask_banned
- startTask_succeed
- startTask_limited
- ...

[javaguide.html#s5.2.3-method-names](https://google.github.io/styleguide/javaguide.html#s5.2.3-method-names)

### 测试用例注释规则

- 1 测试场景说明
- 2 预期结果，实际结果

### 测试范围规则

- 使用Mockito隔离测试边界
- 使用Postman做集成测试
- 控制层也要有测试用例

### 代码覆盖率

- 最大化代码覆盖率

### 测试用例规范

- 构建测试数据
- 使用测试数据构建mock方法
- 执行方法
- 验证mock结果

**要点**
1. 单测用例要体现`单元`的概念，在构建测试数据时应注重`构建数据`之间足够单元和隔离
2. 简而言之，单测代码也需要足够优雅，可扩展性高，后续发生业务修改时才会更好地进行测试的扩展

