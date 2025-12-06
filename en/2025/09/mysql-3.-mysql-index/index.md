# [MySQL] 3. MySQL Index


## What is an Index?

- Index is a data structure that improves the speed of data retrieval operations on a database table at the cost of additional writes and storage space to maintain the index data structure.

## Index Types

### By Data Structure

#### Hash Index

- Hash Index is based on a hash table data structure. It uses a hash function to map keys to specific locations in the hash table, allowing for very fast data retrieval.
- Algorithm Complexity: O(1)
- Advantages:
  - Very fast for equality searches (e.g., `=`).
- Disadvantages:
  - Not suitable for range queries (e.g., `<`, `>`, `BETWEEN`).
  - Hash collisions can occur, leading to performance degradation.

##### why not support `order by`

- let us see the algorithm of hash index

![6. hash function.svg](/images/13.%20mysql%20index/6.%20hash%20function.svg)

- We see that hash index which is k-v structure. So v is not sorted, so it can not support `order by`.

#### BTree(B-Tree) Index 

##### why not AVL or Red-Black Tree

- As to Tree Index, we can think about balanced search tree like AVL tree or Red-Black tree
  - Algorithm Complexity: O(log n)

![4. AVL.svg](/images/13.%20mysql%20index/4.%20AVL.svg)          ![5. Red-Black.svg](/images/13.%20mysql%20index/5.%20Red-Black.svg)

- Obviously, they are binary balance search tree which is not suitable for database index because:
  - High tree height: Binary trees can become tall, leading to increased search times.
  - Frequent rebalancing: Insertions and deletions often require tree rotations to maintain balance, which can be costly in terms of performance.
  - Poor disk I/O performance: Binary trees do not take advantage of spatial locality, leading to inefficient disk access patterns.
    - Disk I/O cost much more than memory access.

##### Why BTree

- So, to reduce the tree height and disk I/O, BTree comes out naturally.
  - Firstly, multi-way tree is used to reduce the tree height.
  - Secondly, each node contains entire disk page data to reduce the disk I/O.

![3. btree_index.svg](/images/13.%20mysql%20index/3.%20btree_index.svg)

- But we still have some problems:
  - When we insert or delete data, the tree may become unbalanced.
  - It is hard to search in order that we need to use in-order traversal, much cost, to get sorted data.
  - So, B+Tree comes out.

#### B+Tree Index

- Firstly, B+Tree reduce the tree node size by only storing keys in internal nodes, which allows more keys to fit in memory and reduces tree height.
  - no value means more keys in one node => less tree height => less disk I/O
- Secondly, B+Tree stores all actual data in leaf nodes, which are linked together in a linked list, so that range queries more efficient.

![1. single_index.svg](/images/13.%20mysql%20index/1.%20single_index.svg)

### By Usage

#### Primary Key Index

- Primary key index is automatically created for primary key columns. If there is no primary key, MySQL will create one. 
- Ensures uniqueness and fast access to records, because only one action can get the entire record.
- Primary Key is B+Tree

![2. composite_index.svg](/images/13.%20mysql%20index/2.%20composite_index.svg)

#### Composite Index

- We know MySQL support composite index which is index on multiple columns.

![2. composite_index.svg](/images/13.%20mysql%20index/2.%20composite_index.svg)

- Let us see the single leaf pages.
    - The leaf pages are sorted by the first column, and then by the second column.
        - {column A, column B} : (1, 1), (1, 2), (2, 1), (2, 2), (3, 1), (3, 2)

- So, let us thinking the classical question: (leftmost prefix rule)
    - If we have a composite index on (A, B), can we use it for query `where B = 1`?
        - No, because the leaf pages are sorted by A first, then B. So we can not find all B = 1 quickly.
    - If we have a composite index on (A, B), can we use it for query `where A = 1 AND B > 1`?
        - Yes, because we can find A = 1 quickly, then we get `(1, 1), (1, 2)` which means B is in order, so we can find B > 1 quickly.
    - If we have a composite index on (A, B), can we use it for query `where A > 1 AND B > 1`?
        - Yes, but only A > 1 is used. Because we will get `(2, 1), (2, 2), (3, 1), (3, 2)` which means B is not in order.

#### Secondary Index (Non-Clustered Index)

- Secondary index is also called non-clustered index, which is different from clustered index (primary key index).
- **Key Difference**: Secondary index leaf nodes only store **index columns + primary key values**, not the complete row data.
- **Index Structure**: B+Tree structure, but leaf nodes contain references to primary key instead of full row data.

![8. secondary_index.svg](/images/13.%20mysql%20index/8.%20secondary_index.svg)

##### Covering Index vs Table Lookup

