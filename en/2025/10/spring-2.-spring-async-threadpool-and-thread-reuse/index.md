# [Spring] 2. Analysis of Custom Thread Pools and Thread Reuse in Spring Async Interfaces


## Preface

When handling high-concurrency scenarios in Spring applications, proper use of asynchronous programming and thread pool management is crucial. This article provides an in-depth analysis of Spring's default thread pool, custom thread pools, and thread reuse mechanisms through practical code examples.

## Why Use Custom Thread Pools?

When a Spring Boot application starts, it automatically configures a global task executor (TaskExecutor) with the default name `applicationTaskExecutor`. However, **using Spring's default thread pool directly in production environments is not recommended** for the following reasons:

1. **Lack of Isolation**: All asynchronous tasks share the same thread pool, causing tasks from different business modules to interfere with each other
2. **Difficult to Monitor**: Unable to perform fine-grained thread pool monitoring and tuning for specific business scenarios
3. **Single Configuration**: Default configuration may not meet the performance needs of all business scenarios

**Best Practice**: Customize thread pools based on business scenarios to achieve task isolation and fine-grained management.

## Custom Thread Pool Configuration

Here's a typical custom thread pool configuration example:

```java
private static final AtomicInteger COUNT = new AtomicInteger(0);
private static final Executor EXECUTOR = new ThreadPoolExecutor(
        10,                              // Core pool size
        10,                              // Maximum pool size
        10,                              // Keep-alive time for idle threads
        TimeUnit.SECONDS,
        new ArrayBlockingQueue<>(10),    // Work queue capacity
        r -> new Thread(r, String.format("customer-t-%s", COUNT.addAndGet(1)))  // Custom thread naming
);
```

### Configuration Breakdown:

- **Core Pool Size = Maximum Pool Size = 10**: Fixed-size thread pool, avoids frequent thread creation and destruction
- **Queue Capacity = 10**: When all 10 threads are working, up to 10 more tasks can be queued
- **Custom Thread Naming**: `customer-t-{number}`, convenient for log tracking and problem diagnosis

## Async Interface vs Sync Interface Comparison

### Async Interface Implementation (asyncQuery1)

```java

@GetMapping("async/query1")
public CompletionStage<String> asyncQuery1() {
   log.info("async query start");                    // Executed by Tomcat thread
   return CompletableFuture.supplyAsync(() -> {
      log.info("async query sleep start");          // Executed by customer-t thread
      ThreadUtils.sleep(10000);                     // Simulate time-consuming operation
      log.info("async query sleep done");
      return "done";
   }, EXECUTOR);
}
```

![1. async display.svg](/images/14.%20Spring%20Async%20ThreadPool%20and%20Thread%20Reuse/1.%20async%20display.svg)

**Characteristics**:

- **Non-blocking**: Tomcat thread is immediately released and can handle other requests
- **High Throughput**: Suitable for I/O-intensive tasks
- **Thread Switching**: Request switches between Tomcat thread and custom thread pool

### Sync Interface Implementation (syncQuery1)

```java

@GetMapping("sync/query1")
public String syncQuery1() throws InterruptedException {
    log.info("sync query start");                     // Executed by Tomcat thread
    final CountDownLatch latch = new CountDownLatch(1);
    EXECUTOR.execute(() -> {
        log.info("sync query sleep start");           // Executed by customer-t thread
        ThreadUtils.sleep(1000);
        latch.countDown();
    });
    latch.await();                                    // Tomcat thread blocks and waits
    log.info("sync query done");                      // Executed by Tomcat thread
    return "done";
}
```

![2. sync display.svg](/images/14.%20Spring%20Async%20ThreadPool%20and%20Thread%20Reuse/2.%20sync%20display.svg)

**Characteristics**:

- **Blocking Wait**: Tomcat thread is blocked by `CountDownLatch`, cannot handle other requests
- **Resource Waste**: Occupies both Tomcat thread and Worker thread, two threads doing the work of one
- **Essentially Synchronous**: Despite using a custom thread pool, the Tomcat thread waits continuously, **completely failing to leverage async advantages**
- **Use Cases**: Almost none! Better to execute directly in Tomcat thread, which also saves a Worker thread

## Thread Reuse in Practice

Sending 20 concurrent requests via load testing tool to observe thread behavior differences between async and sync interfaces.

### Async Interface Concurrency Test

Sending 20 concurrent requests to `/goody/async/query1` (each task takes 10 seconds):

