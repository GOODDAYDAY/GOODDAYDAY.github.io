+++
date = '2025-09-27T19:02:17+08:00'
draft = false
title = '[MySQL] 2. Lock Mechanism Execution Analysis'
categories = ["MySQL"]
tags = ["MySQL", "Lock"]
+++

# [MySQL] 2. Lock Mechanism Execution Analysis

## Introduction

In high-concurrency environments, database locking mechanisms are crucial for ensuring data consistency and integrity. MySQL, as a widely-used relational database, provides various lock types and mechanisms to manage concurrent access. However, improper use of locks may lead to performance bottlenecks, deadlocks, and other issues that affect system stability and response time.

## Basic Lock-Related Concepts

- **Lock Definition**: A lock is a mechanism used to control access to shared resources, preventing multiple transactions from modifying the same data simultaneously, thereby ensuring data consistency and integrity.
- **Lock Types**:
  - **Table-level Lock**: Locks the entire table.
  - **Shared Lock (S Lock)**: Allows multiple transactions to read data simultaneously but prevents modification.
  - **Exclusive Lock (X Lock)**: Allows one transaction to modify data while preventing other transactions from reading or modifying.
  - **Intention Locks (IS and IX Locks)**: Used at the table level to indicate that a transaction intends to acquire locks at the row level.
  - **Auto-increment Lock (AUTO-INC Lock)**: Used to handle concurrent inserts on auto-increment columns, preventing conflicts.
  - **Gap Lock**: Locks the gaps between index records to prevent phantom reads.
  - **Next-Key Lock**: Combines record locks and gap locks, locking index records and the gaps before them.
  - **Record Lock**: Locks specific index records.
  - **Row-level Lock**: Locks specific rows.
  - **Optimistic Lock**: Implemented through version numbers or timestamps, suitable for read-heavy scenarios.
  - **Pessimistic Lock**: Implemented through explicit locking, suitable for write-heavy scenarios.
- **Deadlock**: Multiple transactions wait for each other to release locks, resulting in inability to continue execution.
- **Lock Compatibility**: Compatibility rules exist between different types of locks, determining which locks can coexist.
- **Lock Granularity**: The scope of locked resources; finer granularity provides higher system concurrency but increases management overhead.

## MySQL Lock Introduction

### Basic Commands

- Create test table

```sql
-- auto-generated definition
create table example_single_pk
(
    id      bigint                              not null comment 'id'
        primary key,
    created timestamp default CURRENT_TIMESTAMP not null comment 'create time',
    updated timestamp default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment 'update time'
)
    comment 'example_single_pk' charset = utf8mb4;
```

- Execute commands

```sql
SELECT id, created, updated FROM example_single_pk;

INSERT INTO example_single_pk (id) VALUES (1);

SELECT id, created, updated FROM example_single_pk;

UPDATE example_single_pk SET id = 6 WHERE id = 1;

SELECT id, created, updated FROM example_single_pk;

DELETE FROM example_single_pk WHERE id = 1 or id = 6;

SELECT id, created, updated FROM example_single_pk;
```

- Results

```sql
mysql> SELECT id, created, updated FROM example_single_pk;
Empty set (0.00 sec)

mysql>
mysql> INSERT INTO example_single_pk (id) VALUES (1);
Query OK, 1 row affected (0.00 sec)

mysql>
mysql> SELECT id, created, updated FROM example_single_pk;
+----+---------------------+---------------------+
| id | created             | updated             |
+----+---------------------+---------------------+
|  1 | 2025-09-27 11:14:40 | 2025-09-27 11:14:40 |
+----+---------------------+---------------------+
1 row in set (0.00 sec)

mysql>
mysql> UPDATE example_single_pk SET id = 6 WHERE id = 1;
Query OK, 1 row affected (0.00 sec)
Rows matched: 1  Changed: 1  Warnings: 0

mysql>
mysql> SELECT id, created, updated FROM example_single_pk;
+----+---------------------+---------------------+
| id | created             | updated             |
+----+---------------------+---------------------+
|  6 | 2025-09-27 11:14:40 | 2025-09-27 11:14:40 |
+----+---------------------+---------------------+
1 row in set (0.00 sec)

mysql>
mysql> DELETE FROM example_single_pk WHERE id = 1 or id = 6;
Query OK, 1 row affected (0.00 sec)

mysql>
mysql> SELECT id, created, updated FROM example_single_pk;
Empty set (0.00 sec)
```

### Classification by Granularity

#### Table-level Lock - READ

##### **Locking**

```sql
mysql> LOCK TABLES example_single_pk READ;
Query OK, 0 rows affected (0.00 sec)
```

![1. lock tables read.png](/images/12.%20mysql%20lock/1.1%20lock%20tables%20read.png)

- At this point, other sessions can read data but cannot perform write operations.

##### **Unlocking**

```sql
mysql> UNLOCK tables;
Query OK, 0 rows affected (0.00 sec)
```

![1.2 unlock tables read.png](/images/12.%20mysql%20lock/1.2%20unlock%20tables%20read.png)

- As can be seen, other sessions can read normally but `cannot` write data.

#### Table-level Lock - WRITE

##### **Locking**

```sql
mysql> LOCK TABLES example_single_pk WRITE;
Query OK, 0 rows affected (0.00 sec)
```

![2.1 lock tables write.png](/images/12.%20mysql%20lock/2.1%20lock%20tables%20write.png)

##### **Unlocking**

```sql
mysql> UNLOCK tables;
Query OK, 0 rows affected (0.00 sec)
```

![2.2 unlock tables write.png](/images/12.%20mysql%20lock/2.2%20unlock%20tables%20write.png)

- As can be seen, other sessions can neither read `nor` write data.
- Overall, table-level locks have larger granularity, suitable for scenarios involving bulk operations on entire tables, but they affect concurrency performance.
- Not recommended for use.

#### Row-level Lock - SELECT ... FOR SHARE

##### **Locking**

```sql
mysql> start transaction;
Query OK, 0 rows affected (0.00 sec)

mysql> SELECT * FROM example_single_pk WHERE id = 1 FOR SHARE;
Empty set (0.00 sec)
```

![3.1 select for share.png](/images/12.%20mysql%20lock/3.1%20select%20for%20share.png)

- At this point, it affects locks within other sessions.
- Other sessions can read data but cannot perform write operations. We won't elaborate further or take screenshots.

##### **Unlocking**

```sql
mysql> COMMIT;
Query OK, 0 rows affected (0.00 sec)
```

![3.2 select for share commit.png](/images/12.%20mysql%20lock/3.2%20select%20for%20share%20commit.png)

- After unlocking, read locks and write locks can be acquired normally.

#### Row-level Lock - SELECT ... FOR UPDATE

##### **Locking**

```sql
mysql> start transaction;
Query OK, 0 rows affected (0.00 sec)

mysql> SELECT * FROM example_single_pk WHERE id = 1 FOR UPDATE;
Empty set (0.00 sec)
```

![4.1 select for update.png](/images/12.%20mysql%20lock/4.1%20select%20for%20update.png)

- From the data query perspective, there's no difference from `FOR SHARE`, as it affects locks within other sessions.
- `FOR UPDATE` locks the selected rows, preventing other transactions from reading or modifying these rows.

##### **Unlocking**

```sql
mysql> COMMIT;
Query OK, 0 rows affected (0.00 sec)
```

![4.2 select for update commit.png](/images/12.%20mysql%20lock/4.2%20select%20for%20update%20commit.png)

- After unlocking, read locks and write locks can be acquired normally.

### Classification by Attributes

#### Shared Locks & Exclusive Locks

| No. | Lock Name | Trigger Method | Lock Type | Scope | Key Features |
|----|-----------|----------------|-----------|-------|-------------|
| 1 | Table-level Shared Lock (S Lock) | LOCK TABLES tbl_name READ | Server layer lock | Entire table | Allows other sessions to read, blocks writes; requires manual UNLOCK TABLES. |
| 2 | Table-level Exclusive Lock (X Lock) | LOCK TABLES tbl_name WRITE | Server layer lock | Entire table | Blocks other sessions from reading/writing; requires manual UNLOCK TABLES. |
| 3 | Row-level Shared Lock (S Lock) | SELECT ... FOR SHARE (within transaction) | InnoDB row lock | Single row | Allows other sessions to read the row, blocks writes; auto-unlocked after transaction commit/rollback. |
| 4 | Row-level Exclusive Lock (X Lock) | SELECT ... FOR UPDATE (within transaction) | InnoDB row lock | Single row | Blocks other sessions from reading/writing the row; auto-unlocked after transaction commit/rollback. |

#### Auto-increment Lock (AUTO-INC Lock)
- **Trigger Method**: Automatically triggered when `INSERT` statements operate on AUTO_INCREMENT columns
- **Features**: AUTO-INC lock ensures continuity and uniqueness of auto-increment values. Different from row locks, but behavior results are similar.

