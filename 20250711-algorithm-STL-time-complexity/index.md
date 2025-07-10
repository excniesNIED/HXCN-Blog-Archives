---
算法入门：STL用法与时空复杂度
---

## 1. 时空复杂度 (Time & Space Complexity)

在算法竞赛中，时空复杂度是衡量算法性能的重要指标，通常我们更侧重时间复杂度。

### 1.1. 概述

*   **时间复杂度 (Time Complexity):** 描述算法的执行效率（运行时间），越低越好。
*   **空间复杂度 (Space Complexity):** 描述算法占用的内存大小。在算法竞赛中，通常时间复杂度是主要挑战，空间复杂度一般不会卡得太死，但仍需注意。

### 1.2. 时间复杂度

#### 1.2.1. 定义与表示

时间复杂度描述了算法执行时间随输入数据规模 $N$ 变化的趋势。我们使用大O符号 $O(f(N))$ 来表示。

**常见的时间复杂度函数（高中数学函数）：**

*   $O(1)$ (常数时间)
*   $O(\log N)$ (对数时间，底数通常不重要，如 $O(\log_2 N)$ 或 $O(\ln N)$ 都可以简写为 $O(\log N)$)
*   $O(\sqrt{N})$ (平方根时间)
*   $O(N)$ (线性时间)
*   $O(N \log N)$ (线性对数时间)
*   $O(N^2)$ (平方时间)
*   $O(N^3)$ (立方时间)
*   $O(2^N)$ (指数时间)
*   $O(N!)$ (阶乘时间)

**函数性质：**

*   在算法竞赛中，数据规模 $N$ 通常是非负数（$N \ge 1$），我们只考虑函数在第一象限的表现。
*   在第一象限，上述函数都是递增的，即随着 $N$ 增大，执行时间也增大。
*   **核心特性：忽略常数因子。** 例如，$O(2N)$、$O(5N)$ 都被视为 $O(N)$。这是因为大O表示的是增长趋势，常数因子不影响其渐进趋势。
*   **$O(1)$ 的特殊性：** 当算法执行次数为常数时（如 $A+B$），我们用 $O(1)$ 表示，而不是 $O()$。

#### 1.2.2. 时间复杂度分析示例

1.  **查找数组中的最小值**
    *   **问题描述:** 给定长度为 $N$ 的数组 $A$，求数组中的最小值。
    *   **代码思路:** 遍历数组一次，维护当前最小值。
    *   **数据范围:** $N \le 200,000$。
    *   **示例代码结构 (伪代码):**
        ```cpp
        const int MAXN = 200000 + 5; // 常用技巧，数组开大一点防止越界
        int a[MAXN]; // 或者使用 vector<int> a;
        int n;
        // cin >> n; // 读取N
        // 循环读取a[1]...a[N] (推荐1-based indexing in competitive programming)
        
        int min_val = 2e9; // 初始化为正无穷大 (2 * 10^9)
        for (int i = 1; i <= n; ++i) { // 遍历N次
            // min_val = min(min_val, a[i]); // 每次操作为常数时间
            if (a[i] < min_val) {
                min_val = a[i];
            }
        }
        // cout << min_val;
        ```
    *   **复杂度分析:** 循环执行 $N$ 次，每次循环内部的操作（比较、赋值、自增）都是常数时间。总执行次数约为 $C \times N$，根据常数忽略原则，时间复杂度为 $O(N)$。

2.  **求最大公约数 (GCD) - 欧几里得算法**
    *   **问题描述:** 求两个正整数 $X, Y$ 的最大公约数。
    *   **算法原理:** 基于 $GCD(X, Y) = GCD(X \pmod Y, Y)$，终止条件为 $GCD(X, 0) = X$。
    *   **示例代码 (递归):**
        ```cpp
        int gcd(int x, int y) {
            if (y == 0) {
                return x;
            }
            return gcd(y, x % y); // 递归调用
        }
        ```
    *   **复杂度分析:** 每次递归 $Y$ 都会减小，并且至少减半（斐波那契序列的反向）。因此，该算法的时间复杂度为 $O(\log N)$，其中 $N$ 是 $X$ 和 $Y$ 中较大的数。底数在这里通常不重要，因为 $\log_a N = \frac{\log_b N}{\log_b a}$，不同底数只差一个常数因子。

