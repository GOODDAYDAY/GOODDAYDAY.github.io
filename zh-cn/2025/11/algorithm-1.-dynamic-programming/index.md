# [Algorithm] 1. 动态规划


## 引言

### 什么是动态规划？

动态规划（DP）通常被认为是计算机科学算法中最具挑战性的主题之一。然而，从本质上讲，它只是**一种优化技术**。

动态规划的基本思想是**"不要重复自己"**。

如果你已经解决了一个子问题，你应该保存结果（缓存它），这样你就不必再次计算它。通过用一点**空间**（存储结果）换取**时间**（避免重复计算），动态规划可以将低效的指数级算法（$O(2^n)$）转变为高效的线性算法（$O(n)$）。

#### 一个简单的类比

想象一下，我让你计算：

$$1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 = ?$$

你数一下，告诉我：**"8"**。

现在，如果我在等式末尾再加一个 `+ 1`：
$$1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 \quad \mathbf{+\ 1} = ?$$

你会立即回答：**"9"**。

**为什么？**
你没有重新数前八个 `1`。你记住了之前的结果是 **8**，然后简单地加上 **1**。

**这就是动态规划。**
1. **状态：** 你记住了"前 8 个数字的和"。
2. **转移：** 你使用公式 `当前总和 = 之前的总和 + 1`。

## 核心支柱

### 动态规划的三个核心概念

在解决动态规划问题时，你必须严格遵循三个步骤。把这看作是你的"编码前检查清单"。如果你不能清楚地回答这三点，就不要开始写代码。

#### 定义数组（语义）

我们使用一个数组（通常命名为 `dp[]`）来存储我们的结果。最关键的步骤是定义这个数组的**物理意义**。你必须能够完成这个句子：

> *"`dp[i]` 的值表示..."*

如果你的定义模糊不清，你的逻辑就会失败。
* **糟糕的定义：** `dp[i]` 是 $i$ 的答案。（太抽象）
* **好的定义：** `dp[i]` 表示在售出第 $i$ 件商品后我们能产生的**最大利润**。
* **好的定义：** `dp[i]` 表示到达第 $i$ 级楼梯所需的**最少步数**。

#### 状态转移方程（逻辑）

状态转移方程不是随机的数学公式；它是决策过程的正式描述。

要写出这个方程，你必须问：**"当前状态 $i$ 如何与之前的候选状态相关联？"**

你使用的具体数学运算符严格由**问题的目标**决定。你几乎可以将所有动态规划方程分为三种抽象模式：

##### 模式 A：聚合器（计数 / 求和）
**目标：** "有多少种不同的方法可以到达状态 $i$？"

* **逻辑：** 你不是在选项*之间*选择；你是在**组合**它们。如果你可以从"选项 A"或"选项 B"到达当前状态，那么总的方法数是两个历史记录的总和。
* **抽象方程：**
  $$dp[i] = dp[\text{选项 A}] + dp[\text{选项 B}] + \dots$$
* **思维方式：** 累积。过去的每条有效路径都对现在有贡献。

##### 模式 B：选择器（优化 / 最大或最小）
**目标：** "到达状态 $i$ 的最大利润 / 最小成本是多少？"

* **逻辑：** 你在**竞争**中。你比较"选项 A"（例如，采取某个行动）与"选项 B"（例如，跳过某个行动）。你只关心赢家；失败者被丢弃。
* **抽象方程：**
  $$dp[i] = \max(\text{选项 A 的值}, \quad \text{选项 B 的值})$$
  *（如果你要最小化成本，则使用 $\min$）*
* **思维方式：** 适者生存。只有最佳的先前状态才重要。

##### 模式 C：验证器（存在性 / 布尔）
**目标：** "是否可能到达状态 $i$？"

* **逻辑：** 你在检查**连通性**。如果从先前状态到这里有*至少一条*有效路径，那么当前状态变为有效。
* **抽象方程：**
  $$dp[i] = dp[\text{选项 A}] \lor dp[\text{选项 B}] \dots$$
  *（逻辑或运算）*
* **思维方式：** 传播。如果信号到达了"选项 A"，并且"选项 A"连接到我，那么信号就到达了我。


#### 初始化（基本情况）
状态转移方程驱动逻辑，但它需要一个起点。没有初始化，你的循环将尝试访问负索引（如 `dp[-1]`）或基于空数据计算。

你必须手动设置最小子问题的值。
* 如果你的方程依赖于 `i-1`，你通常需要初始化 `dp[0]`。
* 如果你的方程依赖于 `i-2`，你通常需要初始化 `dp[0]` 和 `dp[1]`。

**把它想象成多米诺骨牌：**
步骤 3 设置第一个多米诺骨牌。步骤 2 确保如果一个倒下，下一个也会倒下。步骤 1 是它们站立的地板。

## 自顶向下方法（递归 + 记忆化）

自顶向下方法使用递归从目标状态分解到基本情况。我们使用记忆化来缓存结果并避免冗余计算。

### 类别 A：求和问题（计数路径）

这些问题问"有多少种方法？"关键洞察是我们**相加**所有通向当前状态的可能路径。

---

#### 爬楼梯（LeetCode 70）

##### **问题：**

你正在爬楼梯。需要 `n` 步才能到达顶部。
每次你可以爬 **1 步**或 **2 步**。
有多少种不同的方法可以爬到顶部？

* **输入：** `n = 3`
* **输出：** `3`
    * *解释：* 有三种方法可以爬到顶部：
        1. 1 步 + 1 步 + 1 步
        2. 1 步 + 2 步
        3. 2 步 + 1 步

##### **解决方案（自顶向下）**

* **1. 数组定义：** `memo[i]` = 到达第 $i$ 级楼梯的不同方法数。
* **2. 方程：** 这是一个**求和**问题。你有两个选择：
  - 从 1 步之前来
  - 从 2 步之前来
  $$memo[i] = memo[i-1] + memo[i-2]$$
* **3. 基本情况：**
    * `memo[0] = 1`（留在地面的一种方法）
    * `memo[1] = 1`（一种方法：走 1 步）

```java
public class ClimbingStairs {
    private int[] memo;

    public int climbStairs(int n) {
        memo = new int[n + 1];
        Arrays.fill(memo, -1);
        return climb(n);
    }

    private int climb(int n) {
        // 基本情况
        if (n == 0) return 1;
        if (n == 1) return 1;

        // 检查记忆化
        if (memo[n] != -1) return memo[n];

        // 递归计算
        int fromOneStepBack = climb(n - 1);
        int fromTwoStepsBack = climb(n - 2);

        // 存储并返回
        memo[n] = fromOneStepBack + fromTwoStepsBack;
        return memo[n];
    }
}
```

---

#### 不同路径（LeetCode 62）

##### **问题：**

机器人位于 `m x n` 网格上。机器人最初位于**左上角**（即 `grid[0][0]`）。
机器人试图移动到**右下角**（即 `grid[m-1][n-1]`）。
机器人在任何时候只能**向下**或**向右**移动。

给定两个整数 `m` 和 `n`，返回机器人可以采取到达右下角的可能唯一路径数。

* **输入：** `m = 3, n = 7`
* **输出：** `28`

**注意：** 答案也可以使用组合数学计算：
$$
C_{m+n-2}^{m-1}
$$

##### **解决方案（自顶向下）**

* **1. 数组定义：** `memo[i][j]` = 到达单元格 $(i, j)$ 的唯一路径数。
* **2. 方程：** 这是一个**求和**问题。你有两个选择：
  * 从**上方**来 (i-1, j)
  * 从**左侧**来 (i, j-1)
  $$memo[i][j] = memo[i-1][j] + memo[i][j-1]$$
* **3. 基本情况：**
    * `memo[0][j] = 1`（第一行：只有一种方法，直接向右）
    * `memo[i][0] = 1`（第一列：只有一种方法，直接向下）

