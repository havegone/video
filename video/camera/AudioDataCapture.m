//
//  AudioCamera.m
//  video
//
//  Created by Tommy on 14-1-17.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import "AudioDataCapture.h"
@interface AudioDataCapture ()<AVCaptureAudioDataOutputSampleBufferDelegate>
{
    dispatch_semaphore_t _sampleSemaphore;
}

@end

@implementation AudioDataCapture

- (void) configure{
    _sampleQueue = dispatch_queue_create("audio.camera.queue", DISPATCH_QUEUE_SERIAL);
    _sampleSemaphore = dispatch_semaphore_create(1);
    
}
- (AVCaptureOutput*)createCameraOutput{
    return nil;
}

- (AVCaptureOutput*)createAudioOutput{
    
    AVCaptureAudioDataOutput* audioOutput = [[AVCaptureAudioDataOutput alloc]init];
    [audioOutput setSampleBufferDelegate:self queue:_sampleQueue];



    return audioOutput;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    if (dispatch_semaphore_wait(_sampleSemaphore, DISPATCH_TIME_NOW)) {
        
        
        dispatch_semaphore_signal(_sampleSemaphore);
    }
}


@end
