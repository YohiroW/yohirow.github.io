---
title: Occlusion Query
author: Yohiro
date: 2020-06-16
categories: []
tags: []
render_with_liquid: false
img_path: /assets/images/OcclusionQuery/
---

## 概述

最近需要利用 Occlusion Query 记录场景中可见物件的信息。为了验证方案的可行性，我决定先在开启 Occlusion Cull 的情况下，从引擎的 View.PrimitiveVisibilityMap 中回读 PrimitiveIndex 来确定可见物件。

其间遇到两个问题，一个是同步，一个是 Occlusion Query 的历史帧带来的误差。

## Occlusion Query

一个简单的 Occlusion Query 的大致流程如下：

1. 创建一个 Query 用作请求查询
2. 禁止颜色写入，所有通道的 ColorMask 设为 false
3. 禁止深度写入
4. 通知 GPU 开始 Query，此时会重置可见像素的数量
5. 在一个 Depth Only 的 Pass 中渲染场景中物体的包围盒做深度测试
6. 结束 Query，停止记录可见像素的数量
7. 开启颜色写入（如有必要，也可开启深度写入）
8. 获取 Query 的结果，即记录的可见像素的数量
9. 根据可见像素的数量判断该物体是否绘制

### 问题

上述的 Occlusion Query 带来了两个问题，分别是 CPU 与 GPU 的同步以及遮挡细节带来的精度问题。

#### 同步

CPU 和 GPU 的任务之间并不是同步进行的。比如，当 CPU 给 GPU 创建一个渲染指令时，CPU 不会在原地等待 GPU 的任务执行完成，而是继续去执行 CPU 上的其他任务，创建的渲染指令会被驱动程序发送给 GPU 的 CommandQueue，当这些命令执行完毕，便完成渲染。

但 Occlusion Query 的流程的问题在于，CPU 需要回读 GPU 端渲染包围盒的结果后才知道是否可见，从而进行裁剪。这意味者 CPU 必须在某一刻等待 GPU 完成查询，这个过程破坏了二者的并行性，从而大大降低了渲染效率。

#### 遮挡

另一个带来的问题是使用包围盒来确认可见性带来的不精确的遮挡，考虑下图的这种情况：
![Occlusion Issue](fig01.jpg)

树的包围盒遮挡了车的包围盒，但是对于实际的像素而言，车并没有完全被树所遮挡。

一种解决方式是将一些几何体作为 Occluder 单独渲染，不经过遮挡剔除。渲染完成后，再针对较小的几何体做遮挡剔除。

## 虚幻中的 Occlusion Query

官方文档[^OffcialDocument]

以下代码基于 Unreal Engine 5.3.2 版本。

### 大致实现

#### 渲染前

FGPUOcclusionPacket::OcclusionCullPrimitive 中实现了具体的行为：

- 首先判断是否需要依据包围盒去判断是否需要做 Occlusion Cull

- 针对需要做 Occlusion Cull 的几何体，根据 PrimitiveOcclusionHistory 进一步进行划分为：

    Grouped Occlusion
    : 对上一帧中被遮挡的，进行粗略的剔除

    Individual Occlusion
    : 没有缓存结果的需要使用精确的遮挡做剔除

    在一个 Vertex Buffer 中 Grouped Occlusion 最大的 Batch 数不超过 16，Individual Occlusion 只有 1：

```cpp
/** 
 * Initialization constructor. 
 * @param InView - copy to init with
 */
FViewInfo::FViewInfo(const FSceneView* InView)
    :   FSceneView(*InView)
    ,   IndividualOcclusionQueries((FSceneViewState*)InView->State,1)
    ,   GroupedOcclusionQueries((FSceneViewState*)InView->State,FOcclusionQueryBatcher::OccludedPrimitiveQueryBatchSize)
    ,   CustomVisibilityQuery(nullptr)
{
    Init();
}
```

每个 FPrimitiveOcclusionHistory 都持有一个相对应的 FPrimitiveComponentId，并记录了其过去几帧（不大于 4）的 Query 结果。

- 更新 PrimitiveOcclusionHistory

    刷新 PrimitiveOcclusionHistory 的上次更新时间（LastConsideredTime），上次更新帧数以及上帧是否被遮挡等信息。其中`上次更新时间`是 FSceneViewState::TrimOcclusionHistory 清除旧 Queries 的重要依据。

#### 渲染中

渲染时的入口可以查看 DeferredShadingRenderer::RenderOcclusion。首先看是否 Depth Target 是否需要 down sample，然后对每个 View 去做 Occlusion Query，将一段时间内没有做 Occlusion Cull 的几何体进行清除。需要注意的一点是，不光 BasePass 其他的渲染特性，如 Shadow，Light，Planar Reflection 等也要在这里创建 Query。

然后合批后在 BeginOcclusionTests 中执行绘制，在 FenceOcclusionTests 中执行同步。

### 部分细节

1. 使用 down sample 的 depth target 去绘制 Occlusion

使用 `r.DownsampledOcclusionQueries` 来开启/关闭使用半分辨率的 Depth Target 来渲染包围盒。

```cpp
const auto RenderOcclusionLambda = [&]()
{
    RDG_GPU_STAT_SCOPE(GraphBuilder, RenderOcclusion);

    const int32 AsyncComputeMode = CVarSceneDepthHZBAsyncCompute.GetValueOnRenderThread();
    bool bAsyncCompute = AsyncComputeMode != 0;

    FBuildHZBAsyncComputeParams AsyncComputeParams = {};
    if (AsyncComputeMode == 2)
    {
        AsyncComputeParams.Prerequisite = ComputeLightGridOutput.CompactLinksPass;
    }

    RenderOcclusion(GraphBuilder, SceneTextures, bIsOcclusionTesting,
        bAsyncCompute ? &AsyncComputeParams : nullptr);

    CompositionLighting.ProcessAfterOcclusion(GraphBuilder);
};
```

2. 缓存的 Occlusion 历史帧最多不超过 4 帧

```cpp
//
// ScenePrivate.h
//
/** The occlusion query which contains the primitive's pending occlusion results. */
FRHIRenderQuery* PendingOcclusionQuery[FOcclusionQueryHelpers::MaxBufferedOcclusionFrames];
uint32 PendingOcclusionQueryFrames[FOcclusionQueryHelpers::MaxBufferedOcclusionFrames]; 

//
// ScenePrivateBase.h
//
enum
{
    MaxBufferedOcclusionFrames = 4
};

// get the system-wide number of frames of buffered occlusion queries.
static int32 GetNumBufferedFrames(ERHIFeatureLevel::Type FeatureLevel);
```

3. 对应正交投影的视口，会丢弃几何体的 AABB 使用圆来作为几何体在场景中的代理。

## 参考

- [chapter-29-efficient-occlusion-culling](https://developer.nvidia.com/gpugems/gpugems/part-v-performance-and-practicalities/chapter-29-efficient-occlusion-culling)
- [Castle Game Engine - Occlusion Culling](https://castle-engine.io/occlusion_culling?page=/occlusion_query)
- [Query Object](https://www.khronos.org/opengl/wiki/Query_Object#Occlusion_queries)
- [Chapter 6. Hardware Occlusion Queries Made Useful](https://developer.nvidia.com/gpugems/gpugems2/part-i-geometric-complexity/chapter-6-hardware-occlusion-queries-made-useful)
- [剔除：从软件到硬件](https://zhuanlan.zhihu.com/p/66407205)

[^OffcialDocument]:  [Visibility and Occlusion Culling](https://docs.unrealengine.com/5.3/en-US/visibility-and-occlusion-culling-in-unreal-engine/)