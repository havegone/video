//
//  Camera+Torch.m
//  video
//
//  Created by Tommy on 14-1-17.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import "Capture.h"
@interface Capture ()
@property (readwrite) BOOL torchOn;
@property (readwrite) BOOL flashOn;
@end

@implementation Capture(Torch)

- (void) turnOnTorchAndFlash:(BOOL)on{
    
    AVCaptureDevice* device = self.cameraDevice;
    if ([device hasTorch] && [device hasFlash] && [device isTorchAvailable] && [device isFlashAvailable]){
        
        [self.cameraDevice lockForConfiguration:nil];
        if (on) {
            [device setTorchMode:AVCaptureTorchModeOn];
            [device setFlashMode:AVCaptureFlashModeOn];
            self.torchOn = YES;
            self.flashOn = YES;
        } else {
            [device setTorchMode:AVCaptureTorchModeOff];
            [device setFlashMode:AVCaptureFlashModeOff];
            self.torchOn = NO;
            self.flashOn = NO;
            
        }
        [device unlockForConfiguration];
    }
    
}


- (BOOL) hasTorch{
    return [self.cameraDevice hasTorch];
}


- (void) turnOnTorch:(BOOL)on{
    AVCaptureDevice* device = self.cameraDevice;
    if ([device hasTorch] && [device isTorchAvailable]){
        
        [self.cameraDevice lockForConfiguration:nil];
        if (on) {
            [device setTorchMode:AVCaptureTorchModeOn];
            self.torchOn = YES;
        } else {
            [device setTorchMode:AVCaptureTorchModeOff];
            self.torchOn = NO;
        }
        [device unlockForConfiguration];
    }
    
}
- (BOOL) hasFlash{
    return [self.cameraDevice hasFlash];
}
- (void) turnOnFlash:(BOOL)on{
    AVCaptureDevice* device = self.cameraDevice;
    if ([device hasFlash]&& [device isFlashAvailable]){
        
        [self.cameraDevice lockForConfiguration:nil];
        if (on) {
            [device setFlashMode:AVCaptureFlashModeOn];
            self.flashOn = YES;
        } else {
            [device setFlashMode:AVCaptureFlashModeOff];
            self.flashOn = NO;
        }
        [device unlockForConfiguration];
    }
}

- (BOOL) isTorchOn{
    return self.torchOn;
}
- (BOOL) isFlashOn{
    return self.flashOn;
}

@end
