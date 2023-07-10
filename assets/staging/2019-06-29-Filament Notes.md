---
title: Filament notes
author: Yohiro
date: 2019-06-29
categories: [Rendering, graphics]
tags: [rendering, graphics, material, lighting]
math: true
img_path: /assets/images/Filament/
---

大概是篇图形渲染的学习笔记，原文档指路👉[**Filament文档**](https://google.github.io/filament/Filament.html)。

可以参考Filament的渲染为了更好地支持移动端，舍弃了哪些，从而结合Desktop的渲染方式一起看。

也可以搭配[【GAMES101-现代计算机图形学入门-闫令琪】 ](https://www.bilibili.com/video/BV1X7411F744/?share_source=copy_web&vd_source=7a4dacf2c6974d860175d6d297f6d566)食用，风味更佳。

# 原则

Filament是用于Android的渲染引擎，设计原则包含以下几个方面：
- 性能，关注实时渲染中移动设备的性能表现，主要目标为OpenGL ES3.x版本的GPU
- 质量，同时兼顾中低性能的GPU
- 易用，方便美术同学直观且快速地迭代资产，因此提供易理解地参数以及物理上合理的视觉效果
- 熟悉，该系统应尽可能使用物理单位，如以开尔文为单位地色温、以流明为单位的光照等
- 灵活，支持非真实感渲染

# PBR

选择采用PBR是因为它从艺术和生产效率的角度来看有好处，而且它能很好的兼容设计目标。

与传统模型相比，PBR是一种可以更准确地表示材质及其与光的交互方式的方法。PBR方法的核心是`材质和光照的分离`，可以创建在统一光照条件下看起来可信的资产。

# 概念

| 符号             | 定义            | 
|:----------------|:----------------|
| $v$             | 观察视角的单位向量 | 
| $l$             | 入射光线的单位向量 |
| $n$             | 表面法线的单位向量 |
| $h$             | 单位半角向量      |
| $f$             | BRDF            |
| $f_d$           | BRDF的漫反射项    |
| $f_r$           | BRDF的镜面反射项  |
| $\alpha$        | 粗糙度           |
| $\sigma$        | 漫反射率         |
| $\Omega$        | 球体区域         |
| $f_0$           | 入射法向的反射率  |
| $f_{90}$        | 掠射角的反射率    |
| $\chi^+(a)$     | 阶跃函数（a>0则为1，否则为0） |
| $n_{ior}$       | 界面折射率（IOR，Index of refraction） |
| $\left< n \cdot l \right>$  | [0, 1]的点积 |
| $\left< a \right>$  | [0, 1]的值 |

# 材质系统

> 详见👉[**Filament材质指南**](https://google.github.io/filament/Materials.html)以及[**材质属性**](https://google.github.io/filament/Material%20Properties.pdf)
{: .prompt-info }

## 标准模型

标准的材质模型通过BSDF（双向散射分布函数）来表达，BSDF有两个组成部分BRDF（双向反射分布函数）以及BTDF（双向透射函数）。
由于绝大多数材质对表面材质进行模拟，因而具有各项同性的标准材质模型会专注于BRDF，从而忽略或近似BTDF。

BRDF将标准材质的表面分为:
- 漫反射项 $f_d$
- 镜面反射项 $f_r$  

![](diagram_fr_fd.png)
_忽略了BTDF的BRDF模型中的$f_d$和$f_r$_

完整的表达为：

$$f(v,l)=f_d(v,l)+f_r(v,l)$$

## Specular BRDF

在Cook-Torrance的微表面模型中，Specular BRDF可描述为，

$$\begin{equation}
f_r(v,l) = \frac{D(h, \alpha) G(v, l, \alpha) F(v, h, f0)}{4 (n \cdot v)(n \cdot l)}
\end{equation}$$

在实时渲染领域常采用对D、G、F项的近似，[**这里**](http://graphicrants.blogspot.com/2013/08/specular-brdf-reference.html)提供了更多关于Specular BRDF的参考。

- **D**

    正态分布函数（NDF）是描述现实世界物体表面分布的一种方式，但在实时渲染领域常用的是Walter描述的GGX分布，GGX具有长衰减和短峰值的特点，GGX的分布函数如下：

    $$\begin{equation}
    D_{GGX}(h,\alpha) = \frac{\alpha^2}{\pi ( (n \cdot h)^2 (\alpha^2 - 1) + 1)^2}
    \end{equation}$$


    下面是来自UnrealEngine中的实现，其中a2是$\alpha^2$
    ```c
    // GGX / Trowbridge-Reitz
    // [Walter et al. 2007, "Microfacet models for refraction through rough surfaces"]
    float D_GGX( float a2, float NoH )
    {
        float d = ( NoH * a2 - NoH ) * NoH + 1;	// 2 mad
        return a2 / ( PI*d*d );					// 4 mul, 1 rcp
    }
    ```

    一个常见的优化手段是使用半精度的浮点数，即`half`类型进行计算。但这种优化方式需要改变原公式，因为公式展开中的$1-(n \cdot h)^2$项的精度问题：
    
    - 高光情况下，即当$(n \cdot h)^2$接近1时，该项会因为浮点数的差值计算问题被截断，导致结果为零。
    - $n \cdot h$本身在接近1时缺少足够的精度。
    
    解决方式是用叉积的展开式代换，

    $$\begin{equation}
    | a \times b |^2 = |a|^2 |b|^2 - (a \cdot b)^2
    \end{equation}$$

    由于$n$和$l$是单位向量，便有 $|n \times h|^2 = 1 - (n \cdot h)^2$ 。这样一来，我们便可以直接使用叉积来直接计算$1-(n \cdot h)^2$了，Filament中的实现如下
    ```c
    #define MEDIUMP_FLT_MAX    65504.0
    #define saturateMediump(x) min(x, MEDIUMP_FLT_MAX)

    float D_GGX(float roughness, float NoH, const vec3 n, const vec3 h) {
        vec3 NxH = cross(n, h);
        float a = NoH * roughness;
        float k = roughness / (dot(NxH, NxH) + a * a);
        float d = k * k * (1.0 / PI);
        return saturateMediump(d);
    }
    ```

- **G**

- **F**

### 法线分布函数

### 表面几何阴影

### 菲涅尔

## Diffuse BRDF

## 标准模型总结

## 提升BRDF

### 能量获取

### 能量损失

## 参量化

## 透明涂层模型

## 各向异性模型

## 次表面散射模型

## 布料模型

# 光照

## 单位

## 直接光照

## IBL

## 静态光照

## 遮挡

## 法线贴图

# 体积效果

# 反走样

# 图像管线

## 基于现实的相机

## 后处理

## 坐标系

# 附件
