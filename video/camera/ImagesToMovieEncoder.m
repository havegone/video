//
//  ImagesToMovieEncoder.m
//  video
//
//  Created by Tommy on 14-1-27.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import "ImagesToMovieEncoder.h"
#import "UIImage+PixelBuffer.h"

//http://blog.csdn.net/zengconggen/article/details/7595449
//http://blog.csdn.net/linzhiji/article/details/6736704
//http://blog.csdn.net/linzhiji/article/details/6735282
//http://stackoverflow.com/questions/16475737/convert-uiimage-to-cmsamplebufferref
//http://stackoverflow.com/questions/3741323/how-do-i-export-uiimage-array-as-a-movie/3742212#3742212

@implementation ImagesToMovieEncoder

- (void)setupVideoWriterInput{
    [super setupVideoWriterInput];
    self.videoWriterInput.expectsMediaDataInRealTime = NO;
}

- (void)setupWriter{
    [super setupWriter];
    self.adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.videoWriterInput
                                                     sourcePixelBufferAttributes:nil];
}

- (void)start:(MovieEncoderStatusChangeBlock)statusChangeBlock{
    [self setupWriter];
    self.statusChangeBlock = statusChangeBlock;
    
    NSAssert(0, @"");
    
//    dispatch_block_t
    DefineWeakSelf();
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [wself imagesToMovie];
        if([self.writer respondsToSelector:@selector(finishWritingWithCompletionHandler:)]){
            [self.writer performSelector:@selector(finishWritingWithCompletionHandler:)withObject:nil];
        }else{
            [self.writer performSelector:@selector(finishWriting) withObject:nil];
            if(wself.statusChangeBlock){
                wself.statusChangeBlock(wself,MovieEncoderStatusStart);
            }
        }
    });
}

- (id)initWithImages:(NSArray*)images toFile:(NSString*)filePath withDurarion:(NSInteger)duration andFPS:(NSInteger)fps andSize:(CGSize)size{
    if(self = [super initWithPath:filePath statusChangeBlock:nil]){
        self.images = images;
        self.fps = fps;
        self.size = size;
        self.duration = duration;
    }
    
    return self;
}


- (void)imagesToMovie{
    
    //Start a session:
    [self.writer startWriting];
    [self.writer startSessionAtSourceTime:kCMTimeZero];
    
    int frameCount = 0;
    
    int imagesCount = [self.images count];
    float averageTime = self.duration/imagesCount;
    int averageFrame = (int)(averageTime * self.fps);
    
    for(UIImage* img in self.images)
    {

        CVPixelBufferRef pixelBuff = [img pixelBuffer];
        BOOL append_ok = NO;
        int j = 0;
        while (!append_ok && j < 30)
        {
            if (self.adaptor.assetWriterInput.readyForMoreMediaData)
            {
                CMTime frameTime = CMTimeMake(frameCount,(int32_t) self.fps);
                float frameSeconds = CMTimeGetSeconds(frameTime);
                NSLog(@"frameCount:%d,kRecordingFPS:%d,frameSeconds:%f",frameCount,self.fps,frameSeconds);
                append_ok = [self.adaptor appendPixelBuffer:pixelBuff withPresentationTime:frameTime];
                
    
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
    [self.videoWriterInput markAsFinished];

}

@end
