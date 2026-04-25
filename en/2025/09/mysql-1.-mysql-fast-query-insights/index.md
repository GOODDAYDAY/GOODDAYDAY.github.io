# [MySQL] 1. MySQL Fast Query Insights


## Preface

- Let's start with some of the most common optimization measures we use in daily learning and business scenarios

    1. Do more things in the same unit of time

        - QuickSort uses the binary search idea to sort multiple arrays within a single loop

          ![1. QuickSort.jpg](/images/3.%20%E6%B5%85%E8%B0%88MySQL%E5%BF%AB%E9%80%9F%E6%9F%A5%E8%AF%A2/1.%20%E5%BF%AB%E6%8E%92.jpg)

    2. Query less information in total
        - KMP algorithm preprocesses the main string to reduce the number of matches. This is the power of logic

          ![2. KMP.jpg](/images/3.%20%E6%B5%85%E8%B0%88MySQL%E5%BF%AB%E9%80%9F%E6%9F%A5%E8%AF%A2/2.%20KMP.jpg)

        - Search trees use binary search ideas to filter half of the remaining data each time to improve efficiency. This is the power of data structures

          ![3. Search Tree.webp](/images/3.%20%E6%B5%85%E8%B0%88MySQL%E5%BF%AB%E9%80%9F%E6%9F%A5%E8%AF%A2/3.%20%E6%90%9C%E7%B4%A2%E6%A0%91.webp)

- For MySQL fast queries, the most critical core is to query less data - the less, the faster. This entire article revolves around this statement.

## Does Not Having an Index Always Mean Slow Queries?

- Define data insertion function

```SQL
DROP TABLE IF EXISTS user;
CREATE TABLE user
(
    id      bigint(20)                          NOT NULL COMMENT 'User ID',
    biz_id  bigint(20)                          NOT NULL COMMENT 'Business ID',
    message text COMMENT 'Business information',
    created timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE = InnoDB COMMENT 'User'
  CHARSET = utf8mb4;

DELIMITER
$$
CREATE PROCEDURE insertUserData(IN start_id int, IN end_id int, IN bizId int)
BEGIN
    DECLARE i int DEFAULT start_id;

    WHILE i <= end_id
        DO
            INSERT INTO user (id, biz_id, message) VALUES (i, bizId, SUBSTRING(MD5(RAND()), 1, 8));

            SET i = i + 1;
        END WHILE;
END
$$
DELIMITER ;
```

- Prepare some data, where bizId = 1 has only two records, the first and last data

```SQL
-- Insert first business id 1 data
CALL insertUserData(1, 1, 1);
-- Insert one million other data
CALL insertUserData(2, 1000000, 2);
-- Insert second business id 1 data
CALL insertUserData(1000001, 1000001, 1);
```

- Looking at the data distribution, I think everyone already knows what I want to express. Even without using indexes, we have scenarios for fast queries here.

**Query limit 1**

> EXPLAIN SELECT \* FROM user WHERE biz_id = 1 LIMIT 1;

| id  | select_type | table | partitions | type | possible_keys | key  | key_len | ref  | rows   | filtered | Extra       |
| :-- | :---------- | :---- | :--------- | :--- | :------------ | :--- | :------ | :--- | :----- | :------- | :---------- |
| 1   | SIMPLE      | user  | null       | ALL  | null          | null | null    | null | 997030 | 10       | Using where |

```SQL
SELECT * FROM user WHERE biz_id = 1 LIMIT 1;
[2023-08-27 10:53:43] 1 row retrieved starting from 1 in 97 ms (execution: 5 ms, fetching: 92 ms)
```

```SQL
SELECT * FROM user WHERE biz_id = 1 LIMIT 2;
[2023-08-27 10:53:48] 2 rows retrieved starting from 1 in 1 s 199 ms (execution: 1 s 172 ms, fetching: 27 ms)
```