3.  **特殊两层For循环**
    *   **问题描述:** 计算以下嵌套循环的执行次数。
    *   **代码示例:**
        ```cpp
        int n; // 假设n已输入
        long long c = 0; // 计数器
        for (int i = 1; i <= n; ++i) {
            for (int j = i; j <= n; j += i) {
                c++; // 每次执行计数器加1
            }
        }
        // cout << c; // 最后输出c
        ```
    *   **复杂度分析:**
        *   外层循环变量 `i` 从 $1$ 到 $N$。
        *   内层循环变量 `j` 从 `i` 开始，每次增加 `i`，直到超过 `N`。
        *   当 `i=1` 时，`j` 取值 $1, 2, \dots, N$，执行 $N/1 = N$ 次。
        *   当 `i=2` 时，`j` 取值 $2, 4, \dots, N'$ (最大不超过 $N$)，执行 $N/2$ 次。
        *   当 `i=3` 时，`j` 取值 $3, 6, \dots, N''$，执行 $N/3$ 次。
        *   ...
        *   当 `i=N` 时，`j` 取值 $N$，执行 $N/N = 1$ 次。
        *   总执行次数为 $N/1 + N/2 + N/3 + \dots + N/N = N \times (1 + 1/2 + 1/3 + \dots + 1/N)$。
        *   括号内的部分是**调和级数**，其和约等于 $\ln N$ (自然对数)。
        *   因此，总执行次数约等于 $N \ln N$。时间复杂度为 $O(N \log N)$。

### 1.3. 空间复杂度

空间复杂度衡量算法在执行过程中临时占用的存储空间大小。

*   **单个变量:** $O(1)$ (常数空间)。例如 `int x;`。
*   **长度为 $N$ 的数组:** $O(N)$ (线性空间)。例如 `int arr[N];`。
*   **二维数组 (N行M列):** $O(N \times M)$。

通常，算法竞赛中的空间限制是足够的，除非题目明确要求优化空间。

## 2. STL (Standard Template Library)

STL 是 C++ 内置的标准模板库，提供了一系列强大且经过高度优化的工具，包括容器、算法和迭代器。

### 2.1. 简介

*   **优势:** 无需手动实现常见数据结构和算法，直接调用即可，通常比手写更高效、更稳定。
*   **使用环境配置:**
    *   **头文件:**
        *   `#include <stack>`: 使用 `std::stack`
        *   `#include <queue>`: 使用 `std::queue`
        *   `#include <vector>`: 使用 `std::vector`
        *   `#include <algorithm>`: 使用 `std::sort`, `std::reverse` 等算法
        *   `#include <string>`: 使用 `std::string`
        *   `#include <set>`: 使用 `std::set`, `std::multiset`
        *   `#include <map>`: 使用 `std::map`, `std::multimap`
        *   `#include <deque>`: 使用 `std::deque`
        *   `#include <functional>`: 用于 `std::greater` 等比较器
    *   **命名空间:** `using namespace std;` (建议在算法竞赛中使用，简化代码)
    *   **万能头文件 (竞赛常用):** `#include <bits/stdc++.h>` (包含几乎所有标准库头文件，方便快捷)

### 2.2. `std::stack` (栈)

*   **概念:** 一种“后进先出”（LIFO）的容器。想象一个只在一端开口的盒子，新元素从顶端加入（压栈），旧元素被压到底部；取出元素时也只能从顶端取出（弹栈），最先进入的元素最后才能出来。
*   **定义:** `std::stack<DataType> stk;` (例如: `std::stack<int> stk;`)
*   **常用函数 (时间复杂度均为 $O(1)$):**
    *   `stk.push(x)`: 将元素 `x` 压入栈顶。
    *   `stk.pop()`: 移除栈顶元素。
    *   `stk.top()`: 获取栈顶元素（不移除）。
    *   `stk.size()`: 返回栈中元素个数。
    *   `stk.empty()`: 判断栈是否为空。
