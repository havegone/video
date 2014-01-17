//
//  Camera.h
//  video
//
//  Created by Tommy on 14-1-16.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class Camera;

typedef NS_ENUM(NSInteger, CameraPresetGravity) {
    CameraPresetGravityResizeAspect,
	CameraPresetGravityResizeAspectFill,
    CameraPresetGravityResize
};



@interface Camera : NSObject

@property (nonatomic,strong) AVCaptureSession       *captureSession;
@property (nonatomic,strong) AVCaptureInput         *cameraInput;
@property (nonatomic,strong) AVCaptureOutput        *cameraOutput;
@property (nonatomic,strong) AVCaptureConnection    *cameraConnection;
@property (nonatomic,strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic,strong,readonly)AVCaptureDevice *cameraDevice;

@property (nonatomic,assign) AVCaptureDevicePosition    cameraPosition;
@property (nonatomic,assign) AVCaptureVideoOrientation  defaultAVCaptureVideoOrientation;
@property (nonatomic,assign,readonly) UIDeviceOrientation        currentDeviceOrientation;
@property (nonatomic,strong) UIView                    *parentView;

@property (nonatomic,assign) BOOL                       useAVCaptureVideoPreviewLayer;
@property (nonatomic,strong) NSString *const            sessionPreset;
@property (nonatomic,assign) int                        defaultFPS;

@property (nonatomic,readonly) int imageWidth;
@property (nonatomic,readonly) int imageHeight;
@property (nonatomic,assign) CameraPresetGravity  presetGravity;  //default is CameraPresetGravityResizeAspectFill
@property (nonatomic,readonly,getter = isTorchOn) BOOL torchOn;
@property (nonatomic,readonly,getter = isFlashOn) BOOL flashOn;



+ (AVCaptureDevice*) cameraDeviceWithPosition:(AVCaptureDevicePosition)position;


- (id)initWithParentView:(UIView*)parent;

- (BOOL) isRunning;

- (void) start;
- (void) stop;
- (void) pause;
- (void) resume;

- (AVCaptureOutput*)    createOutput;
- (AVCaptureInput*)     createInput;
- (AVCaptureSession*)   createSession;
- (void) buildSession;

- (void) createVideoPreviewLayer;
- (void) createCustomVideoPreview;

- (void) switchCamera;
- (void) updateOrientation;

- (NSString* const) getPresentGravity;
- (NSArray*) supportFrameRateRange;


@end


@interface Camera (Focus)

- (void) lockFocus;
- (void) unlockFocus;
- (void) focusAtPoint:(CGPoint)point;
- (void) lockBalance;
- (void) unlockBalance;
- (void) lockExposure;
- (void) unlockExposure;

@end



@interface Camera (Torch)

- (void) turnOnTorchAndFlash:(BOOL)on;
- (BOOL) hasTorch;
- (void) turnOnTorch:(BOOL)on;
- (BOOL) hasFlash;
- (void) turnOnFlash:(BOOL)on;

@end

