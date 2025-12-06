+++
date = '2025-12-01T17:36:17+08:00'
draft = false
title = '[Cluster] - 2. Redis Cluster'
categories = ["Cluster", "Redis"]
tags = ["Redis", "Cluster"]
+++

## Overview

- The common three cluster modes are Redis(Split Cluster), MySQL(Master-Slave), Kafka(RAFT).
- This blog will introduce from the single node to the cluster mode of Redis.

## Evolution History: From Single Node to Cluster

### Single Node Era

- This is the common monolithic architecture of Redis.

![01-evolution-single-Single Node Era.svg](/images/Cluster%20-%202%20-%20Redis%20Cluster/01-evolution-single-Single%20Node%20Era.svg)

| Problems                         | Single Node |
|----------------------------------|:-----------:|
| Single point of failure (SPOF)   |      T      |
| Memory limited to single machine |      T      |
| Write throughput bottleneck      |      T      |

### Master-Slave Replication

- As to reliability, it is easy to think adding some nodes as Master-Slave.

![02-evolution-replication-Master-Slave Replication.svg](/images/Cluster%20-%202%20-%20Redis%20Cluster/02-evolution-replication-Master-Slave%20Replication.svg)

| Problems                         | Single Node | Master-Slave |
|----------------------------------|:-----------:|:------------:|
| Single point of failure (SPOF)   |      T      |    Solved    |
| Memory limited to single machine |      T      |      T       |
| Write throughput bottleneck      |      T      |      T       |
| No automatic failover            |      \      |      T       |

- We can see that, Master-Slave mode just solve the SPOF. And even do not have the failover, so only Master-Slave is not
  something reliable.

### Sentinel Mode

- For failover, we can easily think RAFT or other algorithms for keeping it reliable.
- But in Sentinel Mode, it follows other way like ZK which hosts another server for routing.

![03-evolution-sentinel-Sentinel Mode - High Availability.svg](/images/Cluster%20-%202%20-%20Redis%20Cluster/03-evolution-sentinel-Sentinel%20Mode%20-%20High%20Availability.svg)

| Problems                         | Single Node | Master-Slave | Sentinel |
|----------------------------------|:-----------:|:------------:|:--------:|
| Single point of failure (SPOF)   |      T      |    Solved    |  Solved  |
| Memory limited to single machine |      T      |      T       |    T     |
| Write throughput bottleneck      |      T      |      T       |    T     |
| No automatic failover            |      \      |      T       |  Solved  |

- One core of cluster is horizontal scale for improving the throughput.
- It is clearly that sentinel mode is not support.

### Redis Cluster: The Official Answer

- We know Redis has 16384 slots for saving and loading.
- So it is naturally that we can choose one not common but easy way for cluster.
    - Split these 16384 slots for many different Master-Slave Clusters.

![04-evolution-cluster-Redis Cluster - Multi-Master Architecture.svg](/images/Cluster%20-%202%20-%20Redis%20Cluster/04-evolution-cluster-Redis%20Cluster%20-%20Multi-Master%20Architecture.svg)

| Problems                         | Single Node | Master-Slave | Sentinel | Cluster |
|----------------------------------|:-----------:|:------------:|:--------:|:-------:|
| Single point of failure (SPOF)   |      T      |    Solved    |  Solved  | Solved  |
| Memory limited to single machine |      T      |      T       |    T     | Solved  |
| Write throughput bottleneck      |      T      |      T       |    T     | Solved  |
| No automatic failover            |      \      |      T       |  Solved  | Solved  |

- In this way, we can do many interesting things. Like split some slots for hot cache, some slots for cold cache.
    - Like 0~99 slots are used for hot cache and this cluster can be assembled by 1 Master + 7 Slave.
    - Like 100~199 slots are used for clod cache and this cluster can be assembled by 1 Master + 1 Slave.
    - Other normal data stored in common cluster based 1 Master + 2 Slave.

![05-evolution-cluster-special-Redis Cluster - Multi-Master Architecture - Special.svg](/images/Cluster%20-%202%20-%20Redis%20Cluster/05-evolution-cluster-special-Redis%20Cluster%20-%20Multi-Master%20Architecture%20-%20Special.svg)

