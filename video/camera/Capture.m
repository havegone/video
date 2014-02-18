//
//  Camera.m
//  video
//
//  Created by Tommy on 14-1-16.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import "Capture.h"


@interface Capture (){
   
    BOOL _cameraAvailable;
    BOOL _sessionBuilt;
}

@property(assign) BOOL running;
@property (readwrite) BOOL torchOn;
@property (readwrite) BOOL flashOn;
@property (readwrite) UIDeviceOrientation currentDeviceOrientation;

@end

@implementation Capture
//@synthesize torchOn = _torchOn;
//@synthesize flashOn = _flashOn;
//@synthesize currentDeviceOrientation = _currentDeviceOrientation;


+ (AVCaptureDevice*) cameraDeviceWithPosition:(AVCaptureDevicePosition)position{
    
    NSArray* devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice* device in devices) {
        if([device position] == position){
            return device;
        }
    }
    
    return [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
}

- (void) setDefaultValues{
    // react to device orientation notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceOrientationDidChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    self.currentDeviceOrientation = [[UIDevice currentDevice] orientation];
    
    
    // check if camera available
    _cameraAvailable = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
    NSLog(@"camera available: %@", (_cameraAvailable == YES ? @"YES" : @"NO") );
    
    self.running = NO;
    
    // set camera default configuration
    self.cameraPosition = AVCaptureDevicePositionBack;
    self.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.defaultFPS = 20;
    self.sessionPreset = AVCaptureSessionPreset640x480;
    self.presetGravity = CameraPresetGravityResizeAspectFill;
    
    
    self.parentView = nil;
    self.useAVCaptureVideoPreviewLayer = NO;
    
    
    _sessionBuilt = NO;
}

- (id)init;
{
    self = [super init];
    if (self) {
        [self setDefaultValues];
    }
    return self;
}

- (id)initWithParentView:(UIView*)parent
{
    self = [super init];
    if (self) {
        
        [self setDefaultValues];
        
        self.parentView = parent;
        self.useAVCaptureVideoPreviewLayer = YES;
    }
    return self;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}


#pragma mark -
#pragma mark configure

- (void)createVideoPreviewLayer
{
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    
    if ([self.previewLayer isOrientationSupported]) {
        [self.previewLayer setOrientation:self.defaultAVCaptureVideoOrientation];
    }
    
    if (self.parentView != nil) {
        self.previewLayer.frame = self.parentView.bounds;
        self.previewLayer.videoGravity = [self getPresentGravity];
        [self.parentView.layer addSublayer:self.previewLayer];
    }
    NSLog(@"[Camera] created AVCaptureVideoPreviewLayer");
}

