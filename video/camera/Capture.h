//
//  Camera.h
//  video
//
//  Created by Tommy on 14-1-16.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


@protocol CaptureDelegate <NSObject>

@optional

- (void) captureVideoError:(NSError*)error;
- (void) captureVideoDidStart;
- (void) captureVideoDidStop;

@end

@class Capture;

typedef NS_ENUM(NSInteger, CameraPresetGravity) {
    CameraPresetGravityResizeAspect,
	CameraPresetGravityResizeAspectFill,
    CameraPresetGravityResize
};



@interface Capture : NSObject

@property (nonatomic,weak) id<CaptureDelegate>  delegate;

@property (nonatomic,strong) AVCaptureSession       *captureSession;
@property (nonatomic,strong) AVCaptureInput         *cameraInput;
@property (nonatomic,strong) AVCaptureInput         *audioInput;
@property (nonatomic,strong) AVCaptureOutput        *cameraOutput;
@property (nonatomic,strong) AVCaptureOutput        *audioOutput;
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
//
//default is CameraPresetGravityResizeAspectFill
//
@property (nonatomic,assign) CameraPresetGravity  presetGravity;

@property (nonatomic,readonly,getter = isTorchOn) BOOL torchOn;
@property (nonatomic,readonly,getter = isFlashOn) BOOL flashOn;
@property (nonatomic) CGFloat effectiveScale;



+ (AVCaptureDevice*) cameraDeviceWithPosition:(AVCaptureDevicePosition)position;

- (void) setDefaultValues;
- (id)initWithParentView:(UIView*)parent;

- (BOOL) isRunning;

- (void) start;
- (void) stop;
//- (void) pause;
//- (void) resume;

- (AVCaptureOutput*) createCameraOutput;
//default not implement. 
- (AVCaptureOutput*) createAudioOutput;
- (AVCaptureDeviceInput*) createCameraInput;
//default not implement.
- (AVCaptureDeviceInput*) createAudioInput;
//exclude camera output
- (NSArray*) createInputs;
- (NSArray*) createOutputs;
- (AVCaptureSession*) createSession;
- (void) buildSession;

- (void) createVideoPreviewLayer;
- (void) createCustomVideoPreview;

- (void) switchCamera;
- (void) updateOrientation;

- (NSString* const) getPresentGravity;
- (NSArray*) supportFrameRateRange;


@end


@interface Capture (Focus)

- (void) lockFocus;
- (void) unlockFocus;
- (void) focusAtPoint:(CGPoint)point;
- (void) lockBalance;
- (void) unlockBalance;
- (void) lockExposure;
- (void) unlockExposure;
- (BOOL) isSupportFocusRange;
- (void) setFocusDistance:(CGFloat)distance;
- (CGFloat) getMaxScaleAndCropFactor;

@end



@interface Capture (Torch)

- (void) turnOnTorchAndFlash:(BOOL)on;
- (BOOL) hasTorch;
- (BOOL) turnOnTorch:(BOOL)on;
- (BOOL) hasFlash;
- (void) turnOnFlash:(BOOL)on;

@end

