# [Algorithm] 1. Dynamic Programming


## Introduction

### What is Dynamic Programming?

Dynamic Programming (DP) is often considered one of the most challenging topics in computer science algorithms. However, at its core, it is simply **an optimization technique**.

The fundamental idea of DP is **"Don't Repeat Yourself."**

If you have already solved a sub-problem, you should save the result (cache it) so that you never have to calculate it again. By trading a little bit of **space** (to store results) for **time** (to avoid re-calculation), DP can turn an inefficient exponential algorithm ($O(2^n)$) into a highly efficient linear one ($O(n)$).

#### A Simple Analogy

Imagine I ask you to calculate:

$$1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 = ?$$

You count them up and tell me: **"8"**.

Now, if I add another `+ 1` to the end of that equation:
$$1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 \quad \mathbf{+\ 1} = ?$$

You will immediately answer: **"9"**.

**Why?**
You didn't recount the first eight `1`s. You remembered that the previous result was **8**, and you simply added **1** to it.

**This is Dynamic Programming.**
1. **State:** You remembered "the sum of the first 8 numbers."
2. **Transition:** You used the formula `Current Sum = Previous Sum + 1`.

## Core Pillars

### The Three Core Concepts of Dynamic Programming

When solving a DP problem, you must strictly follow three steps. Think of this as your "pre-coding checklist." If you cannot answer these three points clearly, do not start writing code yet.

#### Define the Array (The Semantics)

We use an array (often named `dp[]`) to store our results. The most critical step is defining the **physical meaning** of this array. You must be able to complete this sentence:

> *"The value of `dp[i]` represents..."*

If your definition is vague, your logic will fail.

* **Bad Definition:** `dp[i]` is the answer for $i$. (Too abstract)
* **Good Definition:** `dp[i]` represents the **maximum profit** we can generate after selling the $i$-th item.
* **Good Definition:** `dp[i]` represents the **minimum number of steps** required to reach stair $i$.

#### The State Transition Equation (The Logic)

The Transition Equation is not random math; it is a formal description of a decision-making process.

To write this equation, you must ask: **"How does the current state $i$ relate to the previous candidate states?"**

The specific mathematical operator you use is strictly determined by the **Goal of the Problem**. You can categorize almost all DP equations into three abstract patterns:

##### Pattern A: The Aggregator (Counting / Sum)

**Goal:** "How many distinct ways are there to reach state $i$?"

* **The Logic:** You are not choosing *between* options; you are **combining** them. If you can arrive at the current state from "Option A" or "Option B," the total number of ways is the sum of both histories.
* **The Abstract Equation:**
  $$dp[i] = dp[\text{Option A}] + dp[\text{Option B}] + \dots$$
* **The Mindset:** Accumulation. Every valid path from the past contributes to the present.

##### Pattern B: The Selector (Optimization / Max or Min)

**Goal:** "What is the maximum profit / minimum cost to reach state $i$?"

* **The Logic:** You are in a **competition**. You compare "Option A" (e.g., taking an action) against "Option B" (e.g., skipping an action). You only care about the winner; the loser is discarded.
* **The Abstract Equation:**
  $$dp[i] = \max(\text{Value of Option A}, \quad \text{Value of Option B})$$
  *(Or $\min$ if you are minimizing cost)*
* **The Mindset:** Survival of the Fittest. Only the best previous state matters.

##### Pattern C: The Validator (Existence / Boolean)

**Goal:** "Is it possible to reach state $i$?"

* **The Logic:** You are checking for **connectivity**. If there is *at least one* valid path from a previous state to here, then the current state becomes valid.
* **The Abstract Equation:**
  $$dp[i] = dp[\text{Option A}] \lor dp[\text{Option B}] \dots$$
  *(Logical OR operation)*
* **The Mindset:** Propagation. If the signal reached "Option A", and "Option A" connects to me, then the signal reaches me.

#### Initialization (The Base Case)

The State Transition Equation drives the logic, but it needs a starting point. Without initialization, your loop will try to access negative indexes (like `dp[-1]`) or calculate based on empty data.

You must manually set the values for the smallest sub-problems.

* If your equation relies on `i-1`, you usually need to initialize `dp[0]`.
* If your equation relies on `i-2`, you usually need to initialize `dp[0]` and `dp[1]`.

**Think of it like Dominos:**
Step 3 sets up the first domino. Step 2 ensures that if one falls, the next one falls. Step 1 is the floor they stand on.

## Top-Down Approach (Recursion + Memoization)

The Top-Down approach uses recursion to break down the problem from the target state to the base cases. We use memoization to cache results and avoid redundant calculations.

### Category A: Sum Problems (Counting Paths)

These problems ask "How many ways?" The key insight is that we **add** all possible paths that lead to the current state.

---

#### Climbing Stairs (LeetCode 70)

##### **The Problem:**

You are climbing a staircase. It takes `n` steps to reach the top.
Each time you can either climb **1 step** or **2 steps**.
In how many distinct ways can you climb to the top?

* **Input:** `n = 3`
* **Output:** `3`
    * *Explanation:* There are three ways to climb to the top:
        1. 1 step + 1 step + 1 step
        2. 1 step + 2 steps
        3. 2 steps + 1 step

##### **Solution (Top-Down)**

* **1. Array Definition:** `memo[i]` = The number of distinct ways to reach the $i$-th step.
* **2. Equation:** This is a **sum** problem. You have two choices:
    - Come from 1 step back
    - Come from 2 steps back
      $$memo[i] = memo[i-1] + memo[i-2]$$
* **3. Base Cases:**
    * `memo[0] = 1` (One way to stay at ground)
    * `memo[1] = 1` (One way: take 1 step)

```java
public class ClimbingStairs {
    private int[] memo;

    public int climbStairs(int n) {
        memo = new int[n + 1];
        Arrays.fill(memo, -1);
        return climb(n);
    }

    private int climb(int n) {
        // Base cases
        if (n == 0) return 1;
        if (n == 1) return 1;

        // Check memo
        if (memo[n] != -1) return memo[n];

        // Recursively calculate
        int fromOneStepBack = climb(n - 1);
        int fromTwoStepsBack = climb(n - 2);

        // Store and return
        memo[n] = fromOneStepBack + fromTwoStepsBack;
        return memo[n];
    }
}
```

---

