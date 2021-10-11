---
layout: post
title: [UE4] RHI层解构
subheading: Render Hardware Interface
author: Yohiro
categories: UE4
banner:
  image: https://bit.ly/3xTmdUP
  opacity: 0.618
  background: "#000"
  height: "100vh"
  min_height: "38vh"
  heading_style: "font-size: 4.25em; font-weight: bold; text-decoration: underline"
  subheading_style: "color: gold"
tags: UE4 Rendering RHI Framework
sidebar: []
---

# [UE4] RHI层解构

一直以来，总觉得自己对于结构这种东西有种奇妙的纠结，每每想实现一个功能点，总是要纠结很久。所以最近想把UE4里一些感兴趣的结构捋一捋。之所以从RHI开始，是因为最近在学Vulkan，想看看一些开源的实现。虽然大学的时候有写过OpenGL的渲染器，但是那东西在现在的我看来，毫无结构可言，更何况NextGenAPI确实和上一代有着巨大的区别。

RHI，即Rendering Hardware Interface。实际上是为了在不用平台上运行时提供统一的上层图形接口。RHI的职责是根据Scene传来的数据组装成为抽象的命令，即FRHICommand，然后将其下发至当前绑定的FDynamicRHI，这里就成为了我们熟悉的DX12,OpenGL或者Vulkan这类图形接口了。官方文档中说RHI就像是图形渲染的前端,除了组装命令外，他还需要多线程渲染的同步。

![](https://docs.unrealengine.com/4.27/Images/ProgrammingAndScripting/Rendering/ParallelRendering/Parallel_Rendering_00.webp)

RHI线程可以在Runtime利用GM命令r.RHIThread.Enable启用，启用后如果开启stat unit可以在屏幕上看到RHI线程的耗时。
```cpp
static FAutoConsoleCommand CVarRHIThreadEnable(
	TEXT("r.RHIThread.Enable"),
	TEXT("Enables/disabled the RHI Thread and determine if the RHI work runs on a dedicated thread or not.\n"),	
	FConsoleCommandWithArgsDelegate::CreateStatic(&HandleRHIThreadEnableChanged)
	);

  Usage: r.RHIThread.Enable 0=off,  1=dedicated thread,  2=task threads;
```
开启后，FRHIThread像UE里每一个线程一样也会指定线程亲和性(Affinity)，直白点说就是我们可以指定我们更倾向于让这个线程运行在哪个核心上，RHI线程和游戏的逻辑线程、渲染线程、loading线程一起可以在对应的PlatformAffinity.h中查看，更具体地设置需要查看Setup函数。



