---
An Introduction to Algorithms: STL Usage and Time & Space Complexity
---

## 1. Time & Space Complexity

In competitive programming, time and space complexity are critical metrics for evaluating an algorithm's performance, with a stronger emphasis typically placed on time complexity.

### 1.1. Overview

*   **Time Complexity:** Describes the execution efficiency (running time) of an algorithm. The lower, the better.
*   **Space Complexity:** Describes the amount of memory an algorithm uses. In competitive programming, time complexity is usually the main challenge, and space constraints are generally less strict, but it still requires attention.

### 1.2. Time Complexity

#### 1.2.1. Definition and Notation

Time complexity describes the trend of an algorithm's execution time as the input data size $N$ changes. We use Big O notation, $O(f(N))$, to represent this.

**Common Time Complexity Functions (High School Math Functions):**

*   $O(1)$ (Constant time)
*   $O(\log N)$ (Logarithmic time; the base is usually unimportant, so $O(\log_2 N)$ or $O(\ln N)$ are simplified to $O(\log N)$)
*   $O(\sqrt{N})$ (Square root time)
*   $O(N)$ (Linear time)
*   $O(N \log N)$ (Linearithmic time)
*   $O(N^2)$ (Quadratic time)
*   $O(N^3)$ (Cubic time)
*   $O(2^N)$ (Exponential time)
*   $O(N!)$ (Factorial time)

**Function Properties:**

*   In competitive programming, the data size $N$ is typically non-negative ($N \ge 1$), so we only consider the function's behavior in the first quadrant.
*   In the first quadrant, the functions listed above are all increasing, meaning execution time grows as $N$ grows.
*   **Core Principle: Ignore constant factors.** For example, $O(2N)$ and $O(5N)$ are both considered $O(N)$. This is because Big O notation represents the growth trend, and constant factors do not affect the asymptotic behavior.
*   **The special nature of $O(1)$:** When the number of operations is constant (e.g., $A+B$), we use $O(1)$ to represent it.

#### 1.2.2. Time Complexity Analysis Examples

1.  **Finding the Minimum Value in an Array**
    *   **Problem:** Given an array $A$ of length $N$, find the minimum value.
    *   **Logic:** Traverse the array once, maintaining the current minimum value.
    *   **Data Range:** $N \le 200,000$.
    *   **Pseudocode Structure:**
        ```cpp
        const int MAXN = 200000 + 5; // Common practice to allocate a slightly larger array to prevent out-of-bounds access
        int a[MAXN]; // Or use vector<int> a;
        int n;
        // cin >> n; // Read N
        // Loop to read a[1]...a[N] (1-based indexing is recommended in competitive programming)
        
        int min_val = 2e9; // Initialize to positive infinity (2 * 10^9)
        for (int i = 1; i <= n; ++i) { // Loop N times
            // min_val = min(min_val, a[i]); // Each operation is constant time
            if (a[i] < min_val) {
                min_val = a[i];
            }
        }
        // cout << min_val;
        ```
    *   **Complexity Analysis:** The loop executes $N$ times. The operations inside the loop (comparison, assignment, increment) are all constant time. The total number of operations is approximately $C \times N$. According to the principle of ignoring constants, the time complexity is $O(N)$.

2.  **Greatest Common Divisor (GCD) - Euclidean Algorithm**
    *   **Problem:** Find the greatest common divisor of two positive integers $X$ and $Y$.
    *   **Algorithm Principle:** Based on $GCD(X, Y) = GCD(Y, X \pmod Y)$, with the base case $GCD(X, 0) = X$.
    *   **Example Code (Recursive):**
        ```cpp
        int gcd(int x, int y) {
            if (y == 0) {
                return x;
            }
            return gcd(y, x % y); // Recursive call
        }
        ```
    *   **Complexity Analysis:** In each recursive step, $Y$ decreases, and it is guaranteed to at least be halved (related to the reverse of the Fibonacci sequence). Therefore, the time complexity of this algorithm is $O(\log N)$, where $N$ is the larger of $X$ and $Y$. The base of the logarithm is not important here because $\log_a N = \frac{\log_b N}{\log_b a}$, meaning different bases differ only by a constant factor.