#### Unique Paths (LeetCode 62)

##### **The Problem:**

There is a robot on an `m x n` grid. The robot is initially located at the **top-left corner** (i.e., `grid[0][0]`).
The robot tries to move to the **bottom-right corner** (i.e., `grid[m-1][n-1]`).
The robot can only move either **down** or **right** at any point in time.

Given the two integers `m` and `n`, return the number of possible unique paths that the robot can take to reach the bottom-right corner.

* **Input:** `m = 3, n = 7`
* **Output:** `28`

**Note:** The answer can also be computed using combinatorics:
$$
C_{m+n-2}^{m-1}
$$

##### **Solution (Top-Down)**

* **1. Array Definition:** `memo[i][j]` = The number of unique paths to reach cell $(i, j)$.
* **2. Equation:** This is a **sum** problem. You have two choices:
    * Come from **top** (i-1, j)
    * Come from **left** (i, j-1)
      $$memo[i][j] = memo[i-1][j] + memo[i][j-1]$$
* **3. Base Cases:**
    * `memo[0][j] = 1` (First row: only one way, go straight right)
    * `memo[i][0] = 1` (First column: only one way, go straight down)

```java
public class UniquePaths {
    private int[][] memo;

    public int uniquePaths(int m, int n) {
        memo = new int[m][n];
        for (int[] row : memo) Arrays.fill(row, -1);
        return paths(m - 1, n - 1);
    }

    private int paths(int i, int j) {
        // Base cases
        if (i == 0 || j == 0) return 1;

        // Check memo
        if (memo[i][j] != -1) return memo[i][j];

        // Recursively calculate
        int fromTop = paths(i - 1, j);
        int fromLeft = paths(i, j - 1);

        // Store and return
        memo[i][j] = fromTop + fromLeft;
        return memo[i][j];
    }
}
```

---

#### Unique Paths II (LeetCode 63)

##### **The Problem:**

Similar to Unique Paths, but now the grid has **obstacles**. An obstacle is marked as `1`, and empty space is marked as `0`.
A path that the robot takes cannot include any square that is an obstacle.

* **Input:** `obstacleGrid = [[0,0,0],[0,1,0],[0,0,0]]`
* **Output:** `2`

##### **Solution (Top-Down)**

* **1. Array Definition:** `memo[i][j]` = Number of paths to reach $(i, j)$.
* **2. Equation:** Same as Unique Paths, but skip cells with obstacles.
  $$memo[i][j] = memo[i-1][j] + memo[i][j-1] \quad \text{if obstacleGrid[i][j] == 0}$$
* **3. Base Cases:**
    * If `obstacleGrid[0][0] == 1`, return `0` (blocked at start)
    * First row/column: propagate `1` until hitting an obstacle

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
        // Out of bounds
        if (i < 0 || j < 0) return 0;

        // Obstacle
        if (grid[i][j] == 1) return 0;

        // Start position
        if (i == 0 && j == 0) return 1;

        // Check memo
        if (memo[i][j] != -1) return memo[i][j];

        // Recursively calculate
        int fromTop = paths(i - 1, j);
        int fromLeft = paths(i, j - 1);

        // Store and return
        memo[i][j] = fromTop + fromLeft;
        return memo[i][j];
    }
}
```

---

#### Decode Ways (LeetCode 91)

##### **The Problem:**

A message containing letters from `A-Z` can be encoded into numbers using the mapping `'A' -> "1"`, `'B' -> "2"`, ..., `'Z' -> "26"`.
Given a string `s` containing only digits, return the **number of ways** to decode it.

* **Input:** `s = "12"`
* **Output:** `2`
    * *Explanation:* "12" could be decoded as "AB" (1 2) or "L" (12).

##### **Solution (Top-Down)**

* **1. Array Definition:** `memo[i]` = Number of ways to decode `s[0...i]`.
* **2. Equation:** This is a **sum** problem. You have two choices:
    - Decode single digit (if valid)
    - Decode two digits (if valid)
      $$memo[i] = \text{decodeSingle}(i) + \text{decodeDouble}(i)$$
* **3. Base Cases:**
    * `memo[0] = 1` if `s[0] != '0'`

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
        // Base case: reached end
        if (index == s.length()) return 1;

        // Leading zero is invalid
        if (s.charAt(index) == '0') return 0;

        // Check memo
        if (memo[index] != -1) return memo[index];

        // Choice 1: decode single digit
        int decodeSingle = decode(index + 1);

        // Choice 2: decode two digits (if valid)
        int decodeDouble = 0;
        if (canDecodeTwo(index)) {
            decodeDouble = decode(index + 2);
        }

        // Store and return
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

#### Fibonacci Number (LeetCode 509)

##### **The Problem:**

The Fibonacci numbers form a sequence where each number is the sum of the two preceding ones:

* `F(0) = 0, F(1) = 1`
* `F(n) = F(n-1) + F(n-2)` for `n > 1`

Return `F(n)`.

* **Input:** `n = 4`
* **Output:** `3`
    * *Explanation:* F(4) = F(3) + F(2) = 2 + 1 = 3

##### **Solution (Top-Down)**

* **1. Array Definition:** `memo[n]` = The $n$-th Fibonacci number.
* **2. Equation:** This is a **sum** problem.
  $$memo[n] = memo[n-1] + memo[n-2]$$
* **3. Base Cases:**
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
        // Base cases
        if (n == 0) return 0;
        if (n == 1) return 1;

        // Check memo
        if (memo[n] != -1) return memo[n];

        // Recursively calculate
        int fromPrevOne = calculate(n - 1);
        int fromPrevTwo = calculate(n - 2);

        // Store and return
        memo[n] = fromPrevOne + fromPrevTwo;
        return memo[n];
    }
}
```

---

#### Count Sorted Vowel Strings (LeetCode 1641)

##### **The Problem:**

Given an integer `n`, return the number of strings of length `n` that consist only of vowels (`a, e, i, o, u`) and are **lexicographically sorted**.

* **Input:** `n = 2`
* **Output:** `15`
    * *Explanation:* The 15 sorted strings are: "aa", "ae", "ai", "ao", "au", "ee", "ei", "eo", "eu", "ii", "io", "iu", "oo", "ou", "uu".

##### **Solution (Top-Down)**