```java
public class UniquePaths {
    private int[][] memo;

    public int uniquePaths(int m, int n) {
        memo = new int[m][n];
        for (int[] row : memo) Arrays.fill(row, -1);
        return paths(m - 1, n - 1);
    }

    private int paths(int i, int j) {
        // 基本情况
        if (i == 0 || j == 0) return 1;

        // 检查记忆化
        if (memo[i][j] != -1) return memo[i][j];

        // 递归计算
        int fromTop = paths(i - 1, j);
        int fromLeft = paths(i, j - 1);

        // 存储并返回
        memo[i][j] = fromTop + fromLeft;
        return memo[i][j];
    }
}
```

---

#### 不同路径 II（LeetCode 63）

##### **问题：**

类似于不同路径，但现在网格有**障碍物**。障碍物标记为 `1`，空白空间标记为 `0`。
机器人采取的路径不能包括任何是障碍物的方格。

* **输入：** `obstacleGrid = [[0,0,0],[0,1,0],[0,0,0]]`
* **输出：** `2`

##### **解决方案（自顶向下）**

* **1. 数组定义：** `memo[i][j]` = 到达 $(i, j)$ 的路径数。
* **2. 方程：** 与不同路径相同，但跳过有障碍物的单元格。
  $$memo[i][j] = memo[i-1][j] + memo[i][j-1] \quad \text{如果 obstacleGrid[i][j] == 0}$$
* **3. 基本情况：**
    * 如果 `obstacleGrid[0][0] == 1`，返回 `0`（起点被阻塞）
    * 第一行/列：传播 `1` 直到遇到障碍物

```java
public class UniquePathsII {
    private int[][] memo;
    private int[][] grid;

    public int uniquePathsWithObstacles(int[][] obstacleGrid) {
        if (obstacleGrid[0][0] == 1) return 0;

        this.grid = obstacleGrid;
        int m = grid.length;
        int n = grid[0].length;
        memo = new int[m][n];
        for (int[] row : memo) Arrays.fill(row, -1);

        return paths(m - 1, n - 1);
    }

    private int paths(int i, int j) {
        // 越界
        if (i < 0 || j < 0) return 0;

        // 障碍物
        if (grid[i][j] == 1) return 0;

        // 起始位置
        if (i == 0 && j == 0) return 1;

        // 检查记忆化
        if (memo[i][j] != -1) return memo[i][j];

        // 递归计算
        int fromTop = paths(i - 1, j);
        int fromLeft = paths(i, j - 1);

        // 存储并返回
        memo[i][j] = fromTop + fromLeft;
        return memo[i][j];
    }
}
```

---

#### 解码方法（LeetCode 91）

##### **问题：**

包含字母 `A-Z` 的消息可以使用映射 `'A' -> "1"`, `'B' -> "2"`, ..., `'Z' -> "26"` 编码为数字。
给定一个只包含数字的字符串 `s`，返回**解码它的方法数**。

* **输入：** `s = "12"`
* **输出：** `2`
    * *解释：* "12" 可以解码为 "AB"（1 2）或 "L"（12）。

##### **解决方案（自顶向下）**

* **1. 数组定义：** `memo[i]` = 解码 `s[0...i]` 的方法数。
* **2. 方程：** 这是一个**求和**问题。你有两个选择：
  - 解码单个数字（如果有效）
  - 解码两个数字（如果有效）
  $$memo[i] = \text{decodeSingle}(i) + \text{decodeDouble}(i)$$
* **3. 基本情况：**
    * 如果 `s[0] != '0'`，则 `memo[0] = 1`

```java
public class DecodeWays {
    private int[] memo;
    private String s;

    public int numDecodings(String s) {
        this.s = s;
        memo = new int[s.length()];
        Arrays.fill(memo, -1);
        return decode(0);
    }

    private int decode(int index) {
        // 基本情况：到达末尾
        if (index == s.length()) return 1;

        // 前导零无效
        if (s.charAt(index) == '0') return 0;

        // 检查记忆化
        if (memo[index] != -1) return memo[index];

        // 选择 1：解码单个数字
        int decodeSingle = decode(index + 1);

        // 选择 2：解码两个数字（如果有效）
        int decodeDouble = 0;
        if (canDecodeTwo(index)) {
            decodeDouble = decode(index + 2);
        }

        // 存储并返回
        memo[index] = decodeSingle + decodeDouble;
        return memo[index];
    }

    private boolean canDecodeTwo(int index) {
        if (index + 1 >= s.length()) return false;
        int twoDigit = Integer.parseInt(s.substring(index, index + 2));
        return twoDigit >= 10 && twoDigit <= 26;
    }
}
```

---

#### 斐波那契数（LeetCode 509）

##### **问题：**

斐波那契数形成一个序列，其中每个数字是前两个数字的和：
* `F(0) = 0, F(1) = 1`
* `F(n) = F(n-1) + F(n-2)` 对于 `n > 1`

返回 `F(n)`。

* **输入：** `n = 4`
* **输出：** `3`
    * *解释：* F(4) = F(3) + F(2) = 2 + 1 = 3

##### **解决方案（自顶向下）**

* **1. 数组定义：** `memo[n]` = 第 $n$ 个斐波那契数。
* **2. 方程：** 这是一个**求和**问题。
  $$memo[n] = memo[n-1] + memo[n-2]$$
* **3. 基本情况：**
    * `memo[0] = 0`
    * `memo[1] = 1`

```java
public class Fibonacci {
    private int[] memo;

    public int fib(int n) {
        memo = new int[n + 1];
        Arrays.fill(memo, -1);
        return calculate(n);
    }

    private int calculate(int n) {
        // 基本情况
        if (n == 0) return 0;
        if (n == 1) return 1;

        // 检查记忆化
        if (memo[n] != -1) return memo[n];

        // 递归计算
        int fromPrevOne = calculate(n - 1);
        int fromPrevTwo = calculate(n - 2);

        // 存储并返回
        memo[n] = fromPrevOne + fromPrevTwo;
        return memo[n];
    }
}
```

---

#### 计数排序元音字符串（LeetCode 1641）

##### **问题：**

给定一个整数 `n`，返回长度为 `n` 的字符串数，这些字符串仅由元音（`a, e, i, o, u`）组成并且是**按字典顺序排序**的。

* **输入：** `n = 2`
* **输出：** `15`
    * *解释：* 15 个排序字符串是："aa", "ae", "ai", "ao", "au", "ee", "ei", "eo", "eu", "ii", "io", "iu", "oo", "ou", "uu"。

##### **解决方案（自顶向下）**

* **1. 数组定义：** `memo[n][vowel]` = 长度为 `n` 的排序字符串数，从索引 `vowel` 或更后的元音开始。
* **2. 方程：** 这是一个**求和**问题。对于每个元音，求和所有可能性。
  $$memo[n][v] = \sum_{i=v}^{4} memo[n-1][i]$$
* **3. 基本情况：**
    * `memo[1][v] = 5 - v`（对于长度 1，计算剩余元音）

```java
public class CountSortedVowelStrings {
    private int[][] memo;

    public int countVowelStrings(int n) {
        // 5 个元音：a(0), e(1), i(2), o(3), u(4)
        memo = new int[n + 1][5];
        for (int[] row : memo) Arrays.fill(row, -1);
        return count(n, 0);
    }

    private int count(int n, int startVowel) {
        // 基本情况
        if (n == 1) return 5 - startVowel;

        // 检查记忆化
        if (memo[n][startVowel] != -1) return memo[n][startVowel];

        // 从当前元音开始求和所有选择
        int total = 0;
        for (int v = startVowel; v < 5; v++) {
            total += chooseVowel(n, v);
        }

        // 存储并返回
        memo[n][startVowel] = total;
        return memo[n][startVowel];
    }

    private int chooseVowel(int n, int vowel) {
        return count(n - 1, vowel);
    }
}
```

---

### 类别 B：最大/最小问题（优化）

这些问题问"最佳值是什么？"关键洞察是我们使用 `max()` 或 `min()` 在所有可能性中**选择**最优选项。

---

#### 最小爬楼梯成本（LeetCode 746）

##### **问题：**

