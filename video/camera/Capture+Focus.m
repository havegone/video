//
//  Camera+Focus.m
//  video
//
//  Created by Tommy on 14-1-17.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import "Capture.h"

@implementation Capture (Focus)

#pragma mark -
#pragma mark foucus/exposure/balance

- (void)lockFocus;
{
    AVCaptureDevice* device = self.cameraDevice;
    if ([device isFocusModeSupported:AVCaptureFocusModeLocked]) {
        NSError *error = nil;
        if ([device lockForConfiguration:&error]) {
            device.focusMode = AVCaptureFocusModeLocked;
            [device unlockForConfiguration];
        } else {
            NSLog(@"unable to lock device for locked focus configuration %@", [error localizedDescription]);
        }
    }
}

- (void) unlockFocus;
{
    AVCaptureDevice* device = self.cameraDevice;
    if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        NSError *error = nil;
        if ([device lockForConfiguration:&error]) {
            device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
            [device unlockForConfiguration];
        } else {
            NSLog(@"unable to lock device for autofocus configuration %@", [error localizedDescription]);
        }
    }
}

- (void)lockExposure
{
    AVCaptureDevice* device = self.cameraDevice;
    if ([device isExposureModeSupported:AVCaptureExposureModeLocked]) {
        NSError *error = nil;
        if ([device lockForConfiguration:&error]) {
            device.exposureMode = AVCaptureExposureModeLocked;
            [device unlockForConfiguration];
        } else {
            NSLog(@"unable to lock device for locked exposure configuration %@", [error localizedDescription]);
        }
    }
}

- (void) unlockExposure
{
    AVCaptureDevice* device = self.cameraDevice;
    if ([device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
        NSError *error = nil;
        if ([device lockForConfiguration:&error]) {
            device.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
            [device unlockForConfiguration];
        } else {
            NSLog(@"unable to lock device for autoexposure configuration %@", [error localizedDescription]);
        }
    }
}

- (void)lockBalance;
{
    AVCaptureDevice* device = self.cameraDevice;
    if ([device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeLocked]) {
        NSError *error = nil;
        if ([device lockForConfiguration:&error]) {
            device.whiteBalanceMode = AVCaptureWhiteBalanceModeLocked;
            [device unlockForConfiguration];
        } else {
            NSLog(@"unable to lock device for locked white balance configuration %@", [error localizedDescription]);
        }
    }
}

- (void) unlockBalance;
{
    AVCaptureDevice* device = self.cameraDevice;
    if ([device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
        NSError *error = nil;
        if ([device lockForConfiguration:&error]) {
            device.whiteBalanceMode = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance;
            [device unlockForConfiguration];
        } else {
            NSLog(@"unable to lock device for auto white balance configuration %@", [error localizedDescription]);
        }
    }
}

- (void) focusAtPoint:(CGPoint)point{
    
    AVCaptureDevice* device = self.cameraDevice;
    if(device && [device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]){
        NSError* error = nil;
        if([device lockForConfiguration:&error]){
            [device setFocusPointOfInterest:point];
            [device setFocusMode:AVCaptureFocusModeAutoFocus];
            [device unlockForConfiguration];
        }else{
            NSLog(@"error:%@",error);
        }
    }else{
        NSLog(@"not support focus at point");
    }
}

- (BOOL) isSupportFocusRange{
    AVCaptureDevice* device = self.cameraDevice;
    return [device isAutoFocusRangeRestrictionSupported];
}

- (void) setFocusDistance:(CGFloat)distance{
    if(distance <1.0){
        self.effectiveScale = 1.0f;
    }else{
        CGFloat maxScale = [self getMaxScaleAndCropFactor];
        if(distance > maxScale){
            self.effectiveScale = maxScale;
        }else{
            self.effectiveScale = distance;
        }
    }
    
    AVCaptureStillImageOutput* output = [self _queryStillImageOutput];
    AVCaptureConnection *videoConnection = [output connectionWithMediaType:AVMediaTypeVideo];
    videoConnection.videoScaleAndCropFactor = self.effectiveScale;
    
    
    [CATransaction begin];
    [CATransaction setAnimationDuration:.025];
    [self.previewLayer setAffineTransform:CGAffineTransformMakeScale(self.effectiveScale, self.effectiveScale)];
    [CATransaction commit];
}

- (AVCaptureStillImageOutput*)_queryStillImageOutput{
    AVCaptureStillImageOutput* stillImageOutput = nil;
    for (AVCaptureOutput* output in self.captureSession.outputs) {
        if( [output class] == [AVCaptureStillImageOutput class]){
            stillImageOutput = (AVCaptureStillImageOutput*)output;
            break;
        }
    }
    
    if(!stillImageOutput){
        stillImageOutput = (AVCaptureStillImageOutput*)[self.captureSession.outputs objectAtIndex:0];
    }
    
    return stillImageOutput;
}
- (CGFloat) getMaxScaleAndCropFactor{
    AVCaptureStillImageOutput* stillImageOutput = [self _queryStillImageOutput];
    AVCaptureConnection *videoConnection = [stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    return videoConnection.videoMaxScaleAndCropFactor;
}




@end