### Sentinel vs Cluster

#### Head-to-Head Comparison

| Aspect                    | Sentinel Mode                            | Cluster Mode (even single-shard)   |
|---------------------------|------------------------------------------|------------------------------------|
| **Automatic Failover**    | Yes (via external Sentinel processes)    | Yes (built-in, no extra processes) |
| **Deployment Complexity** | Need 3+ Sentinel processes + Redis nodes | Just Redis nodes                   |
| **Client SDK**            | Simple SDK                               | Smart Client (slightly heavier)    |
| **Multi-DB (SELECT)**     | Supported (SELECT 0-15)                  | **Only DB 0**                      |
| **Multi-Key Operations**  | Full support                             | Need hash tags for cross-slot      |
| **Future Scalability**    | Must migrate to Cluster                  | Just add nodes                     |
| **Network Overhead**      | Sentinel heartbeats                      | Gossip protocol (similar overhead) |

- I should say that in my mind, if the Cluster Mode is assembled by only one Master and two Slave which hold the whole
  16384 slots.
- This Cluster is better than Sentinel in every aspect except DB isolation.

#### Cluster Mode Problems

- The core problem of Cluster Mode is the keys can be in different clusters.

##### Lua Scripts

- Another problem is Lua scripts may failure while operating different keys which are in different clusters.
- But we can easily solve it by CRC16 algorithm.

![06-lua-scripts-hash-tag-Lua_Scripts__Cross_Slot_Problem___Hash_Tag_Solution.svg](/images/Cluster%20-%202%20-%20Redis%20Cluster/06-lua-scripts-hash-tag-Lua_Scripts__Cross_Slot_Problem___Hash_Tag_Solution.svg)

##### Pub / Sub

###### Before Redis 7.0: Village Loudspeaker Mode

![Pub/Sub Before Redis 7.0](/images/Cluster%20-%202%20-%20Redis%20Cluster/07-pubsub-before-redis7-Pub%20Sub%20Broadcast%20Mode.svg)

Why broadcast? To support "dumb clients":

- Client connects to random Node C, sends `SUBSCRIBE news`
- Node C doesn't know who else subscribed to `news` on other nodes
- When someone publishes on Node A, Node A must broadcast to ALL nodes
- Only then can each node deliver the message to its local subscribers

**Cost**: O(N) network messages per PUBLISH. In a 100-node cluster, every PUBLISH triggers 99 Gossip messages!

###### After Redis 7.0: Sharded Pub/Sub (Precision Mailbox)

![Pub/Sub After Redis 7.0](/images/Cluster%20-%202%20-%20Redis%20Cluster/08-pubsub-after-redis7-Sharded%20Pub%20Sub.svg)

Redis 7.0 made a **definition change**: Channel IS now a special Key!

| Command             | Behavior                                            |
|---------------------|-----------------------------------------------------|
| `SSUBSCRIBE news`   | Slot = CRC16("news") % 16384, connect to owner node |
| `SPUBLISH news msg` | Route to owner node, deliver locally                |

**Trade-off**:

- Clients must be "smart" (like Redisson) - know the topology, connect to correct node
- Can't just connect to any random node and subscribe anymore

**Summary**:

- **Old logic (before 7.0)**: "Village loudspeaker" - convenient but wasteful
- **New logic (after 7.0)**: "Precision mailbox" - efficient but requires smart clients

## The Home of Data: Hash Slot and Routing

### Traditional Hashing VS Consistent Hashing VS Hash Slot

#### Traditional Hashing

The simplest approach: `node = hash(key) % N`

![Traditional Hashing](/images/Cluster%20-%202%20-%20Redis%20Cluster/09-traditional-hashing-Traditional%20Hashing.svg)

**Problem**: When N changes (add/remove node), almost ALL keys get remapped!

```
Example: hash("user:1001") = 1000
Before (3 nodes): 1000 % 3 = 1 -> Node 1
After  (4 nodes): 1000 % 4 = 0 -> Node 0  (MOVED!)

Migration cost: ~(N-1)/N of all keys = ~75% when 3->4 nodes
```

#### Consistent Hashing

