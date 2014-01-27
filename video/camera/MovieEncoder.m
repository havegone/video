//
//  AbstractEncoder.m
//  video
//
//  Created by Tommy on 14-1-22.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import "MovieEncoder.h"

@interface MovieEncoder ()

@property(readwrite) BOOL running;

@end


@implementation MovieEncoder

- (id) initWithPath:(NSString*)filePath{
    if(self = [super init]){
        self.path = filePath;
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

        [self setupWriter];
        _running = YES;
        
    }
}
- (void) stop:(StopDidBlock)block{
    @synchronized(self){
        self.stopDidBlock = block;
        _running = NO;
        if(self.writer.status == AVAssetWriterStatusWriting){
            DefineWeakSelf();
            [self.writer finishWritingWithCompletionHandler:^{
                if(wself.stopDidBlock){
                    wself.stopDidBlock();
                }
            }];
        }else{
            NSLog(@"stop failed:%@",self.writer.error);
        }
    }
}

- (BOOL)isRunning{
    return _running;
}

- (void) appendSampleBuffer:(CMSampleBufferRef)sampleBuffer toInput:(AVAssetWriterInput*)input{
    //return;
    
    if (CMSampleBufferDataIsReady(sampleBuffer))
    {
        
        if (self.writer.status == AVAssetWriterStatusUnknown){
            CMTime startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            [self.writer startWriting];
            [self.writer startSessionAtSourceTime:startTime];
        }
        if (self.writer.status == AVAssetWriterStatusFailed){
            NSLog(@"error %@", self.writer.error.localizedDescription);
            return ;
        }
        
//        while (!input.isReadyForMoreMediaData) {
//            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
//        }
        
        if(input.isReadyForMoreMediaData){
            [input appendSampleBuffer:sampleBuffer];
        }
    }
}

- (void)captureOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer isVideo:(BOOL)isVideo{
    if(self.isRunning){
        [self appendSampleBuffer:sampleBuffer toInput:isVideo?self.videoWriterInput:self.audioWriterInput];
    }

}


@end

