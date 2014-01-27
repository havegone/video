//
//  PartitionEncoder.m
//  video
//
//  Created by Tommy on 14-1-26.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import "PartitionEncoder.h"
@interface PartitionEncoder ()
{
    CMTime _lastVideoPts;
    CMTime _lastAudioPts;
    
    CMTime _timeOffset;
    BOOL   _hasInterrupted;
}

@property(nonatomic)BOOL isPuase;
@property(nonatomic,copy)StopDidBlock stopBlock;

@end

@implementation PartitionEncoder

- (void) resetTime{
    _timeOffset = kCMTimeZero;
    _lastAudioPts = kCMTimeZero;
    _lastVideoPts = kCMTimeZero;
}

- (void)pause{
    @synchronized(self){
        self.isPuase = YES;
        _hasInterrupted = YES;
    }
}

- (void)resume{
    @synchronized(self){
        self.isPuase = NO;
    }
}

- (void) stop:(StopDidBlock)block{
    self.stopBlock = block;
    DefineWeakSelf();
    self.stopDidBlock = ^(void){
        [wself resetTime];
        if(wself.stopBlock)
            wself.stopBlock();
    };
    
    [super stop:self.stopDidBlock];

}

- (CMSampleBufferRef)adjustPts:(CMSampleBufferRef)sampleBuffer withTime:(CMTime)offset{
    
    CMSampleBufferRef sample = nil;
    CMItemCount timingArrayEntriesNeededOut = 0;
    CMSampleTimingInfo *timingArrayOut = nil;
    CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, 0, nil,&timingArrayEntriesNeededOut);
    if(timingArrayEntriesNeededOut){
        timingArrayOut = malloc(sizeof(CMSampleTimingInfo)*timingArrayEntriesNeededOut);
        CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, 0, timingArrayOut,&timingArrayEntriesNeededOut);
    }
    
    if(timingArrayOut){
        for (int i = 0 ; i < timingArrayEntriesNeededOut; ++i) {
            timingArrayOut[i].presentationTimeStamp = CMTimeSubtract(timingArrayOut[i].presentationTimeStamp, offset);
            timingArrayOut[i].decodeTimeStamp = CMTimeSubtract(timingArrayOut[i].decodeTimeStamp, offset);
        }
    }
    
    CMSampleBufferCreateCopyWithNewTiming(0, sampleBuffer, timingArrayEntriesNeededOut, timingArrayOut, &sample);
    
    if(timingArrayOut){
        free(timingArrayOut);
        timingArrayOut = nil;
    }
    
    return sample;
}



- (void)captureOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer isVideo:(BOOL)isVideo{
    
    if(!self.isRunning || self.isPuase){
        goto END;
    }
    
    if(_hasInterrupted){
        if(isVideo){
            goto END;
        }
        
        _hasInterrupted = NO;
        //has resumed
    
        CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        CMTime lastPts = isVideo?_lastVideoPts:_lastAudioPts;
        if (CMTIME_IS_VALID(lastPts)){
            if(CMTIME_IS_VALID(_timeOffset)){
                pts = CMTimeSubtract(pts, _timeOffset);
            }
            CMTime offset = CMTimeSubtract(pts, lastPts);
            if(CMTIME_IS_VALID(_timeOffset)){
                _timeOffset = CMTimeAdd(_timeOffset, offset);
            }else{
                _timeOffset = offset;
            }
        }
        _lastAudioPts.flags = 0;
        _lastVideoPts.flags = 0;
        
    }

    CFRetain(sampleBuffer);
    if(CMTIME_IS_VALID(_timeOffset)){
        CFRelease(sampleBuffer);
        sampleBuffer = [self adjustPts:sampleBuffer withTime:_timeOffset];
    }
    NSParameterAssert(sampleBuffer);
    
    CMTime presentTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    CMTime duration = CMSampleBufferGetDuration(sampleBuffer);
    if (duration.value > 0){
        presentTimeStamp = CMTimeAdd(presentTimeStamp, duration);
    }
    
    if (isVideo){
        _lastVideoPts = presentTimeStamp;
    }
    else{
        _lastAudioPts = presentTimeStamp;
    }
    
    
    [super captureOutputSampleBuffer:sampleBuffer isVideo:isVideo];

    CFRelease(sampleBuffer);

    
END:
    return;

    
}



@end
