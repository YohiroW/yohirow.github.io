---
title: Cpp20 协程
author: Yohiro
date: 2022-01-02
categories: [Programming, Cpp]
tags: [programing, cpp, coroutine]
render_with_liquid: false
img_path: /assets/images/{}/
---

## Intro

在大二用 Unity3d 的时候，做了一个[模仿 Cocos2dx 中 Action 动画的库](https://github.com/YohiroW/EaseAnimate)，用到了协程（Coroutine）这一概念。

其中有这么一段，

```c#
StopCoroutine("ticker");
if (isAnimPlaying)
{
    StartCoroutine("ticker");
}
```

然后 ticker 是这个样子的：

```c#
public IEnumerator ticker()
{
    while (true)
    {
        switch(timeType)
        {
            case TimeUpdateType.NORMAL:
                yield return new WaitForEndOfFrame();
                tick(Time.deltaTime);
                break;
            case TimeUpdateType.FIXED:
                yield return new WaitForFixedUpdate();
                tick(Time.fixedDeltaTime);
                break;
            case TimeUpdateType.REALTIME:
                yield return new WaitForEndOfFrame();
                tick(Time.unscaledDeltaTime);
                break;
        }
    }
}
```

这种以同步的方式写异步的逻辑的编程方式就是协程。协程可以在函数执行的时，在函数体的某个位置挂起并返回，将当前线程的执行让渡给其他的任务

## References

- [N4680](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2017/n4680.pdf)
- [Coroutine Theory](https://lewissbaker.github.io/2017/09/25/coroutine-theory)