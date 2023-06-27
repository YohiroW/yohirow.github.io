- 隐式色彩空间SRGB

Texture input -> Linear Rendering in RGB -> PostProcessing -> Viewport

8bit sRGB encoded texture -> 16bit Linear HDR Scene -> 16bit float Linear with Look applied -> 8bit Display Pixels

sRGBToLinear

Filmic Tone Curve

LinearTosRGB

- 引擎中HDR标准
  - ACES
    - 1000nit/ 2000nit/ GenericPlatformMisc.h

Refs:
https://learn.microsoft.com/en-us/windows/win32/direct3darticles/high-dynamic-range