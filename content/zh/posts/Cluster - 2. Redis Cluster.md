+++
date = '2025-12-01T17:36:17+08:00'
draft = false
title = '[Cluster] - 2. Redis 集群'
categories = ["Cluster", "Redis"]
tags = ["Redis", "Cluster"]
+++

## 概述

- 常见的三种集群模式为 Redis（分片集群）、MySQL（主从复制）、Kafka（RAFT）。
- 本文将介绍 Redis 从单节点到集群模式的演进过程。

## 演进历史：从单节点到集群

### 单节点时代

- 这是 Redis 最常见的单体架构。

![01-evolution-single-Single Node Era.svg](/images/Cluster%20-%202%20-%20Redis%20Cluster/01-evolution-single-Single%20Node%20Era.svg)

| 问题          | 单节点 |
|-------------|:---:|
| 单点故障 (SPOF) |  T  |
| 内存受限于单机     |  T  |
| 写入吞吐量瓶颈     |  T  |

### 主从复制

- 为了提高可靠性，很容易想到添加一些节点作为主从架构。

![02-evolution-replication-Master-Slave Replication.svg](/images/Cluster%20-%202%20-%20Redis%20Cluster/02-evolution-replication-Master-Slave%20Replication.svg)

| 问题          | 单节点 | 主从复制 |
|-------------|:---:|:----:|
| 单点故障 (SPOF) |  T  | 已解决  |
| 内存受限于单机     |  T  |  T   |
| 写入吞吐量瓶颈     |  T  |  T   |
| 无自动故障转移     |  \  |  T   |

- 可以看到，主从模式只解决了单点故障问题。而且甚至没有故障转移功能，所以仅靠主从复制并不可靠。

### 哨兵模式

- 为了实现故障转移，我们很容易想到 RAFT 或其他算法来保持可靠性。
- 但在哨兵模式中，它采用了类似 ZK 的方式，通过托管另一个服务器进行路由。

![03-evolution-sentinel-Sentinel Mode - High Availability.svg](/images/Cluster%20-%202%20-%20Redis%20Cluster/03-evolution-sentinel-Sentinel%20Mode%20-%20High%20Availability.svg)

| 问题          | 单节点 | 主从复制 | 哨兵模式 |
|-------------|:---:|:----:|:----:|
| 单点故障 (SPOF) |  T  | 已解决  | 已解决  |
| 内存受限于单机     |  T  |  T   |  T   |
| 写入吞吐量瓶颈     |  T  |  T   |  T   |
| 无自动故障转移     |  \  |  T   | 已解决  |

- 集群的核心之一是水平扩展以提高吞吐量。
- 很明显，哨兵模式不支持这一点。

### Redis Cluster：官方解决方案

- 我们知道 Redis 有 16384 个槽位用于存储和读取。
- 因此很自然地，我们可以选择一种不太常见但简单的集群方式。
    - 将这 16384 个槽位分配给多个不同的主从集群。

![04-evolution-cluster-Redis Cluster - Multi-Master Architecture.svg](/images/Cluster%20-%202%20-%20Redis%20Cluster/04-evolution-cluster-Redis%20Cluster%20-%20Multi-Master%20Architecture.svg)

| 问题          | 单节点 | 主从复制 | 哨兵模式 | 集群模式 |
|-------------|:---:|:----:|:----:|:----:|
| 单点故障 (SPOF) |  T  | 已解决  | 已解决  | 已解决  |
| 内存受限于单机     |  T  |  T   |  T   | 已解决  |
| 写入吞吐量瓶颈     |  T  |  T   |  T   | 已解决  |
| 无自动故障转移     |  \  |  T   | 已解决  | 已解决  |

- 通过这种方式，我们可以做很多有趣的事情。比如将一些槽位用于热缓存，一些槽位用于冷缓存。
    - 比如 0~99 槽位用于热缓存，这个集群可以由 1 主 + 7 从组成。
    - 比如 100~199 槽位用于冷缓存，这个集群可以由 1 主 + 1 从组成。
    - 其他普通数据存储在基于 1 主 + 2 从的常规集群中。

![05-evolution-cluster-special-Redis Cluster - Multi-Master Architecture - Special.svg](/images/Cluster%20-%202%20-%20Redis%20Cluster/05-evolution-cluster-special-Redis%20Cluster%20-%20Multi-Master%20Architecture%20-%20Special.svg)