> EXPLAIN SELECT \* FROM user WHERE biz_id = 1 LIMIT 2;

| id  | select_type | table | partitions | type | possible_keys | key  | key_len | ref  | rows   | filtered | Extra       |
| :-- | :---------- | :---- | :--------- | :--- | :------------ | :--- | :------ | :--- | :----- | :------- | :---------- |
| 1   | SIMPLE      | user  | null       | ALL  | null          | null | null    | null | 997030 | 10       | Using where |

- From a practical perspective, we can see that the execution time difference between limit 1 and limit 2 is huge.
- Here's a tip: we can use ChatGPT to efficiently organize and analyze explain results.

```
(Wenxin Yiyan)
This query plan shows a full scan of the user table without using indexes, and the WHERE clause is used to filter results.
If the table is large or query performance is poor, this may cause performance issues.
Optimization may need to consider using appropriate indexes to improve query performance.
```

- We can see that the execution plans for limit 1 and limit 2 are almost identical. This confirms that although the time difference is huge, the execution logic is the same for MySQL. So why is there such a huge difference? We need to analyze this specifically.
- In the limit 1 scenario, based on a full table scan, it returns immediately when the first data is found. This is equivalent to querying only one record.
- In the limit 2 scenario, the second data is after one million records, so according to the execution plan, it must scan the entire table to completely find the data.
- In summary, does not having an index always mean slow queries? Not necessarily. Indexes only reduce the amount of data queried, but when the data volume is already extremely small, it won't be slower.

## Indexes

- The explain shows "Using where", and according to ChatGPT's response and our own analysis, we can naturally think of using indexes to optimize queries. Let's try using B+ tree indexes.

### B+ Tree Indexes

> https://www.cs.usfca.edu/~galles/visualization/Algorithms.html

```SQL
CREATE INDEX idx_user_biz_id ON user (biz_id);
```

```SQL
DROP INDEX idx_user_biz_id ON user;
```

> EXPLAIN SELECT \* FROM user WHERE biz_id = 1 LIMIT 1;

| id  | select_type | table | partitions | type | possible_keys   | key             | key_len | ref   | rows | filtered | Extra |
| :-- | :---------- | :---- | :--------- | :--- | :-------------- | :-------------- | :------ | :---- | :--- | :------- | :---- |
| 1   | SIMPLE      | user  | null       | ref  | idx_user_biz_id | idx_user_biz_id | 8       | const | 2    | 100      | null  |

```SQL
SELECT * FROM user WHERE biz_id = 1 LIMIT 1
[2023-08-27 21:09:37] 1 row retrieved starting from 1 in 48 ms (execution: 4 ms, fetching: 44 ms)
```

> EXPLAIN SELECT \* FROM user WHERE biz_id = 1 LIMIT 2;

| id  | select_type | table | partitions | type | possible_keys   | key             | key_len | ref   | rows | filtered | Extra |
| :-- | :---------- | :---- | :--------- | :--- | :-------------- | :-------------- | :------ | :---- | :--- | :------- | :---- |
| 1   | SIMPLE      | user  | null       | ref  | idx_user_biz_id | idx_user_biz_id | 8       | const | 2    | 100      | null  |

```SQL
SELECT * FROM user WHERE biz_id = 1 LIMIT 2
[2023-08-27 21:09:04] 2 rows retrieved starting from 1 in 48 ms (execution: 4 ms, fetching: 44 ms)
```

- As you can see, after adding an index, query time was greatly optimized. The execution plan evolved from "Using where" to using "const"

```
(Wenxin Yiyan)
In your example, this query operates on a table named "user"
using an index named "idx_user_biz_id" with an index length of 8 bytes
the comparison column is constant (const), the system estimates it needs to scan 2 rows of data, returning 100% of the rows, with no additional information.
```

#### Why B+ Trees

**Balanced Binary Tree**