- **Covering Index**: When query fields are all included in the secondary index, no table lookup needed.
  ```sql
  -- Index: idx_AB (A, B)
  SELECT A, B FROM table WHERE A = 1;  -- ✅ Covering index, no lookup
  ```

- **Table Lookup**: When query needs fields not in the secondary index, must lookup primary key.
  ```sql
  -- Index: idx_AB (A, B), but need field C
  SELECT A, B, C FROM table WHERE A = 1;  -- ❌ Need table lookup for field C
  ```

##### Table Lookup Process

1. **Search Secondary Index**: Find matching records, get primary key values
2. **Lookup Primary Index**: Use primary key to fetch complete row data from clustered index
3. **Return Results**: Combine data from both indexes

This is why `SELECT *` often requires table lookup, while selecting only indexed columns can avoid it.

#### Full-Text Index

- Full-Text index is designed to solve finding words in large text problems using **inverted index** structure.

![7. fulltext_index-Full_Text_Index.svg](/images/13.%20mysql%20index/7.%20fulltext_index-Full_Text_Index.svg)

##### Key Differences from B+Tree Index

| Feature | B+Tree Index | Full-Text Index |
|---------|---------------|-----------------|
| **Data Structure** | Balanced tree | Inverted index (word → documents) |
| **Storage** | Complete row data in leaves | Word-to-document mappings |
| **Query Type** | Exact match, range queries | Text search, relevance ranking |
| **Complexity** | O(log n) | Depends on word frequency |

##### Inverted Index Mechanism

1. **Tokenization**: Split text into individual words
2. **Word Mapping**: Create word → document list mappings
3. **Search Process**: Find documents containing query words
4. **Intersection**: Combine results for multi-word queries

##### Supported Data Types
- `CHAR`
- `VARCHAR`
- `TEXT`

##### Create Table Grammar

```sql
-- Single column full-text index
CREATE TABLE articles (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255),
    content TEXT,
    FULLTEXT KEY ft_content (content)
) ENGINE=InnoDB;

-- Multi-column full-text index
CREATE TABLE articles (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255),
    content TEXT,
    FULLTEXT KEY ft_title_content (title, content)
) ENGINE=InnoDB;
```

##### Search Modes

###### Natural Language Mode (Default)
```sql
SELECT * FROM articles
WHERE MATCH(title, content) AGAINST('MySQL optimization');

-- With relevance score
SELECT *, MATCH(title, content) AGAINST('MySQL optimization') as score
FROM articles
WHERE MATCH(title, content) AGAINST('MySQL optimization')
ORDER BY score DESC;
```

###### Boolean Mode
```sql
-- Must contain "MySQL", must not contain "Oracle"
SELECT * FROM articles
WHERE MATCH(title, content) AGAINST('+MySQL -Oracle' IN BOOLEAN MODE);

-- Exact phrase search
SELECT * FROM articles
WHERE MATCH(title, content) AGAINST('"index optimization"' IN BOOLEAN MODE);

-- Wildcard search
SELECT * FROM articles
WHERE MATCH(title, content) AGAINST('optim*' IN BOOLEAN MODE);
```

## Advanced Index Optimization Concepts

Let's analyze various SQL queries to understand **Covering Index**, **Index Condition Pushdown (ICP)**, and **Key Lookup (回表)** behaviors.

### Table Structure and Index

```sql
CREATE TABLE articles (
    id INT PRIMARY KEY AUTO_INCREMENT,
    A BIGINT NOT NULL,
    B BIGINT NOT NULL,
    C BIGINT NOT NULL,
    D BIGINT NOT NULL
) ENGINE=InnoDB;

-- Composite index on columns A, B, C
CREATE INDEX idx_articles_query ON articles (A, B, C);
```

**Index Structure**: `idx_articles_query (A, B, C)`(secondary index) + Primary Key `id` (automatically included in secondary indexes)

### Covering Index

- **Covering Index**: When all query columns are included in the index, eliminating the need for table lookup.
- So, if the query need a table lookup, it must not be a `Covering Index` 

#### Not Covering Index: table lookup for other columns return

```sql
SELECT * FROM articles WHERE A = 1;
SELECT * FROM articles WHERE A = 1 AND B > 1;
SELECT * FROM articles WHERE A = 1 AND B > 1 AND C = 1;
SELECT * FROM articles WHERE A = 1 AND B > 1 AND C = 1 AND D = 1;
SELECT A, B, C, D FROM articles WHERE A = 1 AND B > 1 AND C = 1;
SELECT A, B, C, D FROM articles WHERE A = 1 AND B > 1 AND C = 1 AND D = 1;
```

#### Not Covering Index: table lookup for other columns as conditions

