+++
date = '2025-09-21T23:23:17+08:00'
draft = false
title = '[Spring] 1. spring web CompletionStage 浅谈'
categories = ["Java", "Spring"]
tags = ["Java", "Spring", "web"]
+++

# [Spring] 1. spring web CompletionStage 浅谈

## 介绍

- spring-web里对异步的支持做的很好，可以通过异步返回的形式，做许多优化
  - 提高吞吐量
  - 精细调控各业务执行线程池

## 样例说明

```java
/**
 * async interface controller
 *
 * @author Goody
 * @version 1.0, 2024/9/19
 */
@RestController
@RequestMapping("/goody")
@RequiredArgsConstructor
@Slf4j
public class GoodyAsyncController {

    private static final AtomicInteger COUNT = new AtomicInteger(0);
    private static final Executor EXECUTOR = new ThreadPoolExecutor(
        10,
        10,
        10,
        TimeUnit.SECONDS,
        new ArrayBlockingQueue<>(10),
        r -> new Thread(r, String.format("customer-t-%s", COUNT.addAndGet(1)))
    );

    @GetMapping("async/query1")
    public CompletionStage<String> asyncQuery1() {
        log.info("async query start");
        return CompletableFuture.supplyAsync(() -> {
            log.info("async query sleep start");
            ThreadUtils.sleep(1000);
            log.info("async query sleep done");
            log.info("async query done");
            return "done";
        }, EXECUTOR);
    }

    @GetMapping("sync/query1")
    public String syncQuery1() throws InterruptedException {
        log.info("sync query start");
        final CountDownLatch latch = new CountDownLatch(1);
        EXECUTOR.execute(() -> {
            log.info("sync query sleep start");
            ThreadUtils.sleep(1000);
            log.info("sync query sleep done");
            latch.countDown();
        });
        latch.await();
        log.info("sync query done");
        return "done";
    }
}
```

- 定义了一个自定义的线程池，用于异步状态下使用
- 这里一个同步，一个异步，可以看下具体的请求情况

### 单次请求

#### 请求异步接口

> curl --location '127.0.0.1:50012/goody/async/query1'

```text
2024-09-19 15:56:43.408  INFO 24912 --- [io-50012-exec-1] c.g.u.j.controller.GoodyAsyncController  : async query start
2024-09-19 15:56:43.411  INFO 24912 --- [   customer-t-1] c.g.u.j.controller.GoodyAsyncController  : async query sleep start
2024-09-19 15:56:44.417  INFO 24912 --- [   customer-t-1] c.g.u.j.controller.GoodyAsyncController  : async query sleep done
2024-09-19 15:56:44.417  INFO 24912 --- [   customer-t-1] c.g.u.j.controller.GoodyAsyncController  : async query done
```

#### 请求同步接口

> curl --location '127.0.0.1:50012/goody/sync/query1'

```text
2024-09-19 16:03:00.916  INFO 25780 --- [io-50012-exec-1] c.g.u.j.controller.GoodyAsyncController  : sync query start
2024-09-19 16:03:00.917  INFO 25780 --- [   customer-t-1] c.g.u.j.controller.GoodyAsyncController  : sync query sleep start
2024-09-19 16:03:01.924  INFO 25780 --- [   customer-t-1] c.g.u.j.controller.GoodyAsyncController  : sync query sleep done
2024-09-19 16:03:01.924  INFO 25780 --- [io-50012-exec-1] c.g.u.j.controller.GoodyAsyncController  : sync query done
```

#### 分析

- 其实从一个单独请求的例子里，看出来的差别不大。不过我们先一步一步分析
- 从异步接口里来看，从`CompletableFuture`接手之后，全部都是`自定义线程池`处理，全部交给spring-web框架进行拆包的处理
- 从同步接口里来看，从`CompletableFuture`接手之后，spring-web的线程进行了等待，其实可以推理出来此时是同步等待的。

### 10并发请求

- java程序已经设置`web线程=1`，`自定义业务线程=10`

#### 请求脚本