*   **使用注意:** 在算法竞赛中，`std::stack` 的功能通常可以被 `std::vector` 的 `push_back`/`pop_back`/`back` 操作替代，甚至更灵活。

### 2.3. `std::queue` (队列)

*   **概念:** 一种“先进先出”（FIFO）的容器。想象一个两端开口的管道，元素从一端加入（入队），从另一端取出（出队）。
*   **定义:** `std::queue<DataType> q;` (例如: `std::queue<int> q;`)
*   **常用函数 (时间复杂度均为 $O(1)$):**
    *   `q.push(x)`: 将元素 `x` 加入队尾。
    *   `q.pop()`: 移除队首元素。
    *   `q.front()`: 获取队首元素（不移除）。
    *   `q.back()`: 获取队尾元素（不移除）。
    *   `q.size()`: 返回队列中元素个数。
    *   `q.empty()`: 判断队列是否为空。
*   **常用场景:** 广度优先搜索 (BFS) 等图论算法。

### 2.4. `std::vector` (动态数组)

*   **概念:** C++中最常用、最强大的容器之一。它是一个可以动态改变大小的数组，功能远超普通数组，可以完全替代普通数组。
*   **定义:** `std::vector<DataType> name;` (例如: `std::vector<int> a;`)
*   **初始化与大小调整:**
    *   `std::vector<int> a;`: 定义一个空 `vector`。
    *   `std::vector<int> a(N);`: 定义一个大小为 `N` 的 `vector`，元素默认初始化 (int为0)。
    *   `std::vector<int> a(N, initial_value);`: 定义一个大小为 `N` 的 `vector`，所有元素初始化为 `initial_value`。
    *   **二维 `vector` (等同于二维数组):** `std::vector<std::vector<int>> matrix(N, std::vector<int>(M, 0));` (定义一个 $N$ 行 $M$ 列的矩阵，所有元素初始化为0)。
*   **常用函数：**
    *   `a.push_back(x)`: 在 `vector` 尾部添加元素 `x`。时间复杂度摊还 $O(1)$ (当 `vector` 需要扩容时为 $O(N)$，但平均下来是 $O(1)$)。
    *   `a.pop_back()`: 移除 `vector` 尾部元素。时间复杂度 $O(1)$。
    *   `a.back()`: 获取 `vector` 尾部元素。时间复杂度 $O(1)$。
    *   `a.size()`: 返回 `vector` 中元素个数。时间复杂度 $O(1)$。
    *   `a[i]`: 通过下标访问元素。时间复杂度 $O(1)$。
    *   `a.begin()`: 返回指向 `vector` 第一个元素的迭代器（可视为指针）。
    *   `a.end()`: 返回指向 `vector` 最后一个元素**之后**位置的迭代器。
*   **`std::reverse` (反转):**
    *   `#include <algorithm>`
    *   `std::reverse(a.begin(), a.end());`: 反转整个 `vector`。
    *   `std::reverse(a.begin() + L, a.begin() + R + 1);`: 反转 `[L, R]` 区间的元素（左闭右开原则）。
*   **`std::vector` 优势:**
    *   动态大小调整。
    *   支持像数组一样通过下标访问。
    *   支持 STL 算法（如 `sort`, `reverse`）。
    *   支持直接赋值 `vector_b = vector_a;` (普通数组不允许直接赋值)。
*   **`size_t` 陷阱:**
    *   `vector::size()` 返回 `size_t` 类型（无符号整数）。
    *   当 `vector` 为空时，`a.size() - 1` 会导致无符号整数下溢，变成一个非常大的正数，从而引起越界或无限循环。
    *   **建议避免的写法:** `for (size_t i = a.size() - 1; i >= 0; --i)`
    *   **推荐的写法:**
        *   使用 `std::reverse`。
        *   使用 `for (int i = a.size() - 1; i >= 0; --i)` (确保 `a.size()` 不超过 `int` 最大值，通常可以)。

#### 2.4.1. 练习：反向输出数字