3.  **A Special Nested For Loop**
    *   **Problem:** Calculate the number of executions in the following nested loop.
    *   **Code Example:**
        ```cpp
        int n; // Assume n is already input
        long long c = 0; // Counter
        for (int i = 1; i <= n; ++i) {
            for (int j = i; j <= n; j += i) {
                c++; // Increment counter on each execution
            }
        }
        // cout << c; // Output the final count
        ```
    *   **Complexity Analysis:**
        *   The outer loop variable `i` goes from $1$ to $N$.
        *   The inner loop variable `j` starts at `i` and increments by `i` until it exceeds `N`.
        *   When `i=1`, `j` takes values $1, 2, \dots, N$, executing $N/1 = N$ times.
        *   When `i=2`, `j` takes values $2, 4, \dots, N'$ (up to $N$), executing $N/2$ times.
        *   When `i=3`, `j` takes values $3, 6, \dots, N''$, executing $N/3$ times.
        *   ...
        *   When `i=N`, `j` takes the value $N$, executing $N/N = 1$ time.
        *   The total number of executions is $N/1 + N/2 + N/3 + \dots + N/N = N \times (1 + 1/2 + 1/3 + \dots + 1/N)$.
        *   The part in the parentheses is the **harmonic series**, and its sum is approximately $\ln N$ (natural logarithm).
        *   Therefore, the total number of executions is approximately $N \ln N$. The time complexity is $O(N \log N)$.

### 1.3. Space Complexity

Space complexity measures the temporary storage space an algorithm occupies during its execution.

*   **Single variable:** $O(1)$ (constant space). For example, `int x;`.
*   **Array of length $N$:** $O(N)$ (linear space). For example, `int arr[N];`.
*   **2D array (N rows, M columns):** $O(N \times M)$.

Typically, the space limits in competitive programming are sufficient, unless the problem explicitly requires space optimization.

## 2. STL (Standard Template Library)

The STL is a built-in C++ library that provides a collection of powerful and highly optimized tools, including containers, algorithms, and iterators.

### 2.1. Introduction

*   **Advantages:** Eliminates the need to manually implement common data structures and algorithms. Using the STL is often more efficient and stable than custom implementations.
*   **Environment Setup:**
    *   **Headers:**
        *   `#include <stack>`: For `std::stack`
        *   `#include <queue>`: For `std::queue`
        *   `#include <vector>`: For `std::vector`
        *   `#include <algorithm>`: For `std::sort`, `std::reverse`, etc.
        *   `#include <string>`: For `std::string`
        *   `#include <set>`: For `std::set`, `std::multiset`
        *   `#include <map>`: For `std::map`, `std::multimap`
        *   `#include <deque>`: For `std::deque`
        *   `#include <functional>`: For comparators like `std::greater`
    *   **Namespace:** `using namespace std;` (Recommended in competitive programming to simplify code)
    *   **Universal Header (Common in Contests):** `#include <bits/stdc++.h>` (Includes almost all standard library headers for convenience)

### 2.2. `std::stack` (Stack)

*   **Concept:** A "Last-In, First-Out" (LIFO) container. Imagine a box with only one opening at the top. New elements are added to the top (push), pushing older elements down. Elements can only be removed from the top (pop), meaning the first element added is the last to be removed.
*   **Definition:** `std::stack<DataType> stk;` (e.g., `std::stack<int> stk;`)
*   **Common Functions (All are $O(1)$ time complexity):**
    *   `stk.push(x)`: Pushes element `x` onto the top of the stack.
    *   `stk.pop()`: Removes the top element.
    *   `stk.top()`: Returns a reference to the top element (without removing it).
    *   `stk.size()`: Returns the number of elements in the stack.
    *   `stk.empty()`: Checks if the stack is empty.