```python
import threading
import requests
import datetime

def get_current_time():
    current_time = datetime.datetime.now()
    return current_time.strftime("%Y-%m-%d %H:%M:%S")

url = "http://127.0.0.1:50012/goody/async/query1"
num_threads = 10

def send_request():
    response = requests.get(url)
    print(f"{get_current_time()} Request finished with status code: {response.status_code}")

threads = []

for _ in range(num_threads):
    thread = threading.Thread(target=send_request)
    threads.append(thread)
    thread.start()

# 等待所有线程完成
for t in threads:
    t.join()
```

#### 请求异步接口

**java输出**

```text
2024-09-19 16:11:19.983  INFO 11712 --- [io-50012-exec-1] c.g.u.j.controller.GoodyAsyncController  : async query start
2024-09-19 16:11:19.986  INFO 11712 --- [   customer-t-1] c.g.u.j.controller.GoodyAsyncController  : async query sleep start
2024-09-19 16:11:19.991  INFO 11712 --- [io-50012-exec-1] c.g.u.j.controller.GoodyAsyncController  : async query start
2024-09-19 16:11:19.992  INFO 11712 --- [   customer-t-2] c.g.u.j.controller.GoodyAsyncController  : async query sleep start
2024-09-19 16:11:19.992  INFO 11712 --- [io-50012-exec-1] c.g.u.j.controller.GoodyAsyncController  : async query start
2024-09-19 16:11:19.993  INFO 11712 --- [   customer-t-3] c.g.u.j.controller.GoodyAsyncController  : async query sleep start
2024-09-19 16:11:19.993  INFO 11712 --- [io-50012-exec-1] c.g.u.j.controller.GoodyAsyncController  : async query start
2024-09-19 16:11:19.994  INFO 11712 --- [   customer-t-4] c.g.u.j.controller.GoodyAsyncController  : async query sleep start
2024-09-19 16:11:19.994  INFO 11712 --- [io-50012-exec-1] c.g.u.j.controller.GoodyAsyncController  : async query start
2024-09-19 16:11:19.995  INFO 11712 --- [   customer-t-5] c.g.u.j.controller.GoodyAsyncController  : async query sleep start
2024-09-19 16:11:19.995  INFO 11712 --- [io-50012-exec-1] c.g.u.j.controller.GoodyAsyncController  : async query start
2024-09-19 16:11:19.996  INFO 11712 --- [   customer-t-6] c.g.u.j.controller.GoodyAsyncController  : async query sleep start
2024-09-19 16:11:19.997  INFO 11712 --- [io-50012-exec-1] c.g.u.j.controller.GoodyAsyncController  : async query start
2024-09-19 16:11:19.997  INFO 11712 --- [   customer-t-7] c.g.u.j.controller.GoodyAsyncController  : async query sleep start
2024-09-19 16:11:19.997  INFO 11712 --- [io-50012-exec-1] c.g.u.j.controller.GoodyAsyncController  : async query start
2024-09-19 16:11:19.998  INFO 11712 --- [   customer-t-8] c.g.u.j.controller.GoodyAsyncController  : async query sleep start
2024-09-19 16:11:19.998  INFO 11712 --- [io-50012-exec-1] c.g.u.j.controller.GoodyAsyncController  : async query start
2024-09-19 16:11:19.999  INFO 11712 --- [   customer-t-9] c.g.u.j.controller.GoodyAsyncController  : async query sleep start
2024-09-19 16:11:19.999  INFO 11712 --- [io-50012-exec-1] c.g.u.j.controller.GoodyAsyncController  : async query start
2024-09-19 16:11:20.000  INFO 11712 --- [  customer-t-10] c.g.u.j.controller.GoodyAsyncController  : async query sleep start
2024-09-19 16:11:20.989  INFO 11712 --- [   customer-t-1] c.g.u.j.controller.GoodyAsyncController  : async query sleep done
2024-09-19 16:11:20.989  INFO 11712 --- [   customer-t-1] c.g.u.j.controller.GoodyAsyncController  : async query done
2024-09-19 16:11:21.004  INFO 11712 --- [   customer-t-2] c.g.u.j.controller.GoodyAsyncController  : async query sleep done
2024-09-19 16:11:21.004  INFO 11712 --- [   customer-t-8] c.g.u.j.controller.GoodyAsyncController  : async query sleep done
2024-09-19 16:11:21.004  INFO 11712 --- [   customer-t-6] c.g.u.j.controller.GoodyAsyncController  : async query sleep done
2024-09-19 16:11:21.004  INFO 11712 --- [  customer-t-10] c.g.u.j.controller.GoodyAsyncController  : async query sleep done
2024-09-19 16:11:21.004  INFO 11712 --- [   customer-t-9] c.g.u.j.controller.GoodyAsyncController  : async query sleep done
2024-09-19 16:11:21.004  INFO 11712 --- [   customer-t-7] c.g.u.j.controller.GoodyAsyncController  : async query sleep done
2024-09-19 16:11:21.004  INFO 11712 --- [   customer-t-9] c.g.u.j.controller.GoodyAsyncController  : async query done
2024-09-19 16:11:21.004  INFO 11712 --- [   customer-t-2] c.g.u.j.controller.GoodyAsyncController  : async query done
2024-09-19 16:11:21.004  INFO 11712 --- [   customer-t-8] c.g.u.j.controller.GoodyAsyncController  : async query done
2024-09-19 16:11:21.005  INFO 11712 --- [   customer-t-7] c.g.u.j.controller.GoodyAsyncController  : async query done
2024-09-19 16:11:21.004  INFO 11712 --- [   customer-t-6] c.g.u.j.controller.GoodyAsyncController  : async query done
2024-09-19 16:11:21.004  INFO 11712 --- [  customer-t-10] c.g.u.j.controller.GoodyAsyncController  : async query done
2024-09-19 16:11:21.006  INFO 11712 --- [   customer-t-4] c.g.u.j.controller.GoodyAsyncController  : async query sleep done
2024-09-19 16:11:21.006  INFO 11712 --- [   customer-t-3] c.g.u.j.controller.GoodyAsyncController  : async query sleep done
2024-09-19 16:11:21.006  INFO 11712 --- [   customer-t-5] c.g.u.j.controller.GoodyAsyncController  : async query sleep done
2024-09-19 16:11:21.007  INFO 11712 --- [   customer-t-4] c.g.u.j.controller.GoodyAsyncController  : async query done
2024-09-19 16:11:21.007  INFO 11712 --- [   customer-t-5] c.g.u.j.controller.GoodyAsyncController  : async query done
2024-09-19 16:11:21.007  INFO 11712 --- [   customer-t-3] c.g.u.j.controller.GoodyAsyncController  : async query done
```

