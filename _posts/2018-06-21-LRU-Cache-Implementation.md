---
title: 实现一个LRU Cache
author: Yohiro
date: 2018-06-21
categories: [Programming]
tags: [engine, programming, optimization, algorithm, unrealengine]
img_path: /assets/images/LRU/
---

## 更新日志

2020-07-12 添加了UE4里的LRU实现的相关分析/页面格式整理

--- 

计算机系的同学应该对**LRU**(**Least Recently Used**，中译**最近最少使用**)并不陌生。在操作系统原理课程中，讨论虚拟内存换页算法一节，对LRU有所涉及。实际运用中，LRU也是一种通用的缓存置换策略，所以这里想展开谈谈，并提供一个简易的实现。

## 概念

首先，复习一下LRU的核心概念。

**LRU**
: 即`Least Recently Used(最近最少使用)`。是一种基于最近调度的算法，该类算法的核心思想来自LRU，包括多种变体如：`TLRU（感知时间的最近最少使用）`，`MRU（最近使用）`，`SLRU（分段LRU）`，`Clock-Pro`等。

**缓存**
: 缓存是用于减少处理器访问内存所需平均时间的部件。缓存能够起效，主要是因为程序运行时对内存的访问呈现`局部性（Locality）`特征。这种局部性既包括`空间局部性（Spatial Locality）`，也包括`时间局部性（Temporal Locality）`。有效地利用这种局部性，缓存可以达到极高的命中率。

## 分析

### 如何实现LRU Cache

既然LRU的核心理念是缓存页已满并且引用的缓存中不存在新页面时删除最近最少使用的一页，那么

### 使用怎样的数据结构

## 实现

```cpp
// We can use stl container list as a double
// ended queue to store the cache keys, with
// the descending time of reference from front
// to back and a set container to check presence
// of a key. But to fetch the address of the key
// in the list using find(), it takes O(N) time.
// This can be optimized by storing a reference
//     (iterator) to each key in a hash map.
#include <bits/stdc++.h>
using namespace std;
 
class LRUCache {
    // store keys of cache
    list<int> dq;
 
    // store references of key in cache
    unordered_map<int, list<int>::iterator> ma;
    int csize; // maximum capacity of cache
 
public:
    LRUCache(int);
    void refer(int);
    void display();
};
 
// Declare the size
LRUCache::LRUCache(int n) { csize = n; }
 
// Refers key x with in the LRU cache
void LRUCache::refer(int x)
{
    // not present in cache
    if (ma.find(x) == ma.end()) {
        // cache is full
        if (dq.size() == csize) {
            // delete least recently used element
            int last = dq.back();
 
            // Pops the last element
            dq.pop_back();
 
            // Erase the last
            ma.erase(last);
        }
    }
 
    // present in cache
    else
        dq.erase(ma[x]);
 
    // update reference
    dq.push_front(x);
    ma[x] = dq.begin();
}
 
// Function to display contents of cache
void LRUCache::display()
{
 
    // Iterate in the deque and print
    // all the elements in it
    for (auto it = dq.begin(); it != dq.end(); it++)
        cout << (*it) << " ";
 
    cout << endl;
}
 
// Driver Code
int main()
{
    LRUCache ca(4);
 
    ca.refer(1);
    ca.refer(2);
    ca.refer(3);
    ca.refer(1);
    ca.refer(4);
    ca.refer(5);
    ca.display();
 
    return 0;
}
```

## 示例
> 初始化时页面中均为空页
{: .prompt-info }

## 其他实现参考
这里拿出UE4中的实现来看一下（为什么是UE4？因为恰好最近在用XD）


## 扩展阅读

- [维基百科 - 缓存置换策略](https://en.wikipedia.org/wiki/Cache_replacement_policies)
- [一种低开销高性能的Buffer置换算法](https://www.vldb.org/conf/1994/P439.PDF)