![4. Balanced Binary Tree.png](/images/3.%20%E6%B5%85%E8%B0%88MySQL%E5%BF%AB%E9%80%9F%E6%9F%A5%E8%AF%A2/4.%20%E5%B9%B3%E8%A1%A1%E4%BA%8C%E5%8F%89%E6%A0%91.png)

- In a balanced binary tree, we can think about the query process.
- Suppose we want to query all data from 5 to 16. We need to query six nodes, and the order retrieved is not naturally sorted, requiring in-order traversal algorithm implementation. So we can see that balanced trees are natural data structures for finding single nodes, but support for range queries is relatively poor.
- The first optimization point, if you want to understand in detail, requires deep understanding of disk pre-read optimization. I think it's not very necessary to understand, but can be simply understood as too many IO operations
    - In balanced trees, logically close places may be physically distant, leading to longer IO times during disk rotation operations
- The second optimization point is that there's too much useless data when reading IO data, because the data read back must be larger than the size of a single node's data.
- Additionally, balanced binary trees require rotation to maintain balance, which is difficult to implement efficiently in memory operations

**B Tree**

![5. B Tree.png](/images/3.%20%E6%B5%85%E8%B0%88MySQL%E5%BF%AB%E9%80%9F%E6%9F%A5%E8%AF%A2/5.%20B%E6%A0%91.png)

- To address the above optimization points, we can naturally optimize from `binary` to `multi-way`, thus optimizing the problem of too much useless data in single nodes. Because when single nodes are larger, the number of IO operations also decreases.
- This naturally leads to the idea of B trees. By expanding nodes to form multi-way structures.
- But actually thinking carefully, in-order traversal algorithm implementation is still needed. For range queries, optimization is only at the single node level. When the range span is large, there's still room for performance optimization.

**B+ Tree**

![6. B+ Tree.png](/images/3.%20%E6%B5%85%E8%B0%88MySQL%E5%BF%AB%E9%80%9F%E6%9F%A5%E8%AF%A2/6.%20B%2B%E6%A0%91.png)

- B+ trees first further optimize single node storage efficiency (no Values). This way single nodes can support more `branches`.
- At the same time, the bottom leaf nodes are combined into a linked list through pointers, thus optimizing traversal logic.
    - Note: The bottom layer of B+ trees contains all nodes from upper layers.

### B+ Tree Composite Indexes

![7. Composite Index.png](/images/3.%20%E6%B5%85%E8%B0%88MySQL%E5%BF%AB%E9%80%9F%E6%9F%A5%E8%AF%A2/7.%20%E8%81%94%E5%90%88%E7%B4%A2%E5%BC%95.png)

- We've understood the B+ tree part, which can be simply understood as clustered indexes with Values at the bottom leaf nodes.
- Now let's understand composite indexes.

**Leftmost Matching Principle**

- The specific principle doesn't need explanation, just understanding.

**Why are B+ Tree Indexes Sorted?**

- In the above diagram, our first-level index is ordered, which is easy to understand. When the first-level index is fixed, its second-level index underneath is also ordered.
- My understanding is that B+ trees first search the first-level index. When the first-level index is determined, the B+ tree converts to a second-level index B+ tree. And so on.
    - Note: Composite indexes are on one tree.

**Why Do B+ Tree Indexes Fail?**

- First, we can understand that the second-level index order when first-level index = 1 and the second-level index order when first-level index = 2 have no necessary sequential relationship. They just both have the same monotonicity.
- Following my previous direction of index tree changes, when the first-level index becomes a range, there's more than one tree for second-level indexes. We can't perform the same range single query on multiple trees. We can only combine multiple times.

#### What is Table Lookup?

- Assuming everyone understands clustered indexes and secondary indexes.
- Table lookup, simply put, means after the secondary index is finished, it can't continue, like in the previous table.
- Note: Type represents the optimization order of access types, from best to worst: system->const->eq_ref->ref->ref_or_null->index_merge->unique_subquery->index_subquery->range->index->all. Generally, we hope to reach ref and eq_ref levels, and range queries need to reach range level.

