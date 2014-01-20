//
//  VACapture.m
//  video
//
//  Created by Tommy on 14-1-17.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import "VACapture.h"

//http://blog.csdn.net/zengconggen/article/details/7595449

@interface VACapture()<AVCaptureAudioDataOutputSampleBufferDelegate>

@end

@implementation VACapture
- (void) setDefaultValues{
    [super setDefaultValues];
    _audioSampleQueue = dispatch_queue_create("audio.capture.queue", DISPATCH_QUEUE_SERIAL);
    
    //video
    self.vbitRate = 128.0*1024.0;
    self.vcodec = AVVideoCodecH264;
    self.vwidth = 640 ;
    self.vheight = 480;  
    self.fileType = AVFileTypeQuickTimeMovie;
    
    //audio
    self.bitRate = 64000;
    self.sampleRate = 44100.0;
    self.channel = 1;
    self.format = kAudioFormatMPEG4AAC;

}

- (NSString *)stringFromDate:(NSDate *)date{
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    //zzz表示时区，zzz可以删除，这样返回的日期字符将不包含时区信息 +0000。
    
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSString *destDateString = [dateFormatter stringFromDate:date];
    
    [dateFormatter RELEASE];
    
    return destDateString;
    
}

- (NSString*)generateFilePath{
    NSString * time = [self stringFromDate:[NSDate date]];
    NSString *betaCompressionDirectory = [NSHomeDirectory()stringByAppendingPathComponent:@"Documents"];
    self.filePath = [betaCompressionDirectory stringByAppendingFormat:@"/%@.mp4",time];
    unlink([self.filePath UTF8String]);
    return self.filePath;
}

- (void)initVideoWriter{

    NSError *error = nil;
    
    if(!self.filePath){
        [self generateFilePath];
    }
    
    self.videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:self.filePath]
                                                 fileType:self.fileType
                                                    error:&error];
    NSParameterAssert(self.videoWriter);
    NSErrorLog(error);
    
    self.videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:self.videoWriterSettings];
    
    NSParameterAssert(self.videoWriterInput);

    self.videoWriterInput.expectsMediaDataInRealTime = YES;
    
    NSDictionary *sourcePixelBufferAttributesDictionary = @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32ARGB)};
    self.adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.videoWriterInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    
    NSParameterAssert(self.videoWriterInput);
    NSParameterAssert([self.videoWriter canAddInput:self.videoWriterInput]);
    
    if ([self.videoWriter canAddInput:self.videoWriterInput])
        NSLog(@"I can add this input");
    else
        NSLog(@"i can't add this input");
    
}
- (void)initAudioWriter{

    self.audioWriterInput = [AVAssetWriterInput
                             assetWriterInputWithMediaType: AVMediaTypeAudio
                             outputSettings: self.audioWriterSettings];
    
    self.audioWriterInput.expectsMediaDataInRealTime = YES;
}

-(void) initWriters
{
    
    [self initAudioSettings];
    [self initVideoSettings];
    
    [self initVideoWriter];
    [self initAudioWriter];
    
    [self.videoWriter addInput:self.audioWriterInput];
    [self.videoWriter addInput:self.videoWriterInput];
    
}

- (void)initAudioSettings{
    AudioChannelLayout acl;
    bzero( &acl, sizeof(acl));
    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
    
    self.audioWriterSettings = @{AVFormatIDKey:@(self.format),
                           AVEncoderBitRateKey:@(self.bitRate),
                           AVSampleRateKey:@(self.sampleRate),
                           AVNumberOfChannelsKey:@(self.channel),
                           AVChannelLayoutKey:[NSData dataWithBytes:&acl length: sizeof(acl)]};
}

- (void)initVideoSettings{
    NSDictionary *videoCompressionProps = @{AVVideoAverageBitRateKey:@(self.vbitRate)};
    self.videoWriterSettings = @{AVVideoCodecKey:self.vcodec,
                                    AVVideoWidthKey:@(self.vwidth),
                                    AVVideoHeightKey:@(self.vheight),
                                    AVVideoCompressionPropertiesKey:videoCompressionProps};
}
- (AVCaptureDeviceInput*) createAudioInput{
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:nil];
    
    return audioInput;
}
- (AVCaptureOutput*)createAudioOutput{
    AVCaptureAudioDataOutput* audioOutput = [[AVCaptureAudioDataOutput alloc]init];
    
    [audioOutput setSampleBufferDelegate:self queue:_audioSampleQueue];
    
    return audioOutput;
}

- (void)buildSession{
    [self initWriters];
    [super buildSession];
}
- (void)start:(StartRecordBlock)block{
    self.startBlock = block;
    [self start];
}
- (void)stop:(FinishRecordBlock)block{
    self.finishBlock = block;
    DefineWeakSelf();
    [self.videoWriter finishWritingWithCompletionHandler:^{
        if(wself.finishBlock){
            wself.finishBlock();
        }
    }];
    [self stop];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    //observe session status change
    
}
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    
    static int frame = 0;
    CMTime lastSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    if(frame++ == 0 && self.videoWriter.status != AVAssetWriterStatusWriting)
    {
        [self.videoWriter startWriting];
        [self.videoWriter startSessionAtSourceTime:lastSampleTime];
    }
    
    if(captureOutput == self.cameraOutput){
        
        if(self.videoWriter.status == AVAssetWriterStatusFailed){
            return;
        }
        
        if(self.videoWriterInput.isReadyForMoreMediaData){
            if([self.videoWriterInput appendSampleBuffer:sampleBuffer]){
                NSLog(@"");
            }else{
                NSLog(@"append video sample buffer failed");
            }
        }
    }
    
    if(captureOutput == self.audioOutput){
        if(self.videoWriter.status == AVAssetWriterStatusFailed){
            return;
        }
        
        if(self.audioWriterInput.isReadyForMoreMediaData){
            if([self.audioWriterInput appendSampleBuffer:sampleBuffer]){
                NSLog(@"");
            }else{
                NSLog(@"appedn audio sampel buffer failed");
            }
        }
        
    }
    
}


@end
