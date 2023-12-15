---
title: Pose Space Deformation
author: Yohiro
date: 2023-10-16
categories: [Unreal, Animation]
tags: [animation,deform,blendshape]
render_with_liquid: false
math: true
img_path: /assets/images/{}/
---
## 介绍

Pose Space Deformation（PSD） 是一种针对骨骼动画用于给予 mesh 形变的技术，这种叫法听起来比较学术化，在不同的 DCC 工具中，它的名称也有所不同。比如在 Maya 中被称作 Pose Deformer[^PoseDeformer], 在 Blender 中被叫做 Corrective Shape Keys[^CorrectiveShapeKeys]。

区别于动画曲线基于时域的插值和 Mesh 空间域的插值，PSD 是基于一系列预设的姿态进行匹配，然后在角色的姿态域内进行插值。在[之前的文章](https://blog.yohiro.cn/posts/blendShape-with-pose-wrangler/)中介绍了如何从 DCC 到引擎去应用，这一篇文将着重于原理[^Paper]。

## 径向基函数

## 参考

[^PoseDeformer]: [Pose space deformations (PSD)](https://help.autodesk.com/view/MAYAUL/2020/ENU/?guid=GUID-45D389D6-B8E4-4225-B27B-9927BB61C28D)
[^CorrectiveShapeKeys]: [矫正形态键（Corrective Shape Keys）](https://docs.blender.org/manual/zh-hans/3.5/addons/animation/corrective_shape_keys.html)
[^Paper]: [Pose Space Deformation: A Unified Approach to Shape Interpolation and Skeleton-Driven Deformation J. P. Lewis*, Matt Cordner, Nickson Fong](https://dl.acm.org/doi/pdf/10.1145/344779.344862)

[Pose Space Deformation——从实践到原理再到实践](https://zhuanlan.zhihu.com/p/456538362)
