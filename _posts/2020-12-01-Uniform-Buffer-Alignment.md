---
title: UniformTable里的偏移问题
author: Yohiro
date: 2020-12-01
categories: [Rendering]
tags: [engine, programming, rendering, opengl, unrealengine]
img_path: /assets/images/UniformTable/
---
最近的UE4的项目中遇到了一个Bug，具体问题是这样的：

玩家可以蹲伏在草丛中进入隐匿状态，进入隐匿状态后，草丛有一个不透明度降低的效果。问题出在这种效果在有些平台存在，有些平台不存在。

后来经过一番探索，发现问题出在uniform buffer里。

UE4里的uniform buffer定义在SceneView里：
```cpp
// View uniform buffer member declarations
#define VIEW_UNIFORM_BUFFER_MEMBER_TABLE \
    VIEW_UNIFORM_BUFFER_MEMBER(FMatrix, TranslatedWorldToClip) \
    VIEW_UNIFORM_BUFFER_MEMBER(FMatrix, WorldToClip) \
 
    ....
 
    VIEW_UNIFORM_BUFFER_MEMBER(FVector4, HairRenderInfo) \
    VIEW_UNIFORM_BUFFER_MEMBER(uint32, HairRenderInfoBits) \
```

查下代码，UE4里GLSL默认使用的是std140的布局。在这个uniform table里，如果成员中有数组，便会产生uniform成员偏移的问题，而这些偏移出现在使用GLSL的平台上。

```cpp
ralloc_asprintf_append(buffer, "layout(std140) uniform %s\n{\n", block_name);
```
因为这种布局会将数组中的元素，不论类型，都当做16字节来对齐。

官方的原话是 **The array stride (the bytes between array elements) is always rounded up to the size of a vec4 (ie: 16-bytes).**

![](Layout.png)

也就是说如果你在uniform table中声明了一个新的成员，比如：

```cpp
VIEW_UNIFORM_BUFFER_MEMBER_ARRAY(float, LightVolume, [2])  　
```

这段代码在HLSL和GLSL中内存的布局是不同的，在HLSL中和我们C++中声明的长度一致。而在GLSL中，由于layout是std140，所以这里的LightVolume[2]实际上占用了32 byte，而不是8 byte。

这就使得编译shader时，在加入了一些padding后，从CPU传到GPU的值有了偏移。

最后的解决方法是把这种数组型的uniform buffer放到了table的最后面，然后重新排了下uniform table的顺序，让他少加些padding，从而更紧凑些。

详情可以参考这里👉[**Interface Block (GLSL)**](https://www.khronos.org/opengl/wiki/Interface_Block_(GLSL))