---
title: DBSCAN 聚类算法
author: Yohiro
date: 2024-02-01
categories: []
tags: []
math: true
render_with_liquid: false
img_path: /assets/images/{}/
image:
  path: https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/DBSCAN-density-data.svg/1024px-DBSCAN-density-data.svg.png
---
## 介绍

DBSCAN (Density-based spatial clustering of applications with noise) 是一个基于密度的聚类算法：给定空间里的一个点的集合，该算法能把附近的点分成一组（有很多相邻点的点），并标记出位于低密度区域的局外点（最接近它的点也十分远）。

## 详细描述及参数

| 标识             | 含义                |
|:----------------|:--------------------|
| $D$             | 样本集               |
| $P_i$           | $D$ 中的各样本点      |
| $\epsilon$      | $P_i$ 的邻域距离阈值  |
| $minPts$        | $P_i$ 在 $\epsilon$ 范围内样本的数量 |

核心点
: 满足条件，在 $\epsilon$ 范围内，具有 $minPts$ 个样本的样本点 $P_i$，称作核心点

可达点
: 在`核心点` $\epsilon$ 范围内，且在样本点 $\epsilon$ 范围内的样本数量小于 $minPts$，称作可达点

局外点
: 非可达点，即不在核心点的 $\epsilon$ 范围内的样本点，称为局外点

![referenced from wikipedia](https://upload.wikimedia.org/wikipedia/commons/thumb/a/af/DBSCAN-Illustration.svg/1280px-DBSCAN-Illustration.svg.png)

上图中，$minPts$ = 4，点 A 和其他红色点是核心点，因为它们的 $\epsilon$ 邻域（图中红色圆圈）里包含最少 4 个点（包括自己），由于它们之间相互相可达，它们形成了一个聚类。点 B 和点 C 不是核心点，但它们可由 A 经其他核心点可达，所以也属于同一个聚类。点 N 是局外点，它既不是核心点，又不由其他点可达。

### 距离函数

## 算法

### 步骤

### 伪代码

```python
DBSCAN(D, eps, MinPts) {
   C = 0
   for each point P in dataset D {
      if P is visited
         continue next point
      mark P as visited
      NeighborPts = regionQuery(P, eps)
      if sizeof(NeighborPts) < MinPts
         mark P as NOISE
      else {
         C = next cluster
         expandCluster(P, NeighborPts, C, eps, MinPts)
      }
   }
}

expandCluster(P, NeighborPts, C, eps, MinPts) {
   add P to cluster C
   for each point P' in NeighborPts { 
      if P' is not visited {
         mark P' as visited
         NeighborPts' = regionQuery(P', eps)
         if sizeof(NeighborPts') >= MinPts
            NeighborPts = NeighborPts joined with NeighborPts'
      }
      if P' is not yet member of any cluster
         add P' to cluster C
   }
}

regionQuery(P, eps)
   return all points within P's eps-neighborhood (including P)
```

### 实现参考

这里的参考选择了 [SimpleDBSCAN](https://github.com/CallmeNezha/SimpleDBSCAN)，一个轻量的 header-only 的 C++ 实现。SimpleDBSCAN 的实现中借用了 kd 树来做复杂的样本划分，以加速大样本的查询。

核心实现如下，其中 V 相当于样本集 $D$，dim 为数据的维度，disfunc 为样本距离函数，一般是欧氏距离。函数 regionQuery 使用 kd 树获取邻域的样本点集。

```cpp
template<typename T, typename Float>
int DBSCAN<T, Float>::Run(
    TVector*                V
    , const uint            dim
    , const Float           eps
    , const uint            min
    , const DistanceFunc&   disfunc
) {

    // Validate
    if (V->size() < 1) return ERROR_TYPE::FAILED;
    if (dim < 1) return ERROR_TYPE::FAILED;
    if (min < 1) return ERROR_TYPE::FAILED;

    // initialization
    this->_datalen = (uint)V->size();
    this->_visited = std::vector<bool>(this->_datalen, false);
    this->_assigned = std::vector<bool>(this->_datalen, false);
    this->Clusters.clear();
    this->Noise.clear();
    this->_minpts = min;
    this->_data = V;
    this->_disfunc = disfunc;
    this->_epsilon = eps;
    this->_datadim = dim;

#if BRUTEFORCE
#else
this->buildKdtree(this->_data);
#endif // !BRUTEFORCE


    for (uint pid = 0; pid < this->_datalen; ++pid) {
        // Check if point forms a cluster
        this->_borderset.clear();
        if (!this->_visited[pid]) {
            this->_visited[pid] = true;

            // Outliner it maybe noise or on the border of one cluster.
            const std::vector<uint> neightbors = this->regionQuery(pid);
            if (neightbors.size() < this->_minpts) {
                continue;
            }
            else {
                uint cid = (uint)this->Clusters.size();
                this->Clusters.push_back(std::vector<uint>());
                // first blood
                this->addToBorderSet(pid);
                this->addToCluster(pid, cid);
                this->expandCluster(cid, neightbors);
            }
        }
    }

    for (uint pid = 0; pid < this->_datalen; ++pid) {
        if (!this->_assigned[pid]) {
            this->Noise.push_back(pid);
        }
    }

#if BRUTEFORCE
#else
    this->destroyKdtree();
#endif // !BRUTEFORCE
    
    return ERROR_TYPE::SUCCESS;

}
```

聚类的最终结果会返回到 DBSCAN 类的成员：

```cpp
std::vector<std::vector<uint>>  Clusters;
std::vector<uint>               Noise;
```

### 评估

当 $\epsilon$ 被设为非常大，且样本集数量比较庞大时，kd 树建树的时间消耗会非常大，因此 DBSCAN 不太适合样本分布比较平均的场合。


## 参考

- [DBSCAN](https://zh.wikipedia.org/wiki/DBSCAN)
- [基于密度的聚类算法（1）——DBSCAN详解](https://zhuanlan.zhihu.com/p/643338798)
- [常用聚类算法](https://zhuanlan.zhihu.com/p/104355127)
- [SimpleDBSCAN](https://github.com/CallmeNezha/SimpleDBSCAN)
- [OPTICS](https://zh.wikipedia.org/wiki/OPTICS%E7%AE%97%E6%B3%95)