```SQL
DROP TABLE IF EXISTS user;
CREATE TABLE user
(
    id      bigint(20)                          NOT NULL COMMENT 'User ID',
    biz_id  bigint(20)                          NOT NULL COMMENT 'Business ID',
    message text COMMENT 'Business information',
    created timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE = InnoDB COMMENT 'User'
  CHARSET = utf8mb4;

CREATE INDEX idx_user_biz_id ON user (biz_id);
```

- Using index completely

```SQL
EXPLAIN  SELECT id FROM `user` WHERE biz_id = 2;
```

| id  | select_type | table | partitions | type | possible_keys   | key             | key_len | ref   | rows   | filtered | Extra       |
| :-- | :---------- | :---- | :--------- | :--- | :-------------- | :-------------- | :------ | :---- | :----- | :------- | :---------- |
| 1   | SIMPLE      | user  | null       | ref  | idx_user_biz_id | idx_user_biz_id | 8       | const | 498380 | 100      | Using index |

```
(ChatGPT)
The query involves the "user" table.
The table access method is "ref", indicating that an index was used for the query.
The index used is "idx_user_biz_id", and the query uses this index.
The index length used is 8 bytes.
The query reference value is "const", indicating the query uses a constant value for filtering.
The query returns 498380 rows with a filtering rate of 100%.
"Using index" indicates the query uses a covering index, meaning query results can be obtained directly from the index without accessing table data.
```

- Table lookup once

```SQL
EXPLAIN  SELECT * FROM `user` WHERE biz_id = 2;
```

| id  | select_type | table | partitions | type | possible_keys   | key             | key_len | ref   | rows   | filtered | Extra |
| :-- | :---------- | :---- | :--------- | :--- | :-------------- | :-------------- | :------ | :---- | :----- | :------- | :---- |
| 1   | SIMPLE      | user  | null       | ref  | idx_user_biz_id | idx_user_biz_id | 8       | const | 498380 | 100      | null  |

```
(ChatGPT)
This is a simple SELECT query with no subqueries or joins.
The query references a table named user.
The query uses an index named idx_user_biz_id.
The index length is 8.
The query uses a constant value for reference.
The query scanned 498380 rows and filtered 100 rows based on the WHERE condition.
The query has no other special conditions.
```

- Table lookup once (more table lookup data)

```SQL
EXPLAIN  SELECT * FROM `user` WHERE biz_id = 2 and message = '';
```

| id  | select_type | table | partitions | type | possible_keys   | key             | key_len | ref   | rows   | filtered | Extra       |
| :-- | :---------- | :---- | :--------- | :--- | :-------------- | :-------------- | :------ | :---- | :----- | :------- | :---------- |
| 1   | SIMPLE      | user  | null       | ref  | idx_user_biz_id | idx_user_biz_id | 8       | const | 498380 | 10       | Using where |

```
(ChatGPT)
The given query is a simple SELECT query involving a table named "user".
The query uses an index named "idx_user_biz_id" and uses a WHERE clause.
The query uses regular secondary index for equality matching.
The query returned 498380 rows of results.
```

**Index Pushdown & Covering Index**

```SQL
DROP INDEX idx_user_biz_id ON user;

CREATE INDEX idx_user_biz_id_msg ON user (biz_id, message(8));
```

```SQL
EXPLAIN SELECT id FROM user WHERE biz_id = 2 and message = '99dd8a31';
```

| id  | select_type | table | partitions | type | possible_keys       | key                 | key_len | ref         | rows | filtered | Extra       |
| :-- | :---------- | :---- | :--------- | :--- | :------------------ | :------------------ | :------ | :---------- | :--- | :------- | :---------- |
| 1   | SIMPLE      | user  | null       | ref  | idx_user_biz_id_msg | idx_user_biz_id_msg | 43      | const,const | 1    | 100      | Using where |

