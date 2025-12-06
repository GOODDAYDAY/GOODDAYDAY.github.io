+++
date = '2025-09-21T23:11:17+08:00'
draft = false
title = '[MySQL] 1. 浅谈 MySQL 快速查询'
categories = ["MySQL"]
tags = ["MySQL", "index", "database", "optimization"]
+++

## 讲在开头

- 在最开始先举几个我们常用的在平时学习、业务上最常见的优化措施

    1. 单位时间内更多的事情

        - 快排使用二分的思想，单次循环内对多个数组进行排序

          ![1. 快排.jpg](/images/3.%20%E6%B5%85%E8%B0%88MySQL%E5%BF%AB%E9%80%9F%E6%9F%A5%E8%AF%A2/1.%20%E5%BF%AB%E6%8E%92.jpg)

    2. 总量查更少的信息
        - KMP 算法对主串进行预处理，做到减少匹配次数。这就是逻辑的力量

          ![2. KMP.jpg](/images/3.%20%E6%B5%85%E8%B0%88MySQL%E5%BF%AB%E9%80%9F%E6%9F%A5%E8%AF%A2/2.%20KMP.jpg)

        - 搜索树通过二分的思想，每次过滤剩余数据的一半来提高效率。这就是数据结构的力量

          ![3. 搜索树.webp](/images/3.%20%E6%B5%85%E8%B0%88MySQL%E5%BF%AB%E9%80%9F%E6%9F%A5%E8%AF%A2/3.%20%E6%90%9C%E7%B4%A2%E6%A0%91.webp)

- 对于 MySQL 的快速查询，最为关键的核心就是查询数据量少，越少越快。整篇文章均围绕该句进行展开。

## 没有索引是否一定会慢？

- 定义插入数据函数