*   **Note:** In competitive programming, the functionality of `std::stack` can often be replaced by `std::vector`'s `push_back`, `pop_back`, and `back` operations, which can be even more flexible.

### 2.3. `std::queue` (Queue)

*   **Concept:** A "First-In, First-Out" (FIFO) container. Imagine a pipe open at both ends. Elements are added to one end (enqueue) and removed from the other (dequeue).
*   **Definition:** `std::queue<DataType> q;` (e.g., `std::queue<int> q;`)
*   **Common Functions (All are $O(1)$ time complexity):**
    *   `q.push(x)`: Adds element `x` to the back of the queue.
    *   `q.pop()`: Removes the front element.
    *   `q.front()`: Returns a reference to the front element.
    *   `q.back()`: Returns a reference to the back element.
    *   `q.size()`: Returns the number of elements in the queue.
    *   `q.empty()`: Checks if the queue is empty.
*   **Common Use Case:** Breadth-First Search (BFS) and other graph algorithms.

### 2.4. `std::vector` (Dynamic Array)

*   **Concept:** One of the most common and powerful containers in C++. It is an array that can dynamically change its size, offering functionality far beyond that of a standard array and can completely replace it.
*   **Definition:** `std::vector<DataType> name;` (e.g., `std::vector<int> a;`)
*   **Initialization and Sizing:**
    *   `std::vector<int> a;`: Defines an empty `vector`.
    *   `std::vector<int> a(N);`: Defines a `vector` of size `N`, with elements default-initialized (0 for int).
    *   `std::vector<int> a(N, initial_value);`: Defines a `vector` of size `N`, with all elements initialized to `initial_value`.
    *   **2D `vector` (equivalent to a 2D array):** `std::vector<std::vector<int>> matrix(N, std::vector<int>(M, 0));` (Defines an $N \times M$ matrix with all elements initialized to 0).
*   **Common Functions:**
    *   `a.push_back(x)`: Appends element `x` to the end. Amortized $O(1)$ time complexity (it is $O(N)$ when the vector needs to reallocate, but this happens infrequently).
    *   `a.pop_back()`: Removes the last element. $O(1)$ time complexity.
    *   `a.back()`: Returns a reference to the last element. $O(1)$ time complexity.
    *   `a.size()`: Returns the number of elements. $O(1)$ time complexity.
    *   `a[i]`: Accesses the element at index `i`. $O(1)$ time complexity.
    *   `a.begin()`: Returns an iterator (like a pointer) to the first element.
    *   `a.end()`: Returns an iterator to the position **after** the last element.
*   **`std::reverse` (Reversal):**
    *   `#include <algorithm>`
    *   `std::reverse(a.begin(), a.end());`: Reverses the entire `vector`.
    *   `std::reverse(a.begin() + L, a.begin() + R + 1);`: Reverses elements in the range `[L, R]` (following the left-closed, right-open principle).
*   **`std::vector` Advantages:**
    *   Dynamic size adjustment.
    *   Supports array-like access with an index.
    *   Compatible with STL algorithms (e.g., `sort`, `reverse`).
    *   Supports direct assignment: `vector_b = vector_a;` (not allowed for raw arrays).
*   **The `size_t` Trap:**
    *   `vector::size()` returns a `size_t` type (an unsigned integer).
    *   If a `vector` is empty, `a.size() - 1` will cause an unsigned integer underflow, resulting in a very large positive number, which can lead to out-of-bounds access or infinite loops.
    *   **Style to Avoid:** `for (size_t i = a.size() - 1; i >= 0; --i)`
    *   **Recommended Styles:**
        *   Use `std::reverse`.
        *   Use `for (int i = a.size() - 1; i >= 0; --i)` (This is safe as long as `a.size()` does not exceed the maximum value of `int`, which is usually the case).

#### 2.4.1. Exercise: Reverse Output of Numbers

