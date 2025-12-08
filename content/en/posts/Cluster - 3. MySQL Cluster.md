+++
date = '2025-12-08T10:00:00+08:00'
draft = false
title = '[Cluster] - 3. MySQL Cluster'
categories = ["Cluster", "MySQL"]
tags = ["MySQL", "Cluster", "Distributed System"]
+++

## Overview

- MySQL is the most widely used relational database in the world.
- As business grows, a single MySQL instance becomes the bottleneck — both in capacity and reliability.
- This blog traces the evolution of MySQL high availability: from simple replication to consensus-based clustering.

## Evolution History: The Long Road to High Availability

### Single Node Era

![Single Node Architecture](/images/Cluster%20-%203%20-%20MySQL%20Cluster/01-single-node.svg)

The starting point. One MySQL instance handles everything.

| Problems                       | Single Node |
|--------------------------------|:-----------:|
| Single point of failure (SPOF) |      T      |
| Storage limited to single disk |      T      |
| Write throughput bottleneck    |      T      |
| No automatic failover          |      \      |
| Replication lag                |      \      |
| Data consistency risk          |      \      |

### Master-Slave Replication: The First Step

The obvious solution: add replicas.

![Master-Slave Replication](/images/Cluster%20-%203%20-%20MySQL%20Cluster/02-master-slave.svg)

**How It Works**:

1. Master writes to **Binlog** (binary log)
2. Slave's **IO Thread** pulls Binlog from Master
3. Slave writes to local **Relay Log**
4. Slave's **SQL Thread** replays Relay Log

| Problems                       | Single Node | Master-Slave |
|--------------------------------|:-----------:|:------------:|
| Single point of failure (SPOF) |      T      |   Partial    |
| Storage limited to single disk |      T      |    Solved    |
| Write throughput bottleneck    |      T      |      T       |
| No automatic failover          |      \      |      T       |
| Replication lag                |      \      |      T       |
| Data consistency risk          |      \      |      T       |

**Why "Partial" for SPOF?**
- Data is now on multiple machines
- But if Master dies, **someone must manually promote a Slave**
- During this window, writes are blocked

**The Lag Problem**:
- Replication is **asynchronous** by default
- User writes data, then immediately reads
- Read goes to a Slave that hasn't caught up yet
- User sees stale data

### Semi-Synchronous Replication: The Compromise

![Semi-Sync Replication](/images/Cluster%20-%203%20-%20MySQL%20Cluster/03-semi-sync.svg)

MySQL 5.5 introduced **semi-synchronous replication**:

1. Master writes to Binlog
2. Master **waits** for at least one Slave to acknowledge receipt
3. Only then does Master return success to client

| Problems                       | Single Node | Master-Slave | Semi-Sync |
|--------------------------------|:-----------:|:------------:|:---------:|
| Single point of failure (SPOF) |      T      |   Partial    |  Partial  |
| Storage limited to single disk |      T      |    Solved    |  Solved   |
| Write throughput bottleneck    |      T      |      T       |     T     |
| No automatic failover          |      \      |      T       |     T     |
| Replication lag                |      \      |      T       |  Reduced  |
| Data consistency risk          |      \      |      T       |  Better   |

**Replication Mode Comparison**:

| Mode      | Data Safety                  | Performance    |
|-----------|------------------------------|----------------|
| Async     | Risk of data loss            | Fast           |
| Semi-sync | At least one copy guaranteed | Slower (1 RTT) |
| Full Sync | Majority consensus           | Slowest        |

#### The Critical Question: What Happens During the Wait?

When Master waits for Slave ACK, what about concurrent transactions?

**Lock Protection**:
- The waiting transaction **holds row locks**
- Any other transaction attempting to modify the same rows **blocks**
- Blocked until the first transaction completes (ACK received or timeout)

#### Timeout, Degradation, and Recovery

**The Problem**:
- Slave dies or network breaks
- Master cannot receive ACK
- Without timeout, Master hangs forever

**Timeout Mechanism** (`rpl_semi_sync_master_timeout`, default 10s):

```
[Slave dies] → Master waits 10s → No ACK → Degrade to Async → Commit locally
```

**Async Mode Behavior**:
- Master no longer waits for Slave acknowledgment

| Aspect           | Semi-Sync Mode            | Async Mode (Degraded)      |
|------------------|---------------------------|----------------------------|
| Wait for Slave?  | Yes (ACK required)        | No (fire and forget)       |
| Write Latency    | +1 RTT (network)          | Local disk speed only      |
| Data Location    | Master + at least 1 Slave | Master only                |
| If Master Crashes| No data loss (RPO=0)      | **Data loss** (RPO>0)      |