给定一个整数数组 `cost`，其中 `cost[i]` 是楼梯上第 $i$ 级的成本。一旦你支付了成本，你可以爬 **1 或 2 步**。
你可以从索引 `0` 或索引 `1` 开始。
返回到达楼层顶部（即超过最后一个索引的一步）的*最小成本*。

* **输入：** `cost = [10, 15, 20]`
* **输出：** `15`
    * *解释：* 你将从索引 1 开始。
        1. 支付 15 并爬两步到达顶部。
           总成本是 15。

##### **解决方案（自顶向下）**

* **1. 数组定义：** `memo[i]` = **到达**第 $i$ 级的最小成本。
* **2. 方程：** 这是一个 **min** 问题。你有两个选择：
  - 从 1 步之前来
  - 从 2 步之前来
  $$memo[i] = \min(\text{costFrom1Back}, \quad \text{costFrom2Back})$$
* **3. 基本情况：**
    * `memo[0] = 0`（从地面开始是免费的）
    * `memo[1] = 0`（可以从索引 0 或 1 免费开始）

```java
public class MinCostClimbingStairs {
    private int[] memo;
    private int[] cost;

    public int minCostClimbingStairs(int[] cost) {
        this.cost = cost;
        int n = cost.length;
        memo = new int[n + 1];
        Arrays.fill(memo, -1);
        return minCost(n);
    }

    private int minCost(int step) {
        // 基本情况
        if (step == 0) return 0;
        if (step == 1) return 0;

        // 检查记忆化
        if (memo[step] != -1) return memo[step];

        // 选择 1：从 1 步之前
        int costFrom1Back = minCost(step - 1) + cost[step - 1];

        // 选择 2：从 2 步之前
        int costFrom2Back = minCost(step - 2) + cost[step - 2];

        // 存储并返回最小值
        memo[step] = Math.min(costFrom1Back, costFrom2Back);
        return memo[step];
    }
}
```

---

#### 打家劫舍（LeetCode 198）

##### **问题：**

你是一个专业的强盗，计划沿着街道抢劫房屋。每个房子都藏有一定数量的钱。阻止你的唯一限制是相邻的房屋有连接的安全系统，**如果在同一晚上两个相邻的房屋被闯入，它将自动联系警察**。

给定一个整数数组 `nums`，表示每个房子的钱数，返回今晚你可以在不惊动警察的情况下抢劫的*最大金额*。

* **输入：** `nums = [1, 2, 3, 1]`
* **输出：** `4`
    * *解释：* 抢劫 1 号房（钱 = 1），然后抢劫 3 号房（钱 = 3）。
      你可以抢劫的总金额 = 1 + 3 = 4。

##### **解决方案（自顶向下）**

* **1. 数组定义：** `memo[i]` = 从房屋 `0...i` 中可以抢劫的最大金额。
* **2. 方程：** 这是一个 **max** 问题。对于房屋 $i$，你有两个选择：
    - **不抢劫它：** 值与 `memo[i-1]` 相同。
    - **抢劫它：** 值是当前现金 + `memo[i-2]`（跳过相邻房屋）。
    $$memo[i] = \max(\text{skipHouse}, \quad \text{robHouse})$$
* **3. 基本情况：**
    * `memo[0] = nums[0]`
    * `memo[1] = max(nums[0], nums[1])`

```java
public class HouseRobber {
    private int[] memo;
    private int[] nums;

    public int rob(int[] nums) {
        if (nums.length == 0) return 0;
        if (nums.length == 1) return nums[0];

        this.nums = nums;
        memo = new int[nums.length];
        Arrays.fill(memo, -1);
        return maxRob(nums.length - 1);
    }

    private int maxRob(int i) {
        // 基本情况
        if (i == 0) return nums[0];
        if (i == 1) return Math.max(nums[0], nums[1]);

        // 检查记忆化
        if (memo[i] != -1) return memo[i];

        // 选择 1：跳过这个房子
        int skipHouse = maxRob(i - 1);

        // 选择 2：抢劫这个房子
        int robHouse = nums[i] + maxRob(i - 2);

        // 存储并返回最大值
        memo[i] = Math.max(skipHouse, robHouse);
        return memo[i];
    }
}
```

---

#### 零钱兑换（LeetCode 322）

##### **问题：**

给定一个整数数组 `coins`，表示不同面额的硬币，以及一个整数 `amount`，表示总金额。
返回组成该金额所需的**最少硬币数**。
如果该金额无法由任何硬币组合组成，则返回 `-1`。

* **输入：** `coins = [1, 2, 5]`, `amount = 11`
* **输出：** `3`
    * *解释：* 11 = 5 + 5 + 1（3 个硬币）。

##### **解决方案（自顶向下）**

* **1. 数组定义：** `memo[amount]` = 组成此金额所需的最少硬币数。
* **2. 方程：** 这是一个 **min** 问题。尝试每个硬币：
    $$memo[amt] = \min_{coin} (1 + memo[amt - coin])$$
* **3. 基本情况：**
    * `memo[0] = 0`（0 个硬币组成 0）

```java
public class CoinChange {
    private int[] memo;
    private int[] coins;

    public int coinChange(int[] coins, int amount) {
        this.coins = coins;
        memo = new int[amount + 1];
        Arrays.fill(memo, -1);

        int result = minCoins(amount);
        return result == Integer.MAX_VALUE ? -1 : result;
    }

    private int minCoins(int amount) {
        // 基本情况
        if (amount == 0) return 0;
        if (amount < 0) return Integer.MAX_VALUE;

        // 检查记忆化
        if (memo[amount] != -1) return memo[amount];

        // 尝试每个硬币
        int minCount = Integer.MAX_VALUE;
        for (int coin : coins) {
            int subResult = useCoin(amount, coin);
            if (subResult != Integer.MAX_VALUE) {
                minCount = Math.min(minCount, 1 + subResult);
            }
        }

        // 存储并返回
        memo[amount] = minCount;
        return memo[amount];
    }

    private int useCoin(int amount, int coin) {
        return minCoins(amount - coin);
    }
}
```

---

#### 最长递增子序列（LeetCode 300）

##### **问题：**

给定一个整数数组 `nums`，返回最长严格递增子序列的长度。

* **输入：** `nums = [10,9,2,5,3,7,101,18]`
* **输出：** `4`
    * *解释：* 最长递增子序列是 [2,3,7,101]。

##### **解决方案（自顶向下）**

* **1. 数组定义：** `memo[i]` = 以索引 $i$ 结尾的最长递增子序列的长度。
* **2. 方程：** 这是一个 **max** 问题。对于每个先前元素，检查我们是否可以扩展：
    $$memo[i] = \max(memo[j] + 1) \quad \text{其中 } j < i \text{ 且 } nums[j] < nums[i]$$
* **3. 基本情况：**
    * `memo[i] = 1`（每个元素是长度为 1 的子序列）

```java
public class LongestIncreasingSubsequence {
    private int[] memo;
    private int[] nums;

    public int lengthOfLIS(int[] nums) {
        this.nums = nums;
        memo = new int[nums.length];
        Arrays.fill(memo, -1);

        int maxLength = 0;
        for (int i = 0; i < nums.length; i++) {
            maxLength = Math.max(maxLength, lis(i));
        }
        return maxLength;
    }

    private int lis(int i) {
        // 基本情况
        if (memo[i] != -1) return memo[i];

        // 从长度 1 开始（仅此元素）
        int maxLen = 1;

        // 尝试从先前元素扩展
        for (int j = 0; j < i; j++) {
            if (nums[j] < nums[i]) {
                maxLen = Math.max(maxLen, extendFrom(j));
            }
        }

        // 存储并返回
        memo[i] = maxLen;
        return memo[i];
    }

    private int extendFrom(int j) {
        return lis(j) + 1;
    }
}
```

---

#### 最长公共子序列（LeetCode 1143）

##### **问题：**

给定两个字符串 `text1` 和 `text2`，返回它们的最长**公共子序列**的长度。如果没有公共子序列，返回 `0`。

