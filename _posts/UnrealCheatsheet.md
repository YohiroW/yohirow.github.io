---
sidebar: uecheetsheet
---

### Rendering
 - Shading
    * https://pafuhana1213.hatenablog.com/entry/2019/04/09/104042
    * https://qiita.com/com04/items/a7895160df8d854fe924
    * https://github.com/EpicGames/UnrealEngine/pull/1552
    * https://aqu.hatenablog.com/entry/2018/07/09/000805
    * https://forums.unrealengine.com/t/toon-shading-model/30226
 - Texture
    * https://gameinstitute.qq.com/community/detail/101476
    * https://www.gamedevelopment.blog/texture-filter/
    * https://developer.oculus.com/blog/common-rendering-mistakes-how-to-find-them-and-how-to-fix-them/
 - Geometry
    * https://cs.stackexchange.com/questions/12521/what-are-degenerate-polygons
    * https://arm-software.github.io/opengl-es-sdk-for-android/ocean_f_f_t.html
    * http://www.betelge.com/blog/
 - Other
    * https://shaderbits.com/blog/custom-per-object-shadowmaps-using-blueprints
    * https://ikrima.dev/ue4guide/graphics-development/render-architecture/detailed-render-flow/
    * https://gameinstitute.qq.com/community/detail/117893
    * https://blog.csdn.net/sh15285118586/article/details/116723277
    * https://forums.unrealengine.com/t/how-to-reduce-the-fixed-overhead-of-a-scenecapture/283896
    * http://www.cemyuksel.com/research/hairmodels/
  - Blog
    * http://karim.naaji.fr/posts.html

### Engine
  - Framework
    * https://jip.dev/notes/unreal-engine/#simulation-renderer-synchronization
    * https://unrealcpp.com/
    * https://jashking.github.io/2017/04/26/ue4-rts-selection-box/
    * https://logins.github.io/graphics/2021/05/31/RenderGraphs.html#parallel-command-list-recording
    * https://jinyuliao.github.io/blog/html/2017/12/15/ue4_dialogue_system_part1.html
  - Old wiki
    * https://nerivec.github.io/old-ue4-wiki/index.html
  - MultiThread
    * https://www.docswell.com/s/EpicGamesJapan/5QMWWK-UE4_CEDECKYUSHU2021_MultiThread#p19
  - Workflow
    * https://80.lv/articles/bird-house-working-on-a-stylized-landscape-in-ue4
    * https://www.docswell.com/s/EpicGamesJapan/K7JQ65-UE4-ACTF2022#p92
    * https://ruyo.github.io/VRM4U/02_pbr/
  - Streaming
    * https://www.iteye.com/blog/avi-2524009
    * https://imzlp.com/posts/9455/
  - Lighting
    * https://www.jianshu.com/p/86a65fed79aa
    * https://www.unrealengine.com/en-US/blog/lumen-in-ue5-let-there-be-light
    * https://www.unrealengine.com/en-US/blog/exploring-lumen-unreal-engine-5-s-dynamic-global-illumination-and-reflections-system
  - RHI
    * https://devblogs.microsoft.com/directx/a-look-inside-d3d12-resource-state-barriers/
    * https://gpuopen.com/learn/dcc-overview/
    * https://forums.unrealengine.com/t/writing-data-to-rdg-structured-buffer-general-rdg-questions/138823/4
    * https://microsoft.github.io/DirectX-Specs/
    * https://docs.unrealengine.com/5.0/en-US/mesh-drawing-pipeline-in-unreal-engine/
  - Physics
    * https://glhub.blogspot.com/search/label/Chaos
    * https://matthias-research.github.io/pages/publications/publications.html
    * http://blog.mmacklin.com/
  - Other
    * https://jashking.github.io/2018/04/20/ue4-filesystem/

### Optimization
  - https://80.lv/articles/bird-house-working-on-a-stylized-landscape-in-ue4
  - https://www.famitsu.com/news/201910/16184681.html
  - https://aras-p.info/texts/CompactNormalStorage.html
  - https://stonelzp.github.io/ue4-performance/
  - https://www.docswell.com/s/EpicGamesJapan/ZEEL7Z-UE4_LargeScaleDevSQEX_Optimize#p53
  
### UI
 - Transition
    * https://rwiiug.hatenablog.com/entry/UE4_OtegaruTransition

### Library
 - https://opensourcelibs.com/lib/ue4-cheatsheet
 - CEDIL https://cedil.cesa.or.jp/
 - https://www.docswell.com/user/EpicGamesJapan?page=1
 - https://bartwronski.com/2016/10/30/dithering-part-three-real-world-2d-quantization-dithering/
 - https://gregory-igehy.hatenadiary.com/entry/2018/02/24/023251
 - https://unrealengine.hatenablog.com/
 - https://matlib.gpuopen.com/main/materials/all
 - https://ue5wiki.com/
 - https://gregory-igehy.hatenadiary.com/entry/2017/12/28/002645
 - http://www.teal-game.com/blog/customcrashreporter/

### Animation
- Vertex Animation
   * https://historia.co.jp/archives/21974/
- BoneTransform        
    *Ref: https://forums.unrealengine.com/t/bone-transform-at-certain-time-key/342024/2*
        
    ```cpp
        int BoneIdx = GetMesh()->GetBoneIndex(TEXT("root"));
        if(BoneIdx != INDEX_NONE)
        {
            int32 const TrackIndex = MyAnimSequence->GetSkeleton()->GetAnimationTrackIndex(BoneIdx, MyAnimSequence);
            MyAnimSequence->GetBoneTransform(BoneTrans, TrackIndex, DesiredTime, true);
        }
    ```
    如果是在Montage中：
    ```cpp
        FName SlotNodeName = "DefaultSlot";
        int SlotIndex = -1;
        for (int32 I = 0; I < MyMontage->SlotAnimTracks.Num(); ++I)
        {
            if (MyMontage->SlotAnimTracks[I].SlotName == SlotNodeName)
            {
                SlotIndex = I;
                break;
            }
        }

        if (SlotIndex >= 0)
        {
            FAnimSegment* Result = nullptr;
            for (FAnimSegment& Segment : MyMontage->SlotAnimTracks[SlotIndex].AnimTrack.AnimSegments)
            {
                if (Segment.AnimStartTime <= DesiredTime && DesiredTime <= Segment.StartPos + Segment.GetLength())
                {
                    Result = &Segment;
                    break;
                }
            }

            if (Result != nullptr)
            {
                FTransform BoneTrans;
                int BoneIdx = GetMesh()->GetBoneIndex(TEXT("root"));
                UAnimSequence *AnimSeq = Cast<UAnimSequence>(Result->AnimReference);
                int32 const TrackIndex = AnimSeq->GetSkeleton()->GetAnimationTrackIndex(BoneIdx, AnimSeq);
                AnimSeq->GetBoneTransform(BoneTrans, TrackIndex, DesiredTime, true);
            }
        }
    ```

