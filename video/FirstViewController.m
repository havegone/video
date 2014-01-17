//
//  FirstViewController.m
//  video
//
//  Created by Tommy on 14-1-16.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import "FirstViewController.h"
#import "VideoCamera.h"

@interface FirstViewController ()

@property (nonatomic,strong)Camera* camera;

@end

@implementation FirstViewController{
    UIButton* torchBtn;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.camera = [[VideoCamera alloc]initWithParentView:self.view];
    self.camera.defaultFPS = 25;
    self.camera.sessionPreset = AVCaptureSessionPreset1280x720;
//    self.camera.presetGravity = CameraPresetGravityResize;
//    self.camera.useAVCaptureVideoPreviewLayer = NO;
    [self.camera buildSession];

    //self.camera.useAVCaptureVideoPreviewLayer = NO;
    
    
    torchBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    torchBtn.frame = CGRectMake(0,20, 50, 30);
   // torchBtn.backgroundColor = [UIColor redColor];
//     torchBtn.titleLabel.text = @"torch";
    [torchBtn setTitle:@"torch" forState:UIControlStateNormal];
   
    [torchBtn addTarget:self action:@selector(torchHandler) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:torchBtn];
    
    
    UIButton* switchCameraBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    switchCameraBtn.frame = CGRectMake(70,20, 50, 30);
//    switchCameraBtn.backgroundColor = [UIColor redColor];
//    switchCameraBtn.titleLabel.text = @"switch";
    [switchCameraBtn setTitle:@"switch" forState:UIControlStateNormal];
    [switchCameraBtn addTarget:self action:@selector(switchCameraHandler) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:switchCameraBtn];
    
    
}

- (void)torchHandler{
    static BOOL torchOn = NO;
    torchOn = !torchOn;
    [self.camera turnOnTorchAndFlash:torchOn];
}
- (void)switchCameraHandler{
    [self.camera switchCamera];
   
    [torchBtn setEnabled:[self.camera hasTorch]];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.camera start];
    //[self.camera turnOnFlash:YES];
//    [self.camera switchCamera];
//    [self.camera turnOnTorchAndFlash:YES];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
//    [self.camera turnOnTorchAndFlash:NO];
    [self.camera stop];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