![5.1 auto inc double insert success.png](/images/12.%20mysql%20lock/5.1%20auto%20inc%20double%20insert%20success.png)

- As can be seen, there's no conflict between auto-increment locks, and both sessions successfully insert data.

![5.2 auto inc double insert same id.png](/images/12.%20mysql%20lock/5.2%20auto%20inc%20double%20insert%20same%20id.png)

- Obviously, when the ID is determined, the behavior becomes similar to row locks, and the second session fails to insert.

![5.3 auto inc double insert same id fail.png](/images/12.%20mysql%20lock/5.3%20auto%20inc%20double%20insert%20same%20id%20fail.png)

- After commit, we can see that data insertion failed due to ID conflict.

#### Intention Lock

Intention locks are server-level table locks designed by the InnoDB storage engine to coordinate conflicts between "server layer (MySQL main process) table locks" and "storage engine layer row locks". Their core purpose is to transmit the signal "row locks exist in the storage engine", allowing the server layer to quickly determine compatibility between table locks and row locks, avoiding high-cost conflict detection. The following explains from the perspectives of hierarchical positioning, design goals, linkage mechanisms, and lightweight reasons:

Intention locks serve as "row lock signal lights" at the server layer—using minimal overhead of table-level locks to transmit row lock status from the storage engine, enabling efficient coordination between two-layer lock mechanisms, both correctly and performantly.

##### Hierarchical Positioning: Server Layer's "Row Lock Signal Officer"

• **Server Layer**: MySQL main process manages server-level locks (such as LOCK TABLES), which is a native lock mechanism independent of storage engines.

• **Storage Engine Layer**: InnoDB manages row-level locks (such as X locks from SELECT ... FOR UPDATE), controlling access to specific data rows.

• **Role of Intention Locks**: Intention locks belong to server layer table locks, but they don't directly control data rows—instead, they act as "translators", converting row lock status in the storage engine ("transactions are operating on certain rows") into "signals" understandable by the server layer (table-level IS/IX locks).

##### Core Design Goal: Solving "Information Gap" in Layered Architecture

**MySQL's layered architecture (server layer vs storage engine layer) naturally isolates lock status:**

• When the server layer wants to add table locks, it cannot directly perceive whether there are row locks in the storage engine (e.g., transaction A has locked certain rows);

• Row locks in the storage engine also don't care whether there are table locks at the server layer.

Without intention locks, when the server layer adds table locks, it must traverse all rows in the storage engine (O(n) time complexity) to check for row lock conflicts—this would be catastrophic performance loss for large tables.

**The emergence of intention locks optimizes this "traversal check" to O(1) signal judgment:**

• When the storage engine adds row locks, it automatically registers corresponding intention locks with the server layer (IS=row read intention, IX=row write intention);

• When the server layer adds table locks, it only needs to check table-level intention lock status to immediately determine conflicts.

##### Linkage Mechanism with Row Locks/Table Locks

**The lifecycle of intention locks is completely dependent on row locks, serving as "shadows" of row locks:**

• Row locks trigger intention locks: When a transaction adds row locks (S/X) to certain rows, the InnoDB engine automatically notifies the server layer to add corresponding intention locks (IS or IX) at the table level.

• Example: SELECT * FROM t WHERE id=1 FOR UPDATE (adds row X lock) → Server layer adds table-level IX lock (intention exclusive lock).

• Table locks check intention locks: When a transaction tries to add server layer table locks, the server layer checks table-level intention locks:

• If there's an IX lock (intention exclusive lock) at table level, it indicates row locks are active in the storage engine, and table locks (such as LOCK TABLES ... WRITE) will be blocked;

• If there's an IS lock (intention shared lock) at table level, it indicates row read locks exist in the storage engine, table read locks (LOCK TABLES ... READ) are compatible, but table write locks are still blocked.

##### Why Are Intention Locks "Lightweight"?

**The "lightweight" nature of intention locks stems from their minimal state space and automatic synchronization mechanism:**

• Limited lock scope: Only locks the concept of "entire table" (table level), doesn't involve specific data rows, no need to maintain lock status for each row (such as heap_no or trx_id in row locks).

• Extremely simple state: Only needs to record two "intentions"—IS (transactions want to read rows), IX (transactions want to write rows), logical complexity far lower than row locks.

• Automatic synchronization: Automatically triggered by InnoDB engine when adding/releasing row locks, no manual management required, no additional human or system overhead.

##### Value Summary: Trading Minimal Overhead for Maximum Correctness

**The essence of intention locks is using "lightweight state" of table-level locks to connect lock mechanisms between server layer and storage engine layer:**

• For server layer: Quickly determine whether table locks conflict with row locks, avoiding high cost of traversing all rows;

• For storage engine: No need to care about server layer table locks, focus on managing row locks;

• For overall concurrency: Ensures data consistency (avoiding conflicts between table locks and row locks) while maintaining high concurrency performance.

### Classification by Algorithm (InnoDB Engine)

**1. Record Lock**

**2. Gap Lock**

**3. Next-key Lock**

#### Practical Operation Instructions

