+++
date = '2025-09-26T21:27:17+08:00'
draft = false
title = '[Cluster] 1. RAFT Algorithm: A Complete Evolution from Single Node to Distributed Consensus'
categories = ["Cluster", "Algorithm"]
tags = ["Cluster", "RAFT", "Distributed", "Algorithm"]
+++

# [Cluster] 1. RAFT Algorithm: A Complete Evolution from Single Node to Distributed Consensus


## Introduction

- RAFT (Raft Consensus Algorithm) is a distributed consensus algorithm designed to solve the problem of achieving data state agreement among multiple nodes in distributed systems.
- Compared to the renowned Paxos algorithm, RAFT's design philosophy emphasizes "understandability" through clear role separation and straightforward state transitions, making it easier for developers to comprehend and implement.
- This article demonstrates the complete evolution of the RAFT algorithm from single-node to multi-node clusters through 11 detailed diagrams, covering key scenarios including normal operation, failure handling, network partitions, and conflict resolution.

## Core RAFT Concepts

- Before diving into the analysis, let's familiarize ourselves with several core concepts of RAFT:

**Node States**:
- **Leader**: Handles client requests and replicates log entries to other nodes
- **Follower**: Passively receives log replication requests from the Leader
- **Candidate**: Temporary state during the Leader election process

**Key Data Structures**:
- **Log**: Ordered sequence storing operation commands
- **Term**: Monotonically increasing logical clock used to detect stale information
- **CommitIndex**: Index of the highest log entry known to be committed
- **ApplyIndex/LastApplied**: Index of the highest log entry applied to the state machine
- **State**: Actual business data state

## Stage 1: Single Node Startup (Diagram 1)

```
Node1 starts as Leader with initial state:
- Log=[] (empty log)
- Term=0 (initial term)
- CommitIndex=0, ApplyIndex=0 (no committed/applied entries)
- State={} (empty state machine)
```

![1. single node.svg](/images/9.%20raft/1.%20single%20node.svg)

In a single-node cluster, the node automatically becomes the Leader as it constitutes a "majority" (1 > 1/2). This illustrates a crucial property of the RAFT algorithm: at most one Leader can exist at any given moment.

## Stage 2: Handling Client Requests (Diagram 2)

```
Client request: x=1

Processing workflow:
1. Leader appends "x=1" to the log (Log=[x=1])
2. Updates Term=1 (in some implementations, term updates upon receiving client requests)
3. Single node commits immediately (CommitIndex=1)
4. Applies to state machine (ApplyIndex=1, State={x:1})
```

![2. add value.svg](/images/9.%20raft/2.%20add%20value.svg)

This demonstrates RAFT's fundamental workflow: log append → replicate → commit → apply. In single-node scenarios, this process completes instantaneously.

## Stage 3: Nodes Joining the Cluster (Diagram 3)

```
Node2 and Node3 join as Followers:
- New nodes' initial state: Term=0, empty log, empty state machine
- Discover existing Leader through "join" operation
```

![3. add nodes.svg](/images/9.%20raft/3.%20add%20nodes.svg)

New nodes join in Follower state and require synchronization of historical data from the Leader. This demonstrates RAFT's dynamic membership change capability.

## Stage 4: Log Synchronization (Diagram 4)

```
Leader synchronization process:
1. Node1 sends AppendEntries RPC to Node2 and Node3
2. Contains historical log entry "x=1"
3. Followers update their state:
   - Term=1 (synchronize Leader's term)
   - Log=[x=1] (replicate log entry)
   - CommitIndex=1, ApplyIndex=1 (commit and apply)
   - State={x:1} (state machine synchronization)
```
![4. node sync.svg](/images/9.%20raft/4.%20node%20sync.svg)


This stage showcases RAFT's core mechanism: **log replication**. The Leader ensures all Followers maintain log consistency with itself.

## Stage 5: Cluster Expansion (Diagram 5)

```
Continue adding Node4 and Node5:
- New nodes complete joining and synchronization in one step via "join & rpc sync"
- Eventually forms a 5-node cluster with all nodes in consistent state
```

![5. add nodes.svg](/images/9.%20raft/5.%20add%20nodes.svg)

Clusters can expand dynamically, with new nodes automatically completing historical data synchronization upon joining.

## Stage 6: Batch Operations and Failures (Diagram 6 & 6-Result)

**Diagram 6 illustrates the problem scenario**:
```
Leader processes multiple client requests:
- x=2, y=1, y=2, update term
- Node1 state: Term=2, CommitIndex=4, State={x:2, y:2}
```

![6. add value & update term.svg](/images/9.%20raft/6.%20add%20value%20%26%20update%20term.svg)

**Diagram 6-Result shows recovery state**:
```
Leader continues operation:
- Node1 successfully synchronizes to Node2, Node4, Node5
- Node3 fails, maintaining old state (x=1)
- Cluster continues providing service with majority nodes functioning
```