*   **Problem:** Read a sequence of numbers, ending with 0 (0 is not output). Print the numbers in reverse order.
*   **Logic:** Use `std::vector` to store the numbers, then either reverse the vector or iterate through it backward to print.
*   **Core Code:**
    ```cpp
    #include <iostream>
    #include <vector>
    #include <algorithm> // for std::reverse
    
    int main() {
        // using namespace std; // Optional if using a universal header
        // ios_base::sync_with_stdio(false); cin.tie(NULL); // Optional I/O optimization
        std::vector<int> nums;
        int x;
        while (std::cin >> x && x != 0) { // Read numbers until 0
            nums.push_back(x);
        }
    
        // Method 1: Reverse the vector and print sequentially
        std::reverse(nums.begin(), nums.end());
        for (int i = 0; i < nums.size(); ++i) { // Start from 0 to avoid the size_t trap
            std::cout << nums[i];
            if (i < nums.size() - 1) {
                std::cout << " ";
            }
        }
        std::cout << std::endl;
    
        // Method 2: Iterate backward and print
        // for (int i = nums.size() - 1; i >= 0; --i) {
        //     std::cout << nums[i] << " ";
        // }
        // std::cout << std::endl;
    
        return 0;
    }
    ```

#### 2.4.2. Exercise: Matrix Transposition

*   **Problem:** Given an $N \times M$ matrix, output its transpose ($M \times N$).
*   **Logic:** Store the matrix in a 2D `std::vector` and then swap the order of iteration to print the transpose.
*   **Core Code:**
    ```cpp
    #include <iostream>
    #include <vector>
    
    int main() {
        // using namespace std;
        int n, m;
        std::cin >> n >> m;
    
        // Define and initialize an N x M matrix with default 0s
        std::vector<std::vector<int>> matrix(n, std::vector<int>(m, 0));
    
        // Read matrix elements
        for (int i = 0; i < n; ++i) {
            for (int j = 0; j < m; ++j) {
                std::cin >> matrix[i][j];
            }
        }
    
        // Output the transposed matrix (M x N)
        for (int j = 0; j < m; ++j) { // Iterate through columns first
            for (int i = 0; i < n; ++i) { // Then iterate through rows
                std::cout << matrix[i][j]; // matrix[row][col]
                if (i < n - 1) { // Not the last element in the current transposed row
                    std::cout << " ";
                }
            }
            std::cout << std::endl; // Newline after each transposed row
        }
    
        return 0;
    }
    ```

### 2.5. `std::sort` (Sorting Algorithm)

*   **Concept:** `std::sort` is a highly efficient sorting algorithm provided by the C++ standard library.
*   **Header:** `#include <algorithm>` (or the universal header).
*   **Basic Usage:**
    *   **Sorting a `std::vector`:** `std::sort(vec.begin(), vec.end());`
    *   **Sorting a raw array:** `std::sort(arr, arr + N);` (where `arr` is the array name and `N` is its length).
*   **Time Complexity:** $O(N \log N)$ (based on an optimized version of quicksort, introsort, or heapsort). It is much faster than $O(N^2)$ algorithms like bubble sort, selection sort, or insertion sort.
*   **Custom Comparison Rules (for descending order or more complex logic):**
    *   **Method 1: Lambda Expression (C++11+)**
        ```cpp
        // Sort in descending order
        std::sort(vec.begin(), vec.end(), [](int a, int b) {
            return a > b; // return true if a should come before b
        });
        ```
    *   **Method 2: Custom Comparison Function (Global)**
        ```cpp
        bool compare_desc(int a, int b) {
            return a > b; // Sort in descending order
        }
        std::sort(vec.begin(), vec.end(), compare_desc);
        ```
    *   **Method 3: Custom Comparator Object (Functor)**
        ```cpp
        struct MyComparator {
            bool operator()(int a, int b) const {
                // Example: sort by proximity to 3 (smaller absolute difference comes first)
                return std::abs(a - 3) < std::abs(b - 3);
            }
        };
        std::sort(vec.begin(), vec.end(), MyComparator());
        ```
    *   **`std::greater<DataType>()` (for descending order):**
        ```cpp
        #include <functional> // for std::greater
        std::sort(vec.begin(), vec.end(), std::greater<int>()); // Sort in descending order
        ```