*注意：* 字符串的**子序列**是从原始字符串生成的新字符串，删除了一些字符（可以没有），而不改变剩余字符的相对顺序。
* *示例：* "ace" 是 "abcde" 的子序列。

* **输入：** `text1 = "abcde"`, `text2 = "ace"`
* **输出：** `3`
    * *解释：* 最长公共子序列是 "ace"，其长度为 3。

##### **解决方案（自顶向下）**

* **1. 数组定义：** `memo[i][j]` = `text1[0...i]` 和 `text2[0...j]` 之间的 LCS 长度。
* **2. 方程：** 这是一个 **max** 问题。两种情况：
    * 如果字符匹配：`1 + memo[i-1][j-1]`
    * 如果它们不匹配：`max(memo[i-1][j], memo[i][j-1])`
* **3. 基本情况：**
    * `memo[i][0] = 0` 或 `memo[0][j] = 0`（空字符串比较）

```java
public class LongestCommonSubsequence {
    private int[][] memo;
    private String text1, text2;

    public int longestCommonSubsequence(String text1, String text2) {
        this.text1 = text1;
        this.text2 = text2;
        memo = new int[text1.length()][text2.length()];
        for (int[] row : memo) Arrays.fill(row, -1);

        return lcs(text1.length() - 1, text2.length() - 1);
    }

    private int lcs(int i, int j) {
        // 基本情况
        if (i < 0 || j < 0) return 0;

        // 检查记忆化
        if (memo[i][j] != -1) return memo[i][j];

        // 如果字符匹配
        if (text1.charAt(i) == text2.charAt(j)) {
            memo[i][j] = matchChars(i, j);
        } else {
            // 如果它们不匹配
            memo[i][j] = skipChar(i, j);
        }

        return memo[i][j];
    }

    private int matchChars(int i, int j) {
        return 1 + lcs(i - 1, j - 1);
    }

    private int skipChar(int i, int j) {
        int skipI = lcs(i - 1, j);
        int skipJ = lcs(i, j - 1);
        return Math.max(skipI, skipJ);
    }
}
```

---

#### 最大子数组（LeetCode 53）

##### **问题：**

给定一个整数数组 `nums`，找到具有最大和的连续子数组并返回其和。

* **输入：** `nums = [-2,1,-3,4,-1,2,1,-5,4]`
* **输出：** `6`
    * *解释：* 子数组 [4,-1,2,1] 的最大和 = 6。

##### **解决方案（自顶向下）**

* **1. 数组定义：** `memo[i]` = 以索引 $i$ 结尾的子数组的最大和。
* **2. 方程：** 这是一个 **max** 问题。在每个位置：
    * 要么从当前元素重新开始
    * 要么扩展先前的子数组
    $$memo[i] = \max(nums[i], \quad nums[i] + memo[i-1])$$
* **3. 基本情况：**
    * `memo[0] = nums[0]`

```java
public class MaximumSubarray {
    private int[] memo;
    private int[] nums;

    public int maxSubArray(int[] nums) {
        this.nums = nums;
        memo = new int[nums.length];
        Arrays.fill(memo, Integer.MIN_VALUE);

        int maxSum = Integer.MIN_VALUE;
        for (int i = 0; i < nums.length; i++) {
            maxSum = Math.max(maxSum, maxEndingAt(i));
        }
        return maxSum;
    }

    private int maxEndingAt(int i) {
        // 基本情况
        if (i == 0) return nums[0];

        // 检查记忆化
        if (memo[i] != Integer.MIN_VALUE) return memo[i];

        // 选择 1：重新开始
        int startFresh = nums[i];

        // 选择 2：扩展先前的
        int extendPrev = nums[i] + maxEndingAt(i - 1);

        // 存储并返回最大值
        memo[i] = Math.max(startFresh, extendPrev);
        return memo[i];
    }
}
```

---

### 类别 C：存在性问题（可能性 / 布尔）

这些问题问"是否可能？"关键洞察是我们使用**逻辑或** - 如果任何路径有效，答案就是 true。

---

#### 单词拆分（LeetCode 139）

##### **问题：**

给定一个字符串 `s` 和一个字符串字典 `wordDict`，如果 `s` 可以分段为一个或多个字典单词的空格分隔序列，则返回 `true`。

* **输入：** `s = "leetcode"`, `wordDict = ["leet","code"]`
* **输出：** `true`
    * *解释：* 返回 true，因为 "leetcode" 可以分段为 "leet code"。

##### **解决方案（自顶向下）**

* **1. 数组定义：** `memo[i]` = 子字符串 `s[i...]` 是否可以分段。
* **2. 方程：** 这是一个**存在性**问题。尝试每个单词：
    $$memo[i] = \bigvee_{word} (\text{s 以 word 开头且 } memo[i + word.length])$$
* **3. 基本情况：**
    * `memo[s.length()] = true`（空字符串有效）

```java
public class WordBreak {
    private Boolean[] memo;
    private String s;
    private Set<String> wordSet;

    public boolean wordBreak(String s, List<String> wordDict) {
        this.s = s;
        this.wordSet = new HashSet<>(wordDict);
        memo = new Boolean[s.length()];
        return canBreak(0);
    }

    private boolean canBreak(int start) {
        // 基本情况
        if (start == s.length()) return true;

        // 检查记忆化
        if (memo[start] != null) return memo[start];

        // 尝试每个单词
        for (String word : wordSet) {
            if (tryWord(start, word)) {
                memo[start] = true;
                return true;
            }
        }

        // 没有单词有效
        memo[start] = false;
        return false;
    }

    private boolean tryWord(int start, String word) {
        int end = start + word.length();
        if (end > s.length()) return false;
        if (!s.substring(start, end).equals(word)) return false;
        return canBreak(end);
    }
}
```

---

#### 分割等和子集（LeetCode 416）

##### **问题：**

给定一个整数数组 `nums`，如果你可以将数组分成两个子集，使得两个子集中元素的和相等，则返回 `true`。

* **输入：** `nums = [1,5,11,5]`
* **输出：** `true`
    * *解释：* 数组可以分成 [1, 5, 5] 和 [11]。

##### **解决方案（自顶向下）**

* **1. 数组定义：** `memo[i][sum]` = 我们是否可以使用索引 `i` 及之后的元素实现 `sum`。
* **2. 方程：** 这是一个**存在性**问题。对于每个元素：
    * 包括它，或
    * 排除它
    $$memo[i][sum] = \text{include}(i, sum) \lor \text{exclude}(i, sum)$$
* **3. 基本情况：**
    * `memo[i][0] = true`（和为 0 总是可以实现的）
    * 如果 `i >= nums.length` 且 `sum > 0`，返回 `false`

```java
public class PartitionEqualSubsetSum {
    private Boolean[][] memo;
    private int[] nums;

    public boolean canPartition(int[] nums) {
        int totalSum = 0;
        for (int num : nums) totalSum += num;

        // 如果总和是奇数，则无法平均分割
        if (totalSum % 2 != 0) return false;

        this.nums = nums;
        int target = totalSum / 2;
        memo = new Boolean[nums.length][target + 1];

        return canAchieve(0, target);
    }

    private boolean canAchieve(int i, int sum) {
        // 基本情况
        if (sum == 0) return true;
        if (i >= nums.length || sum < 0) return false;

        // 检查记忆化
        if (memo[i][sum] != null) return memo[i][sum];

        // 选择 1：包括当前数字
        boolean include = includeNum(i, sum);

        // 选择 2：排除当前数字
        boolean exclude = excludeNum(i, sum);

        // 存储并返回
        memo[i][sum] = include || exclude;
        return memo[i][sum];
    }

    private boolean includeNum(int i, int sum) {
        return canAchieve(i + 1, sum - nums[i]);
    }

    private boolean excludeNum(int i, int sum) {
        return canAchieve(i + 1, sum);
    }
}
```

---

#### 目标和（LeetCode 494）

##### **问题：**

