//
//  VideoDataCapture+SupportScaleCrop.m
//  ISearch
//
//  Created by Tommy on 14-3-12.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import "VideoDataCapture+SupportScaleCrop.h"

@implementation VideoDataCapture (SupportScaleCrop)



- (NSArray*) createOutputs{
    
    AVCaptureStillImageOutput * stillImageOutput = [AVCaptureStillImageOutput new];

    return @[stillImageOutput];
}


@end