### 哨兵模式 vs 集群模式

#### 直接对比

| 方面                | 哨兵模式                   | 集群模式（即使单分片）        |
|-------------------|------------------------|--------------------|
| **自动故障转移**        | 是（通过外部哨兵进程）            | 是（内置，无需额外进程）       |
| **部署复杂度**         | 需要 3+ 个哨兵进程 + Redis 节点 | 只需 Redis 节点        |
| **客户端 SDK**       | 简单 SDK                 | 智能客户端（稍重）          |
| **多数据库 (SELECT)** | 支持（SELECT 0-15）        | **只支持 DB 0**       |
| **多键操作**          | 完全支持                   | 需要 hash tag 进行跨槽操作 |
| **未来可扩展性**        | 必须迁移到集群                | 只需添加节点             |
| **网络开销**          | 哨兵心跳                   | Gossip 协议（类似开销）    |

- 我认为，如果集群模式只由一个主节点和两个从节点组成，持有全部 16384 个槽位。
- 这种集群在除了 DB 隔离之外的各个方面都优于哨兵模式。

#### 集群模式的问题

- 集群模式的核心问题是键可能在不同的集群中。

##### Lua 脚本

- 另一个问题是 Lua 脚本在操作位于不同集群中的不同键时可能会失败。
- 但我们可以通过 CRC16 算法轻松解决。

![06-lua-scripts-hash-tag-Lua_Scripts__Cross_Slot_Problem___Hash_Tag_Solution.svg](/images/Cluster%20-%202%20-%20Redis%20Cluster/06-lua-scripts-hash-tag-Lua_Scripts__Cross_Slot_Problem___Hash_Tag_Solution.svg)

##### 发布/订阅

###### Redis 7.0 之前：村庄广播模式

![Pub/Sub Before Redis 7.0](/images/Cluster%20-%202%20-%20Redis%20Cluster/07-pubsub-before-redis7-Pub%20Sub%20Broadcast%20Mode.svg)

为什么要广播？为了支持"笨客户端"：

- 客户端连接到随机节点 C，发送 `SUBSCRIBE news`
- 节点 C 不知道其他节点上谁还订阅了 `news`
- 当有人在节点 A 发布消息时，节点 A 必须广播给所有节点
- 只有这样，每个节点才能将消息传递给其本地订阅者

**代价**：每次 PUBLISH 产生 O(N) 条网络消息。在一个 100 节点的集群中，每次 PUBLISH 触发 99 条 Gossip 消息！

###### Redis 7.0 之后：分片发布/订阅（精准投递）

![Pub/Sub After Redis 7.0](/images/Cluster%20-%202%20-%20Redis%20Cluster/08-pubsub-after-redis7-Sharded%20Pub%20Sub.svg)

Redis 7.0 做了一个**定义变更**：频道现在是一种特殊的键！

| 命令                  | 行为                                   |
|---------------------|--------------------------------------|
| `SSUBSCRIBE news`   | Slot = CRC16("news") % 16384，连接到所属节点 |
| `SPUBLISH news msg` | 路由到所属节点，本地投递                         |

**权衡**：

- 客户端必须是"智能"的（如 Redisson）- 需要知道拓扑结构，连接到正确的节点
- 不能再随便连接任意节点进行订阅了

**总结**：

- **旧逻辑（7.0 之前）**："村庄广播" - 方便但浪费
- **新逻辑（7.0 之后）**："精准投递" - 高效但需要智能客户端

## 数据的家：哈希槽与路由

### 传统哈希 VS 一致性哈希 VS 哈希槽

#### 传统哈希

最简单的方式：`node = hash(key) % N`

![Traditional Hashing](/images/Cluster%20-%202%20-%20Redis%20Cluster/09-traditional-hashing-Traditional%20Hashing.svg)

**问题**：当 N 变化（添加/删除节点）时，几乎所有键都会被重新映射！

```
示例：hash("user:1001") = 1000
之前（3 个节点）：1000 % 3 = 1 -> 节点 1
之后（4 个节点）：1000 % 4 = 0 -> 节点 0（已移动！）

迁移成本：约 (N-1)/N 的所有键 = 3->4 节点时约 75%
```

#### 一致性哈希