```SQL
DROP TABLE IF EXISTS user;
CREATE TABLE user
(
    id      bigint(20)                          NOT NULL COMMENT '用户id',
    biz_id  bigint(20)                          NOT NULL COMMENT '业务id',
    message text COMMENT '业务信息',
    created timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE = InnoDB COMMENT '用户'
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

- 准备数据若干，bizId 为 1 的只有两条，第一条和最后一条数据

```SQL
-- 插入第一条业务id1数据
CALL insertUserData(1, 1, 1);
-- 插入一百万万条其他数据
CALL insertUserData(2, 1000000, 2);
-- 插入第二条业务id1数据
CALL insertUserData(1000001, 1000001, 1);
```

- 其实看数据分布，我想大家已经知道我想表达的，即便不使用索引。我们这里也是有快速查询的场景。

**查询 limit1**

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

- 从实际出发，我们可以看到，limit1 和 limit2 的执行时间相差巨大。
- 这里先分享一个技巧，我们可以使用 chatgpt 来高效整理分析 explain。

```
(文心一言)
这个查询计划显示了一个对user表的完整扫描，没有使用索引，并且WHERE子句用于筛选结果。
如果表很大或者查询的性能低，这可能会导致性能问题。
优化可能需要考虑使用合适的索引来提高查询性能。
```

- 我们可以看到，limit1 和 limi2 中，执行计划是几乎完全一致的。这个可以肯定，两次虽然时间相差巨大，但是对于 MySQL 来说执行逻辑相同。那为什么会相差巨大呢？就需要我们来具体分析。
- 在 limit1 的场景中，基于全表扫描，在第一条数据立即返回。等于仅查询了一条数据。
- 在 limit2 的场景中，第二条数据在百万条之后，所以根据执行计划，必须要扫描到全表才可以完整找到数据。
- 综上，没有索引就一定慢么？不一定的，索引仅仅是减少了数据查询量，但数据量本就极少的情况。是不会更慢的。

## 索引

- explain 里使用 where，根据 chatgpt 的回复，以及自己的分析。我们很自然地能想到索引来进行查询的优化。使用 B+树索引进行尝试。

### B+树索引

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

- 可以看到，增加索引之后，查询时间极大优化。执行计划从 where 进化为了使用 const

```
(文心一言)
在你的例子中，这个查询对名为"user"的表进行查询
使用了名为"idx_user_biz_id"的索引，索引长度为8字节
比较列是常量（const），系统估算需要扫描2行数据，返回的行占总行的100%，没有其他额外信息。
```

#### 为什么是 B+树

**平衡二叉树**

![4. 平衡二叉树.png](/images/3.%20%E6%B5%85%E8%B0%88MySQL%E5%BF%AB%E9%80%9F%E6%9F%A5%E8%AF%A2/4.%20%E5%B9%B3%E8%A1%A1%E4%BA%8C%E5%8F%89%E6%A0%91.png)

- 在平衡二叉树中，我们可以思考一下查询的过程。
- 假设要查询 5~16 的所有数据。需要查询六个节点，且查出来的顺序非天然顺序排序，需要中序遍历的算法实现才可以。所以我们可以看到，平衡树是查找单个节点的天然数据结构，对于范围查询的支持相对较差
- 第一个待优化点，如果要细致理解，需要深入到磁盘预读取的优化。我认为理解必要不大，可以简单理解为 IO 次数过多
    - 平衡树，逻辑较近的地方，可能物理距离较远，导致在磁盘旋转操作中 IO 时间较长
- 第二个待优化点，在 IO 读取数据时，会有过多的无用数据。因为读取数据回来必须大于单个节点数据的大小。
- 另外平衡二叉树，保持平衡需要旋转，在内存操作中比较难以高效实现

**B 树**

![5. B树.png](/images/3.%20%E6%B5%85%E8%B0%88MySQL%E5%BF%AB%E9%80%9F%E6%9F%A5%E8%AF%A2/5.%20B%E6%A0%91.png)

- 针对上述优化点，我们可以很自然地将`二叉`往`多叉`的方向优化，这样优化了单个节点过多无用数据的问题。因为单个节点较大的时候，IO 次数也降了下来
- 这样 B 树的思想可以很自然地出现。通过扩大节点形成多叉结构
- 但其实仔细想来，中序遍历算法的实现依然需要。对于范围查询仅优化在单个节点上，当范围跨度较大的时候，性能依然有可优化空间

**B+树**

![6. B+树.png](/images/3.%20%E6%B5%85%E8%B0%88MySQL%E5%BF%AB%E9%80%9F%E6%9F%A5%E8%AF%A2/6.%20B%2B%E6%A0%91.png)

- B+树首先更加优化了单个节点的存储效率(没有了 Value)。这样单个节点可以支持的`叉`更多了
- 同时最底层的叶子节点通过指针组合成为链表，从而优化遍历逻辑。
    - 注: B+树的最底层是包含上层所有节点的

### B+树联合索引

![7. 联合索引.png](/images/3.%20%E6%B5%85%E8%B0%88MySQL%E5%BF%AB%E9%80%9F%E6%9F%A5%E8%AF%A2/7.%20%E8%81%94%E5%90%88%E7%B4%A2%E5%BC%95.png)

- B+树的部分已经了解了，可以简单降之前的 B+树理解为聚簇索引，Value 在最底层的叶子节点
- 那么我们开始理解联合索引

**最左匹配原则**

- 具体原则，不需要讲述，理解即可

**B+树索引为什么是排序的？**

- 在上图中，我们一级索引是顺序的，这个很好理解，当一级索引固定时，其下的二级索引也是顺序的。
- 我的理解是，B+树先搜索一级索引。当一级索引确定后，B+树转化为二级索引的 B+树。依次类推
    - 注：联合索引在一颗树上

**B+树索引为什么失效？**

- 首先我们可以理解一级索引为 1 的二级索引顺序和一级索引为 2 的二级索引顺序是没有必然先后顺序的。只是都具有相同的单调性而已
- 顺着我之前的索引数变化的方向去理解，当一级索引成为一个范围之后，二级索引不止一颗了，我们没有办法在多颗树上进行相同的范围单次查询。只能多次组合

#### 什么是回表？

- 默认大家了解聚簇索引和二级索引
- 回表通俗地说就是，二级索引走完玩不下去了，比如之前的表
- 注: Type 表示访问类型的优化顺序，从最好到最差的顺序如下：system->const->eq_ref->ref->ref_or_null->index_merge->unique_subquery->index_subquery->range->index->all。一般来说，我们希望达到 ref 和 eq_ref 级别，范围查找需要达到 range 级别。

```SQL
DROP TABLE IF EXISTS user;
CREATE TABLE user
(
    id      bigint(20)                          NOT NULL COMMENT '用户id',
    biz_id  bigint(20)                          NOT NULL COMMENT '业务id',
    message text COMMENT '业务信息',
    created timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE = InnoDB COMMENT '用户'
  CHARSET = utf8mb4;

CREATE INDEX idx_user_biz_id ON user (biz_id);
```

- 完全使用索引

```SQL
EXPLAIN  SELECT id FROM `user` WHERE biz_id = 2;
```

| id  | select_type | table | partitions | type | possible_keys   | key             | key_len | ref   | rows   | filtered | Extra       |
| :-- | :---------- | :---- | :--------- | :--- | :-------------- | :-------------- | :------ | :---- | :----- | :------- | :---------- |
| 1   | SIMPLE      | user  | null       | ref  | idx_user_biz_id | idx_user_biz_id | 8       | const | 498380 | 100      | Using index |

```
(chatgpt)
查询语句涉及的表是"user"表。
表的访问方式为"ref"，表示使用了索引进行查询。
使用的索引为"idx_user_biz_id"，并且查询使用了该索引。
使用的索引长度为8个字节。
查询的参考值为"const"，表示查询使用了一个常量值进行筛选。
查询返回的行数为498380行，过滤率为100%。
"Using index"表示查询使用了覆盖索引，即查询结果可以直接从索引中获取，不需要再去访问表数据。
```

- 回表一次

```SQL
EXPLAIN  SELECT * FROM `user` WHERE biz_id = 2;
```

| id  | select_type | table | partitions | type | possible_keys   | key             | key_len | ref   | rows   | filtered | Extra |
| :-- | :---------- | :---- | :--------- | :--- | :-------------- | :-------------- | :------ | :---- | :----- | :------- | :---- |
| 1   | SIMPLE      | user  | null       | ref  | idx_user_biz_id | idx_user_biz_id | 8       | const | 498380 | 100      | null  |

```
(chatgpt)
该查询是一个简单的SELECT查询，没有子查询或联接。
查询引用了一个名为user的表。
查询使用了名为idx_user_biz_id的索引。
索引的长度为8。
查询使用了一个常量值进行参考。
查询扫描了498380行，并根据WHERE条件过滤了100行。
查询没有其他特殊情况。
```

- 回表一次(回表数据较多)

```SQL
EXPLAIN  SELECT * FROM `user` WHERE biz_id = 2 and message = '';
```

| id  | select_type | table | partitions | type | possible_keys   | key             | key_len | ref   | rows   | filtered | Extra       |
| :-- | :---------- | :---- | :--------- | :--- | :-------------- | :-------------- | :------ | :---- | :----- | :------- | :---------- |
| 1   | SIMPLE      | user  | null       | ref  | idx_user_biz_id | idx_user_biz_id | 8       | const | 498380 | 10       | Using where |

```
(chatgpt)
给定的查询是一个简单的SELECT查询，涉及到名为"user"的表。
查询使用了名为"idx_user_biz_id"的索引，并且使用了WHERE子句。
查询使用了普通的二级索引进行相等匹配。
查询返回了498380行的结果。
```

**索引下推 & 覆盖索引**

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
(chatgpt)
type 字段表示查询的访问方式，从最优到最差的顺序依次是：system, const, eq_ref, ref, ref_or_null, index_merge, unique_subquery, index_subquery, range, index, all。
possible_keys 列出可能有助于查询的索引，如果为空则表示没有可用的索引。
key 列出实际选择使用的索引，如果为 NULL 则表示没有使用索引。
Extra 列出额外的信息，例如 Using where 表示使用了 WHERE 条件过滤。
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

## IN 还是 EXISTS？

```SQL
DROP TABLE IF EXISTS task;

CREATE TABLE task
(
    id      bigint(20)                          NOT NULL COMMENT '用户id',
    biz_id  bigint(20)                          NOT NULL COMMENT '业务id',
    message text COMMENT '业务信息',
    created timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE = InnoDB COMMENT '订单'
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

-- 插入第一条业务id1数据
CALL insertTaskData(1, 1, 1);
-- 插入一百万万条其他数据
CALL insertTaskData(2, 10, 2);
-- 插入第二条业务id1数据
CALL insertTaskData(11, 11, 1);
CALL insertTaskData(12, 12, 3);
CALL insertTaskData(13, 13, 4);
CALL insertTaskData(14, 14, 5);
CALL insertTaskData(15, 15, 6);
CALL insertTaskData(16, 16, 7);
```

### 分析

- 小表驱动大表的原则

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
(chatgpt)
在第一个查询中，系统首先在task表上执行索引扫描，扫描的索引为idx_task_biz_id。
然后在子查询<subquery2>上执行单行索引查找，查找的键为biz_id=task.biz_id。
这是一个典型的嵌套循环连接，系统会获取task表的一行数据，然后在子查询<subquery2>中搜索这一行数据。
这个过程会一直持续到task表的所有行都在子查询<subquery2>中被搜索过sqlshack.com。

在第二个查询中，系统首先在user表上执行索引扫描，扫描的索引为idx_user_biz_id_msg。
然后在子查询<subquery2>上执行单行索引查找，查找的键为biz_id=user.biz_id。
这个查询的执行过程类似于第一个查询，不过这次是从user表开始。
```

```SQL
SELECT COUNT(*) FROM user WHERE EXISTS(SELECT biz_id FROM task WHERE user.biz_id = task.biz_id);
-- [2023-08-30 10:05:00] 1 row retrieved starting from 1 in 567 ms (execution: 523 ms, fetching: 44 ms)
```

- 查询的资料里，反复强调的是小表驱动数据量比大表驱动数据量要少。对于此，其实我是不太能接受。无论小表还是大表驱动，最终的数据量应是相同才对，不然结果不会不同，而且数学上 10 \* 10000 和 10000 \* 10 得出的数据量应相同。
- 不过 IO 确实有差距，大表驱动，会依照大表进行 IO 和索引查询操作。

Reference

1. [MySQL 索引背后的数据结构及算法原理](http://blog.codinglabs.org/articles/theory-of-mysql-index.html)
2. [(MySQL)简单易懂的 B+树索引介绍](https://blog.csdn.net/qq_43352723/article/details/120516281)
3. [MySQL 之 B+树索引的使用](https://www.xjx100.cn/news/311647.html?action=onClick)
4. [B 树与 B+树的区别](https://blog.csdn.net/qq_44918090/article/details/120278339)
5. [MySQL 实战—— Limit 与 Order by 对查询效率的巨大影响](https://blog.csdn.net/zhibo_lv/article/details/117846795)
6. [看一遍就理解：order by 详解](https://zhuanlan.zhihu.com/p/380671457)