给定一个整数数组 `nums` 和一个整数 `target`。
你想通过在 `nums` 中的每个整数前添加 `'+'` 或 `'-'`，然后连接所有整数来构建一个表达式。
返回你可以构建的不同表达式的数量，这些表达式的值等于 `target`。

* **输入：** `nums = [1,1,1,1,1]`, `target = 3`
* **输出：** `5`
    * *解释：* 有 5 种方式：-1+1+1+1+1, +1-1+1+1+1, +1+1-1+1+1, +1+1+1-1+1, +1+1+1+1-1

##### **解决方案（自顶向下）**

* **1. 数组定义：** `memo[i][sum]` = 使用索引 `i` 及之后的元素实现 `sum` 的方法数。
* **2. 方程：** 这是一个**求和**问题（计数方法）。对于每个数字：
    * 加上它，+
    * 减去它
    $$memo[i][sum] = \text{add}(i, sum) + \text{subtract}(i, sum)$$
* **3. 基本情况：**
    * 如果 `i == nums.length`，如果 `sum == target` 返回 `1`，否则返回 `0`

```java
public class TargetSum {
    private Map<String, Integer> memo;
    private int[] nums;
    private int target;

    public int findTargetSumWays(int[] nums, int target) {
        this.nums = nums;
        this.target = target;
        memo = new HashMap<>();
        return countWays(0, 0);
    }

    private int countWays(int i, int currentSum) {
        // 基本情况
        if (i == nums.length) {
            return currentSum == target ? 1 : 0;
        }

        // 检查记忆化
        String key = i + "," + currentSum;
        if (memo.containsKey(key)) return memo.get(key);

        // 选择 1：加上当前数字
        int addWays = addNum(i, currentSum);

        // 选择 2：减去当前数字
        int subtractWays = subtractNum(i, currentSum);

        // 存储并返回总和
        int totalWays = addWays + subtractWays;
        memo.put(key, totalWays);
        return totalWays;
    }

    private int addNum(int i, int currentSum) {
        return countWays(i + 1, currentSum + nums[i]);
    }

    private int subtractNum(int i, int currentSum) {
        return countWays(i + 1, currentSum - nums[i]);
    }
}
```

---

#### 跳跃游戏（LeetCode 55）

##### **问题：**

给定一个整数数组 `nums`。你最初位于数组的**第一个索引**，数组中的每个元素表示你在该位置的最大跳跃长度。
如果你可以到达最后一个索引，则返回 `true`，否则返回 `false`。

* **输入：** `nums = [2,3,1,1,4]`
* **输出：** `true`
    * *解释：* 从索引 0 跳 1 步到索引 1，然后跳 3 步到最后一个索引。

##### **解决方案（自顶向下）**

* **1. 数组定义：** `memo[i]` = 我们是否可以从位置 $i$ 到达最后一个索引。
* **2. 方程：** 这是一个**存在性**问题。尝试所有可能的跳跃：
    $$memo[i] = \bigvee_{j=1}^{nums[i]} memo[i+j]$$
* **3. 基本情况：**
    * `memo[lastIndex] = true`

```java
public class CanJump {
    private Boolean[] memo;
    private int[] nums;

    public boolean canJump(int[] nums) {
        this.nums = nums;
        memo = new Boolean[nums.length];
        return canReachEnd(0);
    }

    private boolean canReachEnd(int pos) {
        // 基本情况：到达末尾
        if (pos >= nums.length - 1) return true;

        // 检查记忆化
        if (memo[pos] != null) return memo[pos];

        // 尝试所有可能的跳跃
        int maxJump = nums[pos];
        for (int jump = 1; jump <= maxJump; jump++) {
            if (tryJump(pos, jump)) {
                memo[pos] = true;
                return true;
            }
        }

        // 没有跳跃有效
        memo[pos] = false;
        return false;
    }

    private boolean tryJump(int pos, int jump) {
        return canReachEnd(pos + jump);
    }
}
```

---

#### 完全平方数（LeetCode 279）

##### **问题：**

给定一个整数 `n`，返回和为 `n` 的完全平方数的最少数量。

* **输入：** `n = 12`
* **输出：** `3`
    * *解释：* 12 = 4 + 4 + 4。

##### **解决方案（自顶向下）**

* **1. 数组定义：** `memo[n]` = 和为 $n$ 的完全平方数的最少数量。
* **2. 方程：** 这是一个 **min** 问题。尝试所有完全平方数：
    $$memo[n] = \min_{i^2 \leq n} (1 + memo[n - i^2])$$
* **3. 基本情况：**
    * `memo[0] = 0`

```java
public class PerfectSquares {
    private int[] memo;

    public int numSquares(int n) {
        memo = new int[n + 1];
        Arrays.fill(memo, -1);
        return minSquares(n);
    }

    private int minSquares(int n) {
        // 基本情况
        if (n == 0) return 0;

        // 检查记忆化
        if (memo[n] != -1) return memo[n];

        // 尝试所有 <= n 的完全平方数
        int minCount = Integer.MAX_VALUE;
        for (int i = 1; i * i <= n; i++) {
            int count = useSquare(n, i);
            minCount = Math.min(minCount, count);
        }

        // 存储并返回
        memo[n] = minCount;
        return memo[n];
    }

    private int useSquare(int n, int i) {
        return 1 + minSquares(n - i * i);
    }
}
```

---

#### 石子游戏（LeetCode 877）

##### **问题：**

Alice 和 Bob 玩一个石子游戏。有偶数堆石子排成一行，每堆有正整数个石子。
目标是以最多的石子结束。玩家轮流，Alice 先手。在每一轮中，玩家从开头或结尾取整堆。
如果 Alice 获胜（假设双方都发挥最佳），则返回 `true`。

* **输入：** `piles = [5,3,4,5]`
* **输出：** `true`

##### **解决方案（自顶向下）**

* **1. 数组定义：** `memo[i][j]` = 对于堆 `i...j` 的最大得分差（当前玩家 - 对手）。
* **2. 方程：** 这是一个 **max** 问题。选择左侧或右侧：
    $$memo[i][j] = \max(\text{takeLeft}, \quad \text{takeRight})$$
* **3. 基本情况：**
    * `memo[i][i] = piles[i]`（只剩一堆）

```java
public class StoneGame {
    private int[][] memo;
    private int[] piles;

    public boolean stoneGame(int[] piles) {
        this.piles = piles;
        int n = piles.length;
        memo = new int[n][n];
        for (int[] row : memo) Arrays.fill(row, -1);

        return maxDiff(0, n - 1) > 0;
    }

    private int maxDiff(int i, int j) {
        // 基本情况：只有一堆
        if (i == j) return piles[i];

        // 检查记忆化
        if (memo[i][j] != -1) return memo[i][j];

        // 选择 1：取左侧堆
        int takeLeft = takeLeftPile(i, j);

        // 选择 2：取右侧堆
        int takeRight = takeRightPile(i, j);

        // 存储并返回最大值
        memo[i][j] = Math.max(takeLeft, takeRight);
        return memo[i][j];
    }

    private int takeLeftPile(int i, int j) {
        return piles[i] - maxDiff(i + 1, j);
    }

    private int takeRightPile(int i, int j) {
        return piles[j] - maxDiff(i, j - 1);
    }
}
```

---

## 自底向上方法（迭代）

### 为什么自底向上更好

虽然动态规划通常使用递归（自顶向下）引入，但自底向上方法有显著的优势：

* **没有栈溢出：** 迭代解决方案使用恒定的栈空间。
* **更好的性能：** 没有函数调用开销。
* **更清晰的流程：** 计算顺序是显式的，易于追踪。
* **空间优化：** 通常更容易降低空间复杂度（例如，滚动数组技术）。

### 思维转变：从递归到迭代

**自顶向下思维：**
> "要解决问题 `f(n)`，我需要先解决 `f(n-1)` 和 `f(n-2)`。"
> 这是**目标导向的**：从目标开始向后工作。

**自底向上思维：**
> "我将首先解决最小的问题：`f(0)`、`f(1)`，然后构建到 `f(n)`。"
> 这是**基础导向的**：从基础开始向前工作。