**python脚本输出**

```text
PS D:\desktop> & C:/Users/86570/AppData/Local/Programs/Python/Python311/python.exe d:/desktop/toy.py
2024-09-19 16:11:21 Request finished with status code: 200
2024-09-19 16:11:21 Request finished with status code: 200
2024-09-19 16:11:21 Request finished with status code: 200
2024-09-19 16:11:21 Request finished with status code: 200
2024-09-19 16:11:21 Request finished with status code: 200
2024-09-19 16:11:21 Request finished with status code: 200
2024-09-19 16:11:21 Request finished with status code: 200
2024-09-19 16:11:21 Request finished with status code: 200
2024-09-19 16:11:21 Request finished with status code: 200
2024-09-19 16:11:21 Request finished with status code: 200
```

#### 请求同步接口

**java输出**

```text
2024-09-19 16:16:12.918  INFO 11712 --- [io-50012-exec-1] c.g.u.j.controller.GoodyAsyncController  : sync query start
2024-09-19 16:16:12.919  INFO 11712 --- [   customer-t-1] c.g.u.j.controller.GoodyAsyncController  : sync query sleep start
2024-09-19 16:16:13.923  INFO 11712 --- [   customer-t-1] c.g.u.j.controller.GoodyAsyncController  : sync query sleep done
2024-09-19 16:16:13.923  INFO 11712 --- [io-50012-exec-1] c.g.u.j.controller.GoodyAsyncController  : sync query done
2024-09-19 16:16:13.927  INFO 11712 --- [io-50012-exec-1] c.g.u.j.controller.GoodyAsyncController  : sync query start
2024-09-19 16:16:13.927  INFO 11712 --- [   customer-t-8] c.g.u.j.controller.GoodyAsyncController  : sync query sleep start
2024-09-19 16:16:14.940  INFO 11712 --- [   customer-t-8] c.g.u.j.controller.GoodyAsyncController  : sync query sleep done
2024-09-19 16:16:14.941  INFO 11712 --- [io-50012-exec-1] c.g.u.j.controller.GoodyAsyncController  : sync query done
2024-09-19 16:16:14.943  INFO 11712 --- [io-50012-exec-1] c.g.u.j.controller.GoodyAsyncController  : sync query start
2024-09-19 16:16:14.943  INFO 11712 --- [   customer-t-7] c.g.u.j.controller.GoodyAsyncController  : sync query sleep start
2024-09-19 16:16:15.957  INFO 11712 --- [   customer-t-7] c.g.u.j.controller.GoodyAsyncController  : sync query sleep done
2024-09-19 16:16:15.957  INFO 11712 --- [io-50012-exec-1] c.g.u.j.controller.GoodyAsyncController  : sync query done
2024-09-19 16:16:15.961  INFO 11712 --- [io-50012-exec-1] c.g.u.j.controller.GoodyAsyncController  : sync query start
2024-09-19 16:16:15.961  INFO 11712 --- [   customer-t-2] c.g.u.j.controller.GoodyAsyncController  : sync query sleep start
2024-09-19 16:16:16.967  INFO 11712 --- [   customer-t-2] c.g.u.j.controller.GoodyAsyncController  : sync query sleep done
2024-09-19 16:16:16.967  INFO 11712 --- [io-50012-exec-1] c.g.u.j.controller.GoodyAsyncController  : sync query done
2024-09-19 16:16:16.972  INFO 11712 --- [io-50012-exec-1] c.g.u.j.controller.GoodyAsyncController  : sync query start
2024-09-19 16:16:16.972  INFO 11712 --- [   customer-t-9] c.g.u.j.controller.GoodyAsyncController  : sync query sleep start
2024-09-19 16:16:17.987  INFO 11712 --- [   customer-t-9] c.g.u.j.controller.GoodyAsyncController  : sync query sleep done
2024-09-19 16:16:17.987  INFO 11712 --- [io-50012-exec-1] c.g.u.j.controller.GoodyAsyncController  : sync query done
2024-09-19 16:16:17.990  INFO 11712 --- [io-50012-exec-1] c.g.u.j.controller.GoodyAsyncController  : sync query start
2024-09-19 16:16:17.991  INFO 11712 --- [  customer-t-10] c.g.u.j.controller.GoodyAsyncController  : sync query sleep start
2024-09-19 16:16:18.996  INFO 11712 --- [  customer-t-10] c.g.u.j.controller.GoodyAsyncController  : sync query sleep done
2024-09-19 16:16:18.996  INFO 11712 --- [io-50012-exec-1] c.g.u.j.controller.GoodyAsyncController  : sync query done
2024-09-19 16:16:18.999  INFO 11712 --- [io-50012-exec-1] c.g.u.j.controller.GoodyAsyncController  : sync query start
2024-09-19 16:16:18.999  INFO 11712 --- [   customer-t-6] c.g.u.j.controller.GoodyAsyncController  : sync query sleep start
2024-09-19 16:16:20.003  INFO 11712 --- [   customer-t-6] c.g.u.j.controller.GoodyAsyncController  : sync query sleep done
2024-09-19 16:16:20.003  INFO 11712 --- [io-50012-exec-1] c.g.u.j.controller.GoodyAsyncController  : sync query done
2024-09-19 16:16:20.007  INFO 11712 --- [io-50012-exec-1] c.g.u.j.controller.GoodyAsyncController  : sync query start
2024-09-19 16:16:20.007  INFO 11712 --- [   customer-t-4] c.g.u.j.controller.GoodyAsyncController  : sync query sleep start
2024-09-19 16:16:21.012  INFO 11712 --- [   customer-t-4] c.g.u.j.controller.GoodyAsyncController  : sync query sleep done
2024-09-19 16:16:21.012  INFO 11712 --- [io-50012-exec-1] c.g.u.j.controller.GoodyAsyncController  : sync query done
2024-09-19 16:16:21.016  INFO 11712 --- [io-50012-exec-1] c.g.u.j.controller.GoodyAsyncController  : sync query start
2024-09-19 16:16:21.016  INFO 11712 --- [   customer-t-5] c.g.u.j.controller.GoodyAsyncController  : sync query sleep start
2024-09-19 16:16:22.018  INFO 11712 --- [   customer-t-5] c.g.u.j.controller.GoodyAsyncController  : sync query sleep done
2024-09-19 16:16:22.018  INFO 11712 --- [io-50012-exec-1] c.g.u.j.controller.GoodyAsyncController  : sync query done
2024-09-19 16:16:22.020  INFO 11712 --- [io-50012-exec-1] c.g.u.j.controller.GoodyAsyncController  : sync query start
2024-09-19 16:16:22.020  INFO 11712 --- [   customer-t-3] c.g.u.j.controller.GoodyAsyncController  : sync query sleep start
2024-09-19 16:16:23.026  INFO 11712 --- [   customer-t-3] c.g.u.j.controller.GoodyAsyncController  : sync query sleep done
2024-09-19 16:16:23.027  INFO 11712 --- [io-50012-exec-1] c.g.u.j.controller.GoodyAsyncController  : sync query done
```