分布式系统的行业标准（Cassandra、DynamoDB 等）

![Consistent Hashing](/images/Cluster%20-%202%20-%20Redis%20Cluster/10-consistent-hashing-Consistent%20Hashing.svg)

**核心思想**：节点和键都映射到一个环上（0 ~ 2^32）。每个键顺时针查找，分配给找到的第一个节点。

**优点**：添加一个节点只影响约 1/N 的键（新节点与其前驱之间的范围）。

**但对 Redis 来说仍有问题**：

1. **虚拟节点复杂性**：需要每个物理节点 100-200 个虚拟节点才能平衡
2. **元数据开销**：客户端必须存储整个环（所有虚拟节点）
3. **迁移粒度**：难以精确控制哪些数据被迁移

#### 哈希槽

- Redis 的务实选择：16384 个固定槽位的数组。

![Hash Slot](/images/Cluster%20-%202%20-%20Redis%20Cluster/11-hash-slot-Hash%20Slot.svg)

**两级映射**：

1. **键 -> 槽位**：`slot = CRC16(key) % 16384`（固定，永不改变）
2. **槽位 -> 节点**：可配置，存储在集群元数据中

#### 没有银弹：传统哈希胜出的场景

警惕"银弹"思维！一致性哈希并非普遍更优。

**传统哈希优于一致性哈希的场景：**

| 方面        | 传统哈希                | 一致性哈希                      |
|-----------|---------------------|----------------------------|
| **均匀性**   | 天然平均                | 天然不平均                      |
| **时间复杂度** | O(1) - CPU 指令级      | O(log N) - TreeMap 二分查找    |
| **分布**    | 数学上完美均匀             | 没有虚拟节点时不均匀（一种"hack"）       |
| **实现**    | 1 行：`hash(key) % N` | 约 50 行：TreeMap + 虚拟节点 + 环绕 |
| **内存**    | 零开销                 | 所有虚拟节点的 TreeMap            |

**传统哈希的最佳场景：**

- **数据库分片**：`user_id % 1024` 用于固定表数量（很少变化）
- **HashMap/Dict 内部实现**：语言级哈希表使用取模，而非一致性哈希
- **任何静态节点数**：当你能保证 N 不会改变时

**一致性哈希的最佳场景：**

- 具有动态后端的负载均衡器
- 频繁节点变化的分布式缓存（Memcached）
- 任何节点频繁加入/离开的系统

**工程智慧**

- 使用最简单可行的方案。如果节点数量固定，传统哈希更快更简单。只有当动态扩展是真实需求时才使用一致性哈希。

### 哈希槽算法

```c
// Redis 源码：cluster.c
unsigned int keyHashSlot(char *key, int keylen) {
    int s, e; /* start-end indexes of { and } */

    // 查找 hash tag {...}
    for (s = 0; s < keylen; s++)
        if (key[s] == '{') break;

    if (s < keylen) {
        for (e = s+1; e < keylen; e++)
            if (key[e] == '}') break;
        if (e < keylen && e != s+1) {
            // 找到 hash tag：只哈希 {} 内的内容
            return crc16(key+s+1, e-s-1) & 16383;
        }
    }

    // 没有 hash tag：哈希整个键
    return crc16(key, keylen) & 16383;
}
```

**公式**：

```
slot = CRC16(key) mod 16384
```

#### 为什么是 16384 (2^14)？

这是 Antirez 的一个硬核设计决策 - 一场**"带宽 vs 粒度"**的权衡博弈。

![Why 16384 Slots](/images/Cluster%20-%202%20-%20Redis%20Cluster/13-why-16384-Why%2016384%20Slots.svg)

**1. Gossip "带宽税"**

每条 Ping/Pong 消息都携带一个**槽位位图** - 每个位代表一个槽位：

| 槽位数量         | 位图大小 | TCP 数据包（MTU=1500） |
|--------------|------|-------------------|
| 65536 (2^16) | 8 KB | 6-7 个包            |
| 16384 (2^14) | 2 KB | 2 个包              |

每次心跳 8KB = 大量带宽浪费 + 更多 TCP 分片 + 更高重传概率。

> **Antirez**："消息太大会浪费大量带宽。"

**2. 1000 节点软限制**

Redis Cluster 针对**中等规模集群**，而非 Google Spanner 级别的全球系统。

