+++
date = '2025-09-28T21:02:17+08:00'
draft = false
title = '[MySQL] 3. MySQL 索引'
categories = ["MySQL"]
tags = ["MySQL", "Index"]
+++

## 什么是索引？

- 索引是一种数据结构，通过额外的写入和存储空间来维护索引数据结构，从而提高数据库表上数据检索操作的速度。

## 索引类型

### 按数据结构分类

#### 哈希索引

- 哈希索引基于哈希表数据结构。它使用哈希函数将键映射到哈希表中的特定位置，允许非常快速的数据检索。
- 算法复杂度：O(1)
- 优点：
  - 对等值查询（如 `=`）非常快。
- 缺点：
  - 不适合范围查询（如 `<`、`>`、`BETWEEN`）。
  - 可能发生哈希冲突，导致性能下降。

##### 为什么不支持 `order by`

- 让我们看看哈希索引的算法

![6. hash function.svg](/images/13.%20mysql%20index/6.%20hash%20function.svg)

- 我们看到哈希索引是键值结构。因此值不是有序的，所以它不能支持 `order by`。

#### BTree(B-Tree) 索引

##### 为什么不用 AVL 或红黑树

- 对于树索引，我们可以考虑平衡搜索树，如 AVL 树或红黑树
  - 算法复杂度：O(log n)

![4. AVL.svg](/images/13.%20mysql%20index/4.%20AVL.svg)          ![5. Red-Black.svg](/images/13.%20mysql%20index/5.%20Red-Black.svg)

- 显然，它们是二叉平衡搜索树，不适合数据库索引，因为：
  - 树高度高：二叉树可能变得很高，导致搜索时间增加。
  - 频繁重新平衡：插入和删除操作经常需要树旋转来维护平衡，这在性能方面代价很高。
  - 磁盘 I/O 性能差：二叉树不利用空间局部性，导致低效的磁盘访问模式。
    - 磁盘 I/O 的成本远高于内存访问。

##### 为什么选择 BTree

- 因此，为了减少树高度和磁盘 I/O，BTree 自然而然地出现了。
  - 首先，使用多路树来减少树高度。
  - 其次，每个节点包含整个磁盘页数据以减少磁盘 I/O。

![3. btree_index.svg](/images/13.%20mysql%20index/3.%20btree_index.svg)

- 但我们仍然有一些问题：
  - 当我们插入或删除数据时，树可能变得不平衡。
  - 很难按顺序搜索，我们需要使用中序遍历，成本很高，才能获得排序数据。
  - 所以，B+Tree 出现了。

#### B+Tree 索引

- 首先，B+Tree 通过只在内部节点中存储键来减少树节点大小，这允许更多键适合内存并减少树高度。
  - 没有值意味着一个节点中有更多键 => 更少的树高度 => 更少的磁盘 I/O
- 其次，B+Tree 将所有实际数据存储在叶节点中，这些节点在链表中链接在一起，使范围查询更高效。

![1. single_index.svg](/images/13.%20mysql%20index/1.%20single_index.svg)

### 按用途分类

#### 主键索引

- 主键索引是为主键列自动创建的。如果没有主键，MySQL 会创建一个。
- 确保唯一性和快速访问记录，因为只有一个操作就能获得整个记录。
- 主键是 B+Tree

![2. composite_index.svg](/images/13.%20mysql%20index/2.%20composite_index.svg)

#### 复合索引

- 我们知道 MySQL 支持复合索引，即多个列上的索引。

![2. composite_index.svg](/images/13.%20mysql%20index/2.%20composite_index.svg)

- 让我们看看单个叶页。
    - 叶页首先按第一列排序，然后按第二列排序。
        - {列 A，列 B}：(1, 1), (1, 2), (2, 1), (2, 2), (3, 1), (3, 2)

