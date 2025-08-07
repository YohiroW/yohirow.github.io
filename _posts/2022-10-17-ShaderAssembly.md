---
title: 阅读 GCN 架构下的 Shader 汇编代码
author: Yohiro
date: 2022-10-17
categories: [Graphics, Shader]
tags: [graphics, shader, assembly, compile]
render_with_liquid: false
img_path: /assets/images/{}/
---

## 前言

在尝试逆向工程时，通常会在截帧的 GPU 信息中看到着色器的汇编代码。为了更好理解 GPU 的工作原理，如何加载数据、选择分支等，同时更好进行 Shader 调试，就个人而言有必要对 shader 汇编有一定的了解。

这篇文章的原文来自[这里](https://interplayoflight.wordpress.com/2021/04/18/how-to-read-shader-assembly)，原文基于 AMD GCN 架构下的着色器汇编代码来进行了简单拆解。了解后，可以将该方法应用到其他 GPU 架构的汇编上。

本文的各种指令在 ["AMD Instinct MI200" Instruction Set Architecture](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/instinct-mi200-cdna2-instruction-set-architecture.pdf) 中有更准确的描述。

本篇使用的工具是[Shader Playground](https://shader-playground.timjones.io/)

## 背景

现代 Shader 会由像是 GLSL、HLSL 这类着色器语言来编写。编写完成后，会使用 fxc 或是 dxc 这种工具将着色器代码转换成与 GPU 无关的形式，这里称作中间语言。然后 GPU 的驱动会将该**中间语言** (IL, Intermediate Language) 转换为在特定 GPU 上执行的**着色器汇编**（ISA）。这里，我们更侧重于关注着色器汇编，因为它更能代表实际执行的代码。

比如下面是一个简单的将输入的像素乘以一个数的 Shader：

``` hlsl
struct PSInput
{
	float4 color : COLOR;
};

cbuffer cbData
{
    float4 data;
}

float4 PSMain(PSInput input) : SV_TARGET
{
	return data * input.color;
}
```

它的中间代码：
```
il_ps_2_55
dcl_global_flags refactoringAllowed
dcl_cb cb0[1]
dcl_input_generic_interp(linear) v0
dcl_output_generic o0
mul_ieee r4096, v0, cb0[0]
mov o0, r4096
ret_dyn
end
```

AMD GCN 架构下的着色器汇编:
``` nasm
s_mov_b32 m0, s8
s_buffer_load_dwordx4 s[0:3], s[4:7], 0x00
v_interp_p1_f32 v2, v0, attr0.x
v_interp_p2_f32 v2, v1, attr0.x
v_interp_p1_f32 v3, v0, attr0.y
v_interp_p2_f32 v3, v1, attr0.y
v_interp_p1_f32 v4, v0, attr0.z
v_interp_p2_f32 v4, v1, attr0.z
v_interp_p1_f32 v0, v0, attr0.w
v_interp_p2_f32 v0, v1, attr0.w
s_waitcnt lgkmcnt(0)
v_mul_f32 v1, s0, v2
v_mul_f32 v2, s1, v3
v_mul_f32 v3, s2, v4
v_mul_f32 v0, s3, v0
v_cvt_pkrtz_f16_f32 v1, v1, v2
v_cvt_pkrtz_f16_f32 v0, v3, v0
exp mrt0, v1, v1, v0, v0 done compr vm
s_endpgm
end
```

这段 Shader 代码过于简单了，没有代表性，让我们稍微添加一点东西。

考虑下面的 Shader 代码，该代码中包含了插值、采样、读取 buffer、基础运算、分支执行的操作：


``` hlsl
struct PSInput
{
    float2 uv : TEXCOORD;
};
 
cbuffer cbData
{
    float4 data;
}
 
Texture2D<float4> tex;
SamplerState samplerLinear;
 
float4 PSMain(PSInput input) : SV_TARGET
{
    float4 result = tex.Sample(samplerLinear, input.uv); 
     
    float factor = data.x * data.y;
     
    if( factor > 0 )
        return data.z * result; 
    else
        return data.w * result;   
}
```

下面的是上面的 Shader 生成的汇编：

``` nasm
  s_mov_b32     m0, s20             
  s_mov_b64     s[22:23], exec      
  s_wqm_b64     exec, exec          
  v_interp_p1_f32  v2, v0, attr0.x  
  v_interp_p2_f32  v2, v1, attr0.x  
  v_interp_p1_f32  v3, v0, attr0.y  
  v_interp_p2_f32  v3, v1, attr0.y  
  s_and_b64     exec, exec, s[22:23]
  image_sample  v[0:3], v[2:4], s[4:11], s[12:15] dmask:0xf 
  s_buffer_load_dwordx4  s[0:3], s[16:19], 0x00   
  s_waitcnt     lgkmcnt(0)                        
  v_mov_b32     v4, s1                            
  v_mul_f32     v4, s0, v4                        
  v_cmp_lt_f32  vcc, 0, v4                        
  s_cbranch_vccz  label_0017                      
  s_waitcnt     vmcnt(0)                          
  v_mul_f32     v0, s2, v0                        
  v_mul_f32     v1, s2, v1                        
  v_mul_f32     v2, s2, v2                        
  v_mul_f32     v3, s2, v3                        
  s_branch      label_001C                        
label_0017:
  s_waitcnt     vmcnt(0)                          
  v_mul_f32     v0, s3, v0                        
  v_mul_f32     v1, s3, v1                        
  v_mul_f32     v2, s3, v2                        
  v_mul_f32     v3, s3, v3                        
label_001C:
  s_mov_b64     exec, s[22:23]                    
  v_cvt_pkrtz_f16_f32  v0, v0, v1                 
  v_cvt_pkrtz_f16_f32  v1, v2, v3                 
  exp           mrt0, v0, v0, v1, v1 done compr vm
  s_endpgm                                        
end
```

直接看可能看不懂，现在忽略一些必要代码，看一些比较明显的（由于 markdown 不好渲染，所以用了 diff 的形式呈现）：

``` diff
+ float4 result = tex.Sample(samplerLinear, input.uv);
- image_sample  v[0:3], v[2:4], s[4:11], s[12:15] dmask:0xf

+ float factor = data.x * data.y;
- v_mov_b32     v4, s1
- v_mul_f32     v4, s0, v4

+ if( factor > 0 )
- v_cmp_lt_f32  vcc, 0, v4
- s_cbranch_vccz  label_0017

+ data.z * result;
- v_mul_f32     v0, s2, v0
- v_mul_f32     v1, s2, v1
- v_mul_f32     v2, s2, v2
- v_mul_f32     v3, s2, v3

+ data.w * result;
- v_mul_f32     v0, s3, v0
- v_mul_f32     v1, s3, v1
- v_mul_f32     v2, s3, v2
- v_mul_f32     v3, s3, v3ji

+ return
- exp     mrt0, v0, v0, v1, v1 done compr vm
```

注意到几乎所有的指令都以 **v_** 或 **s_** 开头，比如 **v_mov_b32**，**s_mov_b32**。这里的 v 代表矢量 vector，s 代表标量 scalar。

根据 [GCN 架构白皮书](https://www.techpowerup.com/gpu-specs/docs/amd-gcn1-architecture.pdf)中的描述，汇编指令会被计算单元（CU）加载为称作 wavefront 的工作项，这个所谓的工作项在不同的架构下的名称有所不同，但是可以笼统地当作处理像素的线程。它会并行地执行着色器指令。

GCN 架构的 CU 可以解码七种指令类型：

- 分支指令
- 标量 ALU 或内存指令
- 矢量 ALU 指令
- 矢量内存指令
- 本地数据共享指令
- 全局内存或导出指令
- 其他特殊指令

标量指令有两条 pipeline，一是用于处理分支和控制终端，二是在标量数据缓存中读取数据。每个 SIMD 内部有矢量 pipeline 用于加速浮点数的计算。

举例来说，当 GPU 从 Constant Buffer 中读取数据时，将会发出标量指令。当需要将一个像素的颜色乘一个值时，将会发出矢量指令。

在着色器汇编代码中，指令的右侧是指令的寄存器，寄存器在存储着色器指令在操作中使用到的数据。
``` nasm
v_mul_f32     v0, s3, v0
```
该指令意为将每个 wavefront 的 v0 矢量寄存器中的值与 s3 标量寄存器中的值相乘，并将结果写入到矢量寄存器 v0 中。注意到上面的汇编中，也有形为 `s[22:23]` 的寄存器，意为寄存器范围，可用来存储更多数据。

在 AMD 的 GCN 指令集架构中，有多种不同的寄存器类型，具体信息可以直接访问[该文档](https://www.amd.com/content/dam/amd/en/documents/radeon-tech-docs/instruction-set-architectures/gcn3-instruction-set-architecture.pdf)。

在上面的指令中，同时也指定了数据类型。v_mul_**f32**表明该指令操作 32 位的浮点数，v_mov_**b32** 表明在寄存器加载 32 位无类型数值，v_cvt_pkrtz**_f16_f32** 表明是将 32 位的浮点数转为半精度的 16 位浮点数。

有了以上的背景知识后，可以尝试解读上面的着色器汇编代码了。

## 解读

```nasm
  s_mov_b32     m0, s20
  s_mov_b64     s[22:23], exec
  s_wqm_b64     exec, exec
```

着色器代码正式执行前会设置数据地址。上面的着色器代码会在后续的操作中进行插值，因此会先将每个顶点的 UV 坐标的本地数据存储的偏移量从标量寄存器 S20 加载到 M0 寄存器中。

然后，**exec** 寄存器中的内容的副本放入了标量寄存器 s22，s23 中。关于 exec 寄存器，文档中的介绍如下：

| Abbrev. | Name | Size | Description |
|---------|------|------|-------------|
| EXEC    | Execute Mask | 64 bits |  A bit mask with one bit per thread, which is applied to vector instructions and controls that threads execute and that ignore the instruction | 

也就是说，exec 寄存器是一个掩码，每个 wavefront 线程占用一位，该掩码用来描述线程的执行状态。

由于该寄存器可用于所有 wavefront 因此它是个标量指令以 s 开头。

最后执行 **s_wqm_b64** 指令，它会检查掩码中每组的四个比特位，如果该组的四个位中任意的一位设置为一，那么该组的四个比特位都会设为一。在使用 Piexl Shader 渲染时，PS 始终以 2x2 的 quad 为单位来进行渲染。因此，该指令会用于确认哪些 quad 是处于激活状态。

```nasm
  v_interp_p1_f32  v2, v0, attr0.x
  v_interp_p2_f32  v2, v1, attr0.x
  v_interp_p1_f32  v3, v0, attr0.y
  v_interp_p2_f32  v3, v1, attr0.y
```

> Pixel shaders use LDS to read vertex parameter values; the pixel shader then interpolates them to find the per-pixel parameter values.
> 
> PS 使用 LDS 读取顶点参数值，然后通过对它们执行插值来找到各像素对应的值。

接下来的部分使用 M0 寄存器中的偏移，对 Vertex Shader 提供的 uv 坐标插值。由于每个像素有自己的独立的 uv 值，因此使用矢量指令。注意到每个 uv 分量的插值都要使用两个指令。这两个指令执行时，GPU 会读取三角形顶点传入的参数中的 uv 值并进行插值。

这也说明在 GCN 架构的 GPU 中插值是发起生在着色器，而非使用专门的硬件单元执行。

```nasm
  s_and_b64     exec, exec, s[22:23]
```

该命令相当于执行了一个按位与的操作，如果 wavefront 的某个线程没有激活则会跳过该线程。

```nasm
image_sample  v[0:3], v[2:4], s[4:11], s[12:15] dmask:0xf
```

**image_sample** 是最基础的图片采样指令。sample 代表该指令可以通过 SamplerState 来指定纹理过滤方式。寄存器 v[0:3] 代表存放结果的 4 个寄存器 v0 到 v3；v[2:4] 包含插值的 uv 坐标 v2，v3；标量寄存器 s[4:11] 表示用于存放纹理描述符的 8 个寄存器，该描述符通常是指向的纹理内存的地址；最后一个标量寄存器 s[12:15] 表示纹理过滤器对象的描述符的 4 个寄存器，也就是 SamplerState 的内存地址。dmask 是一个 4 位的数据掩码，指定纹理采样时应处理的通道的数量，此处 0xf 表示要读取所有 4 个通道。即使没有 v 开头的前缀，image_sample 也是一个矢量指令。

```nasm
s_buffer_load_dwordx4  s[0:3], s[16:19], 0x00   
s_waitcnt     lgkmcnt(0)                        
v_mov_b32     v4, s1                            
v_mul_f32     v4, s0, v4       
```

接下来从 Constant Buffer 中读取常量数据 Data。Constant Buffer 读取数据是所有 wavefront 的通用标量操作，因此使用标量指令 **s_buffer_load_dwordx4**。该指令会从 Constant Buffer 中读取四个 dword，第一个标量范围指定存储加载读取结果的四个标量寄存器 s0 到 s3，存储 fp32 的值；第二个范围指定 Constant Buffer 的描述符，也就是内存地址。

由于内存加载存在延迟，从 s_buffer_load 执行到返回数据给后续指令 **v_mov_b32** 之间会已经经过了若干个时钟周期，因此编译器在两个指令之间添加了 **s_waitcnt** 指令，等待所有的加载操作完成，参数 **lgkmcnt** 占 4 bits 表示等待的 LDS/GDS/Constant/Message，这里我们在等待 Constant Buffer 的数据的加载完成。完成加载后，接下来的移动指令 v_mov_b32 将寄存器 s1 中的数据加载到 v4 寄存器中，然后调用 v_mul_f32 将 v4 中的值直接与寄存器 s0 中的值相乘，并将结果保存到 v4 中。

上面的汇编表示在 GCN 架构中，标量的乘法必须将其中一个值移到矢量寄存器中。但并非所有的数据类型都是如此，如果 Constant Buffer 中的 Data 的数据类型由 float4 改为 uint4，那么这里的 v_mul_f32 就可以由 s_mul_i32 来完成。

```nasm
v_cmp_lt_f32  vcc, 0, v4                        
s_cbranch_vccz  label_0017 
```

接下来执行分支判断指令 **v_cmp_lt_f32**，LT 意为 **L**ess **T**han 判断 0 是否小于寄存器 v4 中的值 ，**vcc** 是一个 64 位的掩码，每个线程一个位，用于存储矢量比较的结果，值为 1 代表通过该比较，值为 0 代表未通过该比较。此处比较虽然是矢量的，也即每个相乘使用不同的值去比较，但 v4 中的值对于各个线程都是相同的。**s_cbranch_vccz** 指令会检查 VCC 的比较结果是否为零，为零意味着比较失败，跳转到 label 0017 处执行，否则则为 NOP，也就是 no operation 不执行任何操作。

另外，比较指令是矢量的，但是实际的分支指令是标量，也就是对所有的线程都是相同的操作。在 GCN 架构中，所有类型的分支指令都是如此，它们由标量单元进行处理。这种情况下，分支指令对 wavefront 中的每个线程就是要么全都执行要么全都不执行，也就是 factor.x 要么都小于 0，要么都大于等于 0，因为编译器是知道该值是来自 Costant Buffer 的标量，对所有线程来说都是相同的，因此对同一个 wavefront 中不存在分歧。

假如将比较的值改为每个线程不同的值：

``` hlsl
float4 PSMain(PSInput input) : SV_TARGET
{
    float4 result = tex.Sample(samplerLinear, input.uv); 

	  // 使用从纹理中采样得到的值，该值对每个像素或者说线程都是不同的
    if( result.x > 0 )   
    	return data.z * result; 
    else
    	return data.w * result; 
}
```

那么相应的 ISA 会变为：

``` nasm
  image_sample  v[0:3], v[2:4], s[4:11], s[12:15] dmask:0xf  
  s_mov_b64     s[0:1], exec                            
  s_waitcnt     vmcnt(0)                                
  v_cmpx_gt_f32  s[2:3], v0, 0                           
  s_cbranch_execz  label_0017
```

可以看到此时会使用 exec 中的掩码来确定哪些线程正在活动，并使用 **v_cmpx_gt_f32** 判断 v0 是否大于 0，比较失败的会返回 NOP，然后执行指令 **s_cbranch_execz**，该指令也是个分支判断的指令，与 s_cbranch_vccz 不同的是，该指令读取 exec 寄存器中的值来判断比较结果。

回到原先的 ISA 中，接下来有：

``` nasm
s_waitcnt     vmcnt(0)                          
v_mul_f32     v0, s2, v0                        
v_mul_f32     v1, s2, v1                        
v_mul_f32     v2, s2, v2                        
v_mul_f32     v3, s2, v3                        
s_branch      label_001C 
```

这是 if 条件为 true 的分支，也即 factor 大于 0 的分支。这里会将纹理采样的结果乘上来自 Constant Buffer 的常量值 data.z。当需要纹理采样值时，GPU 需要确保该结果读取完成，否则会有 undefined 行为。因此，编译器在这里添加了另一个等待指令 **s_waitcnt**，该指令后的 **vmcnt** 与上文提到的 lgkmcnt 不同，vmcnt 表示等待矢量内存返回。

这段代码最后，执行 **s_branch** 直接跳转到 label_001C 位置。

``` nasm
label_0017:
  s_waitcnt     vmcnt(0)                          
  v_mul_f32     v0, s3, v0                        
  v_mul_f32     v1, s3, v1                        
  v_mul_f32     v2, s3, v2                        
  v_mul_f32     v3, s3, v3 
```

这是 else 分支所执行的代码，内容是将纹理采样的结果乘 data.w。同样，这里会使用等待指令以确保该内存读取结果可用。从这两段代码可以看出 v_mul_f32 可以将矢量与标量相乘。

一个 float4 的乘法运算对应了 ISA 中的四条指令，这和 GCN 的架构设计有关， 

``` nasm
label_001C:
  s_mov_b64     exec, s[22:23]                    
  v_cvt_pkrtz_f16_f32  v0, v0, v1                 
  v_cvt_pkrtz_f16_f32  v1, v2, v3                 
  exp           mrt0, v0, v0, v1, v1 done compr vm
s_endpgm  
```

在示例的 ISA 的最后一部分，先是将之前存储在 s22 和 s23 中的掩码值转移到 exec 中，以确保已激活的线程能够正常取得计算结果。

**v_cvt_pkrtz_f16_f32** 指令将两个 f32 的值转为 f16 并 pack 到一个 f32 中。对于 v0/v1 和 v2/v3 该指令各执行了一次，最终在 v0 和 v1 中保存了 float4 类型的计算结果。通过这种方式压缩了数据长度节省了带宽。

**exp** 指令意为 export，对于 Pixel Shader，该指令会将计算的结果输出到绑定的 render target 上。由于 Pixel Shader 必须输出至少一个 Color/Depth/Null 的 Target，因此所有的 Pixel Shader 都包含一个 export 指令。这里的参数 **mrt0** 代表支持 mrt，我们的输出目标是多个 render target 中的第一个。紧接着的几个寄存器，done 表示这是该 Shader 的最后的输出，compr 代表数据为压缩的格式，vm 代表可以使用 exec 的掩码来告知 color buffer 中哪些像素是有效或无效。

最后的 **s_endpgm** 指令表示终止该 wavefront 的执行。到这里该 Shader 便执行完毕了。

## 最后

上面解读的 Shader 的样例可能太简单，并不实用，但是通过这个过程可以更好理解 GPU 如何执行从而提高对 shading language 的敏感程度。比如，将上面示例中的代码稍微改一下，只使用一个 return 语句，它们的代码和 ISA 会变成：

``` hlsl
float4 PSMain(PSInput input) : SV_TARGET
{
    float4 result = tex.Sample(samplerLinear, input.uv); 
     
    float factor = data.x * data.y;
     
    if( factor > 0 )
        result *= data.z; 
    else
        result *= data.w;
     
    return result;  
}
```

``` nasm
  s_mov_b32     m0, s20                    
  s_mov_b64     s[22:23], exec           
  s_wqm_b64     exec, exec               
  v_interp_p1_f32  v2, v0, attr0.x       
  v_interp_p1_f32  v3, v0, attr0.y       
  v_interp_p2_f32  v2, v1, attr0.x       
  v_interp_p2_f32  v3, v1, attr0.y       
  s_and_b64     exec, exec, s[22:23]     
  image_sample  v[0:3], v[2:4], s[4:11], s[12:15] dmask:0xf 
  s_buffer_load_dwordx4  s[0:3], s[16:19], 0x00        
  s_waitcnt     lgkmcnt(0)                             
  v_mov_b32     v4, s1                                 
  v_mul_f32     v4, s0, v4                             
  v_cmp_lt_f32  vcc, 0, v4                             
  s_waitcnt     vmcnt(0)                               
  v_mul_f32     v4, s2, v0                             
  v_mul_f32     v5, s2, v1                             
  v_mul_f32     v6, s2, v2                             
  v_mul_f32     v7, s2, v3                             
  v_mul_f32     v0, s3, v0                             
  v_mul_f32     v1, s3, v1                             
  v_mul_f32     v2, s3, v2                             
  v_mul_f32     v3, s3, v3                             
  v_cndmask_b32  v0, v0, v4, vcc                       
  v_cndmask_b32  v1, v1, v5, vcc                       
  v_cndmask_b32  v2, v2, v6, vcc                       
  v_cndmask_b32  v3, v3, v7, vcc                       
  s_mov_b64     exec, s[22:23]                         
  v_cvt_pkrtz_f16_f32  v0, v0, v1                      
  v_cvt_pkrtz_f16_f32  v1, v2, v3                      
  exp           mrt0, v0, v0, v1, v1 done compr vm     
  s_endpgm       
```

与原本的示例相比，分支指令完全被移除了，取而代之的是四个 **v_cndmask_b32** 指令，它们根据存储在 vcc 中的 **v_cmp_lt_f32** 的比较结果来选择输出的值。

虽然这种写法消除了分支指令的影响，但也引入了更多的矢量寄存器，不过多数情况下，这也是一种优化。

## 参考

- [How to read shader assembly – Interplay of Light](https://interplayoflight.wordpress.com/2021/04/18/how-to-read-shader-assembly/)
- [Low-Level Thinking in High-Level Shading Language](https://www.humus.name/Articles/Persson_LowLevelThinking.pdf)
- [R1200 ISA](https://www.amd.com/content/dam/amd/en/documents/radeon-tech-docs/instruction-set-architectures/gcn3-instruction-set-architecture.pdf)
- ["AMD Instinct MI200" Instruction Set Architecture](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/instinct-mi200-cdna2-instruction-set-architecture.pdf) 