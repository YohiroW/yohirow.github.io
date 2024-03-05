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
IEnumerator easePopOut()
{
    // ...

    while (currentTime < duration)
    {
        yield return new WaitForEndOfFrame();
        currentTime = Mathf.Clamp(currentTime += Time.deltaTime, 0, duration);

        float valueX = EaseAnimate.EaseInSine(start, end, currentTime / duration);
        transform.localPosition = new Vector3(valueX, transform.localPosition.y, transform.localPosition.z);
    }
}
```

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

以同步的方式写异步的逻辑