- 所以，让我们思考经典问题：（最左前缀规则）
    - 如果我们在 (A, B) 上有复合索引，我们能将其用于查询 `where B = 1` 吗？
        - 不能，因为叶页首先按 A 排序，然后按 B 排序。所以我们不能快速找到所有 B = 1。
    - 如果我们在 (A, B) 上有复合索引，我们能将其用于查询 `where A = 1 AND B > 1` 吗？
        - 可以，因为我们可以快速找到 A = 1，然后我们得到 `(1, 1), (1, 2)`，这意味着 B 是有序的，所以我们可以快速找到 B > 1。
    - 如果我们在 (A, B) 上有复合索引，我们能将其用于查询 `where A > 1 AND B > 1` 吗？
        - 可以，但只有 A > 1 被使用。因为我们将得到 `(2, 1), (2, 2), (3, 1), (3, 2)`，这意味着 B 不是有序的。

#### 二级索引（非聚集索引）

- 二级索引也称为非聚集索引，与聚集索引（主键索引）不同。
- **关键区别**：二级索引叶节点只存储**索引列 + 主键值**，不存储完整的行数据。
- **索引结构**：B+Tree 结构，但叶节点包含对主键的引用而不是完整行数据。

![8. secondary_index.svg](/images/13.%20mysql%20index/8.%20secondary_index.svg)

##### 覆盖索引 vs 回表

- **覆盖索引**：当查询字段都包含在二级索引中时，无需回表。
  ```sql
  -- 索引：idx_AB (A, B)
  SELECT A, B FROM table WHERE A = 1;  -- ✅ 覆盖索引，无需回表
  ```

- **回表**：当查询需要不在二级索引中的字段时，必须查找主键。
  ```sql
  -- 索引：idx_AB (A, B)，但需要字段 C
  SELECT A, B, C FROM table WHERE A = 1;  -- ❌ 需要为字段 C 回表
  ```

##### 回表过程

1. **搜索二级索引**：找到匹配记录，获取主键值
2. **查找主索引**：使用主键从聚集索引获取完整行数据
3. **返回结果**：合并来自两个索引的数据

这就是为什么 `SELECT *` 经常需要回表，而只选择索引列可以避免回表。

#### 全文索引

- 全文索引设计用于解决在大文本中查找单词的问题，使用**倒排索引**结构。

![7. fulltext_index-Full_Text_Index.svg](/images/13.%20mysql%20index/7.%20fulltext_index-Full_Text_Index.svg)

##### 与 B+Tree 索引的关键区别

| 特性 | B+Tree 索引 | 全文索引 |
|---------|---------------|-----------------|
| **数据结构** | 平衡树 | 倒排索引（单词 → 文档） |
| **存储** | 叶子中的完整行数据 | 单词到文档的映射 |
| **查询类型** | 精确匹配，范围查询 | 文本搜索，相关性排名 |
| **复杂度** | O(log n) | 取决于单词频率 |

##### 倒排索引机制

1. **分词**：将文本分解为单个单词
2. **单词映射**：创建单词 → 文档列表映射
3. **搜索过程**：查找包含查询单词的文档
4. **交集**：为多词查询合并结果

##### 支持的数据类型
- `CHAR`
- `VARCHAR`
- `TEXT`

##### 创建表语法

```sql
-- 单列全文索引
CREATE TABLE articles (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255),
    content TEXT,
    FULLTEXT KEY ft_content (content)
) ENGINE=InnoDB;

-- 多列全文索引
CREATE TABLE articles (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255),
    content TEXT,
    FULLTEXT KEY ft_title_content (title, content)
) ENGINE=InnoDB;
```

##### 搜索模式

###### 自然语言模式（默认）
```sql
SELECT * FROM articles
WHERE MATCH(title, content) AGAINST('MySQL 优化');

-- 带相关性评分
SELECT *, MATCH(title, content) AGAINST('MySQL 优化') as score
FROM articles
WHERE MATCH(title, content) AGAINST('MySQL 优化')
ORDER BY score DESC;
```