```SQL
EXPLAIN SELECT * FROM user WHERE biz_id = 2 and message = '99dd8a31';
```

| id  | select_type | table | partitions | type | possible_keys       | key                 | key_len | ref         | rows | filtered | Extra       |
| :-- | :---------- | :---- | :--------- | :--- | :------------------ | :------------------ | :------ | :---------- | :--- | :------- | :---------- |
| 1   | SIMPLE      | user  | null       | ref  | idx_user_biz_id_msg | idx_user_biz_id_msg | 43      | const,const | 1    | 100      | Using where |

```
(ChatGPT)
The type field represents the query access method, from most optimal to least optimal: system, const, eq_ref, ref, ref_or_null, index_merge, unique_subquery, index_subquery, range, index, all.
possible_keys lists indexes that might help the query, if empty it means no available indexes.
key lists the actually selected index, if NULL it means no index was used.
Extra lists additional information, for example Using where means WHERE conditions were used for filtering.
```

```SQL
EXPLAIN SELECT id FROM user WHERE biz_id > 2;
```

| id  | select_type | table | partitions | type  | possible_keys       | key                 | key_len | ref  | rows | filtered | Extra                    |
| :-- | :---------- | :---- | :--------- | :---- | :------------------ | :------------------ | :------ | :--- | :--- | :------- | :----------------------- |
| 1   | SIMPLE      | user  | null       | range | idx_user_biz_id_msg | idx_user_biz_id_msg | 8       | null | 1    | 100      | Using where; Using index |

```SQL
EXPLAIN SELECT * FROM user WHERE biz_id > 2 AND message = '';
```

| id  | select_type | table | partitions | type  | possible_keys       | key                 | key_len | ref  | rows | filtered | Extra                              |
| :-- | :---------- | :---- | :--------- | :---- | :------------------ | :------------------ | :------ | :--- | :--- | :------- | :--------------------------------- |
| 1   | SIMPLE      | user  | null       | range | idx_user_biz_id_msg | idx_user_biz_id_msg | 8       | null | 1    | 10       | Using index condition; Using where |

```SQL
EXPLAIN SELECT id FROM user WHERE biz_id > 2 ORDER BY id DESC ;
```

| id  | select_type | table | partitions | type  | possible_keys       | key                 | key_len | ref  | rows | filtered | Extra                                    |
| :-- | :---------- | :---- | :--------- | :---- | :------------------ | :------------------ | :------ | :--- | :--- | :------- | :--------------------------------------- |
| 1   | SIMPLE      | user  | null       | range | idx_user_biz_id_msg | idx_user_biz_id_msg | 8       | null | 1    | 100      | Using where; Using index; Using filesort |

```SQL
EXPLAIN SELECT * FROM user WHERE biz_id > 2 AND message = '' ORDER BY id DESC ;
```

| id  | select_type | table | partitions | type  | possible_keys       | key                 | key_len | ref  | rows | filtered | Extra                                              |
| :-- | :---------- | :---- | :--------- | :---- | :------------------ | :------------------ | :------ | :--- | :--- | :------- | :------------------------------------------------- |
| 1   | SIMPLE      | user  | null       | range | idx_user_biz_id_msg | idx_user_biz_id_msg | 8       | null | 1    | 10       | Using index condition; Using where; Using filesort |

## IN or EXISTS?