The industry standard for distributed systems (Cassandra, DynamoDB, etc.)

![Consistent Hashing](/images/Cluster%20-%202%20-%20Redis%20Cluster/10-consistent-hashing-Consistent%20Hashing.svg)

**Core Idea**: Both nodes and keys are mapped to a ring (0 ~ 2^32). Each key goes to the first node found walking
clockwise.

**Benefit**: Adding a node only affects ~1/N of keys (the range between new node and its predecessor).

**But still has problems for Redis**:

1. **Virtual Nodes Complexity**: Need 100-200 virtual nodes per physical node for balance
2. **Metadata Overhead**: Client must store the entire ring (all virtual nodes)
3. **Migration Granularity**: Hard to control exactly which data moves

#### Hash Slot

- Redis's pragmatic choice: A fixed array of 16384 slots.

![Hash Slot](/images/Cluster%20-%202%20-%20Redis%20Cluster/11-hash-slot-Hash%20Slot.svg)

**Two-Level Mapping**:

1. **Key -> Slot**: `slot = CRC16(key) % 16384` (fixed, never changes)
2. **Slot -> Node**: Configurable, stored in cluster metadata

#### No Silver Bullet: When Traditional Hash Wins

Beware of "silver bullet" thinking! Consistent Hashing is NOT universally better.

**Where Traditional Hash beats Consistent Hash:**

| Aspect              | Traditional Hash               | Consistent Hash                                |
|---------------------|--------------------------------|------------------------------------------------|
| **Uniformity**      | Naturally average              | Naturally not average                          |
| **Time Complexity** | O(1) - CPU instruction level   | O(log N) - binary search in TreeMap            |
| **Distribution**    | Mathematically perfect uniform | Uneven without virtual nodes (a "hack")        |
| **Implementation**  | 1 line: `hash(key) % N`        | ~50 lines: TreeMap + virtual nodes + ring wrap |
| **Memory**          | Zero overhead                  | TreeMap for all virtual nodes                  |

**Best scenarios for Traditional Hash:**

- **Database Sharding**: `user_id % 1024` for fixed table count (rarely changes)
- **HashMap/Dict Internals**: Language-level hash tables use modulo, not consistent hashing
- **Any static node count**: When you can guarantee N won't change

**Best scenarios for Consistent Hash:**

- Load balancers with dynamic backends
- Distributed cache (Memcached) with frequent node changes
- Any system where nodes join/leave frequently

**Engineering Wisdom**

- Use the simplest solution that works. If node count is fixed, traditional hash is faster and
  simpler. Only use consistent hashing when dynamic scaling is a real requirement.

### The Hash Slot Algorithm

```c
// Redis source code: cluster.c
unsigned int keyHashSlot(char *key, int keylen) {
    int s, e; /* start-end indexes of { and } */

    // Look for hash tag {...}
    for (s = 0; s < keylen; s++)
        if (key[s] == '{') break;

    if (s < keylen) {
        for (e = s+1; e < keylen; e++)
            if (key[e] == '}') break;
        if (e < keylen && e != s+1) {
            // Hash tag found: only hash content within {}
            return crc16(key+s+1, e-s-1) & 16383;
        }
    }

    // No hash tag: hash the entire key
    return crc16(key, keylen) & 16383;
}
```

**The Formula**:

```
slot = CRC16(key) mod 16384
```

#### Why 16384 (2^14)?

This is a hardcore design decision by Antirez - a **"bandwidth vs. granularity"** trade-off game.

![Why 16384 Slots](/images/Cluster%20-%202%20-%20Redis%20Cluster/13-why-16384-Why%2016384%20Slots.svg)

**1. The Gossip "Bandwidth Tax"**

Every Ping/Pong message carries a **Slots Bitmap** - each bit represents one slot:

| Slots Count  | Bitmap Size | TCP Packets (MTU=1500) |
|--------------|-------------|------------------------|
| 65536 (2^16) | 8 KB        | 6-7 packets            |
| 16384 (2^14) | 2 KB        | 2 packets              |

8KB per heartbeat = massive bandwidth waste + more TCP fragmentation + higher retransmit probability.