###### 布尔模式
```sql
-- 必须包含"MySQL"，不能包含"Oracle"
SELECT * FROM articles
WHERE MATCH(title, content) AGAINST('+MySQL -Oracle' IN BOOLEAN MODE);

-- 精确短语搜索
SELECT * FROM articles
WHERE MATCH(title, content) AGAINST('"索引优化"' IN BOOLEAN MODE);

-- 通配符搜索
SELECT * FROM articles
WHERE MATCH(title, content) AGAINST('优化*' IN BOOLEAN MODE);
```

## 高级索引优化概念

让我们分析各种 SQL 查询，以了解**覆盖索引**、**索引条件下推（ICP）**和**回表**行为。

### 表结构和索引

```sql
CREATE TABLE articles (
    id INT PRIMARY KEY AUTO_INCREMENT,
    A BIGINT NOT NULL,
    B BIGINT NOT NULL,
    C BIGINT NOT NULL,
    D BIGINT NOT NULL
) ENGINE=InnoDB;

-- 在列 A, B, C 上的复合索引
CREATE INDEX idx_articles_query ON articles (A, B, C);
```

**索引结构**：`idx_articles_query (A, B, C)`（二级索引）+ 主键 `id`（自动包含在二级索引中）

### 覆盖索引

- **覆盖索引**：当所有查询列都包含在索引中时，消除回表需求。
- 所以，如果查询需要回表，它就不能是`覆盖索引`

#### 非覆盖索引：为其他列返回而回表

```sql
SELECT * FROM articles WHERE A = 1;
SELECT * FROM articles WHERE A = 1 AND B > 1;
SELECT * FROM articles WHERE A = 1 AND B > 1 AND C = 1;
SELECT * FROM articles WHERE A = 1 AND B > 1 AND C = 1 AND D = 1;
SELECT A, B, C, D FROM articles WHERE A = 1 AND B > 1 AND C = 1;
SELECT A, B, C, D FROM articles WHERE A = 1 AND B > 1 AND C = 1 AND D = 1;
```

#### 非覆盖索引：为其他列作为条件而回表

```sql
SELECT * FROM articles WHERE A = 1 AND B > 1 AND C = 1 AND D = 1;
SELECT A, B, C FROM articles WHERE A = 1 AND B > 1 AND C = 1 AND D = 1;
SELECT A, B, C, D FROM articles WHERE A = 1 AND B > 1 AND C = 1 AND D = 1;
```

#### 覆盖索引成功

```sql
SELECT A, B, C FROM articles WHERE A = 1 AND B > 1 AND C = 1;
```

### 索引条件下推

**ICP**：将可以使用索引的 WHERE 条件下推到存储引擎层，减少回表。

#### 非 ICP：只有一个条件

```sql
SELECT * FROM articles WHERE A = 1;
```

#### ICP 成功

**即使跳过一个索引列**

```sql
SELECT * FROM articles WHERE A = 1 AND C > 1;
```

**即使有其他索引列**

```sql
SELECT * FROM articles WHERE A = 1 AND B > 1 AND C = 1 AND D = 1;
SELECT A, B, C FROM articles WHERE A = 1 AND B > 1 AND C = 1 AND D = 1;
SELECT A, B, C, D FROM articles WHERE A = 1 AND B > 1 AND C = 1 AND D = 1;
```

**正常情况**

```sql
SELECT * FROM articles WHERE A = 1 AND B > 1;
SELECT * FROM articles WHERE A = 1 AND B > 1 AND C = 1;
SELECT A, B, C FROM articles WHERE A = 1 AND B > 1 AND C = 1;
SELECT A, B, C, D FROM articles WHERE A = 1 AND B > 1 AND C = 1;
```

### 回表

- 二级索引只保存 `id`，如果有其他列，就会发生回表。
- 回表是我们`需要避免`的操作。因为它代价更高。

#### 回表：返回更多列