*   **问题:** 输入一串数字，以0结束（0不输出），反向输出前面的数字。
*   **思路:** 使用 `std::vector` 存储数字，然后反转或从后向前遍历输出。
*   **核心代码:**
    ```cpp
    #include <iostream>
    #include <vector>
    #include <algorithm> // for std::reverse
    
    int main() {
        // using namespace std; // 如果使用万能头文件可省略
        // ios_base::sync_with_stdio(false); cin.tie(NULL); // 优化I/O，可选
        std::vector<int> nums;
        int x;
        while (std::cin >> x && x != 0) { // 读入数字直到0
            nums.push_back(x);
        }
    
        // 方法一：反转vector再顺序输出
        std::reverse(nums.begin(), nums.end());
        for (int i = 0; i < nums.size(); ++i) { // 从0开始遍历，避免size_t陷阱
            std::cout << nums[i];
            if (i < nums.size() - 1) {
                std::cout << " ";
            }
        }
        std::cout << std::endl;
    
        // 方法二：直接从后向前遍历输出
        // for (int i = nums.size() - 1; i >= 0; --i) {
        //     std::cout << nums[i] << " ";
        // }
        // std::cout << std::endl;
    
        return 0;
    }
    ```

#### 2.4.2. 练习：矩阵转置

*   **问题:** 输入一个 $N$ 行 $M$ 列的矩阵，输出其转置矩阵（变为 $M$ 行 $N$ 列）。
*   **思路:** 使用二维 `std::vector` 存储矩阵，然后交换遍历顺序输出。
*   **核心代码:**
    ```cpp
    #include <iostream>
    #include <vector>
    
    int main() {
        // using namespace std;
        int n, m;
        std::cin >> n >> m;
    
        // 定义并初始化N行M列的矩阵，元素默认0
        std::vector<std::vector<int>> matrix(n, std::vector<int>(m, 0));
    
        // 读入矩阵元素
        for (int i = 0; i < n; ++i) {
            for (int j = 0; j < m; ++j) {
                std::cin >> matrix[i][j];
            }
        }
    
        // 输出转置矩阵 (M行N列)
        for (int j = 0; j < m; ++j) { // 先遍历列
            for (int i = 0; i < n; ++i) { // 再遍历行
                std::cout << matrix[i][j]; // matrix[行][列]
                if (i < n - 1) { // 不是当前列的最后一个元素，输出空格
                    std::cout << " ";
                }
            }
            std::cout << std::endl; // 每输出完一列（转置后的一行），换行
        }
    
        return 0;
    }
    ```

### 2.5. `std::sort` (排序算法)

*   **概念:** `std::sort` 是 C++ 标准库提供的一个高效排序算法。
*   **头文件:** `#include <algorithm>` (或万能头文件)。
*   **基本用法:**
    *   **对 `std::vector` 排序:** `std::sort(vec.begin(), vec.end());`
    *   **对普通数组排序:** `std::sort(arr, arr + N);` (其中 `arr` 是数组名，`N` 是数组长度)。
*   **时间复杂度:** $O(N \log N)$ (基于快速排序、内省排序或堆排序的优化版本)。比冒泡、选择、插入排序的 $O(N^2)$ 快得多。
*   **自定义比较规则 (从大到小排序或更复杂的规则):**
    *   **方法一：Lambda 表达式 (C++11+)**
        ```cpp
        // 从大到小排序
        std::sort(vec.begin(), vec.end(), [](int a, int b) {
            return a > b; // 如果a应该在b前面，返回true
        });
        ```
    *   **方法二：自定义比较函数 (全局函数)**
        ```cpp
        bool compare_desc(int a, int b) {
            return a > b; // 从大到小排序
        }
        std::sort(vec.begin(), vec.end(), compare_desc);
        ```
    *   **方法三：自定义比较器对象 (仿函数)**
        ```cpp
        struct MyComparator {
            bool operator()(int a, int b) const {
                // 示例：谁离3更近谁优先 (绝对值越小越优先)
                return std::abs(a - 3) < std::abs(b - 3);
            }
        };
        std::sort(vec.begin(), vec.end(), MyComparator());
        ```
    *   **`std::greater<DataType>()` (用于从大到小排序):**
        ```cpp
        #include <functional> // for std::greater
        std::sort(vec.begin(), vec.end(), std::greater<int>()); // 从大到小排序
        ```
