---
layout: post
title: [UE] UOD Groom Notes
author: Yohiro
categories: Rendering, Shading, Material
banner:
  image: https://bit.ly/3xTmdUP
  opacity: 0.618
  background: "#000"
  height: "100vh"
  min_height: "38vh"
  heading_style: "font-size: 4.25em; font-weight: bold; text-decoration: underline"
  subheading_style: "color: gold"
tags: Groom UENotes
sidebar: []
---

# UOD Groom Notes
## Control Vertex
  - **Uniform CV** 
     <br> 质地均一， 卷发不宜
  - **短发/长发** 
  - **数目** 
    80~100 影视 Downgrade to 60~ in Game，长直发可在30以下
## Hair strands
  - 5W in engine
  - 0.008cm
  - 碎发 0.007~ 0.0065
  - Density* 0.5f -> Width* 2.0f， 游戏中实时使用进行downgrade
## Alembic
  - Guide Cache导出
		  <br> *可参考 https://docs.unrealengine.com/5.0/zh-CN/using-alembic-for-grooms-in-unreal-engine/*
  - Guides weight
		<br>Guides 主要用于物理模拟，对于眉毛之类的可以不导出到groom
    <br>DCC中的物理Cache？
    <br>GuideCache从第0帧开始（Sequence
## Creation
- 毛囊分布、长度（裁剪、LOD
  <br>避免同一个点生成过多毛发
- GroomBuild.cpp
- 0.06~0.12 mm
- AA
    ![](images\GroomNotes\AA.png)
- Stable Rasterization
- Multiple groom group 
- R.HairStrands.ViewTransmittancePass Soften
  ![](images\GroomNotes\SoftRasterization.png)
- Rasterizing via CS
- Harden hair
- Lighting & Shadow
  ![](images\GroomNotes\LighingNShadow.png)
- Depth & Voxel（Skylight involved）
	<br>[Recommanded] Voxel for transmittance, deep shadow for shadow casting
- Deep shadow option attached on light
- Voxel perf better for multiple lights
- Jitter噪点
- ![](images\GroomNotes\Lighting.png)
  
## Debug
  - r.ShaderPrintEnable - > r.hairstrands.debugmode 8