```SQL
DROP TABLE IF EXISTS task;

CREATE TABLE task
(
    id      bigint(20)                          NOT NULL COMMENT 'User ID',
    biz_id  bigint(20)                          NOT NULL COMMENT 'Business ID',
    message text COMMENT 'Business information',
    created timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE = InnoDB COMMENT 'Order'
  CHARSET = utf8mb4;

CREATE INDEX idx_task_biz_id ON task(biz_id);

DELIMITER
$$
CREATE PROCEDURE insertTaskData(IN start_id int, IN end_id int, IN bizId int)
BEGIN
    DECLARE i int DEFAULT start_id;

    WHILE i <= end_id
        DO
            INSERT INTO task (id, biz_id, message) VALUES (i, bizId, SUBSTRING(MD5(RAND()), 1, 8));

            SET i = i + 1;
        END WHILE;
END
$$
DELIMITER ;

-- Insert first business id 1 data
CALL insertTaskData(1, 1, 1);
-- Insert one million other data
CALL insertTaskData(2, 10, 2);
-- Insert second business id 1 data
CALL insertTaskData(11, 11, 1);
CALL insertTaskData(12, 12, 3);
CALL insertTaskData(13, 13, 4);
CALL insertTaskData(14, 14, 5);
CALL insertTaskData(15, 15, 6);
CALL insertTaskData(16, 16, 7);
```

### Analysis

- Principle of small table driving large table

```SQL
EXPLAIN SELECT COUNT(*) FROM task LEFT JOIN user u ON task.biz_id = u.biz_id;
```

| id  | select_type | table | partitions | type  | possible_keys       | key                 | key_len | ref              | rows   | filtered | Extra       |
| :-- | :---------- | :---- | :--------- | :---- | :------------------ | :------------------ | :------ | :--------------- | :----- | :------- | :---------- |
| 1   | SIMPLE      | task  | null       | index | null                | idx_task_biz_id     | 8       | null             | 16     | 100      | Using index |
| 1   | SIMPLE      | u     | null       | ref   | idx_user_biz_id_msg | idx_user_biz_id_msg | 8       | test.task.biz_id | 996761 | 100      | Using index |

```SQL
SELECT COUNT(*) FROM task LEFT JOIN user u ON task.biz_id = u.biz_id;
-- [2023-08-30 10:04:52] 1 row retrieved starting from 1 in 2 s 784 ms (execution: 2 s 766 ms, fetching: 18 ms)
```

---

```SQL
EXPLAIN SELECT COUNT(*) FROM user u LEFT JOIN task t ON u.biz_id = t.biz_id;
```

| id  | select_type | table | partitions | type  | possible_keys   | key                 | key_len | ref           | rows   | filtered | Extra       |
| :-- | :---------- | :---- | :--------- | :---- | :-------------- | :------------------ | :------ | :------------ | :----- | :------- | :---------- |
| 1   | SIMPLE      | u     | null       | index | null            | idx_user_biz_id_msg | 43      | null          | 996761 | 100      | Using index |
| 1   | SIMPLE      | t     | null       | ref   | idx_task_biz_id | idx_task_biz_id     | 8       | test.u.biz_id | 5      | 100      | Using index |

```SQL
SELECT COUNT(*) FROM user u LEFT JOIN task t ON u.biz_id = t.biz_id;
-- [2023-08-30 10:04:57] 1 row retrieved starting from 1 in 4 s 527 ms (execution: 4 s 504 ms, fetching: 23 ms)
```

---

```SQL
EXPLAIN SELECT COUNT(*) FROM task WHERE biz_id IN ( SELECT biz_id FROM user);
```

| id  | select_type  | table             | partitions | type   | possible_keys             | key                       | key_len | ref              | rows   | filtered | Extra       |
| :-- | :----------- | :---------------- | :--------- | :----- | :------------------------ | :------------------------ | :------ | :--------------- | :----- | :------- | :---------- |
| 1   | SIMPLE       | task              | null       | index  | idx_task_biz_id           | idx_task_biz_id           | 8       | null             | 16     | 100      | Using index |
| 1   | SIMPLE       | &lt;subquery2&gt; | null       | eq_ref | &lt;auto_distinct_key&gt; | &lt;auto_distinct_key&gt; | 8       | test.task.biz_id | 1      | 100      | null        |
| 2   | MATERIALIZED | user              | null       | index  | idx_user_biz_id_msg       | idx_user_biz_id_msg       | 43      | null             | 996761 | 100      | Using index |