*   **迭代器 (Iterator):**
    *   `std::vector` 和 `std::string` 的 `begin()` 和 `end()` 返回的是迭代器。
    *   迭代器可以理解为指向容器元素的“智能指针”。
    *   `vec.begin() + L` 表示从 `vec.begin()` 偏移 `L` 个位置的迭代器。
    *   `std::sort` 的区间是**左闭右开**的，即 `[start_iterator, end_iterator)`。

### 2.6. `std::string` (字符串)

*   **概念:** `std::string` 是 C++ 对字符数组（`char[]`）的封装，提供了更高级、更方便的字符串操作。可以把它看作是 `std::vector<char>` 的增强版。
*   **头文件:** `#include <string>` (或万能头文件)。
*   **定义:** `std::string s;`
*   **常用功能 (大部分操作与 `std::vector` 类似):**
    *   `s.size()`: 字符串长度 (O(1))。
    *   `s[i]`: 通过下标访问字符 (O(1))。
    *   `std::reverse(s.begin(), s.end());`: 反转字符串。
    *   **赋值:** `std::string s1 = "hello"; std::string s2 = s1;` (直接赋值，效率高)。
    *   **拼接/连接:**
        *   `s1 + s2`: 将 `s2` 拼接到 `s1` 后面，生成新字符串。
        *   `s += x;`: 将字符 `x` 或字符串 `x` 拼接到 `s` 后面。
            *   在字符串末尾添加字符 (`s += 'a';`): $O(1)$ (摊还)。
            *   在字符串末尾添加字符串 (`s += "abc";`): $O(added_{length})$。
            *   在字符串开头添加字符/字符串 (`s = 'a' + s;`): $O(original_{string_length})$ (因为需要移动现有元素)。
    *   **`s.substr(pos, len)` (取子串):** 从 `pos` 位置开始，截取 `len` 长度的子串。时间复杂度 $O(\text{len})$。如果 `len` 超出剩余长度，则取到字符串末尾。
    *   **其他函数 (不常用但了解):** `s.insert()`, `s.erase()`, `s.replace()`, `s.find()`, `s.compare()`。这些操作通常涉及内存移动，复杂度较高（最坏 $O(N)$）。
*   **输入/输出:**
    *   `std::cin >> s;`: 读取一个单词 (遇到空格、Tab、换行符停止)。
    *   `std::cout << s;`: 输出字符串。
    *   **`std::getline(std::cin, s);`:** 读取一整行 (直到遇到换行符)。它会读取空格，但不会读取换行符本身。
        *   **注意:** 在 `std::cin >> N;` 之后使用 `std::getline` 时，可能会读取到 `N` 后面的换行符而导致空字符串。解决方法是在 `std::cin >> N;` 后加上 `std::cin.ignore()` 或 `getchar()` 来消耗掉换行符。

#### 2.6.1. 练习：规范化药品名

*   **问题:** 输入 $N$ 个药品名（不含空格），将它们规范化：第一个字符如果是字母则大写，其余字符如果是字母则小写。
*   **思路:** 遍历字符串，根据规则进行大小写转换。
*   **字符大小写转换技巧:**
    *   大写转小写：`char_val += 32;` (基于ASCII码) 或 `tolower(char_val)`。
    *   小写转大写：`char_val -= 32;` (基于ASCII码) 或 `toupper(char_val)`。
    *   **判断字符类型 (C语言风格函数，需 `#include <cctype>` 或万能头文件):**
        *   `islower(char c)`: 判断是否为小写字母。
        *   `isupper(char c)`: 判断是否为大写字母。
        *   `isalpha(char c)`: 判断是否为字母。