### 转换策略

要将自顶向下解决方案转换为自底向上：

1. **识别依赖关系：** `dp[i]` 依赖于什么？
   - 如果它依赖于 `dp[i-1]`，从 `1` 循环到 `n`
   - 如果它依赖于较小的索引，向前循环
   - 如果它依赖于较大的索引，向后循环

2. **初始化基本情况：** 直接设置 `dp[0]`、`dp[1]` 等（不需要递归）

3. **迭代填充 DP 表：**
   - 使用循环而不是递归
   - 循环顺序与依赖方向匹配
   - 应用相同的状态转移方程

4. **返回最终答案：** 通常是 `dp[n]` 或 `dp[n-1]`

### 类别 A：求和问题（自底向上）

---

#### 爬楼梯（自底向上）

```java
public class ClimbingStairsBottomUp {
    public int climbStairs(int n) {
        if (n <= 1) return 1;

        // 1. 定义数组
        int[] dp = new int[n + 1];

        // 2. 初始化基本情况
        dp[0] = 1;
        dp[1] = 1;

        // 3. 迭代填充表
        for (int i = 2; i <= n; i++) {
            dp[i] = chooseOneStep(dp, i) + chooseTwoSteps(dp, i);
        }

        // 4. 返回最终答案
        return dp[n];
    }

    private int chooseOneStep(int[] dp, int i) {
        return dp[i - 1];
    }

    private int chooseTwoSteps(int[] dp, int i) {
        return dp[i - 2];
    }
}
```

**空间优化：** 由于我们只需要最后两个值，我们可以使用两个变量而不是数组：

```java
public int climbStairsOptimized(int n) {
    if (n <= 1) return 1;

    int prev2 = 1;  // dp[i-2]
    int prev1 = 1;  // dp[i-1]

    for (int i = 2; i <= n; i++) {
        int current = prev1 + prev2;
        prev2 = prev1;
        prev1 = current;
    }

    return prev1;
}
```

---

#### 不同路径（自底向上）

```java
public class UniquePathsBottomUp {
    public int uniquePaths(int m, int n) {
        // 1. 定义数组
        int[][] dp = new int[m][n];

        // 2. 初始化基本情况
        for (int i = 0; i < m; i++) dp[i][0] = 1;  // 第一列
        for (int j = 0; j < n; j++) dp[0][j] = 1;  // 第一行

        // 3. 迭代填充表
        for (int i = 1; i < m; i++) {
            for (int j = 1; j < n; j++) {
                dp[i][j] = fromTop(dp, i, j) + fromLeft(dp, i, j);
            }
        }

        // 4. 返回最终答案
        return dp[m - 1][n - 1];
    }

    private int fromTop(int[][] dp, int i, int j) {
        return dp[i - 1][j];
    }

    private int fromLeft(int[][] dp, int i, int j) {
        return dp[i][j - 1];
    }
}
```

**空间优化：** 我们只需要当前行和前一行：

```java
public int uniquePathsOptimized(int m, int n) {
    int[] dp = new int[n];
    Arrays.fill(dp, 1);

    for (int i = 1; i < m; i++) {
        for (int j = 1; j < n; j++) {
            dp[j] = dp[j] + dp[j - 1];  // fromTop + fromLeft
        }
    }

    return dp[n - 1];
}
```

---

#### 不同路径 II（自底向上）

```java
public class UniquePathsIIBottomUp {
    public int uniquePathsWithObstacles(int[][] obstacleGrid) {
        if (obstacleGrid[0][0] == 1) return 0;

        int m = obstacleGrid.length;
        int n = obstacleGrid[0].length;

        // 1. 定义数组
        int[][] dp = new int[m][n];

        // 2. 初始化基本情况
        dp[0][0] = 1;

        // 第一列
        for (int i = 1; i < m; i++) {
            dp[i][0] = (obstacleGrid[i][0] == 0 && dp[i - 1][0] == 1) ? 1 : 0;
        }

        // 第一行
        for (int j = 1; j < n; j++) {
            dp[0][j] = (obstacleGrid[0][j] == 0 && dp[0][j - 1] == 1) ? 1 : 0;
        }

        // 3. 迭代填充表
        for (int i = 1; i < m; i++) {
            for (int j = 1; j < n; j++) {
                if (obstacleGrid[i][j] == 1) {
                    dp[i][j] = 0;  // 障碍物
                } else {
                    dp[i][j] = fromTop(dp, i, j) + fromLeft(dp, i, j);
                }
            }
        }

        // 4. 返回最终答案
        return dp[m - 1][n - 1];
    }

    private int fromTop(int[][] dp, int i, int j) {
        return dp[i - 1][j];
    }

    private int fromLeft(int[][] dp, int i, int j) {
        return dp[i][j - 1];
    }
}
```

---

#### 解码方法（自底向上）

```java
public class DecodeWaysBottomUp {
    public int numDecodings(String s) {
        if (s.charAt(0) == '0') return 0;

        int n = s.length();

        // 1. 定义数组
        int[] dp = new int[n + 1];

        // 2. 初始化基本情况
        dp[0] = 1;  // 空字符串
        dp[1] = 1;  // 第一个字符（已验证非零）

        // 3. 迭代填充表
        for (int i = 2; i <= n; i++) {
            // 选择 1：解码单个数字
            int single = decodeSingle(s, i, dp);

            // 选择 2：解码两个数字
            int double_ = decodeDouble(s, i, dp);

            dp[i] = single + double_;
        }

        // 4. 返回最终答案
        return dp[n];
    }

    private int decodeSingle(String s, int i, int[] dp) {
        if (s.charAt(i - 1) != '0') {
            return dp[i - 1];
        }
        return 0;
    }

    private int decodeDouble(String s, int i, int[] dp) {
        int twoDigit = Integer.parseInt(s.substring(i - 2, i));
        if (twoDigit >= 10 && twoDigit <= 26) {
            return dp[i - 2];
        }
        return 0;
    }
}
```

---

#### 斐波那契数（自底向上）

```java
public class FibonacciBottomUp {
    public int fib(int n) {
        if (n <= 1) return n;

        // 1. 定义数组
        int[] dp = new int[n + 1];

        // 2. 初始化基本情况
        dp[0] = 0;
        dp[1] = 1;

        // 3. 迭代填充表
        for (int i = 2; i <= n; i++) {
            dp[i] = fromPrevOne(dp, i) + fromPrevTwo(dp, i);
        }

        // 4. 返回最终答案
        return dp[n];
    }

    private int fromPrevOne(int[] dp, int i) {
        return dp[i - 1];
    }

    private int fromPrevTwo(int[] dp, int i) {
        return dp[i - 2];
    }
}
```

**空间优化：**

```java
public int fibOptimized(int n) {
    if (n <= 1) return n;

    int prev2 = 0;
    int prev1 = 1;

    for (int i = 2; i <= n; i++) {
        int current = prev1 + prev2;
        prev2 = prev1;
        prev1 = current;
    }

    return prev1;
}
```

---

#### 计数排序元音字符串（自底向上）

```java
public class CountSortedVowelStringsBottomUp {
    public int countVowelStrings(int n) {
        // 1. 定义数组
        // dp[i][j] = 长度为 i 且以元音 j 或更后结尾的字符串数
        int[][] dp = new int[n + 1][6];

        // 2. 初始化基本情况
        // 对于长度 1，我们可以使用任何元音
        for (int v = 0; v < 5; v++) {
            dp[1][v] = 5 - v;  // 可以使用从 v 到 4 的元音
        }

        // 3. 迭代填充表
        for (int len = 2; len <= n; len++) {
            for (int v = 4; v >= 0; v--) {  // 反向顺序便于计算
                dp[len][v] = sumVowelChoices(dp, len, v);
            }
        }

        // 4. 返回最终答案
        return dp[n][0];
    }

    private int sumVowelChoices(int[][] dp, int len, int v) {
        int sum = 0;
        for (int nextV = v; nextV < 5; nextV++) {
            sum += dp[len - 1][nextV];
        }
        return sum;
    }
}
```