| Operation Type | Common Scenario | Lock Type | Lock Range | Isolation Level Dependency | Main Conflict Objects | Notes |
|---|---|---|---|---|---|---|
| SELECT | Normal query (without FOR UPDATE/SHARE) | No lock | None | None | None | Read without lock (snapshot read) |
| SELECT FOR UPDATE | Equality query (record exists) | Record lock (LOCK_REC_NOT_GAP) | Specific record (e.g., id=3) | RR/RC | Record locks and next-key locks on same record | Locks target row, blocks modification/deletion |
| SELECT FOR UPDATE | Equality query (record doesn't exist, RR) | Gap lock (LOCK_GAP) | Gap between adjacent records (e.g., (1,5)) | RR | Gap locks and insert intention locks in same gap | Prevents other transactions from inserting missing records (phantom read) |
| SELECT FOR UPDATE | Equality query (record doesn't exist, RC) | No lock | None | RC | None | RC has no gap locks, only read without lock |
| SELECT FOR UPDATE | Range query (e.g., id>2, RR) | Next-key lock (LOCK_NEXT_KEY) | Record+predecessor gap (e.g., (3,3], (3,5]) | RR | Record locks and gap locks on same record | Locks all records and gaps in range (prevents phantom read) |
| SELECT FOR UPDATE | Range query (e.g., id>2, RC) | Record lock | Records meeting conditions (e.g., id=3,5) | RC | Record locks on same record | RC has no gap locks, only locks existing records |
| INSERT | Insert new record (any scenario) | Insert intention lock (LOCK_INSERT_INTENTION) | Gap between adjacent records (e.g., (1,5)) | None (always added) | Normal gap locks and record locks in same gap | Coordinates insert exclusion, conflicts with normal locks |
| DELETE | Equality deletion (record exists) | Record lock (LOCK_REC_NOT_GAP) | Specific record (e.g., id=3) | RR/RC | Record locks and next-key locks on same record | Locks target row, blocks modification/insertion |
| DELETE | Range deletion (e.g., id>2, RR) | Next-key lock (LOCK_NEXT_KEY) | Record+predecessor gap (e.g., (3,3], (3,5]) | RR | Record locks and gap locks on same record | Locks all records and gaps in range (prevents phantom read) |
| DELETE | Range deletion (e.g., id>2, RC) | Record lock | Records meeting conditions (e.g., id=3,5) | RC | Record locks on same record | RC has no gap locks, only locks existing records |
| UPDATE | Equality update (record exists) | Record lock (LOCK_REC_NOT_GAP) | Specific record (e.g., id=3) | RR/RC | Record locks and next-key locks on same record | Locks target row, blocks modification/insertion |
| UPDATE | Range update (e.g., id>2, RR) | Next-key lock (LOCK_NEXT_KEY) | Record+predecessor gap (e.g., (3,3], (3,5]) | RR | Record locks and gap locks on same record | Locks all records and gaps in range (prevents phantom read) |
| UPDATE | Range update (e.g., id>2, RC) | Record lock | Records meeting conditions (e.g., id=3,5) | RC | Record locks on same record | RC has no gap locks, only locks existing records |

##### INSERT

- Insert operations use `insert intention locks`

###### insert into -1

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|:----:|---|---|
| 0.0 | | SESSION 2 START - Waiting for Session1... |
| 0.3 | SESSION 1 START - INSERT | === Round 0: Testing SELECT & INSERT === |
| ~ | mysql> SELECT * FROM example_single_pk | |
| ~ | (1, '2025-09-27 11:22:48', '2025-09-27 11:22:48') | |
| ~ | (4, '2025-09-27 11:22:48', '2025-09-27 11:22:48') | |
| ~ | (5, '2025-09-27 11:22:48', '2025-09-27 11:22:48') | |
| ~ | 3 rows (0.03s) | |
| ~ | === Round -1: Testing INSERT ID=-1 === | |
| ~ | mysql> start transaction | |
| ~ | Query OK, 0 rows affected | |
| ~ | mysql> INSERT INTO example_single_pk (id) VALUES (-1) | |
| ~ | Query OK, 1 row affected (0.03s) | |

- Session 1 inserts a record with ID=-1 and keeps the transaction uncommitted, holding an `insert intention lock`.

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|:----:|---|---|
| 0.7 | | mysql> SELECT * FROM example_single_pk WHERE id = -1 FOR UPDATE |
| 3.7 | | ERROR: SELECT `timeout` (3.04s) (3.04s) |
| 4.1 | | mysql> INSERT INTO example_single_pk (id) VALUES (-1) |
| 7.1 | | ERROR: INSERT `timeout` (3.03s) (3.03s) |

- Session 2 queries the record with ID=-1, finds that the record exists but is held by Session 1's `insert intention lock`, causing the query to block waiting for lock release, ultimately timing out and failing.
- Session 2 attempts to insert a record with ID=-1, also failing due to conflict timeout.

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|:----:|---|---|
| 7.4 | | mysql> SELECT * FROM example_single_pk WHERE id = 0 FOR UPDATE |
| 7.5 | | SELECT returned 0 rows (0.03s) |
| 7.7 | | mysql> INSERT INTO example_single_pk (id) VALUES (0) |
| ~ | | INSERT success (0.02s) |
| 8.0 | | mysql> SELECT * FROM example_single_pk WHERE id = 1 FOR UPDATE |
| 8.1 | | SELECT returned 1 rows (0.03s) |
| ~ | | (1, '2025-09-27 11:22:48', '2025-09-27 11:22:48') |
| 8.4 | | mysql> INSERT INTO example_single_pk (id) VALUES (1) |
| ~ | | ERROR: INSERT duplicate (0.03s) (0.03s) |
| 8.7 | | mysql> SELECT * FROM example_single_pk WHERE id = 2 FOR UPDATE |
| ~ | | SELECT returned 0 rows (0.03s) |
| 9.1 | | mysql> INSERT INTO example_single_pk (id) VALUES (2) |
| ~ | | INSERT success (0.03s) |
| 9.4 | | mysql> SELECT * FROM example_single_pk WHERE id = 3 FOR UPDATE |
| ~ | | SELECT returned 0 rows (0.03s) |
| 9.7 | | mysql> INSERT INTO example_single_pk (id) VALUES (3) |
| ~ | | INSERT success (0.03s) |
| 10.1 | | mysql> SELECT * FROM example_single_pk WHERE id = 4 FOR UPDATE |
| ~ | | SELECT returned 1 rows (0.03s) |
| ~ | | (4, '2025-09-27 11:22:48', '2025-09-27 11:22:48') |
| 10.4 | | mysql> INSERT INTO example_single_pk (id) VALUES (4) |
| ~ | | ERROR: INSERT duplicate (0.03s) (0.03s) |
| 10.8 | | mysql> SELECT * FROM example_single_pk WHERE id = 5 FOR UPDATE |
| ~ | | SELECT returned 1 rows (0.02s) |
| ~ | | (5, '2025-09-27 11:22:48', '2025-09-27 11:22:48') |
| 11.1 | | mysql> INSERT INTO example_single_pk (id) VALUES (5) |
| ~ | | ERROR: INSERT duplicate (0.03s) (0.03s) |
| 11.5 | | mysql> SELECT * FROM example_single_pk WHERE id = 6 FOR UPDATE |
| ~ | | SELECT returned 0 rows (0.03s) |
| 11.9 | | mysql> INSERT INTO example_single_pk (id) VALUES (6) |
| ~ | | INSERT success (0.06s) |
| 12.3 | | mysql> SELECT * FROM example_single_pk WHERE id = 7 FOR UPDATE |
| ~ | | SELECT returned 0 rows (0.04s) |
| 12.6 | | mysql> INSERT INTO example_single_pk (id) VALUES (7) |
| ~ | | INSERT success (0.03s) |
| 12.7 | mysql> rollback | |
| ~ | Query OK, 0 rows affected | |

- Subsequent operations proceed without issues.

###### insert into 0

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|:----:|---|---|
| 12.9 | === Round 0: Testing INSERT ID=0 === | |
| ~ | mysql> start transaction | |
| ~ | Query OK, 0 rows affected | |
| 13.0 | mysql> INSERT INTO example_single_pk (id) VALUES (0) | === Round 1: Testing SELECT & INSERT === |
| ~ | Query OK, 1 row affected (0.02s) | |

- Session 1 inserts a record with ID=0 and keeps the transaction uncommitted, holding an `insert intention lock`.

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|:----:|---|---|
| 13.2 | | mysql> SELECT * FROM example_single_pk WHERE id = -1 FOR UPDATE |
| 13.3 | | SELECT returned 0 rows (0.03s) |
| 13.5 | | mysql> INSERT INTO example_single_pk (id) VALUES (-1) |
| 13.6 | | INSERT success (0.03s) |
| 13.8 | | mysql> SELECT * FROM example_single_pk WHERE id = 0 FOR UPDATE |
| 16.9 | | ERROR: SELECT `timeout` (3.04s) (3.04s) |
| 17.1 | | mysql> INSERT INTO example_single_pk (id) VALUES (0) |
| 20.2 | | ERROR: INSERT `timeout` (3.04s) (3.04s) |

- Session 2 queries the record with ID=0, finds that the record exists but is held by Session 1's `insert intention lock`, causing the query to block waiting for lock release, ultimately timing out and failing.
- Session 2 attempts to insert a record with ID=0, also failing due to conflict timeout.
- Subsequent operations follow the same pattern and won't be elaborated further.

##### SELECT FOR UPDATE

###### select for update -1

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|------|---|---|
| 0.0 | | SESSION 2 START - Waiting for Session1... |
| 0.3 | SESSION 1 START - SELECT_FOR_UPDATE | |
| ~ | mysql> SELECT * FROM example_single_pk | |
| ~ | (1, '2025-09-27 11:22:48', '2025-09-27 11:22:48') | |
| ~ | (4, '2025-09-27 11:22:48', '2025-09-27 11:22:48') | |
| ~ | (5, '2025-09-27 11:22:48', '2025-09-27 11:22:48') | |
| ~ | 3 rows (0.03s) | |
| ~ | === Round -1: Testing SELECT_FOR_UPDATE ID=-1 === | |
| ~ | mysql> start transaction | |
| ~ | Query OK, 0 rows affected | |
| 0.4 | mysql> SELECT * FROM example_single_pk WHERE id = -1 FOR UPDATE | === Round 0: Testing SELECT & INSERT === |
| ~ | Query returned 0 rows (0.03s) | |

- Database contains data with ID=1,4,5
- Session1 performs `SELECT FOR UPDATE` for ID=-1, holding a `gap lock` for the range [-∞, 1) where no records exist, locking the gap [-∞, 1) to prevent other transactions from inserting records within this range.

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|------|---|---|
| 0.7 | | mysql> SELECT * FROM example_single_pk WHERE id = -1 FOR UPDATE |
| 0.8 | | SELECT returned 0 rows (0.03s) |
| 1.1 | | mysql> INSERT INTO example_single_pk (id) VALUES (-1) |
| 4.1 | | ERROR: INSERT `timeout` (3.03s) (3.03s) |
| 4.4 | | mysql> SELECT * FROM example_single_pk WHERE id = 0 FOR UPDATE |
| ~ | | SELECT returned 0 rows (0.03s) |
| 4.7 | | mysql> INSERT INTO example_single_pk (id) VALUES (0) |
| 7.7 | | ERROR: INSERT `timeout` (3.03s) (3.03s) |

###### select for update 0

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|------|---|---|
| 12.9 | === Round 0: Testing SELECT_FOR_UPDATE ID=0 === | === Round 1: Testing SELECT & INSERT === |
| ~ | mysql> start transaction | |
| ~ | Query OK, 0 rows affected | |
| ~ | mysql> SELECT * FROM example_single_pk WHERE id = 0 FOR UPDATE | |
| ~ | Query returned 0 rows (0.03s) | |

- Session1 performs `SELECT FOR UPDATE` for ID=0, holding a `gap lock` for the range [-∞, 1) where no records exist, locking the gap [-∞, 1) to prevent other transactions from inserting records within this range.

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|------|---|---|
| 13.2 | | mysql> SELECT * FROM example_single_pk WHERE id = -1 FOR UPDATE |
| ~ | | SELECT returned 0 rows (0.03s) |
| 13.6 | | mysql> INSERT INTO example_single_pk (id) VALUES (-1) |
| 16.6 | | ERROR: INSERT `timeout` (3.03s) (3.03s) |
| 16.9 | | mysql> SELECT * FROM example_single_pk WHERE id = 0 FOR UPDATE |
| ~ | | SELECT returned 0 rows (0.03s) |
| 17.2 | | mysql> INSERT INTO example_single_pk (id) VALUES (0) |
| 20.2 | | ERROR: INSERT `timeout` (3.03s) (3.03s) |

###### select for update 1

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|------|---|---|
| 25.3 | === Round 1: Testing SELECT_FOR_UPDATE ID=1 === | |
| ~ | mysql> start transaction | |
| ~ | Query OK, 0 rows affected | |
| 25.4 | mysql> SELECT * FROM example_single_pk WHERE id = 1 FOR UPDATE | === Round 2: Testing SELECT & INSERT === |
| ~ | Query returned 1 rows (0.02s) | |
| ~ | (1, '2025-09-27 11:22:48', '2025-09-27 11:22:48') | |

- Session1 performs `SELECT FOR UPDATE` for ID=1, holding a `record lock` on ID=1, preventing other transactions from modifying or deleting this record.

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|------|---|---|
| 27.3 | | mysql> SELECT * FROM example_single_pk WHERE id = 1 FOR UPDATE |
| 30.4 | | ERROR: SELECT `timeout` (3.05s) (3.05s) |
| 30.7 | | mysql> INSERT INTO example_single_pk (id) VALUES (1) |
| 33.7 | | ERROR: INSERT `timeout` (3.03s) (3.03s) |

###### select for update 2

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|------|---|---|
| 38.5 | === Round 2: Testing SELECT_FOR_UPDATE ID=2 === | |
| ~ | mysql> start transaction | |
| ~ | Query OK, 0 rows affected | |
| 38.6 | mysql> SELECT * FROM example_single_pk WHERE id = 2 FOR UPDATE | === Round 3: Testing SELECT & INSERT === |
| ~ | Query returned 0 rows (0.05s) | |

- Session1 performs `SELECT FOR UPDATE` for ID=2, holding a `gap lock` for the range (1,4) where no records exist, locking the gap (1,4) to prevent other transactions from inserting records within this range.

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|------|---|---|
| 41.0 | | mysql> SELECT * FROM example_single_pk WHERE id = 2 FOR UPDATE |
| 41.1 | | SELECT returned 0 rows (0.04s) |
| 41.3 | | mysql> INSERT INTO example_single_pk (id) VALUES (2) |
| 44.4 | | ERROR: INSERT `timeout` (3.04s) (3.04s) |
| 44.7 | | mysql> SELECT * FROM example_single_pk WHERE id = 3 FOR UPDATE |
| ~ | | SELECT returned 0 rows (0.03s) |
| 45.0 | | mysql> INSERT INTO example_single_pk (id) VALUES (3) |
| 48.0 | | ERROR: INSERT `timeout` (3.03s) (3.03s) |

###### select for update 3

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|------|---|---|
| 51.2 | === Round 3: Testing SELECT_FOR_UPDATE ID=3 === | === Round 4: Testing SELECT & INSERT === |
| ~ | mysql> start transaction | |
| ~ | Query OK, 0 rows affected | |
| ~ | mysql> SELECT * FROM example_single_pk WHERE id = 3 FOR UPDATE | |
| ~ | Query returned 0 rows (0.03s) | |

- Session1 performs `SELECT FOR UPDATE` for ID=3, holding a `gap lock` for the range (1,4) where no records exist, locking the gap (1,4) to prevent other transactions from inserting records within this range.

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|------|---|---|
| 53.5 | | mysql> SELECT * FROM example_single_pk WHERE id = 2 FOR UPDATE |
| ~ | | SELECT returned 0 rows (0.03s) |
| 53.8 | | mysql> INSERT INTO example_single_pk (id) VALUES (2) |
| 56.9 | | ERROR: INSERT `timeout` (3.03s) (3.03s) |
| 57.2 | | mysql> SELECT * FROM example_single_pk WHERE id = 3 FOR UPDATE |
| ~ | | SELECT returned 0 rows (0.03s) |
| 57.5 | | mysql> INSERT INTO example_single_pk (id) VALUES (3) |
| 60.5 | | ERROR: INSERT `timeout` (3.03s) (3.03s) |

###### select for update 4

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|------|---|---|
| 63.6 | === Round 4: Testing SELECT_FOR_UPDATE ID=4 === | === Round 5: Testing SELECT & INSERT === |
| ~ | mysql> start transaction | |
| ~ | Query OK, 0 rows affected | |
| ~ | mysql> SELECT * FROM example_single_pk WHERE id = 4 FOR UPDATE | |
| ~ | Query returned 1 rows (0.03s) | |
| ~ | (4, '2025-09-27 11:22:48', '2025-09-27 11:22:48') | |

- Session1 performs `SELECT FOR UPDATE` for ID=4, holding a `record lock` on ID=4, preventing other transactions from modifying or deleting this record.

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|------|---|---|
| 67.4 | | mysql> SELECT * FROM example_single_pk WHERE id = 4 FOR UPDATE |
| 70.4 | | ERROR: SELECT `timeout` (3.03s) (3.03s) |
| 70.7 | | mysql> INSERT INTO example_single_pk (id) VALUES (4) |
| 73.8 | | ERROR: INSERT `timeout` (3.03s) (3.03s) |

###### select for update 5

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|------|---|---|
| ~ | Query OK, 0 rows affected | |
| 76.2 | === Round 5: Testing SELECT_FOR_UPDATE ID=5 === | |
| ~ | mysql> start transaction | |
| ~ | Query OK, 0 rows affected | |
| 76.3 | mysql> SELECT * FROM example_single_pk WHERE id = 5 FOR UPDATE | === Round 6: Testing SELECT & INSERT === |
| ~ | Query returned 1 rows (0.02s) | |
| ~ | (5, '2025-09-27 11:22:48', '2025-09-27 11:22:48') | |

- Session1 performs `SELECT FOR UPDATE` for ID=5, holding a `record lock` on ID=5, preventing other transactions from modifying or deleting this record.

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|------|---|---|
| 80.9 | | mysql> SELECT * FROM example_single_pk WHERE id = 5 FOR UPDATE |
| 84.0 | | ERROR: SELECT `timeout` (3.03s) (3.03s) |
| 84.3 | | mysql> INSERT INTO example_single_pk (id) VALUES (5) |
| 87.3 | | ERROR: INSERT `timeout` (3.03s) (3.03s) |

###### select for update 6

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|------|---|---|
| 89.0 | === Round 6: Testing SELECT_FOR_UPDATE ID=6 === | === Round 7: Testing SELECT & INSERT === |
| ~ | mysql> start transaction | |
| ~ | Query OK, 0 rows affected | |
| ~ | mysql> SELECT * FROM example_single_pk WHERE id = 6 FOR UPDATE | |
| ~ | Query returned 0 rows (0.04s) | |

- Session1 performs `SELECT FOR UPDATE` for ID=6, holding a `gap lock` for the range [6, ∞) where no records exist, locking the gap [6, ∞) to prevent other transactions from inserting records within this range.

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|------|---|---|
| 94.6 | | mysql> INSERT INTO example_single_pk (id) VALUES (6) |
| 97.7 | | ERROR: INSERT `timeout` (3.03s) (3.03s) |
| 97.9 | | mysql> SELECT * FROM example_single_pk WHERE id = 7 FOR UPDATE |
| 98.0 | | SELECT returned 0 rows (0.03s) |
| 98.3 | | mysql> INSERT INTO example_single_pk (id) VALUES (7) |
| 101.4 | mysql> rollback | ERROR: INSERT `timeout` (3.03s) (3.03s) |

##### SELECT FOR UPDATE RANGE

###### SELECT FOR UPDATE RANGE [-1, 1)

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|:----:|---|---|
| 0.0 | | SESSION 2 START - Waiting for Session1... |
| 0.2 | SESSION 1 START - SELECT_FOR_UPDATE_RANGE | |
| 0.3 | mysql> SELECT * FROM example_single_pk | === Round 0: Testing SELECT & INSERT === |
| ~ | (1, '2025-09-27 11:22:48', '2025-09-27 11:22:48') | |
| ~ | (4, '2025-09-27 11:22:48', '2025-09-27 11:22:48') | |
| ~ | (5, '2025-09-27 11:22:48', '2025-09-27 11:22:48') | |
| ~ | 3 rows (0.03s) | |
| ~ | === Round -1: Testing SELECT_FOR_UPDATE_RANGE ID=-1 === | |
| ~ | mysql> start transaction | |
| ~ | Query OK, 0 rows affected | |
| ~ | mysql> SELECT * FROM example_single_pk WHERE id >= -1 AND id < 1 FOR UPDATE | |
| ~ | Range query returned 0 rows (0.03s) | |

- Database contains data with ID=1,4,5
- Session1 performs `SELECT FOR UPDATE` on range [-1, 1), holding a `gap lock` for the range [-∞, 1) where no records exist, locking the gap [-∞, 1) to prevent other transactions from inserting records within this range.

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|:----:|---|---|
| 0.6 | | mysql> SELECT * FROM example_single_pk WHERE id = -1 FOR UPDATE |
| 0.7 | | SELECT returned 0 rows (0.03s) |
| 1.0 | | mysql> INSERT INTO example_single_pk (id) VALUES (-1) |
| 4.1 | | ERROR: INSERT `timeout` (3.04s) (3.04s) |
| 4.4 | | mysql> SELECT * FROM example_single_pk WHERE id = 0 FOR UPDATE |
| ~ | | SELECT returned 0 rows (0.03s) |
| 4.8 | | mysql> INSERT INTO example_single_pk (id) VALUES (0) |
| 7.8 | | ERROR: INSERT `timeout` (3.03s) (3.03s) |

- `Gap lock` for the range [-∞, 1) where no records exist, locking the gap [-∞, 1) to prevent other transactions from inserting records within this range.
- Session2's query operations for ID=-1 and ID=0 are not blocked because they share the same `gap lock`.
- Session2's insert operations for ID=-1 and ID=0 are blocked.

###### SELECT FOR UPDATE RANGE [0, 2)

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|:----:|---|---|
| 12.9 | === Round 0: Testing SELECT_FOR_UPDATE_RANGE ID=0 === | |
| ~ | mysql> start transaction | |
| ~ | Query OK, 0 rows affected | |
| 13.0 | mysql> SELECT * FROM example_single_pk WHERE id >= 0 AND id < 2 FOR UPDATE | === Round 1: Testing SELECT & INSERT === |
| ~ | Range query returned 1 rows (0.02s) | |
| ~ | (1, '2025-09-27 11:22:48', '2025-09-27 11:22:48') | |

- Database contains data with ID=1,4,5
- Session1 performs `SELECT FOR UPDATE` on range [0, 2), holding a `gap lock` for the range [-∞, 3) where no records exist, locking the gap [-∞, 3) to prevent other transactions from inserting records within this range.

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|:----:|---|---|
| 13.3 | | mysql> SELECT * FROM example_single_pk WHERE id = -1 FOR UPDATE |
| ~ | | SELECT returned 0 rows (0.03s) |
| 13.6 | | mysql> INSERT INTO example_single_pk (id) VALUES (-1) |
| 16.6 | | ERROR: INSERT `timeout` (3.03s) (3.03s) |
| 16.8 | | mysql> SELECT * FROM example_single_pk WHERE id = 0 FOR UPDATE |
| 16.9 | | SELECT returned 0 rows (0.03s) |
| 17.2 | | mysql> INSERT INTO example_single_pk (id) VALUES (0) |
| 20.2 | | ERROR: INSERT `timeout` (3.03s) (3.03s) |
| 20.5 | | mysql> SELECT * FROM example_single_pk WHERE id = 1 FOR UPDATE |
| 23.5 | | ERROR: SELECT `timeout` (3.04s) (3.04s) |
| 23.8 | | mysql> INSERT INTO example_single_pk (id) VALUES (1) |
| 26.9 | | ERROR: INSERT `timeout` (3.03s) (3.03s) |
| 27.1 | | mysql> SELECT * FROM example_single_pk WHERE id = 2 FOR UPDATE |
| 27.2 | | SELECT returned 0 rows (0.03s) |
| 27.5 | | mysql> INSERT INTO example_single_pk (id) VALUES (2) |
| 30.5 | | ERROR: INSERT `timeout` (3.03s) (3.03s) |
| 30.8 | | mysql> SELECT * FROM example_single_pk WHERE id = 3 FOR UPDATE |
| ~ | | SELECT returned 0 rows (0.03s) |
| 31.1 | | mysql> INSERT INTO example_single_pk (id) VALUES (3) |
| 34.1 | | ERROR: INSERT `timeout` (3.03s) (3.03s) |
| 34.4 | | mysql> SELECT * FROM example_single_pk WHERE id = 4 FOR UPDATE |
| ~ | | SELECT returned 1 rows (0.03s) |
| ~ | | (4, '2025-09-27 11:22:48', '2025-09-27 11:22:48') |
| 34.8 | | mysql> INSERT INTO example_single_pk (id) VALUES (4) |
| ~ | | ERROR: INSERT duplicate (0.03s) (0.03s) |
| 35.1 | | mysql> SELECT * FROM example_single_pk WHERE id = 5 FOR UPDATE |
| 35.2 | | SELECT returned 1 rows (0.03s) |
| ~ | | (5, '2025-09-27 11:22:48', '2025-09-27 11:22:48') |
| 35.4 | | mysql> INSERT INTO example_single_pk (id) VALUES (5) |
| ~ | | ERROR: INSERT duplicate (0.03s) (0.03s) |
| 35.7 | | mysql> SELECT * FROM example_single_pk WHERE id = 6 FOR UPDATE |
| 35.8 | | SELECT returned 0 rows (0.03s) |
| 36.1 | | mysql> INSERT INTO example_single_pk (id) VALUES (6) |
| ~ | | INSERT success (0.03s) |
| 36.5 | | mysql> SELECT * FROM example_single_pk WHERE id = 7 FOR UPDATE |
| ~ | | SELECT returned 0 rows (0.03s) |
| 36.8 | | mysql> INSERT INTO example_single_pk (id) VALUES (7) |
| 36.9 | mysql> rollback | INSERT success (0.03s) |
| ~ | Query OK, 0 rows affected | |

###### SELECT FOR UPDATE RANGE [1, 3)

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|:----:|---|---|
| 37.2 | === Round 1: Testing SELECT_FOR_UPDATE_RANGE ID=1 === | === Round 2: Testing SELECT & INSERT === |
| ~ | mysql> start transaction | |
| ~ | Query OK, 0 rows affected | |
| ~ | mysql> SELECT * FROM example_single_pk WHERE id >= 1 AND id < 3 FOR UPDATE | |
| ~ | Range query returned 1 rows (0.02s) | |
| ~ | (1, '2025-09-27 11:22:48', '2025-09-27 11:22:48') | |

- Database contains data with ID=1,4,5
- Session1 performs `SELECT FOR UPDATE` on range [1, 3), holding a `gap lock` for the range [1, 3) where no records exist, locking the gap [1, 3) to prevent other transactions from inserting records within this range.

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|:----:|---|---|
| 39.0 | | mysql> SELECT * FROM example_single_pk WHERE id = 1 FOR UPDATE |
| 42.0 | | ERROR: SELECT `timeout` (3.03s) (3.03s) |
| 42.4 | | mysql> INSERT INTO example_single_pk (id) VALUES (1) |
| 45.4 | | ERROR: INSERT `timeout` (3.04s) (3.04s) |
| 45.7 | | mysql> SELECT * FROM example_single_pk WHERE id = 2 FOR UPDATE |
| 45.8 | | SELECT returned 0 rows (0.04s) |
| 46.1 | | mysql> INSERT INTO example_single_pk (id) VALUES (2) |
| 49.1 | | ERROR: INSERT `timeout` (3.03s) (3.03s) |
| 49.5 | | mysql> SELECT * FROM example_single_pk WHERE id = 3 FOR UPDATE |
| ~ | | SELECT returned 0 rows (0.03s) |
| 49.8 | | mysql> INSERT INTO example_single_pk (id) VALUES (3) |
| 52.9 | | ERROR: INSERT `timeout` (3.03s) (3.03s) |

###### SELECT FOR UPDATE RANGE [2, 4)

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|:----:|---|---|
| 55.9 | === Round 2: Testing SELECT_FOR_UPDATE_RANGE ID=2 === | === Round 3: Testing SELECT & INSERT === |
| ~ | mysql> start transaction | |
| ~ | Query OK, 0 rows affected | |
| ~ | mysql> SELECT * FROM example_single_pk WHERE id >= 2 AND id < 4 FOR UPDATE | |
| ~ | Range query returned 0 rows (0.04s) | |

- Database contains data with ID=1,4,5
- Session1 performs `SELECT FOR UPDATE` on range [2, 4), holding a `gap lock` for the range [2, 4) where no records exist, locking the gap [2, 4) to prevent other transactions from inserting records within this range.

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|:----:|---|---|
| 58.4 | | mysql> SELECT * FROM example_single_pk WHERE id = 2 FOR UPDATE |
| 58.5 | | SELECT returned 0 rows (0.03s) |
| 58.8 | | mysql> INSERT INTO example_single_pk (id) VALUES (2) |
| 61.8 | | ERROR: INSERT `timeout` (3.03s) (3.03s) |
| 62.1 | | mysql> SELECT * FROM example_single_pk WHERE id = 3 FOR UPDATE |
| ~ | | SELECT returned 0 rows (0.03s) |
| 62.4 | | mysql> INSERT INTO example_single_pk (id) VALUES (3) |
| 65.4 | | ERROR: INSERT `timeout` (3.03s) (3.03s) |

###### SELECT FOR UPDATE RANGE [3, 5)

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|:----:|---|---|
| 68.6 | === Round 3: Testing SELECT_FOR_UPDATE_RANGE ID=3 === | === Round 4: Testing SELECT & INSERT === |
| ~ | mysql> start transaction | |
| ~ | Query OK, 0 rows affected | |
| ~ | mysql> SELECT * FROM example_single_pk WHERE id >= 3 AND id < 5 FOR UPDATE | |
| ~ | Range query returned 1 rows (0.02s) | |
| ~ | (4, '2025-09-27 11:22:48', '2025-09-27 11:22:48') | |

- Database contains data with ID=1,4,5
- Session1 performs `SELECT FOR UPDATE` on range [3, 5), holding a `gap lock` for the range [2, 5) where no records exist, locking the gap [2, 5) to prevent other transactions from inserting records within this range.

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|:----:|---|---|
| 70.9 | | mysql> SELECT * FROM example_single_pk WHERE id = 2 FOR UPDATE |
| 71.0 | | SELECT returned 0 rows (0.03s) |
| 71.3 | | mysql> INSERT INTO example_single_pk (id) VALUES (2) |
| 74.3 | | ERROR: INSERT `timeout` (3.04s) (3.04s) |
| 74.7 | | mysql> SELECT * FROM example_single_pk WHERE id = 3 FOR UPDATE |
| ~ | | SELECT returned 0 rows (0.03s) |
| 75.0 | | mysql> INSERT INTO example_single_pk (id) VALUES (3) |
| 78.0 | | ERROR: INSERT `timeout` (3.03s) (3.03s) |
| 78.3 | | mysql> SELECT * FROM example_single_pk WHERE id = 4 FOR UPDATE |
| 81.3 | | ERROR: SELECT `timeout` (3.03s) (3.03s) |
| 81.6 | | mysql> INSERT INTO example_single_pk (id) VALUES (4) |
| 84.6 | | ERROR: INSERT `timeout` (3.03s) (3.03s) |
| 84.9 | | mysql> SELECT * FROM example_single_pk WHERE id = 5 FOR UPDATE |
| ~ | | SELECT returned 1 rows (0.03s) |
| ~ | | (5, '2025-09-27 11:22:48', '2025-09-27 11:22:48') |
| 85.2 | | mysql> INSERT INTO example_single_pk (id) VALUES (5) |
| ~ | | ERROR: INSERT duplicate (0.03s) (0.03s) |

###### SELECT FOR UPDATE RANGE [4, 6)

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|:----:|---|---|
| 86.8 | === Round 4: Testing SELECT_FOR_UPDATE_RANGE ID=4 === | === Round 5: Testing SELECT & INSERT === |
| ~ | mysql> start transaction | |
| ~ | Query OK, 0 rows affected | |
| ~ | mysql> SELECT * FROM example_single_pk WHERE id >= 4 AND id < 6 FOR UPDATE | |
| ~ | Range query returned 2 rows (0.03s) | |
| ~ | (4, '2025-09-27 11:22:48', '2025-09-27 11:22:48') | |
| ~ | (5, '2025-09-27 11:22:48', '2025-09-27 11:22:48') | |

- Database contains data with ID=1,4,5
- Session1 performs `SELECT FOR UPDATE` on range [4, 6), holding a `gap lock` for the range [4, +∞) where no records exist, locking the gap [4, +∞) to prevent other transactions from inserting records within this range.

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|:----:|---|---|
| 90.5 | | mysql> SELECT * FROM example_single_pk WHERE id = 4 FOR UPDATE |
| 93.5 | | ERROR: SELECT `timeout` (3.03s) (3.03s) |
| 93.9 | | mysql> INSERT INTO example_single_pk (id) VALUES (4) |
| 96.9 | | ERROR: INSERT `timeout` (3.03s) (3.03s) |
| 97.2 | | mysql> SELECT * FROM example_single_pk WHERE id = 5 FOR UPDATE |
| 100.3 | | ERROR: SELECT `timeout` (3.03s) (3.03s) |
| 100.6 | | mysql> INSERT INTO example_single_pk (id) VALUES (5) |
| 103.6 | | ERROR: INSERT `timeout` (3.03s) (3.03s) |
| 103.9 | | mysql> SELECT * FROM example_single_pk WHERE id = 6 FOR UPDATE |
| ~ | | SELECT returned 0 rows (0.03s) |
| 104.3 | | mysql> INSERT INTO example_single_pk (id) VALUES (6) |
| 107.3 | | ERROR: INSERT `timeout` (3.03s) (3.03s) |
| 107.6 | | mysql> SELECT * FROM example_single_pk WHERE id = 7 FOR UPDATE |
| 107.7 | | SELECT returned 0 rows (0.03s) |
| 108.0 | | mysql> INSERT INTO example_single_pk (id) VALUES (7) |
| 111.0 | mysql> rollback | ERROR: INSERT `timeout` (3.03s) (3.03s) |
| ~ | Query OK, 0 rows affected | |

###### SELECT FOR UPDATE RANGE [5, 7)

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|:----:|---|---|
| 111.3 | === Round 5: Testing SELECT_FOR_UPDATE_RANGE ID=5 === | === Round 6: Testing SELECT & INSERT === |
| ~ | mysql> start transaction | |
| ~ | Query OK, 0 rows affected | |
| ~ | mysql> SELECT * FROM example_single_pk WHERE id >= 5 AND id < 7 FOR UPDATE | |
| ~ | Range query returned 1 rows (0.03s) | |
| ~ | (5, '2025-09-27 11:22:48', '2025-09-27 11:22:48') | |

- Database contains data with ID=1,4,5
- Session1 performs `SELECT FOR UPDATE` on range [5, 7), holding a `gap lock` for the range [5, +∞) where no records exist, locking the gap [5, +∞) to prevent other transactions from inserting records within this range.

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|:----:|---|---|
| 116.0 | | mysql> SELECT * FROM example_single_pk WHERE id = 5 FOR UPDATE |
| 119.0 | | ERROR: SELECT `timeout` (3.03s) (3.03s) |
| 119.3 | | mysql> INSERT INTO example_single_pk (id) VALUES (5) |
| 122.3 | | ERROR: INSERT `timeout` (3.03s) (3.03s) |
| 122.7 | | mysql> SELECT * FROM example_single_pk WHERE id = 6 FOR UPDATE |
| ~ | | SELECT returned 0 rows (0.03s) |
| 123.0 | | mysql> INSERT INTO example_single_pk (id) VALUES (6) |
| 126.1 | | ERROR: INSERT `timeout` (3.03s) (3.03s) |
| 126.4 | | mysql> SELECT * FROM example_single_pk WHERE id = 7 FOR UPDATE |
| ~ | | SELECT returned 0 rows (0.03s) |
| 126.8 | | mysql> INSERT INTO example_single_pk (id) VALUES (7) |
| 129.8 | mysql> rollback | ERROR: INSERT `timeout` (3.03s) (3.03s) |
| ~ | Query OK, 0 rows affected | |

###### SELECT FOR UPDATE RANGE [6, 8)

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|:----:|---|---|
| 130.1 | === Round 6: Testing SELECT_FOR_UPDATE_RANGE ID=6 === | === Round 7: Testing SELECT & INSERT === |
| ~ | mysql> start transaction | |
| ~ | Query OK, 0 rows affected | |
| ~ | mysql> SELECT * FROM example_single_pk WHERE id >= 6 AND id < 8 FOR UPDATE | |
| ~ | Range query returned 0 rows (0.03s) | |

- Database contains data with ID=1,4,5
- Session1 performs `SELECT FOR UPDATE` on range [6, 8), holding a `gap lock` for the range [6, +∞) where no records exist, locking the gap [6, +∞) to prevent other transactions from inserting records within this range.

| Time | SESSION 1 (LEFT) | SESSION 2 (RIGHT) |
|:----:|---|---|
| 135.3 | | mysql> SELECT * FROM example_single_pk WHERE id = 6 FOR UPDATE |
| 135.4 | | SELECT returned 0 rows (0.03s) |
| 135.6 | | mysql> INSERT INTO example_single_pk (id) VALUES (6) |
| 138.7 | | ERROR: INSERT `timeout` (3.11s) (3.11s) |
| 139.1 | | mysql> SELECT * FROM example_single_pk WHERE id = 7 FOR UPDATE |
| ~ | | SELECT returned 0 rows (0.03s) |
| 139.5 | | mysql> INSERT INTO example_single_pk (id) VALUES (7) |
| 142.5 | mysql> rollback | ERROR: INSERT `timeout` (3.03s) (3.03s) |
| ~ | Query OK, 0 rows affected | |
| ~ | | SESSION 2 COMPLETE |
| 142.8 | SESSION 1 COMPLETE | |

### Appendix

- Python script for data collection

```python
#!/usr/bin/env python3
"""
MySQL Lock Testing - Timeline Analysis Version
"""

import pymysql
import threading
import time
from datetime import datetime
from collections import defaultdict

DB_CONFIG = {
    'host': 'localhost',
    'user': 'haotian',
    'password': 'qwe123qwe123',
    'database': 'toy',
    'autocommit': False
}

# Test Configuration - Modify as needed
TEST_CONFIG = {
    # Session1 Configuration
    'session1_operation': 'select_for_update_range',  # 'insert', 'select_for_update', 'select_for_update_range'
    'insert_start': -1,     # Operation start ID
    'insert_end': 7,        # Operation end ID (exclusive)
    'range_size': 2,        # Range size (for select_for_update_range only)

    # Session2 Test Configuration
    'test_ids': [-1, 0, 1, 2, 3, 4, 5, 6, 7],  # ID list to test
    'lock_timeout': 3       # Lock wait timeout in seconds
}

# Global log collector
timeline_log = []
log_lock = threading.Lock()

def log_event(session, event_type, sql, result=None, error=None, duration=None):
    """Record event to timeline"""
    with log_lock:
        timestamp = datetime.now()
        timeline_log.append({
            'timestamp': timestamp,
            'session': session,
            'type': event_type,  # 'sql', 'info', 'error'
            'sql': sql,
            'result': result,
            'error': error,
            'duration': duration
        })

        # Real-time progress display
        time_str = timestamp.strftime("%H:%M:%S.%f")[:-3]
        if event_type == 'sql':
            progress_text = f"mysql> {sql}"
            if duration:
                progress_text += f" ({duration:.2f}s)"
        elif event_type == 'error':
            progress_text = f"ERROR: {error}"
            if duration:
                progress_text += f" ({duration:.2f}s)"
        else:
            progress_text = result or sql

        print(f"[{time_str}] [{session}] {progress_text}")

def session1():
    """Session1: Loop operations (INSERT or SELECT FOR UPDATE)"""
    conn = pymysql.connect(**DB_CONFIG)
    cursor = conn.cursor()

    operation_type = TEST_CONFIG['session1_operation']
    log_event('S1', 'info', '', f'SESSION 1 START - {operation_type.upper()}')

    # Check table status
    start = time.time()
    cursor.execute("SELECT * FROM example_single_pk")
    results = cursor.fetchall()
    duration = time.time() - start
    log_event('S1', 'sql', 'SELECT * FROM example_single_pk', results, duration=duration)

    # Loop operations
    try:
        for target_id in range(TEST_CONFIG['insert_start'], TEST_CONFIG['insert_end']):
            log_event('S1', 'info', '', f'=== Round {target_id}: Testing {operation_type.upper()} ID={target_id} ===')

            try:
                # Start transaction
                log_event('S1', 'sql', 'start transaction', 'Query OK, 0 rows affected')
                cursor.execute("START TRANSACTION")

                if operation_type == 'insert':
                    # INSERT operation
                    sql = f"INSERT INTO example_single_pk (id) VALUES ({target_id})"
                    start = time.time()
                    try:
                        cursor.execute(sql)
                        duration = time.time() - start
                        log_event('S1', 'sql', sql, 'Query OK, 1 row affected', duration=duration)
                    except pymysql.err.IntegrityError as e:
                        duration = time.time() - start
                        log_event('S1', 'error', sql, None, str(e), duration)

                elif operation_type == 'select_for_update':
                    # SELECT FOR UPDATE operation
                    sql = f"SELECT * FROM example_single_pk WHERE id = {target_id} FOR UPDATE"
                    start = time.time()
                    try:
                        cursor.execute(sql)
                        results = cursor.fetchall()
                        duration = time.time() - start
                        log_event('S1', 'sql', sql, None)
                        log_event('S1', 'info', '', f'Query returned {len(results)} rows ({duration:.2f}s)')
                        if results:
                            for row in results:
                                formatted_row = []
                                for item in row:
                                    if hasattr(item, 'strftime'):
                                        formatted_row.append(item.strftime('%Y-%m-%d %H:%M:%S'))
                                    else:
                                        formatted_row.append(item)
                                log_event('S1', 'info', '', str(tuple(formatted_row)))
                    except Exception as e:
                        duration = time.time() - start
                        log_event('S1', 'error', sql, None, str(e), duration)

                elif operation_type == 'select_for_update_range':
                    # SELECT FOR UPDATE range operation
                    range_size = TEST_CONFIG['range_size']
                    end_id = target_id + range_size
                    sql = f"SELECT * FROM example_single_pk WHERE id >= {target_id} AND id < {end_id} FOR UPDATE"
                    start = time.time()
                    try:
                        cursor.execute(sql)
                        results = cursor.fetchall()
                        duration = time.time() - start
                        log_event('S1', 'sql', sql, None)
                        log_event('S1', 'info', '', f'Range query returned {len(results)} rows ({duration:.2f}s)')
                        if results:
                            for row in results:
                                formatted_row = []
                                for item in row:
                                    if hasattr(item, 'strftime'):
                                        formatted_row.append(item.strftime('%Y-%m-%d %H:%M:%S'))
                                    else:
                                        formatted_row.append(item)
                                log_event('S1', 'info', '', str(tuple(formatted_row)))
                    except Exception as e:
                        duration = time.time() - start
                        log_event('S1', 'error', sql, None, str(e), duration)

                # Notify Session2 and wait
                session2_event.set()
                session1_event.wait()
                session1_event.clear()

                # ROLLBACK
                log_event('S1', 'sql', 'rollback', 'Query OK, 0 rows affected')
                cursor.execute("ROLLBACK")

            except Exception as e:
                log_event('S1', 'error', 'transaction', None, str(e))
                cursor.execute("ROLLBACK")

            time.sleep(0.2)

    except Exception as e:
        log_event('S1', 'error', 'main_loop', None, f'Session1 main loop error: {str(e)}')
    finally:
        log_event('S1', 'info', '', 'SESSION 1 COMPLETE')
        session2_event.set()  # Final notification
        conn.close()

def session2():
    """Session2: SELECT FOR UPDATE testing"""
    log_event('S2', 'info', '', 'SESSION 2 START - Waiting for Session1...')

    round_num = 0

    total_rounds = TEST_CONFIG['insert_end'] - TEST_CONFIG['insert_start']
    while round_num < total_rounds:
        session2_event.wait()
        session2_event.clear()

        if round_num >= total_rounds:
            break

        log_event('S2', 'info', '', f'=== Round {round_num}: Testing SELECT & INSERT ===')

        # Test all configured IDs, testing both SELECT FOR UPDATE and INSERT for each ID
        for test_id in TEST_CONFIG['test_ids']:
            # Test 1: SELECT FOR UPDATE
            conn1 = pymysql.connect(**DB_CONFIG)
            cursor1 = conn1.cursor()

            try:
                cursor1.execute(f"SET innodb_lock_wait_timeout = {TEST_CONFIG['lock_timeout']}")
                cursor1.execute("START TRANSACTION")

                # SELECT FOR UPDATE
                sql = f"SELECT * FROM example_single_pk WHERE id = {test_id} FOR UPDATE"
                log_event('S2', 'sql', sql, None)

                start = time.time()
                try:
                    cursor1.execute(sql)
                    results = cursor1.fetchall()
                    duration = time.time() - start
                    log_event('S2', 'info', '', f'SELECT returned {len(results)} rows ({duration:.2f}s)')
                    if results:
                        for row in results:
                            formatted_row = []
                            for item in row:
                                if hasattr(item, 'strftime'):
                                    formatted_row.append(item.strftime('%Y-%m-%d %H:%M:%S'))
                                else:
                                    formatted_row.append(item)
                            log_event('S2', 'info', '', str(tuple(formatted_row)))

                except pymysql.err.OperationalError as e:
                    duration = time.time() - start
                    if "Lock wait timeout" in str(e):
                        log_event('S2', 'error', '', result=None, error=f'SELECT timeout ({duration:.2f}s)', duration=duration)
                    else:
                        log_event('S2', 'error', '', result=None, error=f'SELECT error: {str(e)}', duration=duration)

                cursor1.execute("ROLLBACK")

            except Exception as e:
                log_event('S2', 'error', 'connection', None, f'SELECT connection error: {str(e)}')
            finally:
                conn1.close()

            # Test 2: INSERT
            conn2 = pymysql.connect(**DB_CONFIG)
            cursor2 = conn2.cursor()

            try:
                cursor2.execute(f"SET innodb_lock_wait_timeout = {TEST_CONFIG['lock_timeout']}")
                cursor2.execute("START TRANSACTION")

                # INSERT
                sql = f"INSERT INTO example_single_pk (id) VALUES ({test_id})"
                log_event('S2', 'sql', sql, None)

                start = time.time()
                try:
                    cursor2.execute(sql)
                    duration = time.time() - start
                    log_event('S2', 'info', '', f'INSERT success ({duration:.2f}s)')

                except pymysql.err.OperationalError as e:
                    duration = time.time() - start
                    if "Lock wait timeout" in str(e):
                        log_event('S2', 'error', '', result=None, error=f'INSERT timeout ({duration:.2f}s)', duration=duration)
                    else:
                        log_event('S2', 'error', '', result=None, error=f'INSERT error: {str(e)}', duration=duration)
                except pymysql.err.IntegrityError as e:
                    duration = time.time() - start
                    log_event('S2', 'error', '', result=None, error=f'INSERT duplicate ({duration:.2f}s)', duration=duration)

                cursor2.execute("ROLLBACK")

            except Exception as e:
                log_event('S2', 'error', 'connection', None, f'INSERT connection error: {str(e)}')
            finally:
                conn2.close()

        round_num += 1
        session1_event.set()

    log_event('S2', 'info', '', 'SESSION 2 COMPLETE')

def print_round_analysis(round_num):
    """Print single round analysis"""
    print(f"\n{'='*80}")
    print(f"Round {round_num} Analysis")
    print(f"{'='*80}")

    # Find events for this round
    round_events = []
    for event in timeline_log:
        if (event['session'] == 'S1' and f'Round {round_num}:' in str(event.get('result', ''))) or \
                (event['session'] == 'S2' and f'Round {round_num}:' in str(event.get('result', ''))):
            round_start_time = event['timestamp']
            break
    else:
        return

    # Collect all events for this round
    for event in timeline_log:
        relative_time = (event['timestamp'] - round_start_time).total_seconds()
        if 0 <= relative_time <= 20:  # Assume max 20 seconds per round
            round_events.append((relative_time, event))

    # Display by time columns
    operation_type = TEST_CONFIG['session1_operation'].upper()
    if operation_type == 'SELECT_FOR_UPDATE_RANGE':
        range_size = TEST_CONFIG['range_size']
        s1_header = f"SESSION 1 (RANGE+{range_size})"
    else:
        s1_header = f"SESSION 1 ({operation_type})"
    print(f"{'Time':>6} | {s1_header:^35} | {'SESSION 2 (SELECT & INSERT)':^35}")
    print("-" * 80)

    grouped = defaultdict(list)
    for rel_time, event in round_events:
        time_bucket = round(rel_time, 1)
        grouped[time_bucket].append(event)

    for time_bucket in sorted(grouped.keys()):
        events = grouped[time_bucket]
        s1_events = [e for e in events if e['session'] == 'S1']
        s2_events = [e for e in events if e['session'] == 'S2']

        max_events = max(len(s1_events), len(s2_events))
        for i in range(max_events):
            s1_text = ""
            s2_text = ""

            if i < len(s1_events):
                e = s1_events[i]
                if e['type'] == 'sql':
                    s1_text = f"mysql> {e['sql']}"
                    if e.get('duration'):
                        s1_text += f" ({e['duration']:.2f}s)"
                elif e['type'] == 'info':
                    s1_text = e['result'] or e['sql']

            if i < len(s2_events):
                e = s2_events[i]
                if e['type'] == 'sql':
                    s2_text = f"mysql> {e['sql']}"
                elif e['type'] == 'info':
                    if 'Query returned' in str(e['result']):
                        s2_text = e['result']
                    elif e['result'] and '(' in str(e['result']):
                        s2_text = e['result']
                elif e['type'] == 'error':
                    s2_text = f"ERROR: {e['error']}"

            time_str = f"{time_bucket:6.1f}" if i == 0 else ""
            s1_text = s1_text[:33]
            s2_text = s2_text[:33]
            print(f"{time_str:>6} | {s1_text:<35} | {s2_text:<35}")

    print("=" * 80)

def print_timeline_analysis():
    """Analyze and print timeline"""
    # Print analysis for each round first
    total_rounds = TEST_CONFIG['insert_end'] - TEST_CONFIG['insert_start']
    for round_num in range(total_rounds):
        print_round_analysis(round_num)

    print(f"\n{'='*150}")
    print("Complete Timeline Analysis")
    print("="*150)

    if not timeline_log:
        print("No events recorded")
        return

    # Group by time, find simultaneous events
    grouped_events = defaultdict(list)
    base_time = timeline_log[0]['timestamp']

    for event in timeline_log:
        # Calculate relative time (seconds)
        relative_time = (event['timestamp'] - base_time).total_seconds()
        # Group by 0.1 second intervals
        time_bucket = round(relative_time, 1)
        grouped_events[time_bucket].append(event)

    # Print column format
    print(f"{'Time':>6} | {'SESSION 1 (LEFT)':^70} | {'SESSION 2 (RIGHT)':^70}")
    print("-" * 150)

    for time_bucket in sorted(grouped_events.keys()):
        events = grouped_events[time_bucket]
        s1_events = [e for e in events if e['session'] == 'S1']
        s2_events = [e for e in events if e['session'] == 'S2']

        max_events = max(len(s1_events), len(s2_events))

        for i in range(max_events):
            s1_text = ""
            s2_text = ""

            if i < len(s1_events):
                e = s1_events[i]
                if e['type'] == 'sql':
                    s1_text = f"mysql> {e['sql']}"
                    if e['result'] and isinstance(e['result'], str):
                        s1_text += f"\n{e['result']}"
                    elif e['result'] and hasattr(e['result'], '__iter__'):
                        if len(e['result']) == 0:
                            s1_text += f"\nEmpty set"
                        else:
                            # Display all data, format datetime
                            for row in e['result']:
                                formatted_row = []
                                for item in row:
                                    if hasattr(item, 'strftime'):  # datetime object
                                        formatted_row.append(item.strftime('%Y-%m-%d %H:%M:%S'))
                                    else:
                                        formatted_row.append(item)
                                s1_text += f"\n{tuple(formatted_row)}"
                            s1_text += f"\n{len(e['result'])} rows"
                    if e['duration']:
                        s1_text += f" ({e['duration']:.2f}s)"
                elif e['type'] == 'error':
                    s1_text = f"ERROR: {e['error']}"
                    if e['duration']:
                        s1_text += f" ({e['duration']:.2f}s)"
                else:  # info
                    s1_text = e['result'] or e['sql']

            if i < len(s2_events):
                e = s2_events[i]
                if e['type'] == 'sql':
                    s2_text = f"mysql> {e['sql']}"
                    if e['result'] and isinstance(e['result'], str):
                        s2_text += f"\n{e['result']}"
                    elif e['result'] and hasattr(e['result'], '__iter__'):
                        if len(e['result']) == 0:
                            s2_text += f"\nEmpty set"
                        else:
                            # Display all data, format datetime
                            for row in e['result']:
                                formatted_row = []
                                for item in row:
                                    if hasattr(item, 'strftime'):  # datetime object
                                        formatted_row.append(item.strftime('%Y-%m-%d %H:%M:%S'))
                                    else:
                                        formatted_row.append(item)
                                s2_text += f"\n{tuple(formatted_row)}"
                            s2_text += f"\n{len(e['result'])} rows"
                    if e['duration']:
                        s2_text += f" ({e['duration']:.2f}s)"
                elif e['type'] == 'error':
                    s2_text = f"ERROR: {e['error']}"
                    if e['duration']:
                        s2_text += f" ({e['duration']:.2f}s)"
                else:  # info
                    s2_text = e['result'] or e['sql']

            # Handle multi-line text
            s1_lines = s1_text.split('\n') if s1_text else ['']
            s2_lines = s2_text.split('\n') if s2_text else ['']
            max_lines = max(len(s1_lines), len(s2_lines))

            for j in range(max_lines):
                time_str = f"{time_bucket:6.1f}" if i == 0 and j == 0 else ""
                s1_line = s1_lines[j] if j < len(s1_lines) else ""
                s2_line = s2_lines[j] if j < len(s2_lines) else ""

                # Increase display width, reduce truncation
                s1_line = s1_line[:80] if s1_line.startswith('mysql>') else s1_line[:70]
                s2_line = s2_line[:80] if s2_line.startswith('mysql>') else s2_line[:70]

                print(f"{time_str:>6} | {s1_line:<70} | {s2_line:<70}")

    print("=" * 150)

# Event objects
session1_event = threading.Event()
session2_event = threading.Event()

if __name__ == "__main__":
    operation_type = TEST_CONFIG['session1_operation'].upper()
    print("MySQL Lock Test - Timeline Collection Mode")
    print(f"Session1: {operation_type} operations")
    print(f"Session2: SELECT FOR UPDATE & INSERT tests")
    print("Collecting all events with timestamps...")

    t1 = threading.Thread(target=session1)
    t2 = threading.Thread(target=session2)

    t2.start()
    time.sleep(0.1)
    t1.start()

    t1.join()
    t2.join()

    print_timeline_analysis()
    print("\nAnalysis Complete!")
```
