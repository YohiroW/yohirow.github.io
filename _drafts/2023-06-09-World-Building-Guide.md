---
title: World Building Guide
author: Yohiro
date: 2023-06-09
categories: [UnrealEngine]
tags: [unrealengine, world partition, streaming]
render_with_liquid: false
img_path: /assets/images/{}/
---

World Partition，One File Per Actor(OFPA)，Level Instances和Packed Level Actors(PLA)，Data Layers，HLOD，Editor和UX，WP之外的数据流送

## World Partition

### 实践

#### Grid setup
- 以单独的Grid开始构建，最终的成品中包含的Grid越少越好。
- 应基于Gameplay、物理行为、Actor数量等来规划Grid的具体的尺寸和加载范围，并在规模变化时进行profiling，再次调整。
- 考虑HLOD

#### 使用Level Instance和Packed Level Actor


#### 使用StreamingSourceComponent
在5.1以后的版本中，PlayerController已经是一个StreamingSourceComponent。
``` cpp
class ENGINE_API APlayerController : public AController, 
                                        public IWorldPartitionStreamingSourceProvider
```
这个组件可以附加在任何Actor上，可以用于一些无缝CutScene的预加载。



### 问题

#### 创建许多新Grid以及运行时的Data Layer
- 每个Grid的每一个小格子都至少包含一个Actor，产生一个StreamingLevel。此外，每个Data Layer也会创建一个StreamingLevel。任何行为产生的StreamingLevel都会对性能有所影响，例如:
    - 根据资产类型创建多个Grid或Data Layer，像是在一个森林的场景中创建树木的Grid、FX的Grid、灯光的Grid、大石头小石头的。
    - 仅使用Data Layer用作编辑目的而不在运行时改变其状态。

- 需要平衡Grid/Data Layer的规模和Streaming的效率
    - 通常为一些特殊内容添加Grid/Data Layer的行为，不会造成太大的性能影响，可以放心使用。

#### 场景/Data Layer的组织

#### Actor的包围盒

### 限制

#### Grid隶属于Persistent关卡
目前仅支持一个Persistent关卡中包含多个Grid。