![6. add value & update term - result.svg](/images/9.%20raft/6.%20add%20value%20%26%20update%20term%20-%20result.svg)

This demonstrates RAFT's **fault tolerance**: the cluster continues operating as long as a majority of nodes remain functional.

## Stage 7: Election Failure Scenario (Diagram 7)

```
Network partition occurs:
- Node1 becomes isolated (separate partition)
- Node3 attempts election but fails:
  - Updates Term=2, becomes Candidate
  - Cannot obtain majority votes (log too stale)

Partition state:
- Partition 1: Node1 (isolated old Leader)
- Partition 2: Node2, Node3, Node4, Node5 (no new Leader)
```

![7. vote fail.svg](/images/9.%20raft/7.%20vote%20fail.svg)

This illustrates RAFT's **network partition** handling mechanism: nodes with newer logs are more likely to become the new Leader.

## Stage 8: Election Within Partition (Diagram 8)

```
Node2 initiates election:
- Term=3, becomes Candidate
- Sends RequestVote RPC to Node4, Node5, Node3
- Even though Node3's log is behind, it can still vote for Node2
- Meanwhile, isolated Node1 continues receiving client request "x=9"
```

![8. fail but command.svg](/images/9.%20raft/8.%20fail%20but%20command.svg)

- The partitioned old Leader still processes requests, but these operations **will not be committed** due to inability to obtain majority confirmation.

## Stage 9: New Leader Established with Existing Partition (Diagram 9)

```
Node2 becomes the new Leader:
- Obtains sufficient votes, Term=3
- Begins synchronizing to other nodes
- Node1 and Node3 remain out of sync:
  - Node1: Has uncommitted "x=9", Term=2
  - Node3: Still contains old data, Term=1
```

![10. node2 new leader.svg](/images/9.%20raft/10.%20node2%20new%20leader.svg)

This proves RAFT's **partition tolerance**: even with some unreachable nodes, the majority can continue functioning normally.

## Stage 10: Conflict Detection (Diagram 10)

```
Node2 as the new Leader begins operation:
- Synchronizes to Node4 and Node5 (successful)
- Node1 and Node3 recovery
- Cluster continues running on available majority nodes
```

![9. fail node back.svg](/images/9.%20raft/9.%20fail%20node%20back.svg)

This state demonstrates the **split-brain** problem: the system contains both new and old Leader states.

## Stage 11: Partition Healing and Conflict Resolution (Diagram 11)

```
Final state after network partition repair:
- All nodes reconnect
- Node2 remains Leader, Term=3
- Conflict resolution process:
  1. Node1 discovers higher term, steps down to Follower
  2. Node1's uncommitted operation "x=9" is discarded (log truncation)
  3. Node3 synchronizes to latest state
  4. All nodes eventually consistent: State={x:2, y:2}

Data loss: x=9 permanently lost as it was never majority-confirmed
```

![11. sync & abandon.svg](/images/9.%20raft/11.%20sync%20%26%20abandon.svg)

This represents the classic **log conflict** resolution scenario in RAFT:
- Higher term Leaders are authoritative
- Operations not confirmed by majority are discarded
- All nodes eventually achieve strong consistency

## Key Characteristics Analysis of RAFT Algorithm

Through these 11 diagrams, we can summarize the important characteristics of RAFT:

**1. Strong Consistency**
- All nodes eventually reach identical states
- Data reliability ensured through majority commit

**2. Partition Tolerance**
- During network partitions, majority partition continues service
- Minority partition cannot handle write operations

**3. Leader Election**
- At most one Leader at any given time
- Latest nodes elected through term and log comparison

**4. Log Replication**
- Leader replicates logs to all Followers
- Ensures log ordering and consistency

**5. Failure Recovery**
- Nodes can automatically synchronize after rejoining from failure
- Conflicting logs are correctly overwritten

## Practical Application Considerations

**Performance Characteristics**:
- Write operations require majority confirmation, resulting in higher latency
- Read operations can be performed from Leader or Followers
- Network partitions affect availability

**Suitable Use Cases**:
- Configuration management systems (such as etcd)
- Distributed databases (such as TiKV)
- Distributed lock services

**Important Considerations**:
- Odd-numbered node clusters are preferable (avoid split-brain)
- Network quality significantly impacts performance
- Need to consider safety of membership changes

## Conclusion

The RAFT algorithm elegantly solves distributed consensus problems through clear role separation and simple rules. This article comprehensively demonstrates the progression from single-node to complex failure scenarios through 11 progressive diagrams. Understanding these scenarios is crucial for designing and implementing reliable distributed systems.

RAFT's success lies in its **understandability**: compared to Paxos's complex proofs, RAFT employs intuitive concepts (terms, elections, log replication) that enable developers to truly comprehend and correctly implement distributed consistency systems.
