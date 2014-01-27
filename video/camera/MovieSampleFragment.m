//
//  MovieSampleFragment.m
//  video
//
//  Created by Tommy on 14-1-21.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import "MovieSampleFragment.h"
#import "UIImage+PixelBuffer.h"
#import <CoreFoundation/CoreFoundation.h>

extern UIImageView* g_imageView;

@implementation VideoSample

+ (VideoSample*)sampleFromCMSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    
    CFRetain(sampleBuffer);
    VideoSample* sample = [VideoSample new];
    sample.image =  [UIImage imageFromCMSampleBuffer:sampleBuffer];
    sample.pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);

    
    CFRelease(sampleBuffer);
    return sample;
}


- (void)destoryImage{
//    if(self.image){
//        CFRelease(self.image);
//        self.image = nil;
//    }
}

- (void)dealloc{
    if(self.image){
        CFRelease(self.image);
        self.image = nil;
    }
}

@end

@implementation SampleFragment{
    AVAssetWriterInputPixelBufferAdaptor *_adaptor;
}

- (id)init{
    if(self = [super init]){
        self.sampleArray = [NSMutableArray new];
        self.timeOffset = kCMTimeZero;
        _adaptor = nil;
    }
    
    return self;
}
- (void)writeToInput:(AVAssetWriterInput *)input{
    
    [self.sampleArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CMSampleBufferRef sampleBuffer = (__bridge CMSampleBufferRef)(obj);
        
         CFTimeInterval time = CFAbsoluteTimeGetCurrent();
        
        if(![self writeToInput2:input sample:obj]){
            while (!input.readyForMoreMediaData) {
                [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
            }
            if(input.readyForMoreMediaData){
                
               if(![input appendSampleBuffer:sampleBuffer])
               {
                   NSLog(@"video:%d append failed at %d",self.isVideo, idx);
               }
                
            }
        }
    }];
    
}

- (BOOL) writeToInput2:(AVAssetWriterInput *)input sample:(id)sampleBuffer{
    
    if(!_isVideo){
        return NO;
    }
    
    if(!_adaptor){
        NSDictionary *sourcePixelBufferAttributesDictionary = @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32ARGB)};
        _adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:input sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    }
    
    VideoSample* sample = (VideoSample*)sampleBuffer;
    while (!_adaptor.assetWriterInput.readyForMoreMediaData) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }
    if(_adaptor.assetWriterInput.readyForMoreMediaData){
        
        CVPixelBufferRef buffer = pixelBufferFromCGImage(sample.image);
        if(!buffer||![_adaptor appendPixelBuffer:buffer withPresentationTime:sample.pts])
        {
            NSLog(@"xxx");
        }
        if(buffer)
            CVPixelBufferRelease(buffer);
        
    }else{
        NSLog(@"xxxxxxxx");
    }
    
    [sample destoryImage];
    
    return YES;
    
}

- (CMSampleBufferRef)CMSampleBufferCreateCopyWithDeep:(CMSampleBufferRef)sampleBuffer{
    
    CFRetain(sampleBuffer);
    
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);    
    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
    
    CMItemCount timingCount;
    CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, 0, nil, &timingCount);
    CMSampleTimingInfo* pInfo = malloc(sizeof(CMSampleTimingInfo) * timingCount);
    CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, timingCount, pInfo, &timingCount);
    
    CMItemCount sampleCount = CMSampleBufferGetNumSamples(sampleBuffer);
    
    CMItemCount sizeArrayEntries;
    CMSampleBufferGetSampleSizeArray(sampleBuffer, 0, nil, &sizeArrayEntries);
    size_t *sizeArrayOut = malloc(sizeof(size_t) * sizeArrayEntries);
    CMSampleBufferGetSampleSizeArray(sampleBuffer, sizeArrayEntries, sizeArrayOut, &sizeArrayEntries);
    
    CMSampleBufferRef sout = nil;
    

    if(dataBuffer){
        CMSampleBufferCreate(kCFAllocatorDefault, dataBuffer, YES, nil,nil, formatDescription, sampleCount, timingCount, pInfo, sizeArrayEntries, sizeArrayOut, &sout);
    }else{
        
        CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        NSLog(@"sample:%f",CMTimeGetSeconds(pts));
        
        CVImageBufferRef cvimgRef = CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferLockBaseAddress(cvimgRef,0);
        
        uint8_t *buf=(uint8_t *)CVPixelBufferGetBaseAddress(cvimgRef);
        size_t size = CVPixelBufferGetDataSize(cvimgRef);
        void * data = nil;
        if(buf){
            data = malloc(size);
            memcpy(data, buf, size);
        }
        
        size_t width = CVPixelBufferGetWidth(cvimgRef);
        size_t height = CVPixelBufferGetHeight(cvimgRef);
        OSType pixFmt = CVPixelBufferGetPixelFormatType(cvimgRef);
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(cvimgRef);
        
        
        CVPixelBufferRef pixelBufRef = NULL;
        CMSampleTimingInfo timimgInfo = kCMTimingInfoInvalid;
        CMSampleBufferGetSampleTimingInfo(sampleBuffer, 0, &timimgInfo);
        
        OSStatus result = 0;
        CVPixelBufferCreateWithBytes(kCFAllocatorDefault, width, height, pixFmt, data, bytesPerRow, NULL, NULL, NULL, &pixelBufRef);
        
        CMVideoFormatDescriptionRef videoInfo = NULL;
        
        result = CMVideoFormatDescriptionCreateForImageBuffer(NULL, pixelBufRef, &videoInfo);
        
        CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, pixelBufRef, true, NULL, NULL, videoInfo, &timimgInfo, &sout);
        
        CMItemCount sizeArrayEntries;
        CMSampleBufferGetSampleSizeArray(sout, 0, nil, &sizeArrayEntries);
        size_t *sizeArrayOut = malloc(sizeof(size_t) * sizeArrayEntries);
        CMSampleBufferGetSampleSizeArray(sout, sizeArrayEntries, sizeArrayOut, &sizeArrayEntries);
        
        free(sizeArrayOut);
        
        if(!CMSampleBufferIsValid(sout)){
            NSLog(@"");
        }
    }
    

    free(pInfo);
    free(sizeArrayOut);
    CFRelease(sampleBuffer);
    
    if(self.isVideo){
     //   NSLog(@"%@",sout);
    }
    return sout;
    
}
- (void)appendSample:(CMSampleBufferRef)sampleBuffer{
    @synchronized(self){
        
        if(self.isVideo){
           [self.sampleArray addObject:[VideoSample sampleFromCMSampleBuffer:sampleBuffer]];
        }else{
            CMSampleBufferRef sout = [self CMSampleBufferCreateCopyWithDeep:sampleBuffer];
            if(sout){
                [self.sampleArray addObject:(__bridge id)(sout)];
                CFRelease(sout);
            }
        
        }
        
    }
}

- (void)adjustTime:(CMTime)timeOffset{
    [self.sampleArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CMSampleBufferRef sampleBuffer = [self adjustTime:(__bridge CMSampleBufferRef )obj by: timeOffset];
        [self.sampleArray replaceObjectAtIndex:idx withObject:(__bridge id)sampleBuffer];
        
    }];
}

- (CMSampleBufferRef) adjustTime:(CMSampleBufferRef) sample by:(CMTime) offset{
    
    
    
    return sample;
}

@end

@implementation MovieSampleFragment

- (id)initWithTimeOffset:(CMTime)offset
{
    if(self = [super init]){
        
        self.videoSampleFragment = [SampleFragment new];
        self.videoSampleFragment.isVideo = YES;
        self.audioSampleFragment = [SampleFragment new];
        self.audioSampleFragment.isVideo = NO;
        
        
        self.videoTimeStamp = kCMTimeZero;
        self.audioTimeStamp = kCMTimeZero;
        self.timeOffset = offset;
    }
    return self;
}

- (void)writeToVideoInput:(AVAssetWriterInput *)videoWriterInput andAudioInput:(AVAssetWriterInput *)audioWriterInput;{
    self.videoSampleFragment.adaptor = self.adaptor;
    [self.videoSampleFragment writeToInput:videoWriterInput];
    [self.audioSampleFragment writeToInput:audioWriterInput];

}

- (void)adjustSampleTime:(CMTime)timeOffset{
    [self.videoSampleFragment adjustTime:timeOffset];
    [self.audioSampleFragment adjustTime:timeOffset];
}

- (void)appendSample:(CMSampleBufferRef)sampleBuffer isVideo:(BOOL)isVideo{
    
    if(isVideo){
        [self.videoSampleFragment appendSample:sampleBuffer];
    }else{
        [self.audioSampleFragment appendSample:sampleBuffer];
    }
    
}

- (void)reset{
    self.timeOffset = kCMTimeZero;
    self.videoTimeStamp = kCMTimeZero;
    self.audioTimeStamp = kCMTimeZero;
}

@end


@implementation MovieSampleFragmentMgr

- (id) initWithVideoInput:(AVAssetWriterInput *)videoWriterInput andAudioInput:(AVAssetWriterInput *)audioWriterInput{
    
    if(self = [super init]){
        self.videoWriterInput = videoWriterInput;
        self.audioWriterInput = audioWriterInput;
        self.fragmentArray = [NSMutableArray new];
    }
    return self;
}
- (void) addFragment:(MovieSampleFragment*)fragment{
    @synchronized(self){
        [self.fragmentArray addObject:fragment];
    }
    
}
- (void) removeFragmentAtIndex:(NSInteger)index{
    @synchronized(self){
        if(index < [self.fragmentArray count]){
            
            MovieSampleFragment* fragment = [self.fragmentArray objectAtIndex:index];
            CMTime timeOffset = fragment.timeOffset;
            
            //may be can use dispatch_apply to promto pref
            DefineWeakSelf();
            [self.fragmentArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                if(idx>=index){
                    MovieSampleFragment* fragment = [wself.fragmentArray objectAtIndex:index];
                    [fragment adjustSampleTime:timeOffset];
                }
                
            }];
            
            [self.fragmentArray removeObjectAtIndex:index];

        }
    }
    
}
- (void) writeToInputs:(FinishWriteBlock)block{
    @synchronized(self){
        
        self.finishBlock = block;
        for (MovieSampleFragment * fragment in self.fragmentArray) {
            fragment.adaptor = self.adaptor;
            [fragment writeToVideoInput:self.videoWriterInput andAudioInput:self.audioWriterInput];
        }
        if(self.finishBlock){
            self.finishBlock();
        }
    }
}
- (void) removeAll{
    @synchronized(self){
        [self.fragmentArray removeAllObjects];
    }
}
@end
