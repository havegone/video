//
//  AVCapture.m
//  video
//
//  Created by Tommy on 14-2-18.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import "AVCapture.h"
@interface AVCapture()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>


@end

@implementation AVCapture

- (AVCaptureDeviceInput*) createAudioInput{
    
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:nil];
    
    return audioInput;
}
- (AVCaptureOutput*)createAudioOutput{
    AVCaptureAudioDataOutput* audioOutput = [[AVCaptureAudioDataOutput alloc]init];
    
    [audioOutput setSampleBufferDelegate:self queue:self.sampleQueue];
    
    return audioOutput;
}

- (void)buildSession{
    [super buildSession];
    [self.videoDataOutput setSampleBufferDelegate:self queue:self.sampleQueue];
}



@end
