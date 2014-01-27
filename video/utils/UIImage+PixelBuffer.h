//
//  UIImage+PixelBuffer.h
//  video
//
//  Created by Tommy on 14-1-27.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>

@interface UIImage (PixelBuffer)

+ (CGBitmapInfo) bitmapInfoFromPixelBuffer:(CVPixelBufferRef)pixelBuffer;
+ (UIImage*)imageWithPixelBuffer:(CVPixelBufferRef)pixelBuffer;
+ (CGImageRef)imageFromPixelBuffer:(CVPixelBufferRef)pixelBuffer;
+ (UIImage*)imageWithCMSampleBuffer:(CMSampleBufferRef)sampleBuffer;
+ (CGImageRef) imageFromCMSampleBuffer:(CMSampleBufferRef)sampleBuffer;

- (CVPixelBufferRef)pixelBuffer;


@end


CVPixelBufferRef pixelBufferFromCGImage(CGImageRef image);