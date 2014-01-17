//
//  ImageCamera.h
//  video
//
//  Created by Tommy on 14-1-17.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import "Capture.h"

typedef void(^CaptureImageBlock) (UIImage* image,NSError*error);
typedef void(^CaptureImageBlock2) (CMSampleBufferRef imageBuffer,NSError*error);

@interface StillImageCapture : Capture

@property (nonatomic,copy) NSDictionary* stillImageSettings;
@property (nonatomic,copy) CaptureImageBlock captureImageBlock;
@property (nonatomic,copy) CaptureImageBlock2 captureImageBlock2;

- (void) takePicture:(CaptureImageBlock)block;
- (void) takePictureWithSampleBuffer:(CaptureImageBlock2)block;

@end