* **1. Array Definition:** `memo[n][vowel]` = Number of sorted strings of length `n` starting with vowel at index `vowel` or later.
* **2. Equation:** This is a **sum** problem. For each vowel, sum all possibilities.
  $$memo[n][v] = \sum_{i=v}^{4} memo[n-1][i]$$
* **3. Base Cases:**
    * `memo[1][v] = 5 - v` (for length 1, count remaining vowels)

```java
public class CountSortedVowelStrings {
    private int[][] memo;

    public int countVowelStrings(int n) {
        // 5 vowels: a(0), e(1), i(2), o(3), u(4)
        memo = new int[n + 1][5];
        for (int[] row : memo) Arrays.fill(row, -1);
        return count(n, 0);
    }

    private int count(int n, int startVowel) {
        // Base case
        if (n == 1) return 5 - startVowel;

        // Check memo
        if (memo[n][startVowel] != -1) return memo[n][startVowel];

        // Sum all choices from current vowel onwards
        int total = 0;
        for (int v = startVowel; v < 5; v++) {
            total += chooseVowel(n, v);
        }

        // Store and return
        memo[n][startVowel] = total;
        return memo[n][startVowel];
    }

    private int chooseVowel(int n, int vowel) {
        return count(n - 1, vowel);
    }
}
```

---

### Category B: Max/Min Problems (Optimization)

These problems ask "What is the best value?" The key insight is that we **choose** the optimal option among all possibilities using `max()` or `min()`.

---

#### Min Cost Climbing Stairs (LeetCode 746)

##### **The Problem:**

You are given an integer array `cost` where `cost[i]` is the cost of the $i$-th step on a staircase. Once you pay the cost, you can climb either **1 or 2 steps**.
You can either start from the step with index `0`, or the step with index `1`.
Return the *minimum cost* to reach the top of the floor (which is one step past the last index).

* **Input:** `cost = [10, 15, 20]`
* **Output:** `15`
    * *Explanation:* You will start at index 1.
        1. Pay 15 and climb two steps to reach the top.
           The total cost is 15.

##### **Solution (Top-Down)**

* **1. Array Definition:** `memo[i]` = The minimum cost to **reach** step $i$.
* **2. Equation:** This is a **min** problem. You have two choices:
    - Come from 1 step back
    - Come from 2 steps back
      $$memo[i] = \min(\text{costFrom1Back}, \quad \text{costFrom2Back})$$
* **3. Base Cases:**
    * `memo[0] = 0` (Start at ground floor is free)
    * `memo[1] = 0` (Can start at index 0 or 1 for free)

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
        // Base cases
        if (step == 0) return 0;
        if (step == 1) return 0;

        // Check memo
        if (memo[step] != -1) return memo[step];

        // Choice 1: from 1 step back
        int costFrom1Back = minCost(step - 1) + cost[step - 1];

        // Choice 2: from 2 steps back
        int costFrom2Back = minCost(step - 2) + cost[step - 2];

        // Store and return min
        memo[step] = Math.min(costFrom1Back, costFrom2Back);
        return memo[step];
    }
}
```

---

#### House Robber (LeetCode 198)

##### **The Problem:**

You are a professional robber planning to rob houses along a street. Each house has a certain amount of money stashed. The only constraint stopping you is that adjacent houses have security systems connected and **it will automatically contact the police if two adjacent houses were broken into on the same night**.

Given an integer array `nums` representing the amount of money of each house, return the *maximum amount of money* you can rob tonight without alerting the police.

* **Input:** `nums = [1, 2, 3, 1]`
* **Output:** `4`
    * *Explanation:* Rob house 1 (money = 1) and then rob house 3 (money = 3).
      Total amount you can rob = 1 + 3 = 4.

##### **Solution (Top-Down)**

* **1. Array Definition:** `memo[i]` = The max money we can rob from houses `0...i`.
* **2. Equation:** This is a **max** problem. For house $i$, you have two choices:
    - **Don't rob it:** Value is same as `memo[i-1]`.
    - **Rob it:** Value is current cash + `memo[i-2]` (skip adjacent house).
      $$memo[i] = \max(\text{skipHouse}, \quad \text{robHouse})$$
* **3. Base Cases:**
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
        // Base cases
        if (i == 0) return nums[0];
        if (i == 1) return Math.max(nums[0], nums[1]);

        // Check memo
        if (memo[i] != -1) return memo[i];

        // Choice 1: skip this house
        int skipHouse = maxRob(i - 1);

        // Choice 2: rob this house
        int robHouse = nums[i] + maxRob(i - 2);

        // Store and return max
        memo[i] = Math.max(skipHouse, robHouse);
        return memo[i];
    }
}
```

---

#### Coin Change (LeetCode 322)

##### **The Problem:**

You are given an integer array `coins` representing coins of different denominations and an integer `amount` representing a total amount of money.
Return the **fewest number of coins** that you need to make up that amount.
If that amount of money cannot be made up by any combination of the coins, return `-1`.

* **Input:** `coins = [1, 2, 5]`, `amount = 11`
* **Output:** `3`
    * *Explanation:* 11 = 5 + 5 + 1 (3 coins).

##### **Solution (Top-Down)**

* **1. Array Definition:** `memo[amount]` = The minimum coins needed to make this amount.
* **2. Equation:** This is a **min** problem. Try each coin:
  $$memo[amt] = \min_{coin} (1 + memo[amt - coin])$$