**使用一维数组的更简单方法：**

```java
public int countVowelStringsSimple(int n) {
    // dp[i] = 元音 i 的计数（a=0, e=1, i=2, o=3, u=4）
    int[] dp = new int[5];
    Arrays.fill(dp, 1);

    for (int len = 2; len <= n; len++) {
        for (int v = 3; v >= 0; v--) {
            dp[v] += dp[v + 1];
        }
    }

    int total = 0;
    for (int count : dp) total += count;
    return total;
}
```

---

### 类别 B：最大/最小问题（自底向上）

---

#### 最小爬楼梯成本（自底向上）

```java
public class MinCostClimbingStairsBottomUp {
    public int minCostClimbingStairs(int[] cost) {
        int n = cost.length;

        // 1. 定义数组
        int[] dp = new int[n + 1];

        // 2. 初始化基本情况
        dp[0] = 0;  // 从地面开始（免费）
        dp[1] = 0;  // 从第一步开始（免费）

        // 3. 迭代填充表
        for (int i = 2; i <= n; i++) {
            int costFrom1Back = costFromOneBack(dp, cost, i);
            int costFrom2Back = costFromTwoBack(dp, cost, i);
            dp[i] = Math.min(costFrom1Back, costFrom2Back);
        }

        // 4. 返回最终答案
        return dp[n];
    }

    private int costFromOneBack(int[] dp, int[] cost, int i) {
        return dp[i - 1] + cost[i - 1];
    }

    private int costFromTwoBack(int[] dp, int[] cost, int i) {
        return dp[i - 2] + cost[i - 2];
    }
}
```

---

#### 打家劫舍（自底向上）

```java
public class HouseRobberBottomUp {
    public int rob(int[] nums) {
        if (nums.length == 0) return 0;
        if (nums.length == 1) return nums[0];

        int n = nums.length;

        // 1. 定义数组
        int[] dp = new int[n];

        // 2. 初始化基本情况
        dp[0] = nums[0];
        dp[1] = Math.max(nums[0], nums[1]);

        // 3. 迭代填充表
        for (int i = 2; i < n; i++) {
            int skipHouse = skipCurrent(dp, i);
            int robHouse = robCurrent(dp, nums, i);
            dp[i] = Math.max(skipHouse, robHouse);
        }

        // 4. 返回最终答案
        return dp[n - 1];
    }

    private int skipCurrent(int[] dp, int i) {
        return dp[i - 1];
    }

    private int robCurrent(int[] dp, int[] nums, int i) {
        return dp[i - 2] + nums[i];
    }
}
```

---

#### 零钱兑换（自底向上）

```java
public class CoinChangeBottomUp {
    public int coinChange(int[] coins, int amount) {
        // 1. 定义数组
        int[] dp = new int[amount + 1];

        // 2. 初始化基本情况
        Arrays.fill(dp, amount + 1);  // 无穷大占位符
        dp[0] = 0;  // 金额 0 需要 0 个硬币

        // 3. 迭代填充表
        for (int amt = 1; amt <= amount; amt++) {
            for (int coin : coins) {
                if (coin <= amt) {
                    dp[amt] = Math.min(dp[amt], useCoin(dp, amt, coin));
                }
            }
        }

        // 4. 返回最终答案
        return dp[amount] > amount ? -1 : dp[amount];
    }

    private int useCoin(int[] dp, int amt, int coin) {
        return dp[amt - coin] + 1;
    }
}
```

---

#### 最长递增子序列（自底向上）

```java
public class LongestIncreasingSubsequenceBottomUp {
    public int lengthOfLIS(int[] nums) {
        int n = nums.length;

        // 1. 定义数组
        int[] dp = new int[n];

        // 2. 初始化基本情况
        Arrays.fill(dp, 1);  // 每个元素是长度为 1 的 LIS

        // 3. 迭代填充表
        for (int i = 1; i < n; i++) {
            for (int j = 0; j < i; j++) {
                if (nums[j] < nums[i]) {
                    dp[i] = Math.max(dp[i], extendFrom(dp, j));
                }
            }
        }

        // 4. 返回最终答案（所有 dp 值的最大值）
        int maxLen = 0;
        for (int len : dp) {
            maxLen = Math.max(maxLen, len);
        }
        return maxLen;
    }

    private int extendFrom(int[] dp, int j) {
        return dp[j] + 1;
    }
}
```

---

#### 最长公共子序列（自底向上）

```java
public class LongestCommonSubsequenceBottomUp {
    public int longestCommonSubsequence(String text1, String text2) {
        int m = text1.length();
        int n = text2.length();

        // 1. 定义数组
        int[][] dp = new int[m + 1][n + 1];

        // 2. 初始化基本情况（默认已为 0）
        // dp[0][j] = 0 且 dp[i][0] = 0

        // 3. 迭代填充表
        for (int i = 1; i <= m; i++) {
            for (int j = 1; j <= n; j++) {
                if (text1.charAt(i - 1) == text2.charAt(j - 1)) {
                    dp[i][j] = matchChars(dp, i, j);
                } else {
                    dp[i][j] = skipChar(dp, i, j);
                }
            }
        }

        // 4. 返回最终答案
        return dp[m][n];
    }

    private int matchChars(int[][] dp, int i, int j) {
        return 1 + dp[i - 1][j - 1];
    }

    private int skipChar(int[][] dp, int i, int j) {
        return Math.max(dp[i - 1][j], dp[i][j - 1]);
    }
}
```

---

#### 最大子数组（自底向上）

```java
public class MaximumSubarrayBottomUp {
    public int maxSubArray(int[] nums) {
        int n = nums.length;

        // 1. 定义数组
        int[] dp = new int[n];

        // 2. 初始化基本情况
        dp[0] = nums[0];

        // 3. 迭代填充表
        int maxSum = dp[0];
        for (int i = 1; i < n; i++) {
            int startFresh = nums[i];
            int extendPrev = nums[i] + dp[i - 1];
            dp[i] = Math.max(startFresh, extendPrev);
            maxSum = Math.max(maxSum, dp[i]);
        }

        // 4. 返回最终答案
        return maxSum;
    }
}
```

**空间优化：**

```java
public int maxSubArrayOptimized(int[] nums) {
    int prevMax = nums[0];
    int maxSum = nums[0];

    for (int i = 1; i < nums.length; i++) {
        prevMax = Math.max(nums[i], nums[i] + prevMax);
        maxSum = Math.max(maxSum, prevMax);
    }

    return maxSum;
}
```

---

### 类别 C：存在性问题（自底向上）

---

#### 单词拆分（自底向上）

```java
public class WordBreakBottomUp {
    public boolean wordBreak(String s, List<String> wordDict) {
        Set<String> wordSet = new HashSet<>(wordDict);
        int n = s.length();

        // 1. 定义数组
        boolean[] dp = new boolean[n + 1];

        // 2. 初始化基本情况
        dp[0] = true;  // 空字符串有效

        // 3. 迭代填充表
        for (int i = 1; i <= n; i++) {
            for (String word : wordSet) {
                if (canUseWord(s, dp, i, word)) {
                    dp[i] = true;
                    break;  // 找到一种有效方式
                }
            }
        }

        // 4. 返回最终答案
        return dp[n];
    }

    private boolean canUseWord(String s, boolean[] dp, int i, String word) {
        int len = word.length();
        if (len > i) return false;
        if (!dp[i - len]) return false;
        return s.substring(i - len, i).equals(word);
    }
}
```

---

#### 分割等和子集（自底向上）

```java
public class PartitionEqualSubsetSumBottomUp {
    public boolean canPartition(int[] nums) {
        int totalSum = 0;
        for (int num : nums) totalSum += num;

        if (totalSum % 2 != 0) return false;

        int target = totalSum / 2;

        // 1. 定义数组
        boolean[] dp = new boolean[target + 1];

        // 2. 初始化基本情况
        dp[0] = true;  // 和为 0 总是可以实现的

        // 3. 迭代填充表
        for (int num : nums) {
            // 向后遍历以避免使用同一元素两次
            for (int sum = target; sum >= num; sum--) {
                if (dp[sum - num]) {
                    dp[sum] = includeNum(dp, sum, num);
                }
            }
        }

        // 4. 返回最终答案
        return dp[target];
    }

    private boolean includeNum(boolean[] dp, int sum, int num) {
        return dp[sum - num];  // 如果我们可以组成 (sum - num)，我们可以组成 sum
    }
}
```