**python脚本输出**

```text
PS D:\desktop> & C:/Users/86570/AppData/Local/Programs/Python/Python311/python.exe d:/desktop/toy.py
2024-09-19 16:16:13 Request finished with status code: 200
2024-09-19 16:16:14 Request finished with status code: 200
2024-09-19 16:16:15 Request finished with status code: 200
2024-09-19 16:16:16 Request finished with status code: 200
2024-09-19 16:16:17 Request finished with status code: 200
2024-09-19 16:16:18 Request finished with status code: 200
2024-09-19 16:16:20 Request finished with status code: 200
2024-09-19 16:16:21 Request finished with status code: 200
2024-09-19 16:16:22 Request finished with status code: 200
2024-09-19 16:16:23 Request finished with status code: 200
```

#### 分析

- 此时可以明显看出区别，当web线程作为瓶颈的时候，`return CompletionStage`
  体，会在spring级别有相关优化。将业务放置在业务线程池之后，spring-web线程就会释放用于自身web相关业务处理
- 所以在异步时，会直接被web线程下发10个任务
- 所以在同步时，web线程必须等待每个任务完成后才会继续执行下一个请求数据
- 如果了解过`netty网络模型`就会发现这就是一个经典的`Event Loop` + `Channel` + `Selector`的模式。
    - 也就是spring-web线程作为业务分发者执行`分发`和`回复`，自定义业务线程池作为业务执行者`执行业务`
      。通过这种形式，可以极大提高IO吞吐，并把执行业务的能力更好地把握在自己手中

