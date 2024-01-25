---
title: Occlusion Query
author: Yohiro
date: 2020-06-16
categories: []
tags: []
render_with_liquid: false
img_path: /assets/images/{}/
---

## 概述

最近需要利用 Occlusion Query 记录场景中可见物件的信息。为了验证方案的可行性，我决定在开启 Occlusion Cull 的情况下，从引擎的 View.PrimitiveVisibilityMap 中回读 PrimitiveIndex 来确定可见物件。

其间遇到两个问题，一个是同步，一个是 Occlusion Query 的历史帧带来的误差。

## Occlusion Query

通常的 Occlusion Query 的大致流程如下：

1. 创建一个 Query 用作请求查询
2. 禁止颜色写入，所有通道的 ColorMask 设为 false
3. 禁止深度写入
4. 通知 GPU 开始 Query，此时会重置可见像素的数量
5. 在一个 DepthOnly 的 Pass 中渲染场景中物体的包围盒做深度测试
6. 结束 Query，停止记录可见像素的数量
7. 开启颜色写入
8. 如有必要，也可开启深度写入
9. 获取 Query 的结果，即记录的可见像素的数量
10. 根据可见像素的数量判断该物体是否绘制

## 虚幻中的 Occlusion Query

官方文档[^OffcialDocument]

### 结构
以下代码基于 Unreal Engine 5.3.2 版本。

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

可以使用一个 down sample 的 depth target 去绘制 Occlusion 

缓存的 Occlusion 历史帧最多不超过 4 帧
```cpp
class FOcclusionQueryHelpers
{
public:
    enum
    {
        MaxBufferedOcclusionFrames = 4
    };

    // get the system-wide number of frames of buffered occlusion queries.
    static int32 GetNumBufferedFrames(ERHIFeatureLevel::Type FeatureLevel);
```

## 参考

- [chapter-29-efficient-occlusion-culling](https://developer.nvidia.com/gpugems/gpugems/part-v-performance-and-practicalities/chapter-29-efficient-occlusion-culling)
- [Castle Game Engine - Occlusion Culling](https://castle-engine.io/occlusion_culling?page=/occlusion_query)
- [Query Object](https://www.khronos.org/opengl/wiki/Query_Object#Occlusion_queries)
- [Chapter 6. Hardware Occlusion Queries Made Useful](https://developer.nvidia.com/gpugems/gpugems2/part-i-geometric-complexity/chapter-6-hardware-occlusion-queries-made-useful)
- [剔除：从软件到硬件](https://zhuanlan.zhihu.com/p/66407205)

[^OffcialDocument]:  [Visibility and Occlusion Culling](https://docs.unrealengine.com/5.3/en-US/visibility-and-occlusion-culling-in-unreal-engine/)