```sql
SELECT * FROM articles WHERE A = 1;
SELECT * FROM articles WHERE A = 1 AND B > 1;
SELECT * FROM articles WHERE A = 1 AND B > 1 AND C = 1;
SELECT * FROM articles WHERE A = 1 AND B > 1 AND C = 1 AND D = 1;
SELECT A, B, C, D FROM articles WHERE A = 1 AND B > 1 AND C = 1;
SELECT A, B, C, D FROM articles WHERE A = 1 AND B > 1 AND C = 1 AND D = 1;
```

#### 回表：条件包含更多列

```sql
SELECT * FROM articles WHERE A = 1 AND B > 1 AND C = 1 AND D = 1;
SELECT A, B, C FROM articles WHERE A = 1 AND B > 1 AND C = 1 AND D = 1;
SELECT A, B, C, D FROM articles WHERE A = 1 AND B > 1 AND C = 1 AND D = 1;
```

#### 不回表（好）

```sql
SELECT A, B, C FROM articles WHERE A = 1 AND B > 1 AND C = 1;
```

**id 包含在二级索引叶节点中**

```sql
SELECT id, A, B, C FROM articles WHERE A = 1 AND B > 1 AND C = 1;
```

## 索引使用经验

### 何时使用哈希索引

1. 只搜索`一个`图片。
2. 列内容几乎随机或不相关，如 UUID。

### 过滤率是索引使用的关键点

1. 如果可重用，索引应该更少。
2. 索引设计的要点是更高的过滤率。

#### 经典问题：(id, begin, end) vs (id, end, begin)

- 优惠券表

| user_id | begin         | end           |
|:-------:|---------------|---------------|
|    ~    | ~             | ~             |
|    7    | 1234567890000 | 1234567890100 |
|    7    | 1234567891000 | 1234567891100 |
|    7    | 1234567892000 | 1234567892100 |
|    7    | 1234567893000 | 1234567893100 |
|    7    | 1234567894000 | 1234567894100 |
|    7    | 1234567895000 | 1234567895100 |
|    7    | 1234567896000 | 1234567896100 |
|    7    | 1234567897000 | 1234567897100 |
|    7    | 1234567898000 | 1234567898100 |
|    ~    | ~             | ~             |

##### 查找活跃优惠券

- 让我们分析如果我们搜索下面的 SQL。
  - SELECT * FROM `table` WHERE id = 7 AND begin < 1234567894000 AND end > 1234567894000

1. `索引条件下推`可以用于此查询。
2. 只有`前两列索引`可以使用，即 (id, begin, end) 中的 (id, begin) 或 (id, end, begin) 中的 (id, end)。
3. 但是，对于 (id, begin) 部分，begin > 1234567894000 总是过滤更少的数据，时间总是`现在`。
  - 因为总有数据时间比现在小。
4. 对于 (id, end) 部分，end > 1234567894000 总是能过滤更多的数据。

> 所以更好的是 (id, end, begin)

#### 经典问题：类型索引

- 假设有 5 种类型

##### 几乎平均，如计算机类型

- INDEX idx_computer_type(type)
- 在这种情况下，当我们使用 type = 1 时，只有大约 20% 的过滤率。

##### 不平均，如支付状态

- INDEX idx_payment_status(status)
- 在这种情况下，几乎所有支付都将是 status = final。
- `但是`我们总是查询 status != final，它只占很少的数据，少于 1%（接近超过 99% 的过滤率）。

### 数据大小 VS 索引大小

- 人们总是认为如果数据只是一点点，就不需要创建索引。
- 当数据不大时，有很多索引也没关系。
  - 因为索引不会使用太多存储。
- 当数据很大时，有很多索引也没关系。
  - 因为索引对我们快速查询很重要。

### 不要频繁修改索引列

- 我们知道索引是平衡和有序的。如果我们修改索引列值，B+Tree 需要重新平衡自己，这代价很高。