| 槽位数   | 节点数  | 每节点槽位数 |
|-------|------|--------|
| 65536 | 1000 | ~65    |
| 16384 | 1000 | ~16    |

每节点 16 个槽位**足够用于重平衡**。65 个槽位收益微乎其微，但带宽成本是 4 倍。

**3. 内存开销**

每个节点存储所有其他节点的位图：

```c
// cluster.h
typedef struct {
    unsigned char slots[16384/8]; /* 2048 字节 = 2KB */
} clusterNode;
```

| 槽位数   | 1000 节点内存        |
|-------|------------------|
| 65536 | 1000 x 8KB = 8MB |
| 16384 | 1000 x 2KB = 2MB |

**底线**：16384 是**恰到好处的数字** - 不会太大（浪费带宽），不会太小（限制粒度）。CRC16 可以产生 65536，但 `CRC16(key) % 16384`
刚好满足我们的需求。

### Hash Tag：强制键到同一槽位

![Hash Tags](/images/Cluster%20-%202%20-%20Redis%20Cluster/06-lua-scripts-hash-tag-Lua_Scripts__Cross_Slot_Problem___Hash_Tag_Solution.svg)

**实际用例**：

```redis
# 同一用户的所有键放到同一槽位
SET {user:1001}:name "John"
SET {user:1001}:email "john@example.com"
HSET {user:1001}:profile age 25 city "NYC"

# 现在你可以进行多键操作了！
MGET {user:1001}:name {user:1001}:email

# Lua 脚本也可以了
EVAL "return redis.call('GET', KEYS[1]) .. redis.call('GET', KEYS[2])" 2 {user:1001}:name {user:1001}:email
```

**警告**：不要过度使用 hash tag！如果太多键共享同一个 tag，你会造成"热槽位"问题。

## Gossip 协议：节点如何无中心通信

### 为什么使用 Gossip？

在像 Kafka 这样的中心化系统中，ZooKeeper 维护集群状态。但 Redis Cluster 没有 ZK。节点如何了解彼此？

**答案**：Gossip 协议 — 节点通过周期性"闲聊"交换信息。

![Gossip Protocol](/images/Cluster%20-%202%20-%20Redis%20Cluster/09-gossip-protocol.svg)

### 消息类型

| 消息      | 用途                       |
|---------|--------------------------|
| PING    | "嘿，我还活着！这是我了解的集群信息"      |
| PONG    | 对 PING 的响应，包含发送者对集群状态的视图 |
| MEET    | "欢迎新节点，加入我们的集群"          |
| FAIL    | "节点 X 已确认死亡"             |
| PUBLISH | 发布/订阅消息广播                |

### Gossip 消息里有什么？

![Gossip Message Structure](/images/Cluster%20-%202%20-%20Redis%20Cluster/10-gossip-message.svg)

每条 PING/PONG 包含：

```c
// 简化自 cluster.h
typedef struct {
    char sig[4];        // "RCmb" 签名
    uint32_t totlen;    // 总消息长度
    uint16_t type;      // PING, PONG, MEET, FAIL...
    uint16_t count;     // gossip 条目数量

    uint64_t currentEpoch;  // 集群当前 epoch
    uint64_t configEpoch;   // 发送者的 config epoch

    char sender[40];        // 发送者的节点 ID
    char myslots[2048];     // 位图：我拥有哪些槽位（16384 位）

    char slaveof[40];       // 我的主节点 ID（如果我是从节点）

    uint16_t port;          // 我的端口
    uint16_t flags;         // MASTER, SLAVE, PFAIL, FAIL...

    unsigned char state;    // 集群状态（OK/FAIL）

    // Gossip 部分：关于其他节点的信息
    clusterMsgDataGossip gossip[];
} clusterMsg;

typedef struct {
    char nodename[40];      // 节点 ID
    uint32_t ping_sent;     // 我上次 ping 这个节点的时间
    uint32_t pong_received; // 我上次收到 pong 的时间
    char ip[46];            // IP 地址
    uint16_t port;          // 端口
    uint16_t flags;         // 我对这个节点的看法
} clusterMsgDataGossip;
```

**交换的关键信息**：

1. **我的槽位**：2KB 位图，表示我拥有哪些槽位
2. **我的 Epoch**：我的配置版本（对冲突解决至关重要）
3. **关于其他节点的 Gossip**：我了解的 N 个随机其他节点的信息