* **3. Base Cases:**
    * `memo[0] = 0` (0 coins to make 0)

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
        // Base case
        if (amount == 0) return 0;
        if (amount < 0) return Integer.MAX_VALUE;

        // Check memo
        if (memo[amount] != -1) return memo[amount];

        // Try each coin
        int minCount = Integer.MAX_VALUE;
        for (int coin : coins) {
            int subResult = useCoin(amount, coin);
            if (subResult != Integer.MAX_VALUE) {
                minCount = Math.min(minCount, 1 + subResult);
            }
        }

        // Store and return
        memo[amount] = minCount;
        return memo[amount];
    }

    private int useCoin(int amount, int coin) {
        return minCoins(amount - coin);
    }
}
```

---

#### Longest Increasing Subsequence (LeetCode 300)

##### **The Problem:**

Given an integer array `nums`, return the length of the longest strictly increasing subsequence.

* **Input:** `nums = [10,9,2,5,3,7,101,18]`
* **Output:** `4`
    * *Explanation:* The longest increasing subsequence is [2,3,7,101].

##### **Solution (Top-Down)**

* **1. Array Definition:** `memo[i]` = Length of longest increasing subsequence ending at index $i$.
* **2. Equation:** This is a **max** problem. For each previous element, check if we can extend:
  $$memo[i] = \max(memo[j] + 1) \quad \text{where } j < i \text{ and } nums[j] < nums[i]$$
* **3. Base Cases:**
    * `memo[i] = 1` (each element is a subsequence of length 1)

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
        // Base case
        if (memo[i] != -1) return memo[i];

        // Start with length 1 (just this element)
        int maxLen = 1;

        // Try extending from previous elements
        for (int j = 0; j < i; j++) {
            if (nums[j] < nums[i]) {
                maxLen = Math.max(maxLen, extendFrom(j));
            }
        }

        // Store and return
        memo[i] = maxLen;
        return memo[i];
    }

    private int extendFrom(int j) {
        return lis(j) + 1;
    }
}
```

---

#### Longest Common Subsequence (LeetCode 1143)

##### **The Problem:**

Given two strings `text1` and `text2`, return the length of their longest **common subsequence**. If there is no common subsequence, return `0`.

*Note:* A **subsequence** of a string is a new string generated from the original string with some characters (can be none) deleted without changing the relative order of the remaining characters.

* *Example:* "ace" is a subsequence of "abcde".

* **Input:** `text1 = "abcde"`, `text2 = "ace"`
* **Output:** `3`
    * *Explanation:* The longest common subsequence is "ace" and its length is 3.

##### **Solution (Top-Down)**

* **1. Array Definition:** `memo[i][j]` = LCS length between `text1[0...i]` and `text2[0...j]`.
* **2. Equation:** This is a **max** problem. Two cases:
    * If characters match: `1 + memo[i-1][j-1]`
    * If they don't match: `max(memo[i-1][j], memo[i][j-1])`
* **3. Base Cases:**
    * `memo[i][0] = 0` or `memo[0][j] = 0` (empty string comparison)

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
        // Base cases
        if (i < 0 || j < 0) return 0;

        // Check memo
        if (memo[i][j] != -1) return memo[i][j];

        // If characters match
        if (text1.charAt(i) == text2.charAt(j)) {
            memo[i][j] = matchChars(i, j);
        } else {
            // If they don't match
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

#### Maximum Subarray (LeetCode 53)

##### **The Problem:**

Given an integer array `nums`, find the contiguous subarray which has the largest sum and return its sum.

* **Input:** `nums = [-2,1,-3,4,-1,2,1,-5,4]`
* **Output:** `6`
    * *Explanation:* The subarray [4,-1,2,1] has the largest sum = 6.

##### **Solution (Top-Down)**

* **1. Array Definition:** `memo[i]` = Maximum sum of subarray ending at index $i$.
* **2. Equation:** This is a **max** problem. At each position:
    * Either start fresh from current element
    * Or extend the previous subarray
      $$memo[i] = \max(nums[i], \quad nums[i] + memo[i-1])$$
* **3. Base Cases:**
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
        // Base case
        if (i == 0) return nums[0];

        // Check memo
        if (memo[i] != Integer.MIN_VALUE) return memo[i];

        // Choice 1: start fresh
        int startFresh = nums[i];

        // Choice 2: extend previous
        int extendPrev = nums[i] + maxEndingAt(i - 1);

        // Store and return max
        memo[i] = Math.max(startFresh, extendPrev);
        return memo[i];
    }
}
```

---

### Category C: Exist Problems (Possibility / Boolean)

These problems ask "Is it possible?" The key insight is that we use **logical OR** - if any path works, the answer is true.

---

#### Word Break (LeetCode 139)

##### **The Problem:**

Given a string `s` and a dictionary of strings `wordDict`, return `true` if `s` can be segmented into a space-separated sequence of one or more dictionary words.

* **Input:** `s = "leetcode"`, `wordDict = ["leet","code"]`
* **Output:** `true`
    * *Explanation:* Return true because "leetcode" can be segmented as "leet code".

##### **Solution (Top-Down)**

* **1. Array Definition:** `memo[i]` = Whether substring `s[i...]` can be segmented.
* **2. Equation:** This is an **exist** problem. Try each word:
  $$memo[i] = \bigvee_{word} (\text{s starts with word AND } memo[i + word.length])$$
* **3. Base Cases:**
    * `memo[s.length()] = true` (empty string is valid)

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
        // Base case
        if (start == s.length()) return true;

        // Check memo
        if (memo[start] != null) return memo[start];

        // Try each word
        for (String word : wordSet) {
            if (tryWord(start, word)) {
                memo[start] = true;
                return true;
            }
        }

        // No word works
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

#### Partition Equal Subset Sum (LeetCode 416)

##### **The Problem:**

Given an integer array `nums`, return `true` if you can partition the array into two subsets such that the sum of the elements in both subsets is equal.

* **Input:** `nums = [1,5,11,5]`
* **Output:** `true`
    * *Explanation:* The array can be partitioned as [1, 5, 5] and [11].

##### **Solution (Top-Down)**

* **1. Array Definition:** `memo[i][sum]` = Whether we can achieve `sum` using elements from index `i` onwards.
* **2. Equation:** This is an **exist** problem. For each element:
    * Include it, OR
    * Exclude it
      $$memo[i][sum] = \text{include}(i, sum) \lor \text{exclude}(i, sum)$$
* **3. Base Cases:**
    * `memo[i][0] = true` (sum of 0 is always achievable)
    * If `i >= nums.length` and `sum > 0`, return `false`

```java
public class PartitionEqualSubsetSum {
    private Boolean[][] memo;
    private int[] nums;

    public boolean canPartition(int[] nums) {
        int totalSum = 0;
        for (int num : nums) totalSum += num;

        // If total is odd, can't partition equally
        if (totalSum % 2 != 0) return false;

        this.nums = nums;
        int target = totalSum / 2;
        memo = new Boolean[nums.length][target + 1];

        return canAchieve(0, target);
    }

