//
//  VACapture.m
//  video
//
//  Created by Tommy on 14-1-17.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import "VACapture.h"

//http://blog.csdn.net/zengconggen/article/details/7595449

@interface VACapture()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>
{
    BOOL _canStartRecording;
    BOOL _interrupt;
    CMTime _lastVideo;
    CMTime _timeOffset;
    CMTime _lastAudio;
    dispatch_queue_t  _audioSampleQueue;
}
@property (nonatomic,assign,readwrite)BOOL isRecording;
@property (nonatomic,assign,readwrite)BOOL isPause;
@end

@implementation VACapture
- (void) setDefaultValues{
    [super setDefaultValues];
    

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
    
    _canStartRecording = YES;
    _interrupt = NO;
    _isPause = NO;

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
    
    self.writer = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:self.filePath]
                                                 fileType:self.fileType
                                                    error:&error];
    NSParameterAssert(self.writer);
    NSErrorLog(error);
    
    self.videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:self.videoWriterSettings];
    
    NSParameterAssert(self.videoWriterInput);

    self.videoWriterInput.expectsMediaDataInRealTime = YES;
    
    NSDictionary *sourcePixelBufferAttributesDictionary = @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32ARGB)};
    self.adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.videoWriterInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    
    NSParameterAssert(self.videoWriterInput);
    NSParameterAssert([self.writer canAddInput:self.videoWriterInput]);
    
    if ([self.writer canAddInput:self.videoWriterInput])
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

-(void) initWriter
{
    
    [self initAudioSettings];
    [self initVideoSettings];
    
    [self initVideoWriter];
    [self initAudioWriter];
    
    [self.writer addInput:self.audioWriterInput];
    [self.writer addInput:self.videoWriterInput];
    
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
    
    [audioOutput setSampleBufferDelegate:self queue:self.sampleQueue];
    
    return audioOutput;
}

- (void)buildSession{
    [super buildSession];
    [self.videoDataOutput setSampleBufferDelegate:self queue:self.sampleQueue];
}

- (void)startWithReset{
    _interrupt = NO;
    _timeOffset = CMTimeMake(0, 0);
    [super start];
}

- (void)startRecord:(StartRecordBlock)block{
    @synchronized(self)
    {
        if(!self.isRecording){
            [self initWriter];
            self.startBlock = block;
            self.isRecording = YES;
        }
    }
    
}

- (void)stopRecord:(FinishRecordBlock)block{
    @synchronized(self)
    {
        if(!self.isRecording)
            return;
        self.finishBlock = block;
        self.isRecording = NO;
        DefineWeakSelf();
        dispatch_async(self.sampleQueue, ^{
            [wself.writer finishWritingWithCompletionHandler:^{
                NSLog(@"finish recode");
                _canStartRecording = YES;
                if(wself.finishBlock){
                    wself.finishBlock();
                }
            }];
            
        });
    }
    
   
}

- (BOOL)pauseRecord{
    @synchronized(self){
        if(self.isRecording && !self.isPause){
            self.isPause = YES;
            _interrupt = YES;
            return YES;
        }
    }
    return NO;
}
- (BOOL)resumeRecord{
    @synchronized(self){
        if(self.isRecording && self.isPause){
            self.isPause = NO;
            return YES;
        }
    }
    return NO;
}




- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    //observe session status change
    
}

- (CMSampleBufferRef) adjustTime:(CMSampleBufferRef) sample by:(CMTime) offset
{
    CMItemCount count;
    CMSampleBufferGetSampleTimingInfoArray(sample, 0, nil, &count);
    CMSampleTimingInfo* pInfo = malloc(sizeof(CMSampleTimingInfo) * count);
    CMSampleBufferGetSampleTimingInfoArray(sample, count, pInfo, &count);
    
    for (CMItemCount i = 0; i < count; i++){
        pInfo[i].decodeTimeStamp = CMTimeSubtract(pInfo[i].decodeTimeStamp, offset);
        pInfo[i].presentationTimeStamp = CMTimeSubtract(pInfo[i].presentationTimeStamp, offset);
    }
    
    CMSampleBufferRef sout;
    CMSampleBufferCreateCopyWithNewTiming(nil, sample, count, pInfo, &sout);
    free(pInfo);
    return sout;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    
    @synchronized(self)
    {
        if(!self.isRecording||self.isPause){
            return;
        }
        
        BOOL isVideo = YES;
        
        if(captureOutput == self.audioOutput){
            isVideo = NO;
        }
        
        if (_interrupt){
            if (isVideo){
                return;
            }
            _interrupt = NO;
            
            CMTime presentTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            CMTime last = isVideo ? _lastVideo : _lastAudio;
            if (last.flags & kCMTimeFlags_Valid){
                if (_timeOffset.flags & kCMTimeFlags_Valid){
                    presentTimeStamp = CMTimeSubtract(presentTimeStamp, _timeOffset);
                }
                CMTime offset = CMTimeSubtract(presentTimeStamp, last);
                if (_timeOffset.value == 0){
                    _timeOffset = offset;
                }
                else{
                    _timeOffset = CMTimeAdd(_timeOffset, offset);
                }
            }
            _lastVideo.flags = 0;
            _lastAudio.flags = 0;
        }
        

        CFRetain(sampleBuffer);
        if (_timeOffset.value > 0){
            CFRelease(sampleBuffer);
            sampleBuffer = [self adjustTime:sampleBuffer by:_timeOffset];
        }
        
        CMTime presentTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        CMTime duration = CMSampleBufferGetDuration(sampleBuffer);
        if (duration.value > 0){
            presentTimeStamp = CMTimeAdd(presentTimeStamp, duration);
        }
        
        if (isVideo){
            _lastVideo = presentTimeStamp;
        }
        else{
            _lastAudio = presentTimeStamp;
        }
        
        [self encodeFrame:sampleBuffer isVideo:isVideo];
        CFRelease(sampleBuffer);
        
    }
    
}

- (BOOL) encodeFrame:(CMSampleBufferRef) sampleBuffer isVideo:(BOOL)isVideo
{
    if (CMSampleBufferDataIsReady(sampleBuffer))
    {
        if (_writer.status == AVAssetWriterStatusUnknown){
            CMTime startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            [_writer startWriting];
            [_writer startSessionAtSourceTime:startTime];
        }
        if (_writer.status == AVAssetWriterStatusFailed){
            NSLog(@"error %@", _writer.error.localizedDescription);
            return NO;
        }
        if (isVideo){
            if (self.videoWriterInput.readyForMoreMediaData){
                [self.videoWriterInput appendSampleBuffer:sampleBuffer];
                return YES;
            }
        }else{
            if(self.audioWriterInput.readyForMoreMediaData){
                [self.audioWriterInput appendSampleBuffer:sampleBuffer];
                return YES;
            }
        }
    }
    return NO;
}



@end
