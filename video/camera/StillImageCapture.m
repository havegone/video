//
//  ImageCamera.m
//  video
//
//  Created by Tommy on 14-1-17.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import "StillImageCapture.h"



@implementation StillImageCapture

- (AVCaptureOutput*) createOutput{
    
    AVCaptureStillImageOutput* output = [[AVCaptureStillImageOutput alloc]init];
    
    if(self.stillImageSettings){
        [output setOutputSettings:self.stillImageSettings];
    }
    self.cameraOutput = output;
    
    return self.cameraOutput;
}


- (void) takePicture:(CaptureImageBlock)block{
    self.captureImageBlock = block;
    AVCaptureStillImageOutput * output = (AVCaptureStillImageOutput*)self.cameraOutput;
    
    DefineWeakSelf();
    [output captureStillImageAsynchronouslyFromConnection:self.cameraConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        
        if (imageDataSampleBuffer == NULL) {
            if(wself.captureImageBlock){
                wself.captureImageBlock(nil,error);
            }
            return;
        }

        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        UIImage *image = [[UIImage alloc] initWithData:imageData];
        
        if(wself.captureImageBlock){
            wself.captureImageBlock(image,error);
        }
        
    }];
    
}

- (void) takePictureWithSampleBuffer:(CaptureImageBlock2)block{
    self.captureImageBlock2 = block;
    AVCaptureStillImageOutput * output = (AVCaptureStillImageOutput*)self.cameraOutput;
    
    DefineWeakSelf();
    [output captureStillImageAsynchronouslyFromConnection:self.cameraConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        
        if(wself.captureImageBlock2){
            wself.captureImageBlock2(imageDataSampleBuffer,error);
        }
        
    }];
}




@end