### Gossip 频率和规模限制

```c
// 来自 cluster.c - 多久 gossip 一次
void clusterCron(void) {
    // 每 100ms
    if (!(iteration % 10)) {
        // 选择一个随机节点进行 PING
        // 优先选择最近没联系的节点
    }

    // 每秒
    if (!(iteration % 10)) {
        // 检查可能失败的节点
        // 向最近没联系的节点发送 PING
    }
}
```

**通信风暴问题**：

N 个节点，全网状 = N × (N-1) 个连接

| 节点数   | 连接数     | 消息/秒（估计） |
|-------|---------|----------|
| 10    | 90      | ~100     |
| 100   | 9,900   | ~1,000   |
| 1,000 | 999,000 | ~10,000  |

**Redis 的缓解措施**：

1. **智能节点选择**（非纯随机）：
    - 每轮从集群中随机选择约 5 个节点
    - 从这 5 个中选择 **PONG 时间最久** 的那个（最久没联系的）
    - 这确保没有节点被"遗忘"，同时避免全网状通信

2. **后备机制**：
    - 如果任何节点超过 `cluster-node-timeout / 2` 没有响应
    - 立即强制发送 PING，不管随机选择结果如何
    - 防止误判故障

3. **部分 Gossip**：
    - 每次 PING 只携带约 10% 已知节点的信息（不是全部）
    - 减少消息大小，同时仍能最终传播状态

4. **规模限制**：
    - 推荐最大值：**约 1000 个节点**
    - 超过此数，Gossip 开销变得显著

### Epoch：逻辑时钟

**ConfigEpoch** 对一致性至关重要 — 它类似于 Raft 的 "term" 或 Paxos 的 "ballot number"。

![Epoch Conflict Resolution](/images/Cluster%20-%202%20-%20Redis%20Cluster/11-epoch-conflict.svg)

**Epoch 何时递增**：

1. 从节点赢得选举 → 成为新主节点，获得更高的 epoch
2. 槽位迁移完成 → 新拥有者获得更高的 epoch
3. 手动故障转移 → 强制 epoch 递增

---

## 扩缩容：槽位迁移深入解析

### 何时需要扩缩容？

**扩容（添加节点）**：

- 现有节点内存压力
- CPU 瓶颈
- 网络带宽饱和

**缩容（移除节点）**：

- 集群过度配置
- 成本优化

### 迁移状态机

![Slot Migration States](/images/Cluster%20-%202%20-%20Redis%20Cluster/12-slot-migration-states.svg)

### MIGRATE 命令内部原理

![MIGRATE Command Internals](/images/Cluster%20-%202%20-%20Redis%20Cluster/13-migrate-command.svg)

**MIGRATE 行为**：

- **原子性**：键在目标节点出现和从源节点消失是原子的
- **阻塞**：默认情况下，在传输期间阻塞源节点
- **超时**：可配置超时以防止迁移卡住

**阻塞问题**：

```c
// 简化的 MIGRATE 逻辑
void migrateCommand(client *c) {
    // 这可能会阻塞！
    robj *o = lookupKeyRead(c->db, key);

    // 序列化对象
    rio payload;
    createDumpPayload(&payload, o);

    // 发送到目标（网络 I/O！）
    syncWrite(fd, payload.io.buffer.ptr, sdslen(payload.io.buffer.ptr), timeout);

    // 等待 OK（更多网络 I/O！）
    syncReadLine(fd, buf, sizeof(buf), timeout);

    // 从源删除
    dbDelete(c->db, key);
}
```

**对于大键**：单个大键（大 hash、大 list）可能会阻塞源节点数秒！

**缓解措施**：Redis 6.0+ 支持某些数据类型的非阻塞迁移。

### 迁移期间的请求处理

![Request Flow During Migration](/images/Cluster%20-%202%20-%20Redis%20Cluster/14-migration-request-flow.svg)

迁移期间，Slot 100 处于**瞬态**——正在从 Node A 迁移到 Node B，但尚未完成。

**节点状态**：

| 节点     | 状态          | 职责                             |
|--------|-------------|--------------------------------|
| Node A | `MIGRATING` | 仍拥有 Slot 100，但数据正在迁出           |
| Node B | `IMPORTING` | 正在接收数据，但**尚未正式负责**             |
| Client | -           | Slot Map 仍指向 Slot 100 → Node A |

**请求流程**：

1. **Client → Node A**：客户端根据缓存的 Slot Map 发送请求
2. **Node A 检查本地**：
    - Key 存在 → 处理并返回结果
    - Key 不存在 → 返回 `-ASK <Node B>`（Key 已迁移）
3. **Client → Node B**：必须先发送 `ASKING` 命令，再发送原始命令
4. **Node B 检查 ASKING 标志**：
    - 有标志 → 执行命令
    - 无标志 → 返回 `-MOVED <Node A>`

**为什么需要 ASKING？**

`ASKING` 命令防止**路由表错误更新**：

- 没有 `ASKING`：随机客户端连接到 Node B 可能错误地认为 Slot 100 属于 B
- 客户端过早更新 Slot Map → 后续所有请求都发给 B
- 但迁移刚开始 → 大部分 Key 仍在 A → **严重的缓存未命中**

`ASKING` 标志相当于**一次性授权令牌**——只有被 Node A 明确重定向（通过 `-ASK`）的客户端才能访问正在导入的槽位。

**ASK vs MOVED**：

| 方面        | MOVED       | ASK          |
|-----------|-------------|--------------|
| **时机**    | 迁移已完成       | 迁移进行中        |
| **客户端行为** | 更新 Slot Map | 不更新 Slot Map |
| **语义**    | 永久重定向       | 临时重定向        |

---

## 故障检测和自动故障转移

### 分布式投票问题

**挑战**：没有中央权威，节点如何达成共识认为某个节点已死亡？

**答案**：通过 gossip 进行基于法定人数的故障检测。

### PFAIL vs FAIL：两阶段检测

![PFAIL vs FAIL Detection](/images/Cluster%20-%202%20-%20Redis%20Cluster/15-pfail-fail-detection.svg)

### 配置：cluster-node-timeout

```bash
# redis.conf
cluster-node-timeout 15000  # 15 秒（默认值）
```

**这个配置控制什么**：

1. **PFAIL 触发**：超时无 PONG 后节点被标记为 PFAIL
2. **故障转移速度**：值越低 = 检测越快，但误报越多
3. **网络分区敏感度**：太低 = 频繁不必要的故障转移

**经验法则**：

- 生产环境：15-30 秒
- 测试环境：5-10 秒
- 永远不要低于 5 秒

### 从节点选举：选择新主节点

![Slave Election Process](/images/Cluster%20-%202%20-%20Redis%20Cluster/16-slave-election.svg)

### 手动故障转移

有时你想故意进行故障转移（维护、升级）：

```bash
# 在你想提升的从节点上：
CLUSTER FAILOVER

# 即使主节点健康也强制故障转移：
CLUSTER FAILOVER FORCE

# 无需主节点同意的接管（危险！）：
CLUSTER FAILOVER TAKEOVER
```

**CLUSTER FAILOVER（优雅方式）**：

1. 从节点告诉主节点"停止接受写入"
2. 主节点停止，从节点追上进度
3. 从节点成为主节点
4. 无数据丢失！

**CLUSTER FAILOVER TAKEOVER**：

- 不需要主节点同意
- 可能丢失最近的写入
- 仅在主节点无法访问时使用

---

## 一致性权衡：Redis Cluster 牺牲了什么

### CAP 定理回顾

![CAP Theorem](/images/Cluster%20-%202%20-%20Redis%20Cluster/17-cap-theorem.svg)

### 异步复制：数据丢失窗口

![Asynchronous Replication](/images/Cluster%20-%202%20-%20Redis%20Cluster/18-async-replication.svg)

### 脑裂场景

![Split Brain Scenario](/images/Cluster%20-%202%20-%20Redis%20Cluster/19-split-brain.svg)

### 缓解措施：min-replicas-to-write

![min-replicas-to-write](/images/Cluster%20-%202%20-%20Redis%20Cluster/20-min-replicas.svg)

```bash
# redis.conf
min-replicas-to-write 1      # 至少 1 个从节点必须连接
min-replicas-max-lag 10      # 从节点必须在 10 秒内完成复制
```

**权衡**：更好的一致性，但牺牲可用性。