    private boolean canAchieve(int i, int sum) {
        // Base cases
        if (sum == 0) return true;
        if (i >= nums.length || sum < 0) return false;

        // Check memo
        if (memo[i][sum] != null) return memo[i][sum];

        // Choice 1: include current number
        boolean include = includeNum(i, sum);

        // Choice 2: exclude current number
        boolean exclude = excludeNum(i, sum);

        // Store and return
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

#### Target Sum (LeetCode 494)

##### **The Problem:**

You are given an integer array `nums` and an integer `target`.
You want to build an expression by adding `'+'` or `'-'` before each integer in `nums` and then concatenate all the integers.
Return the number of different expressions that you can build, which evaluates to `target`.

* **Input:** `nums = [1,1,1,1,1]`, `target = 3`
* **Output:** `5`
    * *Explanation:* There are 5 ways: -1+1+1+1+1, +1-1+1+1+1, +1+1-1+1+1, +1+1+1-1+1, +1+1+1+1-1

##### **Solution (Top-Down)**

* **1. Array Definition:** `memo[i][sum]` = Number of ways to achieve `sum` using elements from index `i` onwards.
* **2. Equation:** This is a **sum** problem (counting ways). For each number:
    * Add it, +
    * Subtract it
      $$memo[i][sum] = \text{add}(i, sum) + \text{subtract}(i, sum)$$
* **3. Base Cases:**
    * If `i == nums.length`, return `1` if `sum == target`, else `0`

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
        // Base case
        if (i == nums.length) {
            return currentSum == target ? 1 : 0;
        }

        // Check memo
        String key = i + "," + currentSum;
        if (memo.containsKey(key)) return memo.get(key);

        // Choice 1: add current number
        int addWays = addNum(i, currentSum);

        // Choice 2: subtract current number
        int subtractWays = subtractNum(i, currentSum);

        // Store and return sum
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

#### Can Jump (LeetCode 55)

##### **The Problem:**

You are given an integer array `nums`. You are initially positioned at the array's **first index**, and each element in the array represents your maximum jump length at that position. Return `true` if you can reach the last index, or `false` otherwise.

* **Input:** `nums = [2,3,1,1,4]`
* **Output:** `true`
    * *Explanation:* Jump 1 step from index 0 to 1, then 3 steps to the last index.

##### **Solution (Top-Down)**

* **1. Array Definition:** `memo[i]` = Whether we can reach the last index starting from position $i$.
* **2. Equation:** This is an **exist** problem. Try all possible jumps:
  $$memo[i] = \bigvee_{j=1}^{nums[i]} memo[i+j]$$
* **3. Base Cases:**
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
        // Base case: reached the end
        if (pos >= nums.length - 1) return true;

        // Check memo
        if (memo[pos] != null) return memo[pos];

        // Try all possible jumps
        int maxJump = nums[pos];
        for (int jump = 1; jump <= maxJump; jump++) {
            if (tryJump(pos, jump)) {
                memo[pos] = true;
                return true;
            }
        }

        // No jump works
        memo[pos] = false;
        return false;
    }

    private boolean tryJump(int pos, int jump) {
        return canReachEnd(pos + jump);
    }
}
```

---

#### Perfect Squares (LeetCode 279)

##### **The Problem:**

Given an integer `n`, return the least number of perfect square numbers that sum to `n`.

* **Input:** `n = 12`
* **Output:** `3`
    * *Explanation:* 12 = 4 + 4 + 4.

##### **Solution (Top-Down)**

* **1. Array Definition:** `memo[n]` = Minimum number of perfect squares that sum to $n$.
* **2. Equation:** This is a **min** problem. Try all perfect squares:
  $$memo[n] = \min_{i^2 \leq n} (1 + memo[n - i^2])$$
* **3. Base Cases:**
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
        // Base case
        if (n == 0) return 0;

        // Check memo
        if (memo[n] != -1) return memo[n];

        // Try all perfect squares <= n
        int minCount = Integer.MAX_VALUE;
        for (int i = 1; i * i <= n; i++) {
            int count = useSquare(n, i);
            minCount = Math.min(minCount, count);
        }

        // Store and return
        memo[n] = minCount;
        return memo[n];
    }

    private int useSquare(int n, int i) {
        return 1 + minSquares(n - i * i);
    }
}
```

---

#### Stone Game (LeetCode 877)

##### **The Problem:**

Alice and Bob play a game with piles of stones. There are an even number of piles arranged in a row, and each pile has a positive integer number of stones. The goal is to end with the most stones. Players take turns, and Alice goes first. On each turn, a player takes the
entire pile from either the beginning or the end.
Return `true` if Alice wins (assuming both play optimally).

* **Input:** `piles = [5,3,4,5]`
* **Output:** `true`

##### **Solution (Top-Down)**

* **1. Array Definition:** `memo[i][j]` = Maximum score difference (current player - opponent) for piles `i...j`.
* **2. Equation:** This is a **max** problem. Choose left or right:
  $$memo[i][j] = \max(\text{takeLeft}, \quad \text{takeRight})$$
* **3. Base Cases:**
    * `memo[i][i] = piles[i]` (only one pile left)

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
        // Base case: only one pile
        if (i == j) return piles[i];

        // Check memo
        if (memo[i][j] != -1) return memo[i][j];

        // Choice 1: take left pile
        int takeLeft = takeLeftPile(i, j);

        // Choice 2: take right pile
        int takeRight = takeRightPile(i, j);

        // Store and return max
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

## Bottom-Up Approach (Iteration)

### Why Bottom-Up is Preferred

While DP is often introduced using recursion (Top-Down), the Bottom-Up approach has significant advantages:

* **No Stack Overflow:** Iterative solutions use constant stack space.
* **Better Performance:** No function call overhead.
* **Clearer Flow:** The computation order is explicit and easy to trace.
* **Space Optimization:** Often easier to reduce space complexity (e.g., rolling array technique).

### The Mindset Shift: From Recursion to Iteration

**Top-Down Thinking:**
> "To solve problem `f(n)`, I need to first solve `f(n-1)` and `f(n-2)`."
> This is **goal-oriented**: start from the target and work backwards.

**Bottom-Up Thinking:**
> "I'll solve the smallest problems first: `f(0)`, `f(1)`, then build up to `f(n)`."
> This is **foundation-oriented**: start from the base and work forwards.

### Conversion Strategy

To convert a Top-Down solution to Bottom-Up:

1. **Identify the dependencies:** What does `dp[i]` depend on?
    - If it depends on `dp[i-1]`, loop from `1` to `n`
    - If it depends on smaller indices, loop forward
    - If it depends on larger indices, loop backward