---

#### 目标和（自底向上）

```java
public class TargetSumBottomUp {
    public int findTargetSumWays(int[] nums, int target) {
        int sum = 0;
        for (int num : nums) sum += num;

        // 数学洞察：P - N = target，P + N = sum
        // 因此：P = (target + sum) / 2
        if (sum < Math.abs(target) || (target + sum) % 2 != 0) return 0;

        int positiveSum = (target + sum) / 2;

        // 1. 定义数组
        int[] dp = new int[positiveSum + 1];

        // 2. 初始化基本情况
        dp[0] = 1;  // 组成和 0 的一种方法

        // 3. 迭代填充表
        for (int num : nums) {
            for (int s = positiveSum; s >= num; s--) {
                dp[s] += includeNum(dp, s, num);
            }
        }

        // 4. 返回最终答案
        return dp[positiveSum];
    }

    private int includeNum(int[] dp, int s, int num) {
        return dp[s - num];
    }
}
```

---

#### 跳跃游戏（自底向上）

```java
public class CanJumpBottomUp {
    public boolean canJump(int[] nums) {
        int n = nums.length;

        // 1. 定义数组
        boolean[] dp = new boolean[n];

        // 2. 初始化基本情况
        dp[0] = true;  // 起始位置可达

        // 3. 迭代填充表
        for (int i = 0; i < n; i++) {
            if (!dp[i]) continue;  // 无法到达此位置

            // 标记从这里可达的所有位置
            int maxJump = nums[i];
            for (int jump = 1; jump <= maxJump && i + jump < n; jump++) {
                dp[i + jump] = tryJump(i, jump);
            }
        }

        // 4. 返回最终答案
        return dp[n - 1];
    }

    private boolean tryJump(int pos, int jump) {
        return true;  // 位置可达
    }
}
```

**贪心优化（更好的方法）：**

```java
public boolean canJumpGreedy(int[] nums) {
    int maxReach = 0;

    for (int i = 0; i < nums.length; i++) {
        if (i > maxReach) return false;  // 无法到达此位置
        maxReach = Math.max(maxReach, i + nums[i]);
    }

    return true;
}
```

---

#### 完全平方数（自底向上）

```java
public class PerfectSquaresBottomUp {
    public int numSquares(int n) {
        // 1. 定义数组
        int[] dp = new int[n + 1];

        // 2. 初始化基本情况
        Arrays.fill(dp, Integer.MAX_VALUE);
        dp[0] = 0;

        // 3. 迭代填充表
        for (int i = 1; i <= n; i++) {
            for (int j = 1; j * j <= i; j++) {
                dp[i] = Math.min(dp[i], useSquare(dp, i, j));
            }
        }

        // 4. 返回最终答案
        return dp[n];
    }

    private int useSquare(int[] dp, int i, int j) {
        return dp[i - j * j] + 1;
    }
}
```

---

#### 石子游戏（自底向上）

```java
public class StoneGameBottomUp {
    public boolean stoneGame(int[] piles) {
        int n = piles.length;

        // 1. 定义数组
        int[][] dp = new int[n][n];

        // 2. 初始化基本情况
        for (int i = 0; i < n; i++) {
            dp[i][i] = piles[i];  // 只有一堆
        }

        // 3. 迭代填充表
        // len 是子数组长度
        for (int len = 2; len <= n; len++) {
            for (int i = 0; i <= n - len; i++) {
                int j = i + len - 1;

                int takeLeft = takeLeftPile(piles, dp, i, j);
                int takeRight = takeRightPile(piles, dp, i, j);

                dp[i][j] = Math.max(takeLeft, takeRight);
            }
        }

        // 4. 返回最终答案
        return dp[0][n - 1] > 0;
    }

    private int takeLeftPile(int[] piles, int[][] dp, int i, int j) {
        return piles[i] - dp[i + 1][j];
    }

    private int takeRightPile(int[] piles, int[][] dp, int i, int j) {
        return piles[j] - dp[i][j - 1];
    }
}
```

---

## 汇总表

| 问题 | 类别 | 模式 | 时间 | 空间 |
|------|------|------|------|------|
| 爬楼梯 | 求和 | `dp[i] = dp[i-1] + dp[i-2]` | O(n) | O(1)* |
| 不同路径 | 求和 | `dp[i][j] = dp[i-1][j] + dp[i][j-1]` | O(mn) | O(n)* |
| 不同路径 II | 求和 | 同上，带障碍物 | O(mn) | O(n)* |
| 解码方法 | 求和 | `dp[i] = dp[i-1] + dp[i-2]` | O(n) | O(n) |
| 斐波那契 | 求和 | `dp[i] = dp[i-1] + dp[i-2]` | O(n) | O(1)* |
| 计数元音字符串 | 求和 | `dp[n][v] = Σ dp[n-1][v']` | O(n) | O(n) |
| 最小爬楼梯成本 | Min | `dp[i] = min(dp[i-1], dp[i-2]) + cost` | O(n) | O(1)* |
| 打家劫舍 | Max | `dp[i] = max(dp[i-1], dp[i-2] + nums[i])` | O(n) | O(1)* |
| 零钱兑换 | Min | `dp[i] = min(1 + dp[i-coin])` | O(n×m) | O(n) |
| 最长递增子序列 | Max | `dp[i] = max(dp[j] + 1)` | O(n²) | O(n) |
| 最长公共子序列 | Max | 匹配：`1 + dp[i-1][j-1]`<br>跳过：`max(dp[i-1][j], dp[i][j-1])` | O(mn) | O(n)* |
| 最大子数组 | Max | `dp[i] = max(nums[i], dp[i-1] + nums[i])` | O(n) | O(1)* |
| 单词拆分 | 存在 | `dp[i] = ∨ dp[i-len(word)]` | O(n×m×k) | O(n) |
| 分割等和子集 | 存在 | `dp[sum] = dp[sum] ∨ dp[sum-num]` | O(n×sum) | O(sum) |
| 目标和 | 求和 | `dp[i][sum] = dp[i+1][sum+num] + dp[i+1][sum-num]` | O(n×sum) | O(sum) |
| 跳跃游戏 | 存在 | `dp[i] = ∨ dp[i+jump]` | O(n²) | O(n) |
| 完全平方数 | Min | `dp[n] = min(1 + dp[n-i²])` | O(n√n) | O(n) |
| 石子游戏 | Max | `dp[i][j] = max(piles[i] - dp[i+1][j], piles[j] - dp[i][j-1])` | O(n²) | O(n²) |

*空间复杂度可以使用滚动数组或变量进行优化。

---

## 关键要点

1. **识别模式：**
   - **求和问题** → 添加所有可能性
   - **最大/最小问题** → 选择最佳选项
   - **存在性问题** → 检查是否有任何选项有效

2. **自顶向下 vs 自底向上：**
   - **自顶向下：** 自然递归，更容易思考，但有栈溢出风险
   - **自底向上：** 迭代，性能更好，更容易优化空间

3. **空间优化：**
   - 如果 `dp[i]` 只依赖于 `dp[i-1]` 和 `dp[i-2]`，使用两个变量
   - 对于 2D DP，如果 `dp[i][j]` 只依赖于前一行，使用滚动数组

4. **三步法（永不跳过）：**
   - **定义** `dp[i]` 的含义
   - **推导** 状态转移方程
   - **初始化** 基本情况

5. **熟能生巧：**
   - 从简单问题开始（斐波那契、爬楼梯）
   - 进阶到中等难度（打家劫舍、零钱兑换）
   - 掌握困难问题（LCS、石子游戏）