*   **Iterator:**
    *   The `begin()` and `end()` methods of `std::vector` and `std::string` return iterators.
    *   An iterator can be thought of as a "smart pointer" to an element in a container.
    *   `vec.begin() + L` refers to an iterator offset by `L` positions from `vec.begin()`.
    *   The range for `std::sort` is **left-closed, right-open**, i.e., `[start_iterator, end_iterator)`.

### 2.6. `std::string` (String)

*   **Concept:** `std::string` is C++'s wrapper for character arrays (`char[]`), providing more advanced and convenient string manipulation. It can be seen as an enhanced version of `std::vector<char>`.
*   **Header:** `#include <string>` (or the universal header).
*   **Definition:** `std::string s;`
*   **Common Functions (most operations are similar to `std::vector`):**
    *   `s.size()`: String length (O(1)).
    *   `s[i]`: Access character by index (O(1)).
    *   `std::reverse(s.begin(), s.end());`: Reverses the string.
    *   **Assignment:** `std::string s1 = "hello"; std::string s2 = s1;` (Efficient direct assignment).
    *   **Concatenation:**
        *   `s1 + s2`: Creates a new string by appending `s2` to `s1`.
        *   `s += x;`: Appends a character `x` or string `x` to `s`.
            *   Appending a character (`s += 'a';`): Amortized $O(1)$.
            *   Appending a string (`s += "abc";`): $O(\text{added\_length})$.
            *   Prepending (`s = 'a' + s;`): $O(\text{original\_string\_length})$ (requires moving existing elements).
    *   **`s.substr(pos, len)` (Get Substring):** Extracts a substring of length `len` starting at position `pos`. Time complexity: $O(\text{len})$. If `len` exceeds the remaining length, it extracts until the end of the string.
    *   **Other Functions (less common but good to know):** `s.insert()`, `s.erase()`, `s.replace()`, `s.find()`, `s.compare()`. These often involve memory movement and can have higher complexity (worst case $O(N)$).
*   **Input/Output:**
    *   `std::cin >> s;`: Reads a single word (stops at whitespace, tab, or newline).
    *   `std::cout << s;`: Prints the string.
    *   **`std::getline(std::cin, s);`:** Reads an entire line (until a newline character). It reads spaces but discards the newline character itself.
        *   **Note:** When using `std::getline` after `std::cin >> N;`, you might accidentally read the newline character left behind by `cin`. To fix this, add `std::cin.ignore()` or `getchar()` after `std::cin >> N;` to consume the newline.

#### 2.6.1. Exercise: Normalize Drug Names

*   **Problem:** Given $N$ drug names (without spaces), normalize them: if the first character is a letter, capitalize it; all other letters should be lowercase.
*   **Logic:** Iterate through the string and apply case conversion rules.
*   **Character Case Conversion Tips:**
    *   Uppercase to lowercase: `char_val += 32;` (ASCII-based) or `tolower(char_val)`.
    *   Lowercase to uppercase: `char_val -= 32;` (ASCII-based) or `toupper(char_val)`.
    *   **Character Type Checking (C-style functions, require `#include <cctype>` or universal header):**
        *   `islower(char c)`: Checks if `c` is a lowercase letter.
        *   `isupper(char c)`: Checks if `c` is an uppercase letter.
        *   `isalpha(char c)`: Checks if `c` is a letter.