*   **核心代码:**
    ```cpp
    #include <iostream>
    #include <string>
    #include <cctype> // for islower, isupper, tolower, toupper
    
    int main() {
        // using namespace std;
        int n;
        std::cin >> n;
        while (n--) {
            std::string s;
            std::cin >> s; // 药品名不含空格，直接cin即可
    
            // 处理第一个字符
            if (!s.empty() && std::isalpha(s[0])) { // 如果不为空且是字母
                s[0] = std::toupper(s[0]); // 转换为大写
            }
    
            // 处理后续字符
            for (int i = 1; i < s.size(); ++i) { // 从第二个字符开始遍历
                if (std::isalpha(s[i])) { // 如果是字母
                    s[i] = std::tolower(s[i]); // 转换为小写
                }
            }
            std::cout << s << std::endl;
        }
        return 0;
    }
    ```

### 2.7. `std::set` (集合)

*   **概念:** 存储**唯一且有序**的元素。底层通常由红黑树实现。
*   **头文件:** `#include <set>` (或万能头文件)。
*   **定义:** `std::set<DataType> s;` (例如: `std::set<int> s;`)
*   **特性:**
    *   **互异性:** 不允许重复元素。插入重复元素不会报错，但不会实际添加。
    *   **有序性:** 元素自动按升序排列。
*   **常用函数：**
    *   `s.insert(x)`: 插入元素 `x`。时间复杂度 $O(\log N)$。
    *   `s.erase(x)`: 删除元素 `x`。时间复杂度 $O(\log N)$。
    *   `s.count(x)`: 判断元素 `x` 是否存在 (返回0或1)。时间复杂度 $O(\log N)$。
    *   `s.find(x)`: 查找元素 `x`，返回指向该元素的迭代器；若不存在，返回 `s.end()`。时间复杂度 $O(\log N)$。
    *   `s.size()`: 返回元素个数。时间复杂度 $O(1)$。
    *   `s.empty()`: 判断是否为空。
*   **遍历 (无下标访问):** 必须使用迭代器。
    *   **方法一 (传统迭代器):**
        ```cpp
        for (auto it = s.begin(); it != s.end(); ++it) {
            std::cout << *it << " "; // 使用解引用运算符*访问元素
        }
        ```
    *   **方法二 (C++11 范围for循环):**
        ```cpp
        for (int x : s) { // 自动识别类型，并解引用
            std::cout << x << " ";
        }
        ```
*   **自定义排序 (降序):**
    *   `std::set<int, std::greater<int>> s_desc;` (使用 `std::greater` 仿函数实现降序排列)。

### 2.8. `std::deque` (双端队列)

*   **概念:** `std::deque` (发音 "deck") 是一个双向开口的队列，允许在两端进行高效的插入和删除操作。
*   **头文件:** `#include <deque>` (或万能头文件)。
*   **定义:** `std::deque<DataType> dq;` (例如: `std::deque<int> dq;`)
*   **常用函数 (时间复杂度均为 $O(1)$):**
    *   `dq.push_front(x)`: 在队首添加元素。
    *   `dq.push_back(x)`: 在队尾添加元素。
    *   `dq.pop_front()`: 移除队首元素。
    *   `dq.pop_back()`: 移除队尾元素。
    *   `dq.front()`: 获取队首元素。
    *   `dq.back()`: 获取队尾元素。
    *   `dq[i]`: 支持下标访问，时间复杂度 $O(1)$。
    *   `dq.size()`: 返回元素个数。时间复杂度 $O(1)$。
*   **与 `std::queue` 的比较:** `std::deque` 功能更强大（支持两端操作和下标访问），但通常占用更多内存（常数因子较大），如果仅需要队列功能，`std::queue` 更轻量。
*   **常用场景:** 0-1 BFS、滑动窗口最大/最小值问题。

### 2.9. `std::priority_queue` (优先队列/堆)

*   **概念:** `std::priority_queue` (通常简称 "PQ" 或 "堆") 是一种特殊的队列，它保证每次取出的元素是当前优先级最高的。默认情况下，它是一个**大根堆**（最大值优先）。底层通常是堆结构（二叉堆）。
*   **头文件:** `#include <queue>` (或万能头文件)。
*   **定义:**
    *   **默认 (大根堆):** `std::priority_queue<DataType> pq;` (例如: `std::priority_queue<int> pq;`)
    *   **小根堆:** `std::priority_queue<DataType, std::vector<DataType>, std::greater<DataType>> pq_min;` (例如: `std::priority_queue<int, std::vector<int>, std::greater<int>> pq_min;`)