**The Unprotected Period**:
- After degradation, all subsequent transactions (B, C, D...) commit immediately without Slave confirmation
- Data exists **only on Master**
- If Master crashes during this period, unsynced data is permanently lost

**Automatic Recovery**:

When Slave reconnects:

1. Slave's IO Thread connects to Master
2. Master detects `Rpl_semi_sync_master_clients` increases from 0 to 1
3. Master switches `Rpl_semi_sync_master_status` from OFF to ON
4. Slave requests binlog from last known position
5. Master sends accumulated backlog
6. Next new transaction: Master **waits for ACK** again — protection resumes

**Catch-Up Latency**:
- During backlog transfer, new transactions may experience higher latency
- Network bandwidth is consumed by historical data replication

#### AFTER_COMMIT vs AFTER_SYNC: From "Semi-Safe" to "Lossless"

MySQL 5.5 introduced the **mechanism**, but MySQL 5.7 gave us the **correctness**.

![Semi-Sync Detail](/images/Cluster%20-%203%20-%20MySQL%20Cluster/03-semi-sync-detail.svg)

**AFTER_COMMIT (MySQL 5.5-5.6 default)** — The Flawed Way:

```
Binlog → Commit to InnoDB → Wait for ACK → Return to client
         ↑
         Problem: Data visible before Slave confirms!
```

**Crash Scenario Analysis**: Master crashes while waiting for ACK.
- Slave: Never received the data
- Master: Already committed locally — other clients **can see** this data
- After failover: Data **disappears** from the new Master (Slave)
- Result: "I saw the data a second ago, now it's gone!" — **Phantom Data**

**AFTER_SYNC (MySQL 5.7+ default)** — The Lossless Way:

Controlled by `rpl_semi_sync_master_wait_point = AFTER_SYNC`

```
Binlog → Send to Slave → Wait for ACK → Commit to InnoDB → Return to client
                         ↑
                         Data still invisible (not committed)
```

**Crash Scenario Analysis**: Master crashes while waiting for ACK.
- Slave: Maybe received it, maybe not
- Master: **Not committed** — other clients cannot see this data
- After failover: Data missing, but **no one ever saw it**
- Result: Consistency preserved — **Lossless**

| Feature          | AFTER_COMMIT (5.5)              | AFTER_SYNC (5.7+)              |
|------------------|--------------------------------|--------------------------------|
| Commit Timing    | Before waiting for Slave       | After Slave ACK received       |
| Data Visibility  | Visible during wait            | Invisible until ACK            |
| Failover Risk    | Phantom data possible          | Lossless — consistent          |
| Verdict          | "Semi-Safe"                    | "Truly Safe"                   |

### External HA: MHA and Orchestrator

Since MySQL itself doesn't handle failover, external tools emerged.

![MHA Architecture](/images/Cluster%20-%203%20-%20MySQL%20Cluster/04-mha-architecture.svg)

**MHA (Master High Availability)**:

1. Monitor process watches Master via heartbeat
2. Master dies → MHA compares all Slaves' Binlog positions
3. Promotes the most up-to-date Slave
4. Redirects VIP (Virtual IP) to new Master

| Problems                       | Single Node | Master-Slave | Semi-Sync |   MHA   |
|--------------------------------|:-----------:|:------------:|:---------:|:-------:|
| Single point of failure (SPOF) |      T      |   Partial    |  Partial  | Solved  |
| Storage limited to single disk |      T      |    Solved    |  Solved   | Solved  |
| Write throughput bottleneck    |      T      |      T       |     T     |    T    |
| No automatic failover          |      \      |      T       |     T     | Partial |
| Replication lag                |      \      |      T       |  Reduced  |    T    |
| Data consistency risk          |      \      |      T       |  Better   |    T    |

**Why "Partial" for Auto Failover?**
- MHA provides automatic failover
- But it relies on external monitoring
- Network partitions can cause **split-brain** scenarios

**The Split-Brain Problem**:

![Split Brain Scenario](/images/Cluster%20-%203%20-%20MySQL%20Cluster/05-split-brain.svg)

Network partition creates two "Masters":

- MHA thinks Master is dead (just network issue)
- Promotes Slave B to new Master
- Old Master A recovers, still accepting writes
- **Two Masters, divergent data, disaster**