## 源码分析

```java
    protected void doDispatch(HttpServletRequest request, HttpServletResponse response) throws Exception {
    HttpServletRequest processedRequest = request;
    HandlerExecutionChain mappedHandler = null;
    boolean multipartRequestParsed = false;

    WebAsyncManager asyncManager = WebAsyncUtils.getAsyncManager(request);

    try {
        ModelAndView mv = null;
        Exception dispatchException = null;

        try {
            processedRequest = checkMultipart(request);
            multipartRequestParsed = (processedRequest != request);

            // ===========================================
            // Determine handler for the current request.
            // ===========================================
            mappedHandler = getHandler(processedRequest);
            if (mappedHandler == null) {
                noHandlerFound(processedRequest, response);
                return;
            }

            // ===========================================
            // Determine handler adapter for the current request.
            // ===========================================
            HandlerAdapter ha = getHandlerAdapter(mappedHandler.getHandler());

            // Process last-modified header, if supported by the handler.
            String method = request.getMethod();
            boolean isGet = "GET".equals(method);
            if (isGet || "HEAD".equals(method)) {
                long lastModified = ha.getLastModified(request, mappedHandler.getHandler());
                if (new ServletWebRequest(request, response).checkNotModified(lastModified) && isGet) {
                    return;
                }
            }

            // ===========================================
            // 前置处理
            // ===========================================
            if (!mappedHandler.applyPreHandle(processedRequest, response)) {
                return;
            }

            // ===========================================
            // Actually invoke the handler.
            // asyncManager.isConcurrentHandlingStarted() = false
            // org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter#handleInternal
            // org.springframework.web.servlet.mvc.method.annotation.DeferredResultMethodReturnValueHandler
            // ===========================================
            mv = ha.handle(processedRequest, response, mappedHandler.getHandler());
            // ===========================================
            // asyncManager.isConcurrentHandlingStarted() = true
            // ===========================================

            // ===========================================
            // 如果是异步返回，这里就会是true，下文的后置处理不会执行
            // ===========================================
            if (asyncManager.isConcurrentHandlingStarted()) {
                return;
            }

            applyDefaultViewName(processedRequest, mv);
            mappedHandler.applyPostHandle(processedRequest, response, mv);
        } catch (Exception ex) {
            dispatchException = ex;
        } catch (Throwable err) {
            // As of 4.3, we're processing Errors thrown from handler methods as well,
            // making them available for @ExceptionHandler methods and other scenarios.
            dispatchException = new NestedServletException("Handler dispatch failed", err);
        }
        processDispatchResult(processedRequest, response, mappedHandler, mv, dispatchException);
    } catch (Exception ex) {
        triggerAfterCompletion(processedRequest, response, mappedHandler, ex);
    } catch (Throwable err) {
        triggerAfterCompletion(processedRequest, response, mappedHandler,
            new NestedServletException("Handler processing failed", err));
    } finally {
        if (asyncManager.isConcurrentHandlingStarted()) {
            // Instead of postHandle and afterCompletion
            if (mappedHandler != null) {
                // ===========================================
                // 实际增加的就是以下的后置处理，用于唤醒后，把上下文恢复
                // org.springframework.boot.actuate.metrics.web.servlet.LongTaskTimingHandlerInterceptor
                // org.springframework.web.servlet.handler.ConversionServiceExposingInterceptor
                // org.springframework.web.servlet.resource.ResourceUrlProviderExposingInterceptor
                // ===========================================
                mappedHandler.applyAfterConcurrentHandlingStarted(processedRequest, response);
            }
        } else {
            // Clean up any resources used by a multipart request.
            if (multipartRequestParsed) {
                cleanupMultipart(processedRequest);
            }
        }
    }
}
```

