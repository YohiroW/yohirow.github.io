---
layout: post
title: [CG]SMAA Integration In Unreal
author: Yohiro
tags:  UnrealEngine Graphics Rendering 
---

## 
反走样的算法有两个方向一种是通过采样多个像素来进行混合，另外一种是利用形态（主要是像素边缘）来进行混合。前者的代表是SSAA、MSAA，后者的代表是FXAA。
而SMAA是一种将二者结合起来的方法，

## 参考资料
- [SMAA的主要资料来源](https://www.iryoku.com/smaa)
- [Siggraph2011 各种AA算法](http://iryoku.com/aacourse/)