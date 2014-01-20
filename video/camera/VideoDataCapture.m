//
//  VideoCamera.m
//  video
//
//  Created by Tommy on 14-1-16.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import "VideoDataCapture.h"
//dispatch_semaphore_t

@interface VideoDataCapture ()<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    dispatch_semaphore_t _sampleSemaphore;
}

@end

@implementation VideoDataCapture

- (void) setDefaultValues{
    [super setDefaultValues];
    _sampleQueue = dispatch_queue_create("video.capture.queue", DISPATCH_QUEUE_SERIAL);
    _sampleSemaphore = dispatch_semaphore_create(1);
}


- (AVCaptureOutput*)createCameraOutput{
    
    
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc]init];

    self.videoDataOutput.videoSettings  = @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};
    
    // discard if the data output queue is blocked (as we process the still image)
    [self.videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    
    [[self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:YES];
    

    // set default FPS
    if ([self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo].supportsVideoMinFrameDuration) {
        [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo].videoMinFrameDuration = CMTimeMake(1, self.defaultFPS);
    }
    if ([self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo].supportsVideoMaxFrameDuration) {
        [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo].videoMaxFrameDuration = CMTimeMake(1, self.defaultFPS);
    }
    
    // set video mirroring for front camera (more intuitive)
    if ([self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo].supportsVideoMirroring) {
        if (self.cameraPosition == AVCaptureDevicePositionFront) {
            [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo].videoMirrored = YES;
        } else {
            [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo].videoMirrored = NO;
        }
    }
    
    // set default video orientation
    if ([self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo].supportsVideoOrientation) {
        [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo].videoOrientation = self.defaultAVCaptureVideoOrientation;
    }
    
    [self.videoDataOutput setSampleBufferDelegate:self queue:self.sampleQueue];

    if(self.settings){
        [self.videoDataOutput setVideoSettings:self.settings];
    }

    
    NSLog(@"[Camera] created AVCaptureVideoDataOutput at %d FPS", self.defaultFPS);
    
    return self.videoDataOutput;
}

- (void)createCustomVideoPreview{
    // create a custom preview layer
    if(!self.customPreviewLayer){
        self.customPreviewLayer = [CALayer layer];
        self.customPreviewLayer.bounds = CGRectMake(0, 0, self.parentView.frame.size.width, self.parentView.frame.size.height);
    }
    
    self.customPreviewLayer.contentsGravity = [self getPresentGravity];
    [self.parentView.layer addSublayer:self.customPreviewLayer];
    [self layoutPreviewLayer];
}


// TODO fix
- (void)layoutPreviewLayer;
{
    NSLog(@"layout preview layer");
    if (self.parentView != nil) {
        
        CALayer* layer = self.customPreviewLayer;
        CGRect bounds = self.customPreviewLayer.bounds;
        int rotation_angle = 0;
        bool flip_bounds = false;
        
        switch (self.currentDeviceOrientation) {
            case UIDeviceOrientationPortrait:
                rotation_angle = 270;
                break;
            case UIDeviceOrientationPortraitUpsideDown:
                rotation_angle = 90;
                break;
            case UIDeviceOrientationLandscapeLeft:
                NSLog(@"left");
                rotation_angle = 180;
                break;
            case UIDeviceOrientationLandscapeRight:
                NSLog(@"right");
                rotation_angle = 0;
                break;
            case UIDeviceOrientationFaceUp:
            case UIDeviceOrientationFaceDown:
            default:
                break; // leave the layer in its last known orientation
        }
        
        switch (self.defaultAVCaptureVideoOrientation) {
            case AVCaptureVideoOrientationLandscapeRight:
                rotation_angle += 180;
                break;
            case AVCaptureVideoOrientationPortraitUpsideDown:
                rotation_angle += 270;
                break;
            case AVCaptureVideoOrientationPortrait:
                rotation_angle += 90;
            case AVCaptureVideoOrientationLandscapeLeft:
                break;
            default:
                break;
        }
        rotation_angle = rotation_angle % 360;
        
        if (rotation_angle == 90 || rotation_angle == 270) {
            flip_bounds = true;
        }
        
        if (flip_bounds) {
            NSLog(@"flip bounds");
            bounds = CGRectMake(0, 0, bounds.size.height, bounds.size.width);
        }
        
        layer.position = CGPointMake(self.parentView.frame.size.width/2., self.parentView.frame.size.height/2.);
        layer.affineTransform = CGAffineTransformMakeRotation(DegreesToRadians(rotation_angle));
        layer.bounds = bounds;
    }
    
}


#pragma mark -
#pragma mark camera sample delegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    static int count = 0;
    NSLog(@"%d",count++);
    if (dispatch_semaphore_wait(_sampleSemaphore, DISPATCH_TIME_NOW)) {
        
        UIImage* image = nil;
        CGImageRef dstImage = nil;
        if ([self.delegate respondsToSelector:@selector(processSampleBuffer:)]) {
            image = [self.delegate processSampleBuffer:sampleBuffer];
        }
        
        if(!image){
            // convert from Core Media to Core Video
            CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
            CVPixelBufferLockBaseAddress(imageBuffer, 0);
            
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
            
            
            CGBitmapInfo bitmapInfo;
            colorSpace = CGColorSpaceCreateDeviceRGB();
            bitmapInfo = kCGImageAlphaPremultipliedFirst|kCGBitmapByteOrder32Little;
            
            context = CGBitmapContextCreate(bufferAddress, width, height, 8, bytesPerRow, colorSpace, bitmapInfo);
            dstImage = CGBitmapContextCreateImage(context);
            image = [UIImage imageWithCGImage:dstImage];
            CGContextRelease(context);
            
            
            CGColorSpaceRelease(colorSpace);
            CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
        }
        
        
        if ([self.delegate respondsToSelector:@selector(processImage:)]) {
            [self.delegate processImage:image];
        }
        
        
        if(self.customPreviewLayer && !self.useAVCaptureVideoPreviewLayer){
            // render buffer
            dispatch_sync(dispatch_get_main_queue(), ^{
                CGImageRef oldImage = (__bridge CGImageRef)(self.customPreviewLayer.contents);
                self.customPreviewLayer.contents = (__bridge id)[image CGImage];
                CGImageRelease(oldImage);
            });
        }else{
            CGImageRelease(dstImage);
        }
        
        
        dispatch_semaphore_signal (_sampleSemaphore);
        
    }

}

@end
