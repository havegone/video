//
//  VACapture.m
//  video
//
//  Created by Tommy on 14-1-17.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import "VACapture.h"
#import "MovieSampleFragment.h"
#import "MovieEncoder.h"

//http://blog.csdn.net/zengconggen/article/details/7595449
//http://blog.csdn.net/linzhiji/article/details/6736704
//http://blog.csdn.net/linzhiji/article/details/6735282

@interface VACapture()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>
{
    BOOL _canStartRecording;
    BOOL _interrupted;
    CMTime _lastVideo;
    CMTime _timeOffset;
    CMTime _lastAudio;
    dispatch_queue_t  _audioSampleQueue;
    NSMutableArray *_videoSampleArray;
    NSMutableArray *_audioSampleArray;
    MovieSampleFragment* _currentFragment;
    MovieSampleFragmentMgr* _fragmentMgr;
}
@property (nonatomic,assign,readwrite)BOOL isRecording;
@property (nonatomic,assign,readwrite)BOOL isPause;
@property (nonatomic,assign,readwrite)BOOL isMute;
@end

@implementation VACapture

#pragma override super meathods

- (void) setDefaultValues{
    [super setDefaultValues];
    
    //video
    self.vbitRate = 256*1024.0;
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
    _interrupted = NO;
    _isPause = NO;
    
    _videoSampleArray = [NSMutableArray new];
    _audioSampleArray = [NSMutableArray new];
    _isMute = NO;
    
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


#pragma mark -
#pragma mark video and audio encoder

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
    
    NSDictionary *sourcePixelBufferAttributesDictionary = @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32ARGB),
                                                            (id)kCVPixelBufferCGImageCompatibilityKey:@(YES),
                                                            (id)kCVPixelBufferCGBitmapContextCompatibilityKey:@(YES)
                                                            };
    
//    NSMutableDictionary* inputSettingsDict = [NSMutableDictionary dictionary];
//   
//    [inputSettingsDict setObject:[NSNumber numberWithUnsignedInteger:(NSUInteger)(image.uncompressedSize/image.rect.size.height)] forKey:(NSString*)kCVPixelBufferBytesPerRowAlignmentKey];
//    [inputSettingsDict setObject:[NSNumber numberWithDouble:image.rect.size.width] forKey:(NSString*)kCVPixelBufferWidthKey];
//    [inputSettingsDict setObject:[NSNumber numberWithDouble:image.rect.size.height] forKey:(NSString*)kCVPixelBufferHeightKey];
//    [inputSettingsDict setObject:[NSNumber numberWithBool:YES] forKey:(NSString*)kCVPixelBufferCGImageCompatibilityKey];
//    [inputSettingsDict setObject:[NSNumber numberWithBool:YES] forKey:(NSString*)kCVPixelBufferCGBitmapContextCompatibilityKey];
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
    //setting maybe more,so need consider the init postion
    [self initAudioSettings];
    [self initVideoSettings];
    
    if(self.encoder){
        self.encoder.path = self.filePath;
        self.encoder.fileType = self.fileType;
        self.encoder.videoSettings = self.videoWriterSettings;
        self.encoder.audioSettings = self.audioWriterSettings;
        return;
    }
    
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



#pragma mark -
#pragma mark recode operation handlers

- (void)startWithReset{
    _interrupted = NO;
    _timeOffset = CMTimeMake(0, 0);
    [super start];
}

- (void)startRecord:(StartRecordBlock)block{
    @synchronized(self)
    {
        if(self.encoder){
            [self initWriter];
            [self.encoder start];
            return;
        }
        if(!self.isRecording){
            [self initWriter];
            self.startBlock = block;
            _currentFragment = [[MovieSampleFragment alloc]initWithTimeOffset:kCMTimeZero];
            _fragmentMgr = [[MovieSampleFragmentMgr alloc]initWithVideoInput:self.videoWriterInput andAudioInput:self.audioWriterInput];
            self.isRecording = YES;
        }
    }
    
}

- (void)stopRecord:(FinishRecordBlock)block{
    @synchronized(self)
    {
        if(self.encoder){
            dispatch_async(self.sampleQueue, ^{
                [self.encoder stop];
            });
            return;
        }
        
        
        if(!self.isRecording)
            return;
        self.finishBlock = block;
        self.isRecording = NO;
        
        
//        NSString* path = [self generateFilePath];
//        [self writeImages:_currentFragment.videoSampleFragment.sampleArray ToMovieAtPath:path withSize:CGSizeMake(640, 480) inDuration:5 byFPS:20];
//        return ;

        DefineWeakSelf();
        dispatch_async(self.sampleQueue, ^{
            NSDate* time = [NSDate date];
            NSLog(@"start write");
            [_fragmentMgr addFragment:_currentFragment];
            _fragmentMgr.adaptor = self.adaptor;
            [_fragmentMgr writeToInputs:^{
//                self.adaptor
            
                [wself.writer finishWritingWithCompletionHandler:^{
                    NSLog(@"finish recode");
                    _canStartRecording = YES;
                    
                    if(wself.finishBlock){
                        wself.finishBlock();
                    }
                }];
                
                [_fragmentMgr removeAll];
            }];
            
            _currentFragment = nil;
            
        });
    }
    
   
}

