+++
date = '2025-10-02T10:23:17+08:00'
draft = false
title = '[Spring] 2. 浅谈Spring异步接口中的自定义线程池与线程复用分析'
categories = ["Java", "Spring"]
tags = ["Java", "Spring", "web", "Thread", "Efficiency"]
+++

## 前言

在Spring应用中处理高并发场景时,合理使用异步编程和线程池管理至关重要。本文将通过实际代码示例,深入分析Spring的默认线程池、自定义线程池以及线程复用的机制。

## 为什么要使用自定义线程池?

Spring Boot应用启动时会自动配置一个全局的任务执行器(TaskExecutor),默认名称为`applicationTaskExecutor`。然而,在生产环境中**不推荐直接使用Spring的默认线程池**,主要原因如下:

1. **缺乏隔离性**: 所有异步任务共享同一个线程池,不同业务模块的任务会相互影响
2. **难以监控**: 无法针对特定业务场景进行细粒度的线程池监控和调优
3. **配置单一**: 默认配置可能无法满足所有业务场景的性能需求

**最佳实践**: 根据业务场景自定义线程池,实现任务隔离和精细化管理。

## 自定义线程池配置

以下是一个典型的自定义线程池配置示例:

```java
private static final AtomicInteger COUNT = new AtomicInteger(0);
private static final Executor EXECUTOR = new ThreadPoolExecutor(
        10,                              // 核心线程数
        10,                              // 最大线程数
        10,                              // 空闲线程存活时间
        TimeUnit.SECONDS,
        new ArrayBlockingQueue<>(10),    // 工作队列容量
        r -> new Thread(r, String.format("customer-t-%s", COUNT.addAndGet(1)))  // 自定义线程命名
);
```

### 配置解析:

- **核心线程数 = 最大线程数 = 10**: 固定大小线程池,避免频繁创建销毁线程
- **队列容量 = 10**: 当10个线程都在工作时,最多再排队10个任务
- **自定义线程名**: `customer-t-{序号}`,便于日志追踪和问题定位

## 异步接口 vs 同步接口对比

### 异步接口实现 (asyncQuery1)

```java

@GetMapping("async/query1")
public CompletionStage<String> asyncQuery1() {
   log.info("async query start");                    // Tomcat线程执行
   return CompletableFuture.supplyAsync(() -> {
      log.info("async query sleep start");          // customer-t线程执行
      ThreadUtils.sleep(10000);                     // 模拟耗时操作
      log.info("async query sleep done");
      return "done";
   }, EXECUTOR);
}
```

![1. async display.svg](/images/14.%20Spring%20Async%20ThreadPool%20and%20Thread%20Reuse/1.%20async%20display.svg)

**特点**:

- **非阻塞**: Tomcat线程立即释放,可以处理其他请求
- **高吞吐**: 适合I/O密集型任务
- **线程切换**: 请求在Tomcat线程和自定义线程池之间切换

### 同步接口实现 (syncQuery1)

```java

@GetMapping("sync/query1")
public String syncQuery1() throws InterruptedException {
    log.info("sync query start");                     // Tomcat线程执行
    final CountDownLatch latch = new CountDownLatch(1);
    EXECUTOR.execute(() -> {
        log.info("sync query sleep start");           // customer-t线程执行
        ThreadUtils.sleep(1000);
        latch.countDown();
    });
    latch.await();                                    // Tomcat线程阻塞等待
    log.info("sync query done");                      // Tomcat线程执行
    return "done";
}
```

![2. sync display.svg](/images/14.%20Spring%20Async%20ThreadPool%20and%20Thread%20Reuse/2.%20sync%20display.svg)

**特点**:

- **阻塞等待**: Tomcat线程被`CountDownLatch`阻塞,不能处理其他请求
- **资源浪费**: 同时占用Tomcat线程和Worker线程,两个线程干了一个线程的活
- **本质是同步**: 虽然用了自定义线程池,但Tomcat线程一直等待,**完全没有发挥异步优势**
- **适用场景**: 几乎没有!不如直接在Tomcat线程执行,还能省一个Worker线程

## 线程复用的实战表现

通过压测工具发送20个并发请求,观察异步和同步接口的线程行为差异。

### 异步接口并发测试

发送20个并发请求到`/goody/async/query1`(每个任务耗时10秒):