*   **常用函数：**
    *   `pq.push(x)`: 插入元素 `x`。时间复杂度 $O(\log N)$。
    *   `pq.pop()`: 移除优先级最高的元素。时间复杂度 $O(\log N)$。
    *   `pq.top()`: 获取优先级最高的元素（不移除）。时间复杂度 $O(1)$。
    *   `pq.size()`: 返回元素个数。时间复杂度 $O(1)$。
    *   `pq.empty()`: 判断是否为空。
*   **自定义优先级:** 类似 `std::sort`，可以通过传入自定义的比较器 (仿函数) 来定义元素的优先级。
*   **常用场景:** 贪心算法 (如 Huffman 树)、最短路算法 (Dijkstra)、事件调度、中位数查找等。

#### 2.9.1. 练习：合并果子 (NOIP 2004 提高组第一题)

*   **问题:** 给定 $N$ 堆果子，每次选择两堆合并，合并代价为两堆果子的总和。求将所有果子合并成一堆的最小总代价。
*   **思路:** 每次合并都选择当前最小的两堆果子。这是一个经典的**哈夫曼树**问题，使用**小根堆**来模拟。
*   **核心代码:**
    ```cpp
    #include <iostream>
    #include <queue>      // For std::priority_queue
    #include <vector>     // For std::vector used in priority_queue definition
    #include <functional> // For std::greater
    
    int main() {
        // using namespace std;
        int n;
        std::cin >> n;
    
        // 定义小根堆：优先级队列存储int，底层用vector，比较器为std::greater<int>
        std::priority_queue<int, std::vector<int>, std::greater<int>> pq;
    
        for (int i = 0; i < n; ++i) {
            int x;
            std::cin >> x;
            pq.push(x); // 将所有果子堆的重量加入优先队列
        }
    
        long long total_cost = 0; // 总代价，可能较大，用long long
    
        // 只要堆中还有至少两堆果子，就继续合并
        while (pq.size() > 1) {
            int m1 = pq.top(); // 取出最小的果子堆
            pq.pop();
            int m2 = pq.top(); // 取出第二小的果子堆
            pq.pop();
    
            int combined_weight = m1 + m2;
            total_cost += combined_weight; // 累加合并代价
            pq.push(combined_weight);       // 将合并后的新堆放回优先队列
        }
    
        std::cout << total_cost << std::endl;
    
        return 0;
    }
    ```

### 2.10. `std::map` (映射/字典)

*   **概念:** `std::map` (通常简称 "map") 是一种键值对（Key-Value Pair）的容器，其中每个键（Key）都是唯一的，并且键值对按键的顺序进行排序。底层通常由红黑树实现。
*   **头文件:** `#include <map>` (或万能头文件)。
*   **定义:** `std::map<KeyType, ValueType> mp;` (例如: `std::map<std::string, int> mp;` 键为字符串，值为整数)。
*   **特性:**
    *   **唯一键:** 一个键只能映射一个值。
    *   **有序性:** 键值对按键的升序排列。
*   **常用函数 (大部分操作时间复杂度为 $O(\log N)$):**
    *   `mp.insert({key, value})` 或 `mp.insert(std::make_pair(key, value))`: 插入键值对。
    *   **通过下标访问/插入/修改 (常用):** `mp[key] = value;`
        *   如果 `key` 不存在，则插入新的键值对，值会默认初始化（如 `int` 为0）。
        *   如果 `key` 存在，则修改对应 `value`。
        *   时间复杂度 $O(\log N)$。
    *   `mp.erase(key)`: 根据键删除键值对。
    *   `mp.count(key)`: 判断键 `key` 是否存在 (返回0或1)。
    *   `mp.find(key)`: 查找键 `key`，返回指向键值对的迭代器；若不存在，返回 `mp.end()`。
    *   `mp.size()`: 返回键值对数量。时间复杂度 $O(1)$。
    *   `mp.empty()`: 判断是否为空。