*   **Core Code:**
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
            std::cin >> s; // Drug names have no spaces, so cin is fine
    
            // Process the first character
            if (!s.empty() && std::isalpha(s[0])) { // If not empty and is a letter
                s[0] = std::toupper(s[0]); // Convert to uppercase
            }
    
            // Process subsequent characters
            for (int i = 1; i < s.size(); ++i) { // Start from the second character
                if (std::isalpha(s[i])) { // If it's a letter
                    s[i] = std::tolower(s[i]); // Convert to lowercase
                }
            }
            std::cout << s << std::endl;
        }
        return 0;
    }
    ```

### 2.7. `std::set` (Set)

*   **Concept:** Stores **unique and sorted** elements. It is typically implemented using a red-black tree.
*   **Header:** `#include <set>` (or the universal header).
*   **Definition:** `std::set<DataType> s;` (e.g., `std::set<int> s;`)
*   **Properties:**
    *   **Uniqueness:** Does not allow duplicate elements. Inserting a duplicate is ignored without an error.
    *   **Sorted:** Elements are automatically kept in ascending order.
*   **Common Functions:**
    *   `s.insert(x)`: Inserts element `x`. Time complexity $O(\log N)$.
    *   `s.erase(x)`: Deletes element `x`. Time complexity $O(\log N)$.
    *   `s.count(x)`: Checks if element `x` exists (returns 0 or 1). Time complexity $O(\log N)$.
    *   `s.find(x)`: Finds element `x` and returns an iterator to it; returns `s.end()` if not found. Time complexity $O(\log N)$.
    *   `s.size()`: Returns the number of elements. Time complexity $O(1)$.
    *   `s.empty()`: Checks if the set is empty.
*   **Traversal (No Index Access):** Must use iterators.
    *   **Method 1 (Traditional Iterator):**
        ```cpp
        for (auto it = s.begin(); it != s.end(); ++it) {
            std::cout << *it << " "; // Use the dereference operator * to access the element
        }
        ```
    *   **Method 2 (C++11 Range-based for loop):**
        ```cpp
        for (int x : s) { // Automatically infers type and dereferences
            std::cout << x << " ";
        }
        ```
*   **Custom Sorting (Descending):**
    *   `std::set<int, std::greater<int>> s_desc;` (Uses the `std::greater` functor to achieve descending order).

### 2.8. `std::deque` (Double-Ended Queue)

*   **Concept:** `std::deque` (pronounced "deck") is a double-ended queue that allows for efficient insertions and deletions at both its front and back.
*   **Header:** `#include <deque>` (or the universal header).
*   **Definition:** `std::deque<DataType> dq;` (e.g., `std::deque<int> dq;`)
*   **Common Functions (All are $O(1)$ time complexity):**
    *   `dq.push_front(x)`: Adds an element to the front.
    *   `dq.push_back(x)`: Adds an element to the back.
    *   `dq.pop_front()`: Removes the front element.
    *   `dq.pop_back()`: Removes the back element.
    *   `dq.front()`: Accesses the front element.
    *   `dq.back()`: Accesses the back element.
    *   `dq[i]`: Supports index-based access in $O(1)$ time.
    *   `dq.size()`: Returns the number of elements in $O(1)$ time.
*   **Comparison with `std::queue`:** `std::deque` is more powerful (supports front/back operations and indexed access) but typically uses more memory (larger constant factor). If you only need FIFO functionality, `std::queue` is more lightweight.
*   **Common Use Cases:** 0-1 BFS, sliding window maximum/minimum problems.

### 2.9. `std::priority_queue` (Priority Queue / Heap)

*   **Concept:** `std::priority_queue` (often called "PQ" or "heap") is a special queue that ensures the element you retrieve is always the one with the highest priority. By default, it is a **max-heap** (largest value has the highest priority). It is typically implemented with a binary heap.
*   **Header:** `#include <queue>` (or the universal header).
*   **Definition:**
    *   **Default (Max-heap):** `std::priority_queue<DataType> pq;` (e.g., `std::priority_queue<int> pq;`)
    *   **Min-heap:** `std::priority_queue<DataType, std::vector<DataType>, std::greater<DataType>> pq_min;` (e.g., `std::priority_queue<int, std::vector<int>, std::greater<int>> pq_min;`)