**Mitigation**:
- STONITH (Shoot The Other Node In The Head)
- Before promoting new Master, **physically power off** old Master via IPMI/PDU
- Dead nodes can't write data

### MySQL Group Replication (MGR): The Official Answer

MySQL 5.7.17 introduced **Group Replication** — built-in clustering based on **Paxos consensus**.

![MGR Architecture](/images/Cluster%20-%203%20-%20MySQL%20Cluster/06-mgr-architecture.svg)

**How It Works**:

1. Write arrives at any node (in multi-primary mode)
2. Node broadcasts transaction to group
3. **Majority must agree** before commit
4. Conflicting transactions are automatically rolled back

| Problems                       | Single Node | Master-Slave | Semi-Sync |   MHA   |   MGR   |
|--------------------------------|:-----------:|:------------:|:---------:|:-------:|:-------:|
| Single point of failure (SPOF) |      T      |   Partial    |  Partial  | Solved  | Solved  |
| Storage limited to single disk |      T      |    Solved    |  Solved   | Solved  | Solved  |
| Write throughput bottleneck    |      T      |      T       |     T     |    T    |    T    |
| No automatic failover          |      \      |      T       |     T     | Partial | Solved  |
| Replication lag                |      \      |      T       |  Reduced  |    T    | Minimal |
| Data consistency risk          |      \      |      T       |  Better   |    T    | Strong  |

**Single-Primary vs Multi-Primary**:

| Mode           | Writes        | Conflicts                       | Use Case                       |
|----------------|---------------|---------------------------------|--------------------------------|
| Single-Primary | One node only | None                            | Most production systems        |
| Multi-Primary  | Any node      | Auto-detected, loser rolls back | Specific geo-distributed cases |

**Warning**:
- Multi-Primary sounds cool but has pitfalls
- Auto-increment conflicts (need offset configuration)
- High conflict rate = poor performance
- Most teams use Single-Primary even with MGR

## The Physics Problem: Latency is Law

Here's where many architects fail: **you cannot beat the speed of light**.

### MGR's Write Penalty

![MGR Write Latency](/images/Cluster%20-%203%20-%20MySQL%20Cluster/07-mgr-latency.svg)

Every MGR write requires:

1. Broadcast to all nodes
2. Wait for majority ACK
3. Then commit

**In a LAN (same datacenter)**:
- +0.5ms to +2ms per write
- Acceptable

**Across regions**:
- Singapore ↔ New York: ~200ms RTT
- Every write waits 200ms for consensus
- TPS drops to single digits

### The Correct Multi-Region Architecture

![Multi-Region Architecture](/images/Cluster%20-%203%20-%20MySQL%20Cluster/08-multi-region.svg)

**Don't do this**:
- MGR nodes spread across continents

**Do this instead**:
1. **Same-city multi-AZ**: MGR cluster within one region (AZ latency < 2ms)
2. **Cross-region async replication**: Separate MGR clusters connected by async replication
3. **Accept eventual consistency** for cross-region reads

## Scaling: The Hardest Part

### Read Scaling: Easy Mode

![Read Scaling](/images/Cluster%20-%203%20-%20MySQL%20Cluster/09-read-scaling.svg)

Adding read capacity is straightforward:

1. Backup existing Slave (XtraBackup)
2. Restore to new server
3. `CHANGE MASTER TO` point to Master
4. Add to load balancer

### Write Scaling: Hard Mode (Sharding)

When single-Master can't handle write load, you need **sharding**.

![Sharding Architecture](/images/Cluster%20-%203%20-%20MySQL%20Cluster/10-sharding.svg)

**The Pain Points**:

1. **Cross-shard JOINs**: Impossible at database level, must handle in application
2. **Distributed transactions**: XA protocol is slow; most use eventual consistency
3. **Global unique IDs**: Auto-increment breaks; need Snowflake or similar
4. **Resharding**: Moving data between shards is operational nightmare

**Sharding Strategies**:

| Strategy  | Example               | Pros                  | Cons                     |
|-----------|-----------------------|-----------------------|--------------------------|
| Range     | user_id 1-1M → Shard1 | Simple, range queries | Hotspots on recent data  |
| Hash      | user_id % 4 → Shard N | Even distribution     | Range queries impossible |
| Directory | Lookup table          | Flexible              | Extra hop, SPOF risk     |

### Online Migration: The Double-Write Pattern

![Double Write Migration](/images/Cluster%20-%203%20-%20MySQL%20Cluster/11-double-write.svg)