*   **遍历:** 使用迭代器。
    *   **方法一 (传统迭代器):**
        ```cpp
        for (auto it = mp.begin(); it != mp.end(); ++it) {
            std::cout << it->first << ": " << it->second << std::endl; // it->first是键，it->second是值
        }
        ```
    *   **方法二 (C++17 结构化绑定):**
        ```cpp
        for (auto const& [key, val] : mp) {
            std::cout << key << ": " << val << std::endl;
        }
        ```
*   **Map 的优势:**
    *   键可以是任意类型（`int`, `string`, `char`, 甚至 `vector`, `pair` 等，只要可比较）。
    *   提供灵活的键到值的映射，相当于一个“字典”或“哈希表”（有序版本）。
*   **Map 的缺点:** 访问和修改操作的复杂度为 $O(\log N)$，不如数组的 $O(1)$。

### 2.11. `std::multiset` (多重集合)

*   **概念:** 类似于 `std::set`，但允许存储重复元素，且元素依然有序。
*   **头文件:** `#include <set>`。
*   **定义:** `std::multiset<DataType> ms;`
*   **`erase(x)` 注意:** `ms.erase(x)` 会删除所有值为 `x` 的元素。如果只想删除一个，需要先 `find()` 到该元素的迭代器，然后 `ms.erase(it)`。

### 2.12. `std::multimap` (多重映射)

*   **概念:** 类似于 `std::map`，但允许存储重复的键，即一个键可以映射多个值。
*   **头文件:** `#include <map>`。
*   **定义:** `std::multimap<KeyType, ValueType> mmp;`

### 2.13. `std::unordered_map` (无序映射)

*   **概念:** 类似于 `std::map`，但键是无序的。底层通常由哈希表实现。
*   **头文件:** `#include <unordered_map>`。
*   **时间复杂度:** 平均 $O(1)$，最坏 $O(N)$ (当哈希冲突严重时)。
*   **注意 (竞赛建议):** **初学者不建议在算法竞赛中使用 `std::unordered_map`。** 虽然平均性能更快，但在面对精心构造的测试数据时，哈希冲突可能导致其退化到 $O(N)$，从而造成超时 (TLE)。建议先熟练掌握 `std::map`，它在所有情况下都是稳定的 $O(\log N)$。

### 2.14. STL 嵌套使用

STL 容器可以互相嵌套，实现复杂的数据结构。

*   `std::vector<std::string>`: 字符串数组。
*   `std::map<int, std::vector<double>>`: 键是整数，值是双精度浮点数向量的映射。
*   `std::vector<std::vector<int>>` (二维数组)。
*   `std::map<std::string, std::string>`: 字符串到字符串的映射（如姓名到电话号码）。

只要能够通过编译，理论上都可以进行嵌套。

---

## 3. 总结

本视频详细讲解了算法竞赛中两大基石：时空复杂度和C++ STL。

*   **时空复杂度：** 理解 $O(N)$ 符号的含义，掌握常见的时间复杂度函数及其增长趋势，尤其要注意常数因子在分析中的省略。
*   **STL：**
    *   **核心容器:**
        *   `std::vector`: 动态数组，替代传统数组，功能强大。
        *   `std::string`: 字符串，替代 `char` 数组，操作更便捷。
        *   `std::queue`: 队列，常用于 BFS。
        *   `std::priority_queue` (堆): 优先队列，常用于贪心和 Dijkstra 算法。
        *   `std::set`: 唯一有序集合，查找、插入、删除 $O(\log N)$。
        *   `std::map`: 键值对映射，键唯一且有序，查找、插入、删除 $O(\log N)$。
    *   **核心算法:** `std::sort`: 高效排序，复杂度 $O(N \log N)$，支持自定义比较规则。
    *   **通用特性:** 许多容器都支持 `size()`、`empty()` 等函数，并可通过迭代器遍历。
    *   **性能权衡:** 了解不同容器的底层实现及其带来的时间复杂度（如 `map` 和 `set` 的 $O(\log N)$ vs. `vector` 的 $O(1)$ 访问）。

熟练掌握这些 STL 工具，将大大提升算法竞赛的解题效率和代码质量。

**练习题列表:**

1.  **反向输出数字**
2.  **矩阵转置**
3.  **规范化药品名**
4.  **合并果子**