2. **Initialize base cases:** Set `dp[0]`, `dp[1]`, etc. directly (no recursion needed)

3. **Fill the DP table iteratively:**
    - Use loops instead of recursion
    - The loop order matches the dependency direction
    - Apply the same state transition equation

4. **Return the final answer:** Usually `dp[n]` or `dp[n-1]`

### Category A: Sum Problems (Bottom-Up)

---

#### Climbing Stairs (Bottom-Up)

```java
public class ClimbingStairsBottomUp {
    public int climbStairs(int n) {
        if (n <= 1) return 1;

        // 1. Define array
        int[] dp = new int[n + 1];

        // 2. Initialize base cases
        dp[0] = 1;
        dp[1] = 1;

        // 3. Fill table iteratively
        for (int i = 2; i <= n; i++) {
            dp[i] = chooseOneStep(dp, i) + chooseTwoSteps(dp, i);
        }

        // 4. Return final answer
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

**Space Optimization:** Since we only need the last two values, we can use two variables instead of an array:

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

#### Unique Paths (Bottom-Up)

```java
public class UniquePathsBottomUp {
    public int uniquePaths(int m, int n) {
        // 1. Define array
        int[][] dp = new int[m][n];

        // 2. Initialize base cases
        for (int i = 0; i < m; i++) dp[i][0] = 1;  // First column
        for (int j = 0; j < n; j++) dp[0][j] = 1;  // First row

        // 3. Fill table iteratively
        for (int i = 1; i < m; i++) {
            for (int j = 1; j < n; j++) {
                dp[i][j] = fromTop(dp, i, j) + fromLeft(dp, i, j);
            }
        }

        // 4. Return final answer
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

**Space Optimization:** We only need the current row and previous row:

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

#### Unique Paths II (Bottom-Up)

```java
public class UniquePathsIIBottomUp {
    public int uniquePathsWithObstacles(int[][] obstacleGrid) {
        if (obstacleGrid[0][0] == 1) return 0;

        int m = obstacleGrid.length;
        int n = obstacleGrid[0].length;

        // 1. Define array
        int[][] dp = new int[m][n];

        // 2. Initialize base cases
        dp[0][0] = 1;

        // First column
        for (int i = 1; i < m; i++) {
            dp[i][0] = (obstacleGrid[i][0] == 0 && dp[i - 1][0] == 1) ? 1 : 0;
        }

        // First row
        for (int j = 1; j < n; j++) {
            dp[0][j] = (obstacleGrid[0][j] == 0 && dp[0][j - 1] == 1) ? 1 : 0;
        }

        // 3. Fill table iteratively
        for (int i = 1; i < m; i++) {
            for (int j = 1; j < n; j++) {
                if (obstacleGrid[i][j] == 1) {
                    dp[i][j] = 0;  // Obstacle
                } else {
                    dp[i][j] = fromTop(dp, i, j) + fromLeft(dp, i, j);
                }
            }
        }

        // 4. Return final answer
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

#### Decode Ways (Bottom-Up)

```java
public class DecodeWaysBottomUp {
    public int numDecodings(String s) {
        if (s.charAt(0) == '0') return 0;

        int n = s.length();

        // 1. Define array
        int[] dp = new int[n + 1];

        // 2. Initialize base cases
        dp[0] = 1;  // Empty string
        dp[1] = 1;  // First character (already validated non-zero)

        // 3. Fill table iteratively
        for (int i = 2; i <= n; i++) {
            // Choice 1: decode single digit
            int single = decodeSingle(s, i, dp);

            // Choice 2: decode two digits
            int double_ = decodeDouble(s, i, dp);

            dp[i] = single + double_;
        }

        // 4. Return final answer
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

#### Fibonacci Number (Bottom-Up)

```java
public class FibonacciBottomUp {
    public int fib(int n) {
        if (n <= 1) return n;

        // 1. Define array
        int[] dp = new int[n + 1];

        // 2. Initialize base cases
        dp[0] = 0;
        dp[1] = 1;

        // 3. Fill table iteratively
        for (int i = 2; i <= n; i++) {
            dp[i] = fromPrevOne(dp, i) + fromPrevTwo(dp, i);
        }

        // 4. Return final answer
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

**Space Optimization:**

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

#### Count Sorted Vowel Strings (Bottom-Up)

```java
public class CountSortedVowelStringsBottomUp {
    public int countVowelStrings(int n) {
        // 1. Define array
        // dp[i][j] = number of strings of length i ending with vowel j or later
        int[][] dp = new int[n + 1][6];

        // 2. Initialize base cases
        // For length 1, we can use any vowel
        for (int v = 0; v < 5; v++) {
            dp[1][v] = 5 - v;  // Can use vowels from v to 4
        }

        // 3. Fill table iteratively
        for (int len = 2; len <= n; len++) {
            for (int v = 4; v >= 0; v--) {  // Reverse order for easier calculation
                dp[len][v] = sumVowelChoices(dp, len, v);
            }
        }

        // 4. Return final answer
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

**Simpler approach with 1D array:**

```java
public int countVowelStringsSimple(int n) {
    // dp[i] = count for vowel i (a=0, e=1, i=2, o=3, u=4)
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

### Category B: Max/Min Problems (Bottom-Up)

---

#### Min Cost Climbing Stairs (Bottom-Up)

```java
public class MinCostClimbingStairsBottomUp {
    public int minCostClimbingStairs(int[] cost) {
        int n = cost.length;

        // 1. Define array
        int[] dp = new int[n + 1];

        // 2. Initialize base cases
        dp[0] = 0;  // Start at ground (free)
        dp[1] = 0;  // Start at first step (free)

        // 3. Fill table iteratively
        for (int i = 2; i <= n; i++) {
            int costFrom1Back = costFromOneBack(dp, cost, i);
            int costFrom2Back = costFromTwoBack(dp, cost, i);
            dp[i] = Math.min(costFrom1Back, costFrom2Back);
        }

        // 4. Return final answer
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

#### House Robber (Bottom-Up)

```java
public class HouseRobberBottomUp {
    public int rob(int[] nums) {
        if (nums.length == 0) return 0;
        if (nums.length == 1) return nums[0];

        int n = nums.length;

        // 1. Define array
        int[] dp = new int[n];

        // 2. Initialize base cases
        dp[0] = nums[0];
        dp[1] = Math.max(nums[0], nums[1]);

        // 3. Fill table iteratively
        for (int i = 2; i < n; i++) {
            int skipHouse = skipCurrent(dp, i);
            int robHouse = robCurrent(dp, nums, i);
            dp[i] = Math.max(skipHouse, robHouse);
        }

        // 4. Return final answer
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

#### Coin Change (Bottom-Up)

```java
public class CoinChangeBottomUp {
    public int coinChange(int[] coins, int amount) {
        // 1. Define array
        int[] dp = new int[amount + 1];

        // 2. Initialize base cases
        Arrays.fill(dp, amount + 1);  // Infinity placeholder
        dp[0] = 0;  // 0 coins for amount 0

        // 3. Fill table iteratively
        for (int amt = 1; amt <= amount; amt++) {
            for (int coin : coins) {
                if (coin <= amt) {
                    dp[amt] = Math.min(dp[amt], useCoin(dp, amt, coin));
                }
            }
        }

        // 4. Return final answer
        return dp[amount] > amount ? -1 : dp[amount];
    }

    private int useCoin(int[] dp, int amt, int coin) {
        return dp[amt - coin] + 1;
    }
}
```

---

#### Longest Increasing Subsequence (Bottom-Up)

```java
public class LongestIncreasingSubsequenceBottomUp {
    public int lengthOfLIS(int[] nums) {
        int n = nums.length;

        // 1. Define array
        int[] dp = new int[n];

        // 2. Initialize base cases
        Arrays.fill(dp, 1);  // Each element is a LIS of length 1

        // 3. Fill table iteratively
        for (int i = 1; i < n; i++) {
            for (int j = 0; j < i; j++) {
                if (nums[j] < nums[i]) {
                    dp[i] = Math.max(dp[i], extendFrom(dp, j));
                }
            }
        }

        // 4. Return final answer (max of all dp values)
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

#### Longest Common Subsequence (Bottom-Up)

```java
public class LongestCommonSubsequenceBottomUp {
    public int longestCommonSubsequence(String text1, String text2) {
        int m = text1.length();
        int n = text2.length();

        // 1. Define array
        int[][] dp = new int[m + 1][n + 1];

        // 2. Initialize base cases (already 0 by default)
        // dp[0][j] = 0 and dp[i][0] = 0

        // 3. Fill table iteratively
        for (int i = 1; i <= m; i++) {
            for (int j = 1; j <= n; j++) {
                if (text1.charAt(i - 1) == text2.charAt(j - 1)) {
                    dp[i][j] = matchChars(dp, i, j);
                } else {
                    dp[i][j] = skipChar(dp, i, j);
                }
            }
        }

        // 4. Return final answer
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

#### Maximum Subarray (Bottom-Up)

```java
public class MaximumSubarrayBottomUp {
    public int maxSubArray(int[] nums) {
        int n = nums.length;

        // 1. Define array
        int[] dp = new int[n];

        // 2. Initialize base case
        dp[0] = nums[0];

        // 3. Fill table iteratively
        int maxSum = dp[0];
        for (int i = 1; i < n; i++) {
            int startFresh = nums[i];
            int extendPrev = nums[i] + dp[i - 1];
            dp[i] = Math.max(startFresh, extendPrev);
            maxSum = Math.max(maxSum, dp[i]);
        }

        // 4. Return final answer
        return maxSum;
    }
}
```

**Space Optimization:**

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

### Category C: Exist Problems (Bottom-Up)

---

#### Word Break (Bottom-Up)

```java
public class WordBreakBottomUp {
    public boolean wordBreak(String s, List<String> wordDict) {
        Set<String> wordSet = new HashSet<>(wordDict);
        int n = s.length();

        // 1. Define array
        boolean[] dp = new boolean[n + 1];

        // 2. Initialize base case
        dp[0] = true;  // Empty string is valid

        // 3. Fill table iteratively
        for (int i = 1; i <= n; i++) {
            for (String word : wordSet) {
                if (canUseWord(s, dp, i, word)) {
                    dp[i] = true;
                    break;  // Found one valid way
                }
            }
        }

        // 4. Return final answer
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

#### Partition Equal Subset Sum (Bottom-Up)

```java
public class PartitionEqualSubsetSumBottomUp {
    public boolean canPartition(int[] nums) {
        int totalSum = 0;
        for (int num : nums) totalSum += num;

        if (totalSum % 2 != 0) return false;

        int target = totalSum / 2;

        // 1. Define array
        boolean[] dp = new boolean[target + 1];

        // 2. Initialize base case
        dp[0] = true;  // Sum of 0 is always achievable

        // 3. Fill table iteratively
        for (int num : nums) {
            // Traverse backwards to avoid using same element twice
            for (int sum = target; sum >= num; sum--) {
                if (dp[sum - num]) {
                    dp[sum] = includeNum(dp, sum, num);
                }
            }
        }

        // 4. Return final answer
        return dp[target];
    }

    private boolean includeNum(boolean[] dp, int sum, int num) {
        return dp[sum - num];  // If we can make (sum - num), we can make sum
    }
}
```

---

#### Target Sum (Bottom-Up)

```java
public class TargetSumBottomUp {
    public int findTargetSumWays(int[] nums, int target) {
        int sum = 0;
        for (int num : nums) sum += num;

        // Mathematical insight: P - N = target, P + N = sum
        // Therefore: P = (target + sum) / 2
        if (sum < Math.abs(target) || (target + sum) % 2 != 0) return 0;

        int positiveSum = (target + sum) / 2;

        // 1. Define array
        int[] dp = new int[positiveSum + 1];

        // 2. Initialize base case
        dp[0] = 1;  // One way to make sum 0

        // 3. Fill table iteratively
        for (int num : nums) {
            for (int s = positiveSum; s >= num; s--) {
                dp[s] += includeNum(dp, s, num);
            }
        }

        // 4. Return final answer
        return dp[positiveSum];
    }

    private int includeNum(int[] dp, int s, int num) {
        return dp[s - num];
    }
}
```

---

#### Can Jump (Bottom-Up)

```java
public class CanJumpBottomUp {
    public boolean canJump(int[] nums) {
        int n = nums.length;

        // 1. Define array
        boolean[] dp = new boolean[n];

        // 2. Initialize base case
        dp[0] = true;  // Starting position is reachable

        // 3. Fill table iteratively
        for (int i = 0; i < n; i++) {
            if (!dp[i]) continue;  // Can't reach this position

            // Mark all reachable positions from here
            int maxJump = nums[i];
            for (int jump = 1; jump <= maxJump && i + jump < n; jump++) {
                dp[i + jump] = tryJump(i, jump);
            }
        }

        // 4. Return final answer
        return dp[n - 1];
    }

    private boolean tryJump(int pos, int jump) {
        return true;  // Position is reachable
    }
}
```

**Greedy Optimization (Better approach):**

```java
public boolean canJumpGreedy(int[] nums) {
    int maxReach = 0;

    for (int i = 0; i < nums.length; i++) {
        if (i > maxReach) return false;  // Can't reach this position
        maxReach = Math.max(maxReach, i + nums[i]);
    }

    return true;
}
```

---

#### Perfect Squares (Bottom-Up)

```java
public class PerfectSquaresBottomUp {
    public int numSquares(int n) {
        // 1. Define array
        int[] dp = new int[n + 1];

        // 2. Initialize base cases
        Arrays.fill(dp, Integer.MAX_VALUE);
        dp[0] = 0;

        // 3. Fill table iteratively
        for (int i = 1; i <= n; i++) {
            for (int j = 1; j * j <= i; j++) {
                dp[i] = Math.min(dp[i], useSquare(dp, i, j));
            }
        }

        // 4. Return final answer
        return dp[n];
    }

    private int useSquare(int[] dp, int i, int j) {
        return dp[i - j * j] + 1;
    }
}
```

---

#### Stone Game (Bottom-Up)

```java
public class StoneGameBottomUp {
    public boolean stoneGame(int[] piles) {
        int n = piles.length;

        // 1. Define array
        int[][] dp = new int[n][n];

        // 2. Initialize base cases
        for (int i = 0; i < n; i++) {
            dp[i][i] = piles[i];  // Only one pile
        }

        // 3. Fill table iteratively
        // len is the subarray length
        for (int len = 2; len <= n; len++) {
            for (int i = 0; i <= n - len; i++) {
                int j = i + len - 1;

                int takeLeft = takeLeftPile(piles, dp, i, j);
                int takeRight = takeRightPile(piles, dp, i, j);

                dp[i][j] = Math.max(takeLeft, takeRight);
            }
        }

        // 4. Return final answer
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

## Summary Table

| Problem                        | Category | Pattern                                                          | Time     | Space  |
|--------------------------------|----------|------------------------------------------------------------------|----------|--------|
| Climbing Stairs                | Sum      | `dp[i] = dp[i-1] + dp[i-2]`                                      | O(n)     | O(1)*  |
| Unique Paths                   | Sum      | `dp[i][j] = dp[i-1][j] + dp[i][j-1]`                             | O(mn)    | O(n)*  |
| Unique Paths II                | Sum      | Same as above with obstacles                                     | O(mn)    | O(n)*  |
| Decode Ways                    | Sum      | `dp[i] = dp[i-1] + dp[i-2]`                                      | O(n)     | O(n)   |
| Fibonacci                      | Sum      | `dp[i] = dp[i-1] + dp[i-2]`                                      | O(n)     | O(1)*  |
| Count Vowel Strings            | Sum      | `dp[n][v] = Σ dp[n-1][v']`                                       | O(n)     | O(n)   |
| Min Cost Stairs                | Min      | `dp[i] = min(dp[i-1], dp[i-2]) + cost`                           | O(n)     | O(1)*  |
| House Robber                   | Max      | `dp[i] = max(dp[i-1], dp[i-2] + nums[i])`                        | O(n)     | O(1)*  |
| Coin Change                    | Min      | `dp[i] = min(1 + dp[i-coin])`                                    | O(n×m)   | O(n)   |
| Longest Increasing Subsequence | Max      | `dp[i] = max(dp[j] + 1)`                                         | O(n²)    | O(n)   |
| Longest Common Subsequence     | Max      | Match: `1 + dp[i-1][j-1]`<br>Skip: `max(dp[i-1][j], dp[i][j-1])` | O(mn)    | O(n)*  |
| Maximum Subarray               | Max      | `dp[i] = max(nums[i], dp[i-1] + nums[i])`                        | O(n)     | O(1)*  |
| Word Break                     | Exist    | `dp[i] = ∨ dp[i-len(word)]`                                      | O(n×m×k) | O(n)   |
| Partition Equal Subset Sum     | Exist    | `dp[sum] = dp[sum] ∨ dp[sum-num]`                                | O(n×sum) | O(sum) |
| Target Sum                     | Sum      | `dp[i][sum] = dp[i+1][sum+num] + dp[i+1][sum-num]`               | O(n×sum) | O(sum) |
| Can Jump                       | Exist    | `dp[i] = ∨ dp[i+jump]`                                           | O(n²)    | O(n)   |
| Perfect Squares                | Min      | `dp[n] = min(1 + dp[n-i²])`                                      | O(n√n)   | O(n)   |
| Stone Game                     | Max      | `dp[i][j] = max(piles[i] - dp[i+1][j], piles[j] - dp[i][j-1])`   | O(n²)    | O(n²)  |

*Space complexity can be optimized using rolling array or variables.

---

## Key Takeaways

1. **Identify the Pattern:**
    - **Sum problems** → Add all possibilities
    - **Max/Min problems** → Choose the best option
    - **Exist problems** → Check if any option works

2. **Top-Down vs Bottom-Up:**
    - **Top-Down:** Natural recursion, easier to think, but risk of stack overflow
    - **Bottom-Up:** Iterative, better performance, easier to optimize space

3. **Space Optimization:**
    - If `dp[i]` only depends on `dp[i-1]` and `dp[i-2]`, use two variables
    - For 2D DP, if `dp[i][j]` only depends on previous row, use rolling array

4. **The Three Steps (Never Skip):**
    - **Define** what `dp[i]` means
    - **Derive** the state transition equation
    - **Initialize** the base cases

5. **Practice Makes Perfect:**
    - Start with easy problems (Fibonacci, Climbing Stairs)
    - Progress to medium (House Robber, Coin Change)
    - Master hard problems (LCS, Stone Game)