```log
// ============ 阶段1: 前10个请求立即被Tomcat线程接收并提交 ============
09:53:20.896  INFO [io-50012-exec-1] async query start         ← Tomcat线程快速释放
09:53:20.899  INFO [customer-t-1]    async query sleep start   ← Worker线程1开始执行
09:53:21.026  INFO [io-50012-exec-1] async query start         ← Tomcat线程又接收新请求
09:53:21.026  INFO [customer-t-2]    async query sleep start   ← Worker线程2开始执行
09:53:21.186  INFO [io-50012-exec-1] async query start
09:53:21.187  INFO [customer-t-3]    async query sleep start
...
09:53:22.261  INFO [io-50012-exec-1] async query start
09:53:22.261  INFO [customer-t-10]   async query sleep start   ← 10个线程全部占满

// ============ 阶段2: 第11-20个请求进入队列等待 ============
09:53:22.411  INFO [io-50012-exec-1] async query start         ← 第11个请求,进入队列
09:53:22.597  INFO [io-50012-exec-1] async query start         ← 第12个请求,进入队列
09:53:22.732  INFO [io-50012-exec-1] async query start         ← ...持续到第20个
...
09:53:24.048  INFO [io-50012-exec-1] async query start         ← 第20个请求,队列满

// ============ 阶段3: 第21个请求触发拒绝策略 ============
09:53:24.065 ERROR [io-50012-exec-1] RejectedExecutionException:
    ThreadPoolExecutor@79a3d00d[Running, pool size = 10, active threads = 10, queued tasks = 10]
    ↑ 线程池状态: 10个线程全忙 + 10个任务排队 = 容量已满

// ============ 阶段4: 线程复用开始 - 关键现象! ============
09:53:30.313  INFO [customer-t-1]    async query sleep done    ← 线程1完成第1个任务
09:53:30.313  INFO [customer-t-1]    async query done
09:53:30.314  INFO [customer-t-1]    async query sleep start   ← 线程1立即执行第11个任务(复用!)

09:53:31.041  INFO [customer-t-2]    async query sleep done    ← 线程2完成第2个任务
09:53:31.041  INFO [customer-t-2]    async query sleep start   ← 线程2立即执行第12个任务(复用!)

09:53:31.197  INFO [customer-t-3]    async query sleep done
09:53:31.197  INFO [customer-t-3]    async query sleep start   ← 线程3复用

// ... 所有10个线程依次复用,处理队列中的第11-20个任务

// ============ 阶段5: 第二轮任务全部完成 ============
09:53:40.320  INFO [customer-t-1]    async query sleep done    ← 线程1完成第11个任务
09:53:41.048  INFO [customer-t-2]    async query sleep done    ← 线程2完成第12个任务
...
```

**核心观察点**:

1. **并发能力强**: Tomcat线程(io-50012-exec-1)在2秒内接收了20个请求,平均100ms处理一个
2. **线程固定**: 始终只有`customer-t-1`到`customer-t-10`这10个Worker线程
3. **线程复用**: `customer-t-1`在09:53:30完成第1个任务后,立即执行第11个任务(间隔仅1ms)
4. **拒绝策略**: 超过容量(10线程+10队列)时,第21个请求被拒绝

### 同步接口串行执行

发送20个并发请求到`/goody/sync/query1`(每个任务耗时1秒):

```log
// ============ 串行处理: Tomcat线程被阻塞 ============
09:54:02.401  INFO [io-50012-exec-1] sync query start          ← Tomcat线程处理第1个请求
09:54:02.401  INFO [customer-t-1]    sync query sleep start    ← Worker线程执行
09:54:03.407  INFO [customer-t-1]    sync query sleep done     ← 1秒后完成
09:54:03.407  INFO [io-50012-exec-1] sync query done           ← Tomcat线程才返回

09:54:03.409  INFO [io-50012-exec-1] sync query start          ← 处理第2个请求
09:54:03.409  INFO [customer-t-2]    sync query sleep start
09:54:04.416  INFO [customer-t-2]    sync query sleep done
09:54:04.416  INFO [io-50012-exec-1] sync query done

09:54:04.418  INFO [io-50012-exec-1] sync query start          ← 处理第3个请求
09:54:04.418  INFO [customer-t-3]    sync query sleep start
...

// ============ 线程复用也存在 ============
09:54:12.490  INFO [io-50012-exec-1] sync query start          ← 第11个请求
09:54:12.490  INFO [customer-t-1]    sync query sleep start    ← 线程1被复用
09:54:13.500  INFO [customer-t-1]    sync query sleep done
09:54:13.500  INFO [io-50012-exec-1] sync query done
```

**对比分析**:

| 维度             | 异步接口                          | 同步接口                           |
|----------------|-------------------------------|---------------------------------|
| **Tomcat线程**   | 快速释放,2秒接收20个请求                | 被阻塞,20秒才处理完20个请求               |
| **并发能力**       | 可同时处理20个(10线程+10队列)           | 只能串行处理,1个接1个                   |
| **Worker线程复用** | ✅ 存在(customer-t-1处理第1和第11个任务) | ✅ 存在(customer-t-1处理第1和第11个任务)  |
| **总耗时**        | ~20秒(10秒×2轮)                  | ~20秒(1秒×20个)                   |
| **线程利用率**      | 高(Tomcat空闲,Worker忙)           | 低(Tomcat+Worker同时占用,干一份活)      |
| **系统吞吐**       | 高(Tomcat线程可处理其他请求)            | 低(Tomcat线程被占用)                 |
| **异步本质**       | ✅ 真正异步,释放主线程                 | ❌ 假异步,本质是同步等待(两线程干一份活,还更慢) |

**关键结论**:

同步接口虽然也展示了Worker线程复用,但**本质上没有利用异步优势**。它反而带来了额外开销:
- Tomcat线程阻塞 → 无法处理其他请求
- Worker线程执行 → 占用线程池资源
- **两个线程配合完成一个任务,不如直接在Tomcat线程执行,还能省掉线程切换开销**

这种写法在生产环境中是**反模式**,仅用于对比演示异步的优势。

## 线程复用的核心机制

### 生产者-消费者模型

Java线程池的线程复用基于**生产者-消费者模型**:

1. **工作线程循环**: 线程池中的Worker线程不断从`BlockingQueue`中获取任务
2. **任务队列**: 新任务提交到队列,空闲线程立即取出执行
3. **复用优势**: 避免频繁创建销毁线程的开销(上下文切换、内存分配)

### 与IO多路复用的相似之处

**核心**: 异步线程池本质上是**应用层的"多路复用"思想**,虽然实现机制不同,但解决问题的思路与IO多路复用高度相似。

#### 相似之处

1. **核心思想: 用少量资源处理大量请求**
   - **IO多路复用**: 1个线程通过epoll/select监听N个socket连接
   - **异步线程池**: 少量Tomcat线程处理N个并发请求(通过快速释放)

2. **非阻塞模式**
   - **IO多路复用**: 主线程不阻塞在单个IO操作上,轮询等待多个IO事件就绪
   - **异步线程池**: Tomcat线程不阻塞在耗时任务上,立即返回处理下个请求

3. **事件通知机制**
   - **IO多路复用**: epoll通知哪个socket可读/可写
   - **异步线程池**: CompletableFuture通知任务完成

#### 本质区别

| 维度       | IO多路复用              | 异步线程池                 |
|----------|---------------------|-----------------------|
| **复用对象** | 复用线程(单线程处理多IO)      | 复用Tomcat线程(快速释放)      |
| **适用场景** | 网络IO密集型             | CPU/IO混合型             |
| **实现层次** | 操作系统层(epoll/select) | 应用层(线程池调度)            |
| **典型应用** | Netty, Redis, Nginx | Spring WebFlux, 传统Web |
| **设计模式** | Reactor模式           | 生产者-消费者模式             |

#### 类比理解

```
IO多路复用:
┌─────────────┐
│ Event Loop  │ ──监听──> [Socket1, Socket2, ..., SocketN]
│  (1 thread) │           哪个就绪处理哪个
└─────────────┘

异步线程池:
┌─────────────┐
│ Tomcat线程池│ ──快速释放──> [Request1, Request2, ..., RequestN]
│  (200线程)  │               交给Worker池异步处理
└─────────────┘
```

**结论**: 虽然底层机制不同,但都在解决"如何用有限资源应对高并发"的核心问题。异步线程池可以理解为**应用层实现的多路复用思想
**。

## 总结

本文通过对比异步和同步两种接口实现,揭示了自定义线程池的重要性和线程复用的机制。关键要点:

- ✅ 自定义线程池实现业务隔离和精细化管理
- ✅ 异步接口提升系统吞吐量,释放Tomcat线程
- ✅ 线程复用避免频繁创建销毁线程的开销
- ✅ 合理配置线程池参数,避免资源浪费或任务拒绝
- ✅ 通过日志中的线程名可以清晰观察到线程复用过程

在实际生产环境中,还需要结合监控指标(线程池活跃度、队列长度、拒绝次数等)持续优化线程池配置。