- (void) createCustomVideoPreview{
    [NSException raise:NSInternalInconsistencyException
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}


- (AVCaptureOutput*) createCameraOutput{
    [NSException raise:NSInternalInconsistencyException
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
    return nil;
}

- (AVCaptureOutput*) createAudioOutput{
    return nil;
}

- (AVCaptureDeviceInput*) createCameraInput{
    NSError *error = nil;
    AVCaptureDevice *device = [Capture cameraDeviceWithPosition:self.cameraPosition];
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    
    if(!input){
        NSErrorLog(error);
    }else{
        _cameraDevice = device;
    }
    
    return input;
}

- (AVCaptureDeviceInput*)     createAudioInput{
    return nil;
}
- (NSArray*) createInputs{
//    [NSException raise:NSInternalInconsistencyException
//                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
    return nil;
}
- (AVCaptureSession*) createSession{
    
    AVCaptureSession *session = [[AVCaptureSession alloc]init];
    
    if ([session canSetSessionPreset:self.sessionPreset]) {
        [session setSessionPreset:self.sessionPreset];
    } else if ([session canSetSessionPreset:AVCaptureSessionPresetLow]) {
        [session setSessionPreset:AVCaptureSessionPresetLow];
    } else {
        NSLog(@"[Camera] Error: could not set session preset");
    }
    
    return session;
}
//below ios7 set fps in connection
//avaliable from ios7,
- (void) configureFPSForDevice:(AVCaptureDevice*)device{
    
    [device lockForConfiguration:nil];
    
    device.activeVideoMaxFrameDuration = CMTimeMake(1, self.defaultFPS);;
    device.activeVideoMinFrameDuration = CMTimeMake(1, self.defaultFPS);;
    
    [device unlockForConfiguration];
    
}

- (void) buildSession{
    
    AVCaptureDeviceInput* camerainput = [self createCameraInput];
    AVCaptureDeviceInput* audioInput = [self createAudioInput];
    AVCaptureOutput* cameraOutput = [self createCameraOutput];
    AVCaptureOutput* audioOutput = [self createAudioOutput];
    AVCaptureSession* session = [self createSession];
    NSArray * inputs = [self createInputs];
    
    
    [session beginConfiguration];
    
    for (AVCaptureDeviceInput * tmpInput in inputs) {
        if([camerainput device]!=[tmpInput device] && [camerainput device] != [audioInput device] && [session canAddInput:tmpInput] ){
           [session addInput:tmpInput];
            if([[tmpInput device] hasMediaType:AVMediaTypeVideo]){
                self.cameraInput = camerainput;
                [self configureFPSForDevice:self.cameraDevice];
            }
        }
    }
    
    if(camerainput && [session canAddInput:camerainput]){
        [session addInput:camerainput];
        self.cameraInput = camerainput;
        [self configureFPSForDevice:self.cameraDevice];
    }
    
    if(audioInput && [session canAddInput:audioInput]){
        [session addInput:audioInput];
        self.audioInput = audioInput;
    }
    
    if(cameraOutput && [session canAddOutput:cameraOutput]){
        [session addOutput:cameraOutput];
        self.cameraOutput = cameraOutput;
    }
    
    if(audioOutput && [session canAddOutput:audioOutput]){
        [session addOutput:audioOutput];
        self.audioOutput = audioOutput;
    }
    [session commitConfiguration];
    
    self.captureSession = session;
    
    // setup preview layer
    if (self.useAVCaptureVideoPreviewLayer) {
        [self createVideoPreviewLayer];
    } else {
        [self createCustomVideoPreview];
       
    }
    
    [self resetConnection];
    

    _sessionBuilt = YES;
}

- (void) resetConnection{
    for (AVCaptureConnection *connection in self.cameraOutput.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([port.mediaType isEqual:AVMediaTypeVideo]) {
                self.cameraConnection = connection;
                [self configureConntion];
                break;
            }
        }
        if (self.cameraConnection) {
            break;
        }
    }
}

- (void) configureConntion{
    if(self.cameraConnection){

        
        if (self.cameraPosition == AVCaptureDevicePositionFront) {
            self.cameraConnection.videoMirrored = YES;
        } else {
            self.cameraConnection.videoMirrored = NO;
        }
        
        if([self.cameraConnection isVideoOrientationSupported]){
            self.cameraConnection.videoOrientation = self.defaultAVCaptureVideoOrientation;
        }
        
        if([self.cameraConnection isVideoStabilizationSupported]){
            self.cameraConnection.enablesVideoStabilizationWhenAvailable = YES;
        }
        
//        if([self.cameraConnection isVideoMaxFrameDurationSupported]){
//            
//        }
        if (self.cameraConnection.supportsVideoMinFrameDuration) {
            self.cameraConnection.videoMinFrameDuration = CMTimeMake(1, self.defaultFPS);
        }
        if (self.cameraConnection.supportsVideoMaxFrameDuration) {
            self.cameraConnection.videoMaxFrameDuration = CMTimeMake(1, self.defaultFPS);
        }
    }
    
}

//- (void) setPresetGravity:(CameraPresetGravity)gravity{
//    if(gravity != _presetGravity){
//        _presetGravity = gravity;
//    }
//}

- (NSString* const) getPresentGravity{
    NSString* gravity = nil;
    switch (_presetGravity) {
        case CameraPresetGravityResizeAspect:
            gravity = self.useAVCaptureVideoPreviewLayer?AVLayerVideoGravityResizeAspect:kCAGravityResizeAspect;
            break;
        case CameraPresetGravityResizeAspectFill:
            gravity = self.useAVCaptureVideoPreviewLayer?AVLayerVideoGravityResizeAspectFill:kCAGravityResizeAspectFill;
            break;
        case CameraPresetGravityResize:
            gravity = self.useAVCaptureVideoPreviewLayer?AVLayerVideoGravityResize:kCAGravityResize;
            break;
            
        default:
            gravity = self.useAVCaptureVideoPreviewLayer?AVLayerVideoGravityResizeAspectFill:kCAGravityResizeAspectFill;
            break;
    }

    return gravity;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    
}


#pragma mark -

- (BOOL) isRunning{
    return _running;
}
#pragma mark - Device Orientation Changes


- (void)deviceOrientationDidChange:(NSNotification*)notification
{
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    
    switch (orientation)
    {
        case UIDeviceOrientationPortrait:
        case UIDeviceOrientationPortraitUpsideDown:
        case UIDeviceOrientationLandscapeLeft:
        case UIDeviceOrientationLandscapeRight:
            self.currentDeviceOrientation = orientation;
            break;
            
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationFaceDown:
        default:
            break;
    }
    NSLog(@"deviceOrientationDidChange: %d", orientation);
    
    [self updateOrientation];
}
- (void)updateOrientation;
{
    // nothing to do here
}


- (void)updateSize;
{
    if ([self.sessionPreset isEqualToString:AVCaptureSessionPresetPhoto]) {
        //TODO: find the correct resolution
        _imageWidth = 640;
        _imageHeight = 480;
    } else if ([self.sessionPreset isEqualToString:AVCaptureSessionPresetHigh]) {
        //TODO: find the correct resolution
        _imageWidth = 640;
        _imageHeight = 480;
    } else if ([self.sessionPreset isEqualToString:AVCaptureSessionPresetMedium]) {
        //TODO: find the correct resolution
        _imageWidth = 640;
        _imageHeight = 480;
    } else if ([self.sessionPreset isEqualToString:AVCaptureSessionPresetLow]) {
        //TODO: find the correct resolution
        _imageWidth = 640;
        _imageHeight = 480;
    } else if ([self.sessionPreset isEqualToString:AVCaptureSessionPreset352x288]) {
        _imageWidth = 352;
        _imageHeight = 288;
    } else if ([self.sessionPreset isEqualToString:AVCaptureSessionPreset640x480]) {
        _imageWidth = 640;
        _imageHeight = 480;
    } else if ([self.sessionPreset isEqualToString:AVCaptureSessionPreset1280x720]) {
        _imageWidth = 1280;
        _imageHeight = 720;
    } else {
        _imageWidth = 640;
        _imageHeight = 480;
    }
}


#pragma mark -
#pragma mark session


- (void) start{
    if(![self isRunning]){
        [self updateSize];
        
        if(!_sessionBuilt){
            [self buildSession];
        }
        DefineWeakSelf();
        dispatch_async(dispatch_get_main_queue(), ^{
            [wself.captureSession startRunning];
            wself.running = YES;
        });
    }
}
- (void) stop{
    if([self isRunning]){
        DefineWeakSelf();
        dispatch_async(dispatch_get_main_queue(), ^{
            [wself.captureSession stopRunning];
            wself.running = NO;
        });
    }
    
}
//- (void) pause{
//    [self stop];
//}
//- (void) resume{
//    [self start];
//}


- (void) switchCamera{
    if(self.cameraPosition == AVCaptureDevicePositionBack){
        self.cameraPosition = AVCaptureDevicePositionFront;
    }else{
        self.cameraPosition = AVCaptureDevicePositionBack;
    }
    NSError *error = nil;
    AVCaptureDevice *device = [Capture cameraDeviceWithPosition:self.cameraPosition];
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    
   
    // support for autofocus
    if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        NSError *error = nil;
        if ([device lockForConfiguration:&error]) {
            device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
            [device unlockForConfiguration];
        } else {
            NSLog(@"unable to lock device for autofocos configuration %@", [error localizedDescription]);
        }
    }
    
    if(input){
        [self.captureSession beginConfiguration];
        [self.captureSession removeInput:self.cameraInput];
        if([self.captureSession canAddInput:input]){
            _cameraDevice = device;
            [self.captureSession addInput:input];
            [self configureFPSForDevice:self.cameraDevice];
            self.cameraInput = input;
        }else{
            [self.captureSession addInput:self.cameraInput];
            NSLog(@"switch camera failed");
        }
        [self.captureSession commitConfiguration];
        [self resetConnection];
    }else{
        NSErrorLog(error);
    }
    
}



- (NSArray*) supportFrameRateRange{
    return self.cameraDevice.activeFormat.videoSupportedFrameRateRanges;
}
@end