- (BOOL)pauseRecord{
    @synchronized(self){
        if(self.encoder){
            [self.encoder pause];
            return YES;
        }
        
        if(self.isRecording && !self.isPause){
            self.isPause = YES;
            _interrupted = YES;
            return YES;
        }
    }
    return NO;
}
- (BOOL)resumeRecord{
    @synchronized(self){
        if(self.encoder){
            [self.encoder resume];
            return YES;
        }
        
        
        if(self.isRecording && self.isPause){
            self.isPause = NO;
            return YES;
        }
    }
    return NO;
}

- (void)enableMute:(BOOL)mute{
    if([self processMuteOperation:mute])
        self.isMute = mute;
}

- (BOOL)processMuteOperation:(BOOL)mute{
 
    return YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    //observe session status change
    
}


#pragma mark -
#pragma mark video/audio stream handler
- (void)logCMTime:(CMTime)time{
    NSLog(@"cmtime value:%lld scale:%d dur:%f",time.value,time.timescale,CMTimeGetSeconds(time));
}
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    
    @synchronized(self)
    {

        BOOL isVideo = YES;
        if(captureOutput == self.audioOutput){
            isVideo = NO;
        }
        
        if(self.encoder){
            [self.encoder captureOutputSampleBuffer:sampleBuffer isVideo:isVideo];
            return;
        }
        
        if(!self.isRecording||self.isPause){
            return;
        }
        
        
        //NSLog(@"isVideo:%d,%ld",isVideo,CFGetRetainCount(sampleBuffer));
        
        if(![self processSampleBuffer:sampleBuffer isVideo:isVideo]){
            
            if((sampleBuffer = [self processPartialRecord:sampleBuffer isVideo:isVideo]))
            {
                [self encodeFrame:sampleBuffer isVideo:isVideo];
                CFRelease(sampleBuffer);
            }
            
        }
        
//        NSLog(@"after:%ld",CFGetRetainCount(sampleBuffer));
        
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


#pragma mark -
#pragma mark interrupt record handlers

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

- (CMSampleBufferRef)processPartialRecord:(CMSampleBufferRef)sampleBuffer isVideo:(BOOL)isVideo{
    if (_interrupted){
        if (isVideo){
            return nil;
        }
        _interrupted = NO;
        
        CMTime presentTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        CMTime last = isVideo ? _lastVideo : _lastAudio;
        if (CMTIME_IS_VALID(last)){
            if (CMTIME_IS_VALID(_timeOffset)){
                presentTimeStamp = CMTimeSubtract(presentTimeStamp, _timeOffset);
            }
            CMTime offset = CMTimeSubtract(presentTimeStamp, last);
            [self logCMTime:offset];
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
    
    return sampleBuffer;
}

#pragma mark - 
#pragma mark segment handlers

- (BOOL) processSampleBuffer:(CMSampleBufferRef)sampleBuffer isVideo:(BOOL)isVideo{
    
    return NO;

    if (CMSampleBufferDataIsReady(sampleBuffer))
    {
        if (_writer.status == AVAssetWriterStatusUnknown){
            CMTime startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            [_writer startWriting];
            [_writer startSessionAtSourceTime:startTime];
        }
        if (_writer.status == AVAssetWriterStatusFailed){
            NSLog(@"error %@", _writer.error.localizedDescription);
            return YES;
        }
        
        
        if(isVideo || !self.isMute)
           [_currentFragment appendSample:sampleBuffer isVideo:isVideo];
    }else{
        NSLog(@"xxxxxxx");
    }
    
    return YES;
    
    
    if(isVideo){
        
        
        
        
    }else{
        AudioBufferList audioBufferList;
        NSMutableData *data= [[NSMutableData alloc] init];
        CMBlockBufferRef blockBuffer;
        CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &audioBufferList, sizeof(audioBufferList), NULL, NULL, 0, &blockBuffer);
        
        
        //for (int y = 0; y < audioBufferList.mNumberBuffers; y++) {
        //  AudioBuffer audioBuffer = audioBufferList.mBuffers[y];
        //  Float32 *frame = (Float32*)audioBuffer.mData;
        //
        //  [data appendBytes:frame length:audioBuffer.mDataByteSize];
        //}
        
        // append [data bytes] to your NSOutputStream
        
        
        
        CFRelease(blockBuffer);
        blockBuffer=NULL;
        [data RELEASE];
 
    }
    
    return YES;
}



- (BOOL) deleteLastSegment{
    
    
    return NO;
}
- (BOOL) deleteSegmentAtIndex:(NSInteger)index{
    return NO;
}

- (CGImageRef) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer // Create a CGImageRef from sample buffer data
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer,0);        // Lock the image buffer
    
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);   // Get information of the image
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef newImage = CGBitmapContextCreateImage(newContext);
    CGContextRelease(newContext);
    
    CGColorSpaceRelease(colorSpace);
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    /* CVBufferRelease(imageBuffer); */  // do not call this!
    
    return newImage;
}