```SQL
SELECT COUNT(*) FROM task WHERE biz_id IN (SELECT biz_id FROM user);
-- [2023-08-30 10:04:35] 1 row retrieved starting from 1 in 443 ms (execution: 399 ms, fetching: 44 ms)
```

---

```SQL
EXPLAIN SELECT COUNT(*) FROM user WHERE biz_id IN (SELECT biz_id FROM task);
```

| id  | select_type  | table             | partitions | type   | possible_keys             | key                       | key_len | ref              | rows   | filtered | Extra       |
| :-- | :----------- | :---------------- | :--------- | :----- | :------------------------ | :------------------------ | :------ | :--------------- | :----- | :------- | :---------- |
| 1   | SIMPLE       | user              | null       | index  | idx_user_biz_id_msg       | idx_user_biz_id_msg       | 43      | null             | 996761 | 100      | Using index |
| 1   | SIMPLE       | &lt;subquery2&gt; | null       | eq_ref | &lt;auto_distinct_key&gt; | &lt;auto_distinct_key&gt; | 8       | test.user.biz_id | 1      | 100      | null        |
| 2   | MATERIALIZED | task              | null       | index  | idx_task_biz_id           | idx_task_biz_id           | 8       | null             | 16     | 100      | Using index |

```SQL
SELECT COUNT(*) FROM user WHERE biz_id IN (SELECT biz_id FROM task);
-- [2023-08-30 10:04:58] 1 row retrieved starting from 1 in 545 ms (execution: 507 ms, fetching: 38 ms)
```

---

```SQL
EXPLAIN SELECT COUNT(*) FROM task WHERE EXISTS(SELECT biz_id FROM user WHERE user.biz_id = task.biz_id);
```

| id  | select_type  | table             | partitions | type   | possible_keys             | key                       | key_len | ref              | rows   | filtered | Extra       |
| :-- | :----------- | :---------------- | :--------- | :----- | :------------------------ | :------------------------ | :------ | :--------------- | :----- | :------- | :---------- |
| 1   | SIMPLE       | task              | null       | index  | idx_task_biz_id           | idx_task_biz_id           | 8       | null             | 16     | 100      | Using index |
| 1   | SIMPLE       | &lt;subquery2&gt; | null       | eq_ref | &lt;auto_distinct_key&gt; | &lt;auto_distinct_key&gt; | 8       | test.task.biz_id | 1      | 100      | null        |
| 2   | MATERIALIZED | user              | null       | index  | idx_user_biz_id_msg       | idx_user_biz_id_msg       | 43      | null             | 996761 | 100      | Using index |

```SQL
EXPLAIN format=tree SELECT COUNT(*) FROM task WHERE EXISTS(SELECT biz_id FROM user WHERE user.biz_id = task.biz_id);
-- -> Aggregate: count(0)  (cost=3189638.65 rows=1)
--     -> Nested loop inner join  (cost=1594821.05 rows=15948176)
--         -> Index scan on task using idx_task_biz_id  (cost=1.85 rows=16)
--         -> Single-row index lookup on <subquery2> using <auto_distinct_key> (biz_id=task.biz_id)
--             -> Materialize with deduplication  (cost=202826.45..202826.45 rows=996761)
--                 -> Index scan on user using idx_user_biz_id_msg  (cost=103150.35 rows=996761)
```

```SQL
SELECT COUNT(*) FROM task WHERE EXISTS(SELECT biz_id FROM user WHERE user.biz_id = task.biz_id);
-- [2023-08-30 10:04:59] 1 row retrieved starting from 1 in 459 ms (execution: 421 ms, fetching: 38 ms)
```

---

