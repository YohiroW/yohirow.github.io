---
sidebar: uecheetsheet
---

### Animation
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