//http://stackoverflow.com/questions/16475737/convert-uiimage-to-cmsamplebufferref
//http://stackoverflow.com/questions/3741323/how-do-i-export-uiimage-array-as-a-movie/3742212#3742212
//- (CVPixelBufferRef) newPixelBufferFromCGImage: (CGImageRef) image

- (void) cropSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    CGRect cropRect = CGRectMake(0, 0, 640, 480);
    
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:(CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer)]; //options: [NSDictionary dictionaryWithObjectsAndKeys:[NSNull null], kCIImageColorSpace, nil]];
    ciImage = [ciImage imageByCroppingToRect:cropRect];
    
    CVPixelBufferRef pixelBuffer;
    CVPixelBufferCreate(kCFAllocatorSystemDefault, 640, 480, kCVPixelFormatType_32BGRA, NULL, &pixelBuffer);
    
    CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
    
    CIContext * ciContext = [CIContext contextWithOptions: nil];
    [ciContext render:ciImage toCVPixelBuffer:pixelBuffer];
    CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
    
    CMSampleTimingInfo sampleTime = {
        .duration = CMSampleBufferGetDuration(sampleBuffer),
        .presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer),
        .decodeTimeStamp = CMSampleBufferGetDecodeTimeStamp(sampleBuffer)
    };
    
    CMVideoFormatDescriptionRef videoInfo = NULL;
    CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, &videoInfo);
    
    CMSampleBufferRef oBuf;
    CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, true, NULL, NULL, videoInfo, &sampleTime, &oBuf);
    
    //or using AVAssetWriterInputPixelBufferAdaptor to append corped image to input
    /*
     NSMutableDictionary* inputSettingsDict = [NSMutableDictionary dictionary];
     [inputSettingsDict setObject:[NSNumber numberWithInt:pixelFormat] forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
     [inputSettingsDict setObject:[NSNumber numberWithUnsignedInteger:(NSUInteger)(image.uncompressedSize/image.rect.size.height)] forKey:(NSString*)kCVPixelBufferBytesPerRowAlignmentKey];
     [inputSettingsDict setObject:[NSNumber numberWithDouble:image.rect.size.width] forKey:(NSString*)kCVPixelBufferWidthKey];
     [inputSettingsDict setObject:[NSNumber numberWithDouble:image.rect.size.height] forKey:(NSString*)kCVPixelBufferHeightKey];
     [inputSettingsDict setObject:[NSNumber numberWithBool:YES] forKey:(NSString*)kCVPixelBufferCGImageCompatibilityKey];
     [inputSettingsDict setObject:[NSNumber numberWithBool:YES] forKey:(NSString*)kCVPixelBufferCGBitmapContextCompatibilityKey];
     AVAssetWriterInputPixelBufferAdaptor* pixelBufferAdapter = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:assetWriterInput sourcePixelBufferAttributes:inputSettingsDict];
     
     [pixelBufferAdapter appendPixelBuffer:completePixelBuffer withPresentationTime:pixelBufferTime]
     */
    
}
- (NSData*)dataFromSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    return nil;
//    return [NSData dataWithBytes:&sampleBuffer length:malloc_size(sampleBuffer)];
}