> **Antirez**: "Making the message too big would waste a lot of bandwidth."

**2. The 1000-Node Soft Limit**

Redis Cluster targets **medium-scale clusters**, not Google Spanner-level global systems.

| Slots | Nodes | Slots per Node |
|-------|-------|----------------|
| 65536 | 1000  | ~65            |
| 16384 | 1000  | ~16            |

16 slots per node is **enough for rebalancing**. 65 slots adds negligible benefit but 4x bandwidth cost.

**3. Memory Overhead**

Each node stores bitmap for ALL other nodes:

```c
// cluster.h
typedef struct {
    unsigned char slots[16384/8]; /* 2048 bytes = 2KB */
} clusterNode;
```

| Slots | 1000 Nodes Memory |
|-------|-------------------|
| 65536 | 1000 x 8KB = 8MB  |
| 16384 | 1000 x 2KB = 2MB  |

**Bottom Line**: 16384 is the **Goldilocks number** - not too big (wastes bandwidth), not too small (limits granularity). CRC16 can produce 65536, but `CRC16(key) % 16384` gives us just what we need.

### Hash Tags: Forcing Keys to Same Slot

![Hash Tags](/images/Cluster%20-%202%20-%20Redis%20Cluster/06-lua-scripts-hash-tag-Lua_Scripts__Cross_Slot_Problem___Hash_Tag_Solution.svg)

**Practical Use Cases**:

```redis
# All keys for same user go to same slot
SET {user:1001}:name "John"
SET {user:1001}:email "john@example.com"
HSET {user:1001}:profile age 25 city "NYC"

# Now you can do multi-key operations!
MGET {user:1001}:name {user:1001}:email

# Lua scripts work too
EVAL "return redis.call('GET', KEYS[1]) .. redis.call('GET', KEYS[2])" 2 {user:1001}:name {user:1001}:email
```

**Warning**: Don't overuse hash tags! If too many keys share the same tag, you create a "hot slot" problem.

## The Gossip Protocol: How Nodes Talk Without a Boss

### Why Gossip?

In centralized systems like Kafka, ZooKeeper maintains cluster state. But Redis Cluster has no ZK. How do nodes know
about each other?

**Answer**: Gossip Protocol — nodes exchange information through periodic "chitchat".

![Gossip Protocol](/images/Cluster%20-%202%20-%20Redis%20Cluster/09-gossip-protocol.svg)

### Message Types

| Message | Purpose                                                |
|---------|--------------------------------------------------------|
| PING    | "Hey, I'm alive! Here's what I know about the cluster" |
| PONG    | Response to PING with sender's view of cluster state   |
| MEET    | "Welcome new node, join our cluster"                   |
| FAIL    | "Node X is confirmed dead"                             |
| PUBLISH | Pub/Sub message broadcast                              |

### What's Inside a Gossip Message?

![Gossip Message Structure](/images/Cluster%20-%202%20-%20Redis%20Cluster/10-gossip-message.svg)

Each PING/PONG contains:

```c
// Simplified from cluster.h
typedef struct {
    char sig[4];        // "RCmb" signature
    uint32_t totlen;    // Total message length
    uint16_t type;      // PING, PONG, MEET, FAIL...
    uint16_t count;     // Number of gossip entries

    uint64_t currentEpoch;  // Cluster's current epoch
    uint64_t configEpoch;   // Sender's config epoch

    char sender[40];        // Sender's node ID
    char myslots[2048];     // Bitmap: which slots I own (16384 bits)

    char slaveof[40];       // My master's node ID (if I'm slave)

    uint16_t port;          // My port
    uint16_t flags;         // MASTER, SLAVE, PFAIL, FAIL...

    unsigned char state;    // Cluster state (OK/FAIL)

    // Gossip section: info about OTHER nodes
    clusterMsgDataGossip gossip[];
} clusterMsg;

typedef struct {
    char nodename[40];      // Node ID
    uint32_t ping_sent;     // When I last pinged this node
    uint32_t pong_received; // When I last got pong
    char ip[46];            // IP address
    uint16_t port;          // Port
    uint16_t flags;         // What I think about this node
} clusterMsgDataGossip;
```

