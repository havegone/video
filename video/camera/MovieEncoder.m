//
//  AbstractEncoder.m
//  video
//
//  Created by Tommy on 14-1-22.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import "MovieEncoder.h"

@interface MovieEncoder (){
    CMTime _lastVideoPts;
    CMTime _lastAudioPts;
    
    CMTime _timeOffset;
    CMTime _startTimeStamp;
    BOOL   _hasInterrupted;
}

@property(readwrite) BOOL running;


@end


@implementation MovieEncoder

- (instancetype) initWithPath:(NSString*)filePath statusChangeBlock:(MovieEncoderStatusChangeBlock)block;{
    if(self = [super init]){
        self.path = filePath;
        self.statusChangeBlock = block;
        self.isPuase = NO;
    }
    return self;
}

- (void) setupWriter{
    
    NSError *error = nil;
    
    [self setupVideoWriterInput];
    [self setupAudioWriterInput];
    self.writer = [AVAssetWriter assetWriterWithURL:[NSURL fileURLWithPath:self.path] fileType:self.fileType error:&error];
    if(error){
        NSErrorLog(error);
    }
    NSParameterAssert(self.writer);
    
    if([self.writer canAddInput:self.videoWriterInput])
    {
        [self.writer addInput:self.videoWriterInput];
    }
    
    if([self.writer canAddInput:self.audioWriterInput])
    {
        [self.writer addInput:self.audioWriterInput];
    }
}

- (void) setupVideoWriterInput{
    
    self.videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:self.videoSettings];
    self.videoWriterInput.expectsMediaDataInRealTime = YES;
}
- (void) setupAudioWriterInput{
    self.audioWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:self.audioSettings];
    self.audioWriterInput.expectsMediaDataInRealTime = YES;
}

- (void) start{
    @synchronized(self){
        
        if(!self.isRunning){
            [self setupWriter];
            [self resetTime];
            _running = YES;
            if(self.statusChangeBlock){
                self.statusChangeBlock(self,MovieEncoderStatusStart);
            }
        }
    }
}
- (void) stop{
    @synchronized(self){
        if(self.isRunning){
            _running = NO;
            self.isPuase = NO;
            if(self.writer.status == AVAssetWriterStatusWriting){
                DefineWeakSelf();
                [self.writer finishWritingWithCompletionHandler:^{
                    if(wself.statusChangeBlock){
                        wself.statusChangeBlock(wself,MovieEncoderStatusStop);
                    }
                }];
                
            }else{
                NSLog(@"stop failed:%@",self.writer.error);
            }
        }
    }
}

- (void)pause{
    @synchronized(self){
        if(!self.isPuase && self.isRunning){
            self.isPuase = YES;
            _hasInterrupted = YES;
            
            if(self.statusChangeBlock){
                self.statusChangeBlock(self,MovieEncoderStatusPause);
            }
        }
    }
}

- (void)resume{
    @synchronized(self){
        if(self.isPuase && self.isRunning){
            self.isPuase = NO;
            if(self.statusChangeBlock){
                self.statusChangeBlock(self,MovieEncoderStatusResume);
            }
        }
    }
}

- (BOOL)isRunning{
    return _running;
}

- (BOOL) appendSampleBuffer:(CMSampleBufferRef)sampleBuffer toInput:(AVAssetWriterInput*)input{

    if (CMSampleBufferDataIsReady(sampleBuffer))
    {
        if (self.writer.status == AVAssetWriterStatusUnknown){
            CMTime startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            _startTimeStamp = startTime;
            [self.writer startWriting];
            [self.writer startSessionAtSourceTime:startTime];
        }
        if (self.writer.status == AVAssetWriterStatusFailed){
            NSLog(@"error %@", self.writer.error.localizedDescription);
            return NO;
        }
        
        if(input.isReadyForMoreMediaData){
            if([input appendSampleBuffer:sampleBuffer]){
                return YES;
            }
        }else{
            NSLog(@"append sample buffer failed");
        }
    }
    
    return NO;
}


- (BOOL) encodeFrame:(CMSampleBufferRef) sampleBuffer isVideo:(BOOL)isVideo
{
   return [self appendSampleBuffer:sampleBuffer toInput:isVideo?self.videoWriterInput:self.audioWriterInput];
}


- (void) resetTime{
    _timeOffset = kCMTimeZero;
    _lastAudioPts = kCMTimeZero;
    _lastVideoPts = kCMTimeZero;
}

- (CMSampleBufferRef)adjustPts:(CMSampleBufferRef)sampleBuffer withTime:(CMTime)offset{
    
    CMSampleBufferRef sample = nil;
    CMItemCount timingArrayEntriesNeededOut = 0;
    CMSampleTimingInfo *timingArrayOut = nil;
    CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, 0, nil,&timingArrayEntriesNeededOut);
    if(timingArrayEntriesNeededOut){
        timingArrayOut = malloc(sizeof(CMSampleTimingInfo)*timingArrayEntriesNeededOut);
        CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, timingArrayEntriesNeededOut, timingArrayOut,&timingArrayEntriesNeededOut);
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
            if(_timeOffset.value == 0){
                _timeOffset = offset;
            }else{
                _timeOffset = CMTimeAdd(_timeOffset, offset);
            }
        }
        
        _lastAudioPts.flags = kCMTimeFlags_Valid;
        _lastVideoPts.flags = kCMTimeFlags_Valid;
        
    }
    
    CFRetain(sampleBuffer);
    if(CMTIME_IS_VALID(_timeOffset) && _timeOffset.value > 0){
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
    
    [self encodeFrame:sampleBuffer isVideo:isVideo];
    CFRelease(sampleBuffer);
    
END:
    return;
}

- (CGFloat)duration{
    CMTime durationTime = CMTimeMaximum(CMTimeSubtract(_lastVideoPts, _startTimeStamp), CMTimeSubtract(_lastAudioPts, _startTimeStamp));
    return CMTimeGetSeconds(durationTime);
}




@end

