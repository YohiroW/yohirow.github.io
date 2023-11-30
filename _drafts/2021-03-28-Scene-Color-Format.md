---
title: SceneColorFormat
author: Yohiro
date: 2021-03-28
categories: [Rendering, Graphics]
tags: [graphics, rendering, profile, unrealengine]
render_with_liquid: false
img_path: /assets/images/{}/
---

| SceneColorFormat          | FP16 | RGB111110 | RGBA1010102 | BGRA8888 |
|:--------------------------|:-----|:----------|:------------|:---------|
| Bandwidth(R/W mega beats) | 12   | 8         | 6           | 6        |

在 Adreno 文档的 [**FAQ**](https://developer.qualcomm.com/sites/default/files/docs/adreno-gpu/snapdragon-game-toolkit/gdg/gpu/faq.html#what-is-the-performance-of-1010102-vs-111110-formats) 里有这样一个问题：

> **What is the performance of 1010102 vs. 111110 formats?**
>
> Both formats will perform better than FP16.
> There is a hardware “fast path” for 1010102 which will allow it to perform slightly better than 111110.


[Game Developer Guides](https://developer.qualcomm.com/sites/default/files/docs/adreno-gpu/snapdragon-game-toolkit/gdg/gpu/best_practices_other.html#bandwidth-optimization)