Zero-downtime data migration:

1. **Enable double-write**: Application writes to both old and new location
2. **Backfill historical data**: Background job copies old data
3. **Verify consistency**: Compare checksums
4. **Switch reads**: Gradually move read traffic
5. **Disable old writes**: Final cutover

## The Transaction Nightmare

### Distributed Transactions: Choose Your Pain

When data spans multiple databases, ACID breaks down.

![Distributed Transaction Options](/images/Cluster%20-%203%20-%20MySQL%20Cluster/12-distributed-tx.svg)

**Option 1: XA/2PC (Two-Phase Commit)**

- MySQL native support
- Strong consistency
- **Terrible performance**: Locks held across network round-trips
- Almost never used in high-throughput systems

**Option 2: TCC (Try-Confirm-Cancel)**

- Business logic split into three phases
- Better performance than XA
- **Massive code complexity**: Every operation needs Try/Confirm/Cancel implementations

**Option 3: Saga + Event Sourcing**

- Chain of local transactions
- Compensating transactions for rollback
- **Eventual consistency**: Not suitable for financial core

**Option 4: Local Message Table**

- Write business data + message in same local transaction
- Background job sends message to other services
- **Best balance** for most internet applications

### Read-Write Splitting: The Stale Read Trap

![Read Write Split](/images/Cluster%20-%203%20-%20MySQL%20Cluster/13-read-write-split.svg)

**The Problem**:

1. User updates profile (writes to Master)
2. User refreshes page (reads from Slave)
3. Slave hasn't replicated yet
4. User sees old data, files bug report

**Solutions**:

| Approach           | Implementation                                  | Trade-off                    |
|--------------------|-------------------------------------------------|------------------------------|
| Force Master read  | After write, read from Master for N seconds     | Reduces read scaling benefit |
| Causal consistency | Track write timestamp, route to caught-up Slave | Complex routing logic        |
| Accept staleness   | For non-critical reads (view counts, etc.)      | Limited applicability        |

## Production War Stories

### The Big Transaction Disaster

**Scenario**:
- Batch job deletes 1 million expired records in single transaction

**What happens**:

1. Binlog grows to gigabytes
2. Slaves struggle to replay
3. Replication lag spikes to hours
4. MGR nodes get kicked out for being too far behind
5. Cluster becomes read-only or crashes

**Solution**:
- Chunk large operations

```sql
-- Bad
DELETE FROM logs WHERE created_at < '2024-01-01';

-- Good
DELETE FROM logs WHERE created_at < '2024-01-01' LIMIT 10000;
-- Repeat in loop with sleep between batches
```

### The Failover That Wasn't

**Scenario**:
- MHA triggers failover, but old Master wasn't actually dead

**Timeline**:

1. 00:00 - Network glitch, MHA loses heartbeat
2. 00:01 - MHA promotes Slave B
3. 00:02 - Network recovers, old Master A still running
4. 00:02-00:10 - Both A and B accepting writes
5. 00:10 - DBA notices, panic ensues
6. Next 2 days - Manual data reconciliation

**Prevention**:

- STONITH (power off old Master before promotion)
- Fencing (network isolation scripts)
- `super_read_only` on potential Masters

## Architecture Decision Guide

### When to Use What

| Scenario                   | Recommendation                                |
|----------------------------|-----------------------------------------------|
| Startup, < 10k QPS         | Single node + daily backup                    |
| Growth, need HA            | Master-Slave + Semi-sync + ProxySQL           |
| Enterprise, zero data loss | MGR Single-Primary                            |
| Global users               | Regional MGR clusters + async replication     |
| Massive write load         | Sharding (but exhaust vertical scaling first) |

### The Golden Rules

1. **Don't shard until you must**: Vertical scaling (bigger machine) is always simpler
2. **Don't chase strong consistency globally**: Physics wins; accept regional consistency
3. **Don't trust auto-failover blindly**: Always have runbooks for manual intervention
4. **Don't forget the application**: Most "database problems" are actually query problems

## Summary

MySQL clustering is fundamentally about **trade-offs**:

- **Async replication**: Fast but may lose data
- **Semi-sync**: Balanced but can degrade
- **MGR**: Safe but slower and complex
- **Sharding**: Scales writes but breaks SQL semantics

The right architecture depends on your **actual requirements**, not theoretical ideals. Most systems are fine with
Master-Slave + Semi-sync. Only upgrade complexity when you have real problems to solve.
