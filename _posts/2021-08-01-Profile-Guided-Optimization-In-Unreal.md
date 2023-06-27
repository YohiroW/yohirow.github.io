---
title: UE4中的PGO
author: Yohiro
date: 2021-08-01
categories: [UnrealEngine]
tags: [unrealengine, optimization, tool]
render_with_liquid: false
img_path: /assets/images/PGOInUnreal/
---

## 简介

`PGO(Profile Guided Optimization)`是一种基于LLVM的编译时优化，通过使用运行时收集的分析数据来指导编译器进行优化。截至UE5.0版本，Epic对PC、Android以及各Console平台都进行了配置。网路上很少有PGO相关的文章，这篇文章旨在尝试PGO的使用流程。

## 流程

按照Epic的流程，PGO可以直接启用，也可以搭配`Gauntlet自动测试框架`集成到自动测试流程中使用。关于Gauntlet框架的可参考官方文档[**Gauntlet自动化框架**](https://docs.unrealengine.com/4.27/zh-CN/TestingAndOptimization/Automation/Gauntlet/)。PGO整体的大致流程如图：

![Progress2](Progress2.png)

### 构建用于PGO的版本

  首先需要构建用于收集分析数据的PGO版本。PGO版本中，宏`ENABLE_PGO_PROFILE`应该被启用，否则不会输出PGO的临时文件:

  ```csharp
  /* --- TargetRules.cs --- */
  /// <summary>
  /// Whether to enable Profile Guided Optimization (PGO) instrumentation in this build.
  /// </summary>
  [CommandLine("-PGOProfile", Value = "true")]
  [XmlConfigFile(Category = "BuildConfiguration")]
  public bool bPGOProfile = true;

  /* --- UEBuildTarget.cs --- */
  if (Rules.bPGOProfile)
  {
    GlobalCompileEnvironment.Definitions.Add("ENABLE_PGO_PROFILE=1");
  }
  else
  {
    GlobalCompileEnvironment.Definitions.Add("ENABLE_PGO_PROFILE=0");
  }
  ```

  ```cpp
  /* --- PlatformMisc.cpp --- */
  #if ENABLE_PGO_PROFILE
    // Write the PGO profiling file on a clean shutdown.
    extern void PGO_WriteFile();
    PGO_WriteFile();
  #endif
  ```

  可以通过在build时传入指定的参数`-PGOProfile`来控制是否开启`ENABLE_PGO_PROFILE`。默认情况下打开PGOProfile后也会打开LTO，因此链接时间会变得非常长。

### 运行时收集数据

  接下来需要启动游戏正常游玩、正常退出。因为只有在`RequestExit()`时才会在`PGO_WriteFile`中调用`__llvm_profile_write_file`即写入扩展名为`*.profraw`的临时文件。
  该临时文件的输出目录可由命令行参数指定，但由于实现的问题，在不同的平台中，命令行参数有所不同，在启动时不指定输出目录，便会将该文件写入到默认位置，详情可参照`PGO_GetOutputDirectory`函数。

### 创建Gauntlet的测试用例<可选>

  如果需要集成到自动测试流程中，需要创建测试用例并添加该测试至Gauntlet的项目里。这个过程可以参考`Engine\Source\Programs\AutomationTool\Gauntlet\Unreal\Game`下的Samples。
  Gauntlet中已经有一个PGO的测试节点`Gauntlet.UnrealPGONode.cs`，其中PGOConfig有下面几个参数，可通过命令行传入给UAT，其中`ProfileOutputDirectory`是必需的。

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

#### 通过UAT启动测试

  使用UAT运行指定的测试用例。可以加入到bat文件里，方便集成到Jenkins一类的CI里：

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
  set PLATFORM=Android
  rem build configuration
  set CONFIG=Test

  rem ********************* Start Gauntlet Test *********************
  %UAT_PATH% %TEST_CMD% -project=%PRJ_NAME% -platform=%PLATFORM% -configuration=%CONFIG% -build=%STAGING_DIR%\%PLATFORM%  -test=%TEST_NAME% -ProfileOutputDirectory=%PROFILE_OUTPUT_PATH% -ScreenshotDirectory=%SCREENSHOT_DIRECTORY% 
  rem ********************* End   Gauntlet Test *********************
  pause
  ```

## 注意事项

- PGO本质上是编译器优化，因此随着优化等级的提高，有可能会暴露出代码中一些原本不存在的问题。
- 随着版本的迭代，代码不断更新，原本PGO收集的数据在用于新版本的优化时的效果会大打折扣。
- Profile数据会有额外的内存占用。

## 参考资料

- [Gauntlet Automation Framework](https://qiita.com/donbutsu17/items/cd17d500a9fed143e061) 介绍Gauntlet测试框架，可以搭配官方文档一起看
- [GAUNTLET AUTOMATED TESTING AND PERFORMANCE METRICS IN UE4](https://horugame.com/gauntlet-automated-testing-and-performance-metrics-in-ue4/) 古早版本中Gauntlet，可以当作参考
- [実行速度の最適化のあれこれ](https://www.docswell.com/s/EpicGamesJapan/ZEEL7Z-UE4_LargeScaleDevSQEX_Optimize#p31) 介绍了基于Sample的PGO
- [Daedalic Test Automation Plugin](https://github.com/DaedalicEntertainment/ue4-test-automation) Github上一款开源的UE的自动测试插件，对Gauntlet也进行了封装
- [使用配置文件引导的优化 (PGO)](https://source.android.google.cn/devices/tech/perf/pgo) Android项目中使用PGO