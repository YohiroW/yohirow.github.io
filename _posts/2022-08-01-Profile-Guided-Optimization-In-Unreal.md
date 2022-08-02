---
layout: post
title: [Automation] Unreal中的PGO
author: Yohiro
tags:  PGO Automation Unreal
sidebar: []
---

## Overview
PGO(Profile Guided Optimization)是一种基于LLVM的编译时优化，使用运行时收集的分析数据来指导编译器进行优化。截至5.0版本，Epic对PC以及各Console平台都进行了配置。PGO在UE中一般会搭配LTO(Link Time Optimization)一起使用以求在静态的编译、链接期达到最好的效果。鉴于网路上现在没有找到PGO相关的文章（反正我没找到），所以这篇文章旨在探明PGO的使用流程以及对PGO结果的评估。

## 食用方法
按照Epic的流程，PGO应搭配Gauntlet测试框架食用，关于Gauntlet框架的可参考官方文档[**Gauntlet自动化框架**](https://docs.unrealengine.com/4.27/zh-CN/TestingAndOptimization/Automation/Gauntlet/)，这里不做赘述。

- 创建Gauntlet的测试用例并添加该测试至Gauntletd的项目中。这个过程可以参考`Engine\Source\Programs\AutomationTool\Gauntlet\Unreal\Game`下的Samples。
  Gauntlet中已经有一个PGO的测试节点`Gauntlet.UnrealPGONode.cs`，其中PGOConfig有下面几个参数，可通过命令行传入，其中`ProfileOutputDirectory`是必需的。
  ```csharp
    /// <summary>
		/// Output directory to write the resulting profile data to.
		/// </summary>
		[AutoParam("")]
		public string ProfileOutputDirectory;

		/// <summary>
		/// Directory to save periodic screenshots to whilst the PGO run is in progress.
		/// </summary>
		[AutoParam("")]
		public string ScreenshotDirectory;

		[AutoParam("")]
		public string PGOAccountSandbox;

		[AutoParam("")]
		public string PgcFilenamePrefix;
  ```
- 构建用于PGO的版本
- 使用UAT运行指定的测试用例。也可以加入到bat文件里：
  ```bat
  rem path for RunUAT.bat
  set UAT_PATH=RunUAT.bat
  rem project name
  set PRJ_NAME={ProjectName}
  rem staging path
  set STAGING_DIR={EngineRoot}\{ProjectName}\Saved\StagedBuilds
  rem test command
  set TEST_CMD=RunUnreal
  rem test name
  set TEST_NAME=PGOTest
  rem profdata output path
  set PROFILE_OUTPUT_PATH={ProjectName}\Saved\Automation\PGO\
  rem screenshot path
  set SCREENSHOT_DIRECTORY={ProjectName}\Saved\Automation\PGO\Screenshot\
  rem platform Name
  set PLATFORM=PS5
  rem build configuration
  set CONFIG=Test

  rem ********************* Start Gauntlet Test *********************
  %UAT_PATH% %TEST_CMD% -project=%PRJ_NAME% -platform=%PLATFORM% -configuration=%CONFIG% -build=%STAGING_DIR%\%PLATFORM%  -test=%TEST_NAME% -ProfileOutputDirectory=%PROFILE_OUTPUT_PATH% -ScreenshotDirectory=%SCREENSHOT_DIRECTORY% 
  rem ********************* End   Gauntlet Test *********************
  pause
  ```
- 等待测试完成。如果无误的话，将会在`ProfileOutputDirectory`下面生成扩展名为`*.profraw`的文件，一旦测试流程结束，这些`*.profraw`文件会合并成为一个`profile.profdata`文件，这个文件将在我们使用命令行`-PGOOptimize`启动时

## Summarize
随着代码的不断改动，原本的Profile数据将变得不会再对当前版本起效。如果使用诸如#if、#ifdef等预编译指令或是inline的函数都会使当前PGO失效。
| Pros | Cons |
|-|-|
| | |

  


## Ref
- [Gauntlet Automation Framework](https://qiita.com/donbutsu17/items/cd17d500a9fed143e061) 介绍Gauntlet测试框架，可以搭配官方文档一起看
- [GAUNTLET AUTOMATED TESTING AND PERFORMANCE METRICS IN UE4](https://horugame.com/gauntlet-automated-testing-and-performance-metrics-in-ue4/) 古早版本中Gauntlet，可以当作参考
- [実行速度の最適化のあれこれ](https://www.docswell.com/s/EpicGamesJapan/ZEEL7Z-UE4_LargeScaleDevSQEX_Optimize#p31) 介绍了基于Sample的PGO
- [Daedalic Test Automation Plugin](https://github.com/DaedalicEntertainment/ue4-test-automation)Github上一款开源的UE的自动测试插件，对Gauntlet也进行了封装