- 这里是非常spring的写法
    1. 前置装载若干处理器。
    2. 执行前置处理器
    3. 开始执行
    4. 执行后置处理器
- 不过不同的是，里面的一个处理器`DeferredResultMethodReturnValueHandler`会判断结果是否是异步。当是异步的时候，会直接短路下文后置处理器逻辑。
  ```java
      @Override
    public void handleReturnValue(@Nullable Object returnValue, MethodParameter returnType,
            ModelAndViewContainer mavContainer, NativeWebRequest webRequest) throws Exception {

        if (returnValue == null) {
            mavContainer.setRequestHandled(true);
            return;
        }

        DeferredResult<?> result;

        if (returnValue instanceof DeferredResult) {
            result = (DeferredResult<?>) returnValue;
        }
        else if (returnValue instanceof ListenableFuture) {
            result = adaptListenableFuture((ListenableFuture<?>) returnValue);
        }
        else if (returnValue instanceof CompletionStage) {
            // ===========================================
            // 此处处理CompletionStage异步相关后续逻辑
            // ===========================================
            result = adaptCompletionStage((CompletionStage<?>) returnValue);
        }
        else {
            // Should not happen...
            throw new IllegalStateException("Unexpected return value type: " + returnValue);
        }

        WebAsyncUtils.getAsyncManager(webRequest).startDeferredResultProcessing(result, mavContainer);
  }
  ```

- 此时等待异步`CompletionStage`
- 值得一提的是spring-web上下文的传递这里非常有意思，传递路径为`web-thread` -> `biz-thread` -> `web-thread`
- 睡眠和唤醒具体使用的是`java.util.concurrent.locks.LockSupport`里的`park()`和`unpark()`两个方法

- 画了一个图辅助参考

  ![img1.png](/images/5.%20spring-web-CompletionStage/img1.png)
