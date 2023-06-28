---
title: 色彩管线与色彩空间
author: Yohiro
date: 2021-10-14
categories: [UnrealEngine]
tags: [engine, unrealengine, colorspace, HDR]
render_with_liquid: false
math: true
img_path: /assets/images/ColorPipeline/
image:
  path: rtaImage (5).png
  alt: Basic Color Pipeline in UnrealEngine
---

在处理材质贴图、Sampler或RenderTarget时，经常会看到sRGB/Linear字样。颜色在渲染时是如何编码解码的？在不同的阶段是怎样的颜色类型？发生怎样的转换？这篇文章尝试回答这些问题。

## 概念

- `颜色空间（Color Space`）——生成红色、绿色、蓝色和白色的具体颜色。由于可以定义多个颜色空间，这会导致1,0,0（为例）在一个颜色空间中的颜色更为饱和，例如：`Rec709`、`Rec2020`、`sRGB`、`ACES 2065-1`等。
- `颜色编码（Color Encoding）`——颜色的数字呈现方式，以及该呈现方式所产生的光，例如：线性、sRGB、伽马、PQ（ST 2084）和多种供应商专用的日志编码。
- `伽马值（Gamma）`——一种非线性的颜色编码方式，主要用于对亮度值进行编码，使用的表达式为$Output=A\times{Input}^{Gamma}$，A通常使用常数1.0，Gamma是我们所称的“伽马校正”值。
- `色域（Gamut`）——可通过颜色空间、输出设备或特定图像在某一时间的颜色集所代表的颜色子集。
- `线性颜色空间（Linear Color Space）`——一种使用了线性颜色编码方式的颜色空间，它所表示的光照量与存储值成比例，因此该数值翻倍将会使亮度翻倍。
- `sRGB（sRGB`）——在计算机图像（和虚幻引擎）中，sRGB指的是一种特定的颜色空间和颜色编码方式。你可以使用线性sRGB，或者sRGB编码的sRGB。如果不澄清颜色空间或颜色编码方式的背景，该术语很可能产生混淆。

## 参考

- [颜色管线基础](https://udn.unrealengine.com/s/article/Color-Pipeline-Basics)