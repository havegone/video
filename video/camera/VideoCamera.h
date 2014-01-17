//
//  VideoCamera.h
//  video
//
//  Created by Tommy on 14-1-16.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import "Camera.h"

static CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};

@protocol SampleProcessDelegate <NSObject>

@optional

- (void)processImage:(UIImage*)image;
- (UIImage*)processSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end

@interface VideoCamera : Camera


@property (nonatomic,readonly) dispatch_queue_t sampleQueue;
@property (nonatomic,strong) AVCaptureVideoDataOutput   *videoDataOutput;
@property (nonatomic,strong) CALayer            *customPreviewLayer;


@property (nonatomic,weak) id delegate;

- (void) configure;


@end
