//
//  UIImage+PixelBuffer.m
//  video
//
//  Created by Tommy on 14-1-27.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import "UIImage+PixelBuffer.h"

@implementation UIImage (PixelBuffer)


+ (CGBitmapInfo) bitmapInfoFromPixelBuffer:(CVPixelBufferRef)pixelBuffer{
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedFirst|kCGBitmapByteOrder32Little;
    OSType pixelFormatType = CVPixelBufferGetPixelFormatType(pixelBuffer);
    switch(pixelFormatType)
    {
        case kCVPixelFormatType_24RGB:
            break;
        case kCVPixelFormatType_24BGR:
            break;
        case kCVPixelFormatType_32ARGB:
            bitmapInfo = kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big;
            break;
        case kCVPixelFormatType_32BGRA:
            bitmapInfo = kCGImageAlphaPremultipliedFirst|kCGBitmapByteOrder32Little;
            break;
        case kCVPixelFormatType_32ABGR:
            bitmapInfo = kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Little;
            break;
        case kCVPixelFormatType_32RGBA:
            bitmapInfo = kCGImageAlphaPremultipliedFirst|kCGBitmapByteOrder32Big;
            break;
            
    }
    
    return bitmapInfo;
}

+ (UIImage*)imageWithPixelBuffer:(CVPixelBufferRef)pixelBuffer{
    CGImageRef image = [UIImage imageFromPixelBuffer:pixelBuffer];
    return [UIImage imageWithCGImage:image];
}

+ (CGImageRef) imageFromPixelBuffer:(CVPixelBufferRef)imageBuffer{
    
    CGBitmapInfo bitmapInfo = [UIImage bitmapInfoFromPixelBuffer:imageBuffer];
    
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    CGImageRef image = nil;
    
    void* bufferAddress;
    size_t width;
    size_t height;
    size_t bytesPerRow;
    
    CGColorSpaceRef colorSpace;
    CGContextRef context;
    
    bufferAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    width = CVPixelBufferGetWidth(imageBuffer);
    height = CVPixelBufferGetHeight(imageBuffer);
    bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    
    colorSpace = CGColorSpaceCreateDeviceRGB();
    context = CGBitmapContextCreate(bufferAddress, width, height, 8, bytesPerRow, colorSpace, bitmapInfo);
    
    image = CGBitmapContextCreateImage(context);
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    return image;
}

+ (UIImage*)imageWithCMSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    return [UIImage imageWithPixelBuffer:pixelBuffer];
}

+ (CGImageRef) imageFromCMSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    return [UIImage imageFromPixelBuffer:pixelBuffer];
}


- (CVPixelBufferRef)pixelBuffer{
    return  pixelBufferFromCGImage(self.CGImage);
}

CVPixelBufferRef pixelBufferFromCGImage(CGImageRef image){
    CVPixelBufferRef pxbuffer = NULL;
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    
    size_t width =  CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    size_t bytesPerRow = CGImageGetBytesPerRow(image);
    
    
    CFDataRef  dataFromImageDataProvider = CGDataProviderCopyData(CGImageGetDataProvider(image));
    GLubyte  *imageData = (GLubyte *)CFDataGetBytePtr(dataFromImageDataProvider);
    
    CVPixelBufferCreateWithBytes(kCFAllocatorDefault,width,height,kCVPixelFormatType_32BGRA,imageData,bytesPerRow,NULL,NULL,(__bridge CFDictionaryRef)options,&pxbuffer);
    
    CFRelease(dataFromImageDataProvider);
    
    return pxbuffer;
}


@end