```sql
SELECT * FROM articles WHERE A = 1 AND B > 1 AND C = 1 AND D = 1;
SELECT A, B, C FROM articles WHERE A = 1 AND B > 1 AND C = 1 AND D = 1;
SELECT A, B, C, D FROM articles WHERE A = 1 AND B > 1 AND C = 1 AND D = 1;
```

#### Covering Index success

```sql
SELECT A, B, C FROM articles WHERE A = 1 AND B > 1 AND C = 1;
```

### Index Condition Pushdown

**ICP**: Pushes WHERE conditions that can use the index down to the storage engine level, reducing table lookups.

#### Not ICP : Just one condition

```sql
SELECT * FROM articles WHERE A = 1;
```

#### ICP Success 

**even skip one index column**

```sql
SELECT * FROM articles WHERE A = 1 AND C > 1;
```

**even has other index column**

```sql
SELECT * FROM articles WHERE A = 1 AND B > 1 AND C = 1 AND D = 1;
SELECT A, B, C FROM articles WHERE A = 1 AND B > 1 AND C = 1 AND D = 1;
SELECT A, B, C, D FROM articles WHERE A = 1 AND B > 1 AND C = 1 AND D = 1;
```

**normal**

```sql
SELECT * FROM articles WHERE A = 1 AND B > 1;
SELECT * FROM articles WHERE A = 1 AND B > 1 AND C = 1;
SELECT A, B, C FROM articles WHERE A = 1 AND B > 1 AND C = 1;
SELECT A, B, C, D FROM articles WHERE A = 1 AND B > 1 AND C = 1;
```

### Key Lookup

- Secondary index only save `id` that key lookup will occur if there has other column.
- Key Lookup is the action we `need to avoid`. Because it cost more.

#### Key Lookup : return more columns

```sql
SELECT * FROM articles WHERE A = 1;
SELECT * FROM articles WHERE A = 1 AND B > 1;
SELECT * FROM articles WHERE A = 1 AND B > 1 AND C = 1;
SELECT * FROM articles WHERE A = 1 AND B > 1 AND C = 1 AND D = 1;
SELECT A, B, C, D FROM articles WHERE A = 1 AND B > 1 AND C = 1;
SELECT A, B, C, D FROM articles WHERE A = 1 AND B > 1 AND C = 1 AND D = 1;
```

#### Key Lookup : conditions contain more column

```sql
SELECT * FROM articles WHERE A = 1 AND B > 1 AND C = 1 AND D = 1;
SELECT A, B, C FROM articles WHERE A = 1 AND B > 1 AND C = 1 AND D = 1;
SELECT A, B, C, D FROM articles WHERE A = 1 AND B > 1 AND C = 1 AND D = 1;
```

#### Not Key Lookup(Good) 

```sql
SELECT A, B, C FROM articles WHERE A = 1 AND B > 1 AND C = 1;
```

**id contains in secondary index leaf** 

```sql
SELECT id, A, B, C FROM articles WHERE A = 1 AND B > 1 AND C = 1;
```

## Index Usage Experience

### When to Use Hash Index

1. Just search `one` picture.
2. The column content nearly random or unrelated, such as UUID.

### Filter rate is the point for index usage

1. If reusable, index should be less. 
2. The index design is point to more filter rate.

#### Classic Question: (id, begin, end) vs (id, end, begin)

- coupons table

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

##### find the actives coupons.  

- Let us analysis if we search the below SQL.
  - SELECT * FROM `table` WHERE id = 7 AND begin < 1234567894000 AND end > 1234567894000

1. `Index Condition Pushdown` can be used for this query.
2. Only `first two column index` can be used which is (id, begin) in (id, begin, end) or (id, end) in (id, end, begin).
3. But, as to (id, begin) part, begin > 1234567894000 always filter less data, which the time always be `now`.
   - Because there are always data begin less than now.
4. As to (id, end) part, end > 1234567894000 always filter more data, which time always be `now`.

> So the better one is (id, end, begin)

#### Classic Question: types index

- Assume there are 5 types

##### nearly average like computer types

- INDEX idx_computer_type(type)
- In this situation, when we use type = 1, just nearly 20% filter rate.

##### not average like payment status

- INDEX idx_payment_status(status)
- In this situation, almost payment will be status = final.
- `But` we always query the status != final which just occupy a little data like less than 1% (nearly more than 99% filter rate).

### Data Size VS Index Size

- People always think that if data is just a little, there is no need to create index.
- When data is not large, it does not matter if we have many indexes.
  - Because indexes will not use much storage.
- When data is large, it does not matter if we have many indexes.
  - Because indexes will be important for us to query quickly.

### Do not modify index column frequently

- We know the index is balanced and in order. If we modify the index column value, the B+Tree need to rebalance itself which cost much.


