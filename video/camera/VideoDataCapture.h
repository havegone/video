//
//  VideoCamera.h
//  video
//
//  Created by Tommy on 14-1-16.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import "Capture.h"

#define DegreesToRadians(degrees) ((CGFloat)degrees * M_PI / 180)

@protocol SampleProcessDelegate;

@interface VideoDataCapture : Capture

@property (nonatomic,readonly) dispatch_queue_t sampleQueue;
@property (nonatomic,strong) AVCaptureVideoDataOutput   *videoDataOutput;
@property (nonatomic,strong) CALayer            *customPreviewLayer;

@property (nonatomic,copy) NSDictionary* settings;
@property (nonatomic,weak) id delegate;

- (void) configure;


@end



@protocol SampleProcessDelegate <NSObject>

@optional
- (void)processImage:(UIImage*)image;
- (UIImage*)processSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end