```log
// ============ Phase 1: First 10 requests immediately received by Tomcat thread and submitted ============
09:53:20.896  INFO [io-50012-exec-1] async query start         ← Tomcat thread quickly released
09:53:20.899  INFO [customer-t-1]    async query sleep start   ← Worker thread 1 starts executing
09:53:21.026  INFO [io-50012-exec-1] async query start         ← Tomcat thread receives new request again
09:53:21.026  INFO [customer-t-2]    async query sleep start   ← Worker thread 2 starts executing
09:53:21.186  INFO [io-50012-exec-1] async query start
09:53:21.187  INFO [customer-t-3]    async query sleep start
...
09:53:22.261  INFO [io-50012-exec-1] async query start
09:53:22.261  INFO [customer-t-10]   async query sleep start   ← All 10 threads fully occupied

// ============ Phase 2: Requests 11-20 enter queue to wait ============
09:53:22.411  INFO [io-50012-exec-1] async query start         ← 11th request, enters queue
09:53:22.597  INFO [io-50012-exec-1] async query start         ← 12th request, enters queue
09:53:22.732  INFO [io-50012-exec-1] async query start         ← ...continues to 20th
...
09:53:24.048  INFO [io-50012-exec-1] async query start         ← 20th request, queue full

// ============ Phase 3: 21st request triggers rejection policy ============
09:53:24.065 ERROR [io-50012-exec-1] RejectedExecutionException:
    ThreadPoolExecutor@79a3d00d[Running, pool size = 10, active threads = 10, queued tasks = 10]
    ↑ Thread pool status: 10 busy threads + 10 queued tasks = full capacity

// ============ Phase 4: Thread reuse begins - Key phenomenon! ============
09:53:30.313  INFO [customer-t-1]    async query sleep done    ← Thread 1 completes 1st task
09:53:30.313  INFO [customer-t-1]    async query done
09:53:30.314  INFO [customer-t-1]    async query sleep start   ← Thread 1 immediately executes 11th task (reused!)

09:53:31.041  INFO [customer-t-2]    async query sleep done    ← Thread 2 completes 2nd task
09:53:31.041  INFO [customer-t-2]    async query sleep start   ← Thread 2 immediately executes 12th task (reused!)

09:53:31.197  INFO [customer-t-3]    async query sleep done
09:53:31.197  INFO [customer-t-3]    async query sleep start   ← Thread 3 reused

// ... All 10 threads reused sequentially, processing queued tasks 11-20

// ============ Phase 5: Second round of tasks all completed ============
09:53:40.320  INFO [customer-t-1]    async query sleep done    ← Thread 1 completes 11th task
09:53:41.048  INFO [customer-t-2]    async query sleep done    ← Thread 2 completes 12th task
...
```

**Key Observations**:

1. **Strong Concurrency**: Tomcat thread (io-50012-exec-1) received 20 requests in 2 seconds, averaging 100ms per request
2. **Fixed Threads**: Only `customer-t-1` through `customer-t-10` Worker threads throughout
3. **Thread Reuse**: `customer-t-1` immediately executes the 11th task after completing the 1st task at 09:53:30 (only 1ms interval)
4. **Rejection Policy**: When exceeding capacity (10 threads + 10 queue), the 21st request is rejected

### Sync Interface Serial Execution

Sending 20 concurrent requests to `/goody/sync/query1` (each task takes 1 second):

```log
// ============ Serial Processing: Tomcat thread blocked ============
09:54:02.401  INFO [io-50012-exec-1] sync query start          ← Tomcat thread handles 1st request
09:54:02.401  INFO [customer-t-1]    sync query sleep start    ← Worker thread executes
09:54:03.407  INFO [customer-t-1]    sync query sleep done     ← Completes after 1 second
09:54:03.407  INFO [io-50012-exec-1] sync query done           ← Tomcat thread then returns

09:54:03.409  INFO [io-50012-exec-1] sync query start          ← Handles 2nd request
09:54:03.409  INFO [customer-t-2]    sync query sleep start
09:54:04.416  INFO [customer-t-2]    sync query sleep done
09:54:04.416  INFO [io-50012-exec-1] sync query done

09:54:04.418  INFO [io-50012-exec-1] sync query start          ← Handles 3rd request
09:54:04.418  INFO [customer-t-3]    sync query sleep start
...

// ============ Thread reuse also exists ============
09:54:12.490  INFO [io-50012-exec-1] sync query start          ← 11th request
09:54:12.490  INFO [customer-t-1]    sync query sleep start    ← Thread 1 reused
09:54:13.500  INFO [customer-t-1]    sync query sleep done
09:54:13.500  INFO [io-50012-exec-1] sync query done
```

**Comparative Analysis**:

| Dimension | Async Interface | Sync Interface |
|----------------|-------------------------------|----------------------------------|
| **Tomcat Thread** | Quickly released, receives 20 requests in 2 seconds | Blocked, takes 20 seconds to process 20 requests |
| **Concurrency** | Can handle 20 simultaneously (10 threads + 10 queue) | Can only process serially, one after another |
| **Worker Thread Reuse** | ✅ Exists (customer-t-1 handles 1st and 11th tasks) | ✅ Exists (customer-t-1 handles 1st and 11th tasks) |
| **Total Time** | ~20 seconds (10 seconds × 2 rounds) | ~20 seconds (1 second × 20) |
| **Thread Utilization** | High (Tomcat idle, Worker busy) | Low (Tomcat + Worker both occupied, doing one job) |
| **System Throughput** | High (Tomcat thread can handle other requests) | Low (Tomcat thread occupied) |
| **Async Nature** | ✅ Truly async, releases main thread | ❌ Fake async, essentially sync waiting (two threads doing one job, even slower) |

**Key Conclusion**:

Although the sync interface also demonstrates Worker thread reuse, **it essentially doesn't leverage async advantages**. Instead, it brings additional overhead:
- Tomcat thread blocked → Cannot handle other requests
- Worker thread executes → Occupies thread pool resources
- **Two threads cooperating to complete one task is worse than executing directly in Tomcat thread, which also saves thread switching overhead**

This approach is an **anti-pattern** in production environments, used only for comparison to demonstrate async advantages.

## Core Mechanism of Thread Reuse

### Producer-Consumer Model

Java thread pool's thread reuse is based on the **Producer-Consumer Model**:

1. **Worker Thread Loop**: Worker threads in the thread pool continuously fetch tasks from `BlockingQueue`
2. **Task Queue**: New tasks are submitted to the queue, and idle threads immediately retrieve and execute them
3. **Reuse Advantages**: Avoids overhead of frequent thread creation and destruction (context switching, memory allocation)

### Similarities with IO Multiplexing

**Core**: Async thread pools are essentially **"multiplexing" thinking at the application layer**. Although implementation mechanisms differ, the approach to solving problems is highly similar to IO multiplexing.

#### Similarities

1. **Core Idea: Using Limited Resources to Handle Massive Requests**
   - **IO Multiplexing**: 1 thread monitors N socket connections via epoll/select
   - **Async Thread Pool**: A small number of Tomcat threads handle N concurrent requests (through quick release)

2. **Non-blocking Mode**
   - **IO Multiplexing**: Main thread doesn't block on a single IO operation, polls waiting for multiple IO events to be ready
   - **Async Thread Pool**: Tomcat thread doesn't block on time-consuming tasks, immediately returns to handle next request

3. **Event Notification Mechanism**
   - **IO Multiplexing**: epoll notifies which socket is readable/writable
   - **Async Thread Pool**: CompletableFuture notifies task completion

#### Essential Differences

| Dimension | IO Multiplexing | Async Thread Pool |
|----------|---------------------|------------------------|
| **Reuse Object** | Reuse thread (single thread handles multiple IO) | Reuse Tomcat thread (quick release) |
| **Use Case** | Network IO-intensive | CPU/IO mixed |
| **Implementation Level** | OS level (epoll/select) | Application level (thread pool scheduling) |
| **Typical Applications** | Netty, Redis, Nginx | Spring WebFlux, Traditional Web |
| **Design Pattern** | Reactor pattern | Producer-Consumer pattern |

#### Analogy

```
IO Multiplexing:
┌─────────────┐
│ Event Loop  │ ──monitor──> [Socket1, Socket2, ..., SocketN]
│  (1 thread) │              Handle whichever is ready
└─────────────┘

Async Thread Pool:
┌─────────────┐
│ Tomcat Pool │ ──quick release──> [Request1, Request2, ..., RequestN]
│  (200 threads) │                   Handed to Worker pool for async processing
└─────────────┘
```

**Conclusion**: Although underlying mechanisms differ, both are solving the core problem of "how to handle high concurrency with limited resources". Async thread pools can be understood as **multiplexing thinking implemented at the application layer**.

## Summary

This article reveals the importance of custom thread pools and thread reuse mechanisms by comparing async and sync interface implementations. Key points:

- ✅ Custom thread pools achieve business isolation and fine-grained management
- ✅ Async interfaces improve system throughput by releasing Tomcat threads
- ✅ Thread reuse avoids overhead of frequent thread creation and destruction
- ✅ Properly configure thread pool parameters to avoid resource waste or task rejection
- ✅ Thread reuse process can be clearly observed through thread names in logs

In actual production environments, it's also necessary to continuously optimize thread pool configuration by combining monitoring metrics (thread pool activity, queue length, rejection count, etc.).