#### 2D Streaming
当前版本的Streaming是2D视角的，不支持垂直空间的Streaming。根据World Partition的[Roadmap](https://udn.unrealengine.com/s/article/World-Building-Features-Roadmap)，将在5.4plus版本中添加3D区块的支持。

#### 重新配置区块vs分割Actor
分割Actor，例如Landscape、Foliage时，不能超过区块大小的限制，否则导致该Actor（Landscape/Foliage）在每次Streaming grid重新配置后无法更新。当前版本的引擎内提供了命令行重新创建这类Actor，需要时可以调用。

#### 编辑器内需要手动加载
当前版本中并不支持根据相机的位置、朝向自动加载区块，需要设计者在World Partition编辑器内选择加载。相较于Nanite和Texture的Streaming，World Partition在编辑器内的加载不受Pool/Buffer数量的限制，因此会导致内存耗尽从而崩溃。

#### 运行时限制
- 运行时无法创建/修改grid，生成streaming的行为法中在PIE和Cook时。
- 不支持运行时关卡的创建/注入行为
    - 修改Game Feature插件可以往指定的关卡添加Actor。
    - 修改Level Instance的代码也是可行的。
- Spawn的Actor是位于Persistent关卡中的，子Actor的关卡位置取决于其父节点的加载关卡。
- Persistent关卡中的Actor引用其他Spatially Loaded的Actor，引擎禁止该行为。

#### GC
为了分散GC的压力，已卸载的内容会在项目配置中定义的固定时间片后进行GC，或是当指定数量的cell被卸载后进行GC。

#### One File Per Actor（OFPA）
WP与OFPA密不可分，因此需要考虑产生的额外的actor文件数量所带来的问题，还有source control所面临的问题。

#### Hot reload
当Sync/Revert一个资产时，引用到该资产的Actor，如果位于WP中，hot reload不会对这个Actor起效。WP关卡必须关闭然后重新加载Actor。

#### 服务器端的Streaming
当前版本不支持，根据[**Roadmap**](https://udn.unrealengine.com/s/article/World-Building-Features-Roadmap)显示，将在5.3版本中添加该功能（Experimental），5.4plus版本中可供产品使用。

#### 光照 
仅支持动态光照，不允许烘培静态光。

### 用例

#### 堡垒之夜 第四章

|地图大小|`2km x 2km`|
|Actor数量|`约100k`|
|Cell大小|`128m`|
|加载范围|`256m（加载距离随平台和性能等级改变）`|

- 2 HLOD setup
    - 建筑物的HLOD（两层）
        - HLOD 0 
            为支持破坏功能，HLOD0的mesh被合并。256m cell，加载范围512m，spatially loaded
        - HLOD 1
            简化的mesh，512m cell，2048m load range，spatially loaded
    - 树木的HLOD（一层）
        - 使用imposter的Instanced layer , always loaded
- Level Instances:
    - 所有的POI
- Data layer：
    - 4个 初生岛屿和团队战大厅
    - 1个 用于赛季变换/特殊事件
- 服务器端：
    - 全部加载
    - Server streaming在PIE下使用，用于提升开发者的迭代效率
- Landscape: 
    - Always loaded
- Packaed Level Actors: 
    - 无

#### 黑客帝国demo

|地图大小|`4km x 4km`|
|Actor数量|`约107k`|
|Cell大小|`128m`|
|加载范围|`128m`|

- HLOD setup
    - HLOD 0 
        启用Nanite的Instance layer，256m cell，加载范围768m，spatially loaded
    - HLOD 1
        简化的mesh，256m cell，always loaded
- 使用houdini过程化构建，同时使用Rule Processor插件
    - 所有的POI
- Packaed Level Actors: 
    - PLA和使用了Instanced static mesh过程化生成的Actor
    - 该做法应用于所有的建筑物、街道、小物件
- Data layer（运行时 35/ 编辑器 21）：
    - 用于cut scenee和gameplay
    - 用于屋顶和路面下的资产
- Landscape: 
    - 无

#### 古代山谷demo

|地图大小|`2km x 2km`|
|Actor数量|`约14k`|
|Cell大小|`64m`|
|加载范围|`64m`|


- HLOD setup
    - HLOD 0 
       Instance layer，always loaded
- Packaed Level Actors: 
    - 用于组合岩石
- Data layer（运行时 2/ 编辑器 1）
- Landscape: 
    - 无

### 调试
 - 常用CVars

    更多的可以执行DumpConsoleCommands，将所有命令dump出来，wp相关的debug指令太多，下面仅列出一些常用的。

| wp.Runtime.ToggleDrawRuntimeHash2D or 3D                                              | streaming grid可视化 | 
| wp.Runtime.OverrideRuntimeSpatialHashLoadingRange \n -grid=[index] -range=[DesiredValue] | 覆写指定grid的加载距离 |
| wp.runtime.hlod                                                                       | 显示HLOD |
| wp.Runtime.RuntimeSpatialHashUseAlignedGridLevels                                     |       |
| wp.Runtime.RuntimeSpatialHashSnapNonAlignedGridLevelsToLowerLevels                    |       |       
| wp.Runtime.RuntimeSpatialHashPlaceSmallActorsUsingLocation                            |       |


## One File Per Actor

One File Per Actor(OFPA) 

### 实践

#### Epic强烈简易WP的使用者使用引擎内部的版本管理
原因如下：
- WP所引用的外部Actor文件以GUID命名，因此在外部文件夹中或是版本控制软件中难以识别。而在引擎的版本控制视图下，可以看到Actor的名称、类型以及路径，允许使用者对这些文件进行过滤、排序。
- Uncontrolled CL可以追踪所有本地非只读的文件，这一功能在外部的版本控制（如Perforce）中不可用。
- 在提交时存在数据验证阶段，而且这里的验证可以根据项目需要进行扩展。
- 在引擎内通过CL导航至Actor或其他内容，比起切换到外部的版本控制软件，体验上更加丝滑。

#### 使用Uncontrolled CL（ChangeList）
- 使用Uncontrolled CL可以在不打开版本控制软件的情况下看到你编辑的、设为可写的或是添加的资产。
- 能使workspace的使用情况更加清晰，避免出现不受版本控制的文件的影响。
- 当修改内容准备完毕，将Uncontrolled CL移到版本控制的CL。
- 程序同学应该使用Uncontrolled CL进行调试、测试以避免版本控制对binary的锁定（比如check out）。

#### 创建自定义的提交验证
提交验证可以通过代码进行扩展，关键的验证如CL中的文件缺失、资产引用问题，这些已集成到引擎中。

### 缺陷

#### 需要使用者去管理个人文件
大多数使用OFPA的人并不想管理一个又大又长的Changelist，并且担忧与同事并行工作会带来问题。

#### 使用P4V管理外部Actor
如上文实践中所述，使用WP的过程中应该尽量避免使用P4提交。

#### 分支/合并/创建副本/文件数量
- OFPA会给服务器端的加载、同步以及创建分支添加很大的压力，需要DM多加注意。
- 对大型工作室，应考虑代理、edge server等方式分散负载。

### 限制

#### GUID只能在UE里转为可读的名称

#### 启用OFPA vs 不启用OFPA

对于启用和不启用OFPA的Level Instances，他们的Streaming行为有所不同：

启用OFPA：
: 在PIE/Cook生成流送数据时，Level Instance中的内容会被分散开放到Persistent关卡，并被指定到相应的Grid中。而Level Instance本身在运行时不存在。

不启用OFPA
: 在PIE/Cook生成流送数据时，Level Instance会被保留，而且会被当作一个Actor在包含该Level Instance的grid cell level被加载的同时Stream in。

#### 访问未加载Actor
一些工具需要获取Actor的描述以找到其GUID，但是在关卡编辑器内没有加载对应关卡时，无法访问该Actor。