-(void)recieveVideoFromData:(NSData *)data{
    //http://blog.csdn.net/zxc110110/article/details/7191016
    CMSampleBufferRef sampleBuffer;
    [data getBytes:&sampleBuffer length:sizeof(sampleBuffer)];
 
    
    CVImageBufferRef imageBuffer= CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    uint8_t *baseAddress=(uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    size_t bytesPerRow= CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width= CVPixelBufferGetWidth(imageBuffer);
    size_t height= CVPixelBufferGetHeight(imageBuffer);
    
    CGColorSpaceRef colorSpace= CGColorSpaceCreateDeviceRGB();
    CGContextRef newContext= CGBitmapContextCreate(baseAddress,
                                                   width,height, 8, bytesPerRow,colorSpace,
                                                   kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef newImage= CGBitmapContextCreateImage(newContext);
    
    CGContextRelease(newContext);
    CGColorSpaceRelease(colorSpace);
    
    UIImage *image=[UIImage imageWithCGImage:newImage scale:1.0
                                 orientation:UIImageOrientationRight];
    
    CGImageRelease(newImage);
//    [self.imageView performSelectorOnMainThread:@selector(setImage:)
//                                     withObject:image waitUntilDone:YES];
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    
}


#pragma mark -
#pragma mark images to video
- (CVPixelBufferRef )pixelBufferFromCGImage:(CGImageRef)image size:(CGSize)size
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey, nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width, size.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options, &pxbuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width, size.height, 8, 4*size.width, rgbColorSpace, kCGImageAlphaPremultipliedFirst|kCGBitmapByteOrder32Little);
    NSParameterAssert(context);
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image)), image);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}
- (void)writeImageAsMovie:(NSArray*)imageArray toPath:(NSString*)path size:(CGSize)size duration:(int)duration
{
    NSError *error = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:
                                  [NSURL fileURLWithPath:path] fileType:AVFileTypeQuickTimeMovie
                                                              error:&error];
    NSParameterAssert(videoWriter);
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey,
                                   nil];
    AVAssetWriterInput* writerInput = [[AVAssetWriterInput
                                        assetWriterInputWithMediaType:AVMediaTypeVideo
                                        outputSettings:videoSettings] RETAIN];
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
                                                     sourcePixelBufferAttributes:nil];
    NSParameterAssert(writerInput);
    NSParameterAssert([videoWriter canAddInput:writerInput]);
    [videoWriter addInput:writerInput];
    
    //Start a session:
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    //Write samples:
    for (UIImage * image in imageArray) {
        NSAssert(0, @"need fix time bugs");
        CVPixelBufferRef buffer = [self pixelBufferFromCGImage:image.CGImage size:size];
        [adaptor appendPixelBuffer:buffer withPresentationTime:kCMTimeZero];
        [adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeMake(duration-1, 2)];
    }

    
    //Finish the session:
    [writerInput markAsFinished];
    [videoWriter endSessionAtSourceTime:CMTimeMake(duration, 2)];
    [videoWriter finishWritingWithCompletionHandler:nil];
}

- (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image andSize:(CGSize) size
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width,
                                          size.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width,
                                                 size.height, 8, 4*size.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}



- (void) writeImages:(NSArray *)imagesArray ToMovieAtPath:(NSString *) path withSize:(CGSize) size
          inDuration:(float)duration byFPS:(int32_t)fps{
    //Wire the writer:
    NSError *error = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:path]
                                                            fileType:AVFileTypeQuickTimeMovie
                                                               error:&error];
    NSParameterAssert(videoWriter);
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey,
                                   nil];
    
    AVAssetWriterInput* videoWriterInput = [AVAssetWriterInput
                                             assetWriterInputWithMediaType:AVMediaTypeVideo
                                             outputSettings:videoSettings];
    
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput
                                                     sourcePixelBufferAttributes:nil];
    NSParameterAssert(videoWriterInput);
    NSParameterAssert([videoWriter canAddInput:videoWriterInput]);
    [videoWriter addInput:videoWriterInput];
    
    //Start a session:
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    //Write some samples:
    CVPixelBufferRef buffer = NULL;
    
    int frameCount = 0;
    
    int imagesCount = [imagesArray count];
    float averageTime = duration/imagesCount;
    int averageFrame = (int)(averageTime * fps);
    
    for(VideoSample* img in imagesArray)
    {
        [self pixelBufferFromCGImage:img.image andSize:size];
        
        BOOL append_ok = NO;
        int j = 0;
        while (!append_ok && j < 30)
        {
            if (adaptor.assetWriterInput.readyForMoreMediaData)
            {
                printf("appending %d attemp %d\n", frameCount, j);
                
                CMTime frameTime = CMTimeMake(frameCount,(int32_t) fps);
                float frameSeconds = CMTimeGetSeconds(frameTime);
                NSLog(@"frameCount:%d,kRecordingFPS:%d,frameSeconds:%f",frameCount,fps,frameSeconds);
                append_ok = [adaptor appendPixelBuffer:buffer withPresentationTime:frameTime];
                
                if(buffer)
                    [NSThread sleepForTimeInterval:0.05];
            }
            else
            {
                printf("adaptor not ready %d, %d\n", frameCount, j);
                [NSThread sleepForTimeInterval:0.1];
            }
            j++;
        }
        if (!append_ok) {
            printf("error appending image %d times %d\n", frameCount, j);
        }
        
        frameCount = frameCount + averageFrame;
    }
    
    //Finish the session:
    [videoWriterInput markAsFinished];
    [videoWriter finishWriting];
    NSLog(@"finishWriting");
}


@end