*   **Common Functions:**
    *   `pq.push(x)`: Inserts element `x`. Time complexity $O(\log N)$.
    *   `pq.pop()`: Removes the highest-priority element. Time complexity $O(\log N)$.
    *   `pq.top()`: Accesses the highest-priority element (without removing it). Time complexity $O(1)$.
    *   `pq.size()`: Returns the number of elements. Time complexity $O(1)$.
    *   `pq.empty()`: Checks if the queue is empty.
*   **Custom Priority:** Similar to `std::sort`, you can define element priority by passing a custom comparator (functor).
*   **Common Use Cases:** Greedy algorithms (like Huffman coding), shortest path algorithms (Dijkstra's), event scheduling, finding medians, etc.

#### 2.9.1. Exercise: Merge Fruit (NOIP 2004 Advanced Group, Problem 1)

*   **Problem:** Given $N$ piles of fruit, you can merge two piles at a time. The cost of a merge is the sum of the number of fruits in the two piles. Find the minimum total cost to merge all fruits into a single pile.
*   **Logic:** At each step, merge the two smallest piles. This is a classic **Huffman tree** problem, which can be simulated using a **min-heap**.
*   **Core Code:**
    ```cpp
    #include <iostream>
    #include <queue>      // For std::priority_queue
    #include <vector>     // For std::vector used in priority_queue definition
    #include <functional> // For std::greater
    
    int main() {
        // using namespace std;
        int n;
        std::cin >> n;
    
        // Define a min-heap: priority_queue storing int, using vector as the underlying container,
        // and std::greater<int> as the comparator.
        std::priority_queue<int, std::vector<int>, std::greater<int>> pq;
    
        for (int i = 0; i < n; ++i) {
            int x;
            std::cin >> x;
            pq.push(x); // Add the weight of each fruit pile to the priority queue
        }
    
        long long total_cost = 0; // Total cost can be large, use long long
    
        // Continue merging as long as there are at least two piles
        while (pq.size() > 1) {
            int m1 = pq.top(); // Get the smallest pile
            pq.pop();
            int m2 = pq.top(); // Get the second smallest pile
            pq.pop();
    
            int combined_weight = m1 + m2;
            total_cost += combined_weight; // Add the cost of this merge
            pq.push(combined_weight);      // Push the new merged pile back into the priority queue
        }
    
        std::cout << total_cost << std::endl;
    
        return 0;
    }
    ```

### 2.10. `std::map` (Map / Dictionary)

*   **Concept:** `std::map` is a container of Key-Value pairs, where each key is unique, and the pairs are sorted by key. It is typically implemented using a red-black tree.
*   **Header:** `#include <map>` (or the universal header).
*   **Definition:** `std::map<KeyType, ValueType> mp;` (e.g., `std::map<std::string, int> mp;` where keys are strings and values are integers).
*   **Properties:**
    *   **Unique Keys:** A key can map to only one value.
    *   **Sorted:** Key-value pairs are sorted in ascending order of their keys.
*   **Common Functions (most operations have $O(\log N)$ time complexity):**
    *   `mp.insert({key, value})` or `mp.insert(std::make_pair(key, value))`: Inserts a key-value pair.
    *   **Access/Insert/Modify with Subscript (Common):** `mp[key] = value;`
        *   If `key` does not exist, a new key-value pair is inserted, and the value is default-initialized (e.g., 0 for `int`).
        *   If `key` exists, the corresponding `value` is updated.
        *   Time complexity is $O(\log N)$.
    *   `mp.erase(key)`: Deletes the key-value pair by key.
    *   `mp.count(key)`: Checks if a `key` exists (returns 0 or 1).
    *   `mp.find(key)`: Finds a `key` and returns an iterator to the pair; returns `mp.end()` if not found.
    *   `mp.size()`: Returns the number of key-value pairs. Time complexity $O(1)$.
    *   `mp.empty()`: Checks if the map is empty.
*   **Traversal:** Use iterators.
    *   **Method 1 (Traditional Iterator):**
        ```cpp
        for (auto it = mp.begin(); it != mp.end(); ++it) {
            std::cout << it->first << ": " << it->second << std::endl; // it->first is the key, it->second is the value
        }
        ```
    *   **Method 2 (C++17 Structured Binding):**
        ```cpp
        for (auto const& [key, val] : mp) {
            std::cout << key << ": " << val << std::endl;
        }
        ```
*   **`map` Advantages:**
    *   Keys can be of almost any type (`int`, `string`, `char`, even `vector` or `pair`, as long as they are comparable).
    *   Provides a flexible key-to-value mapping, acting like a "dictionary" or an ordered "hash table".
*   **`map` Disadvantage:** Access and modification operations are $O(\log N)$, which is slower than an array's $O(1)$.

### 2.11. `std::multiset` (Multiset)

*   **Concept:** Similar to `std::set`, but allows duplicate elements. The elements are still kept in sorted order.
*   **Header:** `#include <set>`.
*   **Definition:** `std::multiset<DataType> ms;`
*   **Note on `erase(x)`:** `ms.erase(x)` will remove **all** elements with the value `x`. To remove only one, you must first `find()` an iterator to the element and then call `ms.erase(it)`.

### 2.12. `std::multimap` (Multimap)

*   **Concept:** Similar to `std::map`, but allows duplicate keys, meaning one key can map to multiple values.
*   **Header:** `#include <map>`.
*   **Definition:** `std::multimap<KeyType, ValueType> mmp;`

### 2.13. `std::unordered_map` (Unordered Map)

*   **Concept:** Similar to `std::map`, but the keys are not sorted. It is typically implemented using a hash table.
*   **Header:** `#include <unordered_map>`.
*   **Time Complexity:** Average case $O(1)$, worst case $O(N)$ (when hash collisions are severe).
*   **Competitive Programming Advice:** **Beginners are advised not to use `std::unordered_map` in contests.** Although its average performance is faster, carefully crafted test data can cause hash collisions that degrade its performance to $O(N)$, leading to a Time Limit Exceeded (TLE) verdict. It's better to master `std::map` first, as its $O(\log N)$ performance is guaranteed in all cases.

### 2.14. Nested STL Usage

STL containers can be nested within each other to create complex data structures.

*   `std::vector<std::string>`: An array of strings.
*   `std::map<int, std::vector<double>>`: A map where keys are integers and values are vectors of doubles.
*   `std::vector<std::vector<int>>` (A 2D array).
*   `std::map<std::string, std::string>`: A map from a string to another string (e.g., name to phone number).

As long as the code compiles, nesting is theoretically possible.

---

## 3. Summary

This guide has covered two fundamental pillars of competitive programming: time/space complexity and the C++ STL.

*   **Time & Space Complexity:** Understand the meaning of Big O notation and master the common time complexity functions and their growth rates. Remember to ignore constant factors in analysis.
*   **STL:**
    *   **Core Containers:**
        *   `std::vector`: A powerful dynamic array that should be used in place of traditional arrays.
        *   `std::string`: A convenient string class to replace `char` arrays.
        *   `std::queue`: A queue, commonly used for BFS.
        *   `std::priority_queue` (heap): A priority queue, often used in greedy and Dijkstra's algorithms.
        *   `std::set`: A unique, sorted collection with $O(\log N)$ for find, insert, and delete.
        *   `std::map`: A key-value mapping with unique, sorted keys and $O(\log N)$ for find, insert, and delete.
    *   **Core Algorithm:** `std::sort`: An efficient sorting algorithm with $O(N \log N)$ complexity that supports custom comparison rules.
    *   **Common Features:** Many containers support functions like `size()` and `empty()` and can be traversed with iterators.
    *   **Performance Trade-offs:** Be aware of the underlying implementations and their time complexities (e.g., $O(\log N)$ for `map`/`set` vs. $O(1)$ access for `vector`).

Mastering these STL tools will significantly improve your problem-solving efficiency and code quality in competitive programming. programming.