**Key Information Exchanged**:

1. **My Slots**: 2KB bitmap of which slots I own
2. **My Epoch**: My configuration version (critical for conflict resolution)
3. **Gossip About Others**: What I know about N random other nodes

### Gossip Frequency and Scale Limits

```c
// From cluster.c - How often to gossip
void clusterCron(void) {
    // Every 100ms
    if (!(iteration % 10)) {
        // Select a random node to PING
        // Prefer nodes we haven't heard from recently
    }

    // Every second
    if (!(iteration % 10)) {
        // Check for nodes that might be failing
        // Send PING to nodes not contacted recently
    }
}
```

**The Communication Storm Problem**:

With N nodes, full mesh = N × (N-1) connections

| Nodes | Connections | Messages/sec (estimated) |
|-------|-------------|--------------------------|
| 10    | 90          | ~100                     |
| 100   | 9,900       | ~1,000                   |
| 1,000 | 999,000     | ~10,000                  |

**Redis's Mitigation**:

1. **Smart Node Selection** (not purely random):
    - Each round, randomly pick ~5 nodes from the cluster
    - From these 5, choose the one with **oldest PONG time** (least recently contacted)
    - This ensures no node gets "forgotten" while avoiding full mesh

2. **Fallback Mechanism**:
    - If any node hasn't responded for > `cluster-node-timeout / 2`
    - Force send a PING immediately, regardless of random selection
    - Prevents false-positive failure detection

3. **Partial Gossip**:
    - Each PING only carries info about ~10% of known nodes (not all)
    - Reduces message size while still propagating state eventually

4. **Scale Limit**:
    - Recommended max: **~1000 nodes**
    - Beyond this, Gossip overhead becomes significant

### Epoch: The Logical Clock

**ConfigEpoch** is crucial for consistency — it's like Raft's "term" or Paxos's "ballot number".

![Epoch Conflict Resolution](/images/Cluster%20-%202%20-%20Redis%20Cluster/11-epoch-conflict.svg)

**When Epoch Increments**:

1. Slave wins election → becomes new master with higher epoch
2. Slot migration completes → new owner gets higher epoch
3. Manual failover → forced epoch bump

---

## Scaling: Slot Migration Deep Dive

### When Do You Need to Scale?

**Scale Out (Add Nodes)**:

- Memory pressure on existing nodes
- CPU bottleneck
- Network bandwidth saturation

**Scale In (Remove Nodes)**:

- Over-provisioned cluster
- Cost optimization

### The Migration State Machine

![Slot Migration States](/images/Cluster%20-%202%20-%20Redis%20Cluster/12-slot-migration-states.svg)

### The MIGRATE Command Internals

![MIGRATE Command Internals](/images/Cluster%20-%202%20-%20Redis%20Cluster/13-migrate-command.svg)

**MIGRATE Behavior**:

- **Atomic**: Key appears on target and disappears from source atomically
- **Blocking**: By default, blocks the source node during transfer
- **Timeout**: Configurable timeout to prevent stuck migrations

**The Blocking Problem**:

```c
// Simplified MIGRATE logic
void migrateCommand(client *c) {
    // This can block!
    robj *o = lookupKeyRead(c->db, key);

    // Serialize object
    rio payload;
    createDumpPayload(&payload, o);

    // Send to target (network I/O!)
    syncWrite(fd, payload.io.buffer.ptr, sdslen(payload.io.buffer.ptr), timeout);

    // Wait for OK (more network I/O!)
    syncReadLine(fd, buf, sizeof(buf), timeout);

    // Delete from source
    dbDelete(c->db, key);
}
```

**For Large Keys**: A single large key (big hash, big list) can block the source node for seconds!

**Mitigation**: Redis 6.0+ supports non-blocking migration for certain data types.

### Request Handling During Migration

![Request Flow During Migration](/images/Cluster%20-%202%20-%20Redis%20Cluster/14-migration-request-flow.svg)

During migration, Slot 100 is in a **transient state** — moving from Node A to Node B but not yet complete.

**Node States**:

| Node     | State       | Responsibility                                      |
|----------|-------------|-----------------------------------------------------|
| Node A   | `MIGRATING` | Still owns Slot 100, but data is moving out         |
| Node B   | `IMPORTING` | Receiving data, but **not officially responsible**  |
| Client   | -           | Slot Map still points Slot 100 → Node A             |

**Request Flow**:

1. **Client → Node A**: Client sends request based on cached Slot Map
2. **Node A checks local**:
    - Key exists → Process and return result
    - Key missing → Return `-ASK <Node B>` (key already migrated)
3. **Client → Node B**: Must send `ASKING` command first, then the original command
4. **Node B checks ASKING flag**:
    - Flag present → Execute command
    - Flag absent → Return `-MOVED <Node A>`

**Why Require ASKING?**

The `ASKING` command prevents **routing table corruption**:

- Without `ASKING`: A random client connecting to Node B might incorrectly assume Slot 100 belongs to B
- Client updates its Slot Map prematurely → All future requests go to B
- But migration just started → Most keys still on A → **Severe cache misses**

The `ASKING` flag acts as a **one-time authorization token** — only clients explicitly redirected by Node A (via `-ASK`)
can access the importing slot.

**ASK vs MOVED**:

| Aspect            | MOVED                | ASK                      |
|-------------------|----------------------|--------------------------|
| **When**          | Migration completed  | Migration in progress    |
| **Client action** | Update Slot Map      | Do NOT update Slot Map   |
| **Semantics**     | Permanent redirect   | Temporary redirect       |

---

## Failure Detection and Automatic Failover

### The Distributed Voting Problem

**The Challenge**: Without a central authority, how do nodes agree that a node is dead?

**The Answer**: Quorum-based failure detection through gossip.

### PFAIL vs FAIL: The Two-Phase Detection

![PFAIL vs FAIL Detection](/images/Cluster%20-%202%20-%20Redis%20Cluster/15-pfail-fail-detection.svg)

### The Configuration: cluster-node-timeout

```bash
# redis.conf
cluster-node-timeout 15000  # 15 seconds (default)
```

**What This Controls**:

1. **PFAIL Trigger**: Node marked PFAIL after timeout with no PONG
2. **Failover Speed**: Lower = faster detection, but more false positives
3. **Network Partition Sensitivity**: Too low = frequent unnecessary failovers

**Rule of Thumb**:

- Production: 15-30 seconds
- Testing: 5-10 seconds
- Never below 5 seconds

### Slave Election: Choosing the New Master

![Slave Election Process](/images/Cluster%20-%202%20-%20Redis%20Cluster/16-slave-election.svg)

### Manual Failover

Sometimes you want to failover deliberately (maintenance, upgrades):

```bash
# On the slave you want to promote:
CLUSTER FAILOVER

# Force failover even if master is healthy:
CLUSTER FAILOVER FORCE

# Takeover without master agreement (dangerous!):
CLUSTER FAILOVER TAKEOVER
```

**CLUSTER FAILOVER (graceful)**:

1. Slave tells master "stop accepting writes"
2. Master stops, slave catches up
3. Slave becomes master
4. No data loss!

**CLUSTER FAILOVER TAKEOVER**:

- Doesn't need master's consent
- May lose recent writes
- Use only when master is unreachable

---

## Consistency Trade-offs: What Redis Cluster Sacrifices

### CAP Theorem Recap

![CAP Theorem](/images/Cluster%20-%202%20-%20Redis%20Cluster/17-cap-theorem.svg)

### Asynchronous Replication: The Data Loss Window

![Asynchronous Replication](/images/Cluster%20-%202%20-%20Redis%20Cluster/18-async-replication.svg)

### The Split-Brain Scenario

![Split Brain Scenario](/images/Cluster%20-%202%20-%20Redis%20Cluster/19-split-brain.svg)

### Mitigation: min-replicas-to-write

![min-replicas-to-write](/images/Cluster%20-%202%20-%20Redis%20Cluster/20-min-replicas.svg)

```bash
# redis.conf
min-replicas-to-write 1      # At least 1 slave must be connected
min-replicas-max-lag 10      # Slave must have replicated within 10 seconds
```

**Trade-off**: Better consistency, but sacrifices availability.

