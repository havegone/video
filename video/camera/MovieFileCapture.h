//
//  FileCamera.h
//  video
//
//  Created by Tommy on 14-1-17.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import "Capture.h"

@interface MovieFileCapture : Capture<AVCaptureFileOutputRecordingDelegate>


@property (nonatomic,strong)AVCaptureDeviceInput *audioInput;
@property (nonatomic,strong)AVCaptureFileOutput *fileOutput;
@property (nonatomic,strong)NSString            *filePath;

- (NSString*)generatePath;
- (AVCaptureDeviceInput*)createAudioInput;

@end