```SQL
EXPLAIN SELECT COUNT(*) FROM user WHERE EXISTS(SELECT biz_id FROM task WHERE user.biz_id = task.biz_id);
```

| id  | select_type  | table             | partitions | type   | possible_keys             | key                       | key_len | ref              | rows   | filtered | Extra       |
| :-- | :----------- | :---------------- | :--------- | :----- | :------------------------ | :------------------------ | :------ | :--------------- | :----- | :------- | :---------- |
| 1   | SIMPLE       | user              | null       | index  | idx_user_biz_id_msg       | idx_user_biz_id_msg       | 43      | null             | 996761 | 100      | Using index |
| 1   | SIMPLE       | &lt;subquery2&gt; | null       | eq_ref | &lt;auto_distinct_key&gt; | &lt;auto_distinct_key&gt; | 8       | test.user.biz_id | 1      | 100      | null        |
| 2   | MATERIALIZED | task              | null       | index  | idx_task_biz_id           | idx_task_biz_id           | 8       | null             | 16     | 100      | Using index |


```SQL
EXPLAIN format=tree SELECT COUNT(*) FROM user WHERE EXISTS(SELECT biz_id FROM task WHERE user.biz_id = task.biz_id);
-- -> Aggregate: count(0)  (cost=3392461.65 rows=1)
--     -> Nested loop inner join  (cost=1797644.05 rows=15948176)
--         -> Index scan on user using idx_user_biz_id_msg  (cost=103150.35 rows=996761)
--         -> Single-row index lookup on <subquery2> using <auto_distinct_key> (biz_id=`user`.biz_id)
--             -> Materialize with deduplication  (cost=3.45..3.45 rows=16)
--                 -> Index scan on task using idx_task_biz_id  (cost=1.85 rows=16)
```

```
(ChatGPT)
In the first query, the system first performs an index scan on the task table, scanning the idx_task_biz_id index.
Then it performs a single-row index lookup on subquery<subquery2>, looking up with the key biz_id=task.biz_id.
This is a typical nested loop join, where the system gets a row of data from the task table, then searches for this row in subquery<subquery2>.
This process continues until all rows in the task table have been searched in subquery<subquery2>.

In the second query, the system first performs an index scan on the user table, scanning the idx_user_biz_id_msg index.
Then it performs a single-row index lookup on subquery<subquery2>, looking up with the key biz_id=user.biz_id.
This query's execution process is similar to the first query, but this time starting from the user table.
```

```SQL
SELECT COUNT(*) FROM user WHERE EXISTS(SELECT biz_id FROM task WHERE user.biz_id = task.biz_id);
-- [2023-08-30 10:05:00] 1 row retrieved starting from 1 in 567 ms (execution: 523 ms, fetching: 44 ms)
```

- In the materials I've researched, it's repeatedly emphasized that small table driving produces less data volume than large table driving. I find this hard to accept. Whether small table or large table driving, the final data volume should be the same, otherwise the results would be different, and mathematically 10 * 10000 and 10000 * 10 should produce the same data volume.
- However, there is indeed a difference in IO. Large table driving will perform IO and index query operations according to the large table.

Reference

1. [MySQL Index Background Data Structures and Algorithm Principles](http://blog.codinglabs.org/articles/theory-of-mysql-index.html)
2. [(MySQL) Simple and Easy-to-Understand B+ Tree Index Introduction](https://blog.csdn.net/qq_43352723/article/details/120516281)
3. [MySQL B+ Tree Index Usage](https://www.xjx100.cn/news/311647.html?action=onClick)
4. [Differences Between B Trees and B+ Trees](https://blog.csdn.net/qq_44918090/article/details/120278339)
5. [MySQL Practice - Huge Impact of Limit and Order by on Query Efficiency](https://blog.csdn.net/zhibo_lv/article/details/117846795)
6. [Understanding Order By in One Read: Detailed Explanation](https://zhuanlan.zhihu.com/p/380671457)

