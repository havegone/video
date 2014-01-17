//
//  FirstViewController.m
//  video
//
//  Created by Tommy on 14-1-16.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import "FirstViewController.h"
#import "VideoDataCapture.h"
#import "MovieFileCapture.h"

@interface FirstViewController ()

@property (nonatomic,strong)Capture* camera;

@end

@implementation FirstViewController{
    UIButton* torchBtn;
    UIButton* recordBtn;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.camera = [[MovieFileCapture alloc]initWithParentView:self.view];
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
    
    
    recordBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    recordBtn.frame = CGRectMake(120,20, 50, 30);
    recordBtn.backgroundColor = [UIColor redColor];
    //    switchCameraBtn.titleLabel.text = @"switch";
    [recordBtn setTitle:@"start" forState:UIControlStateNormal];
    [recordBtn addTarget:self action:@selector(recordHandler) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:recordBtn];
    
    
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
- (void)recordHandler{
    static BOOL record = NO;
    record = !record;
    if(record){
        [recordBtn setTitle:@"stop" forState:UIControlStateNormal];
        [self.camera start];
    }else{
        [recordBtn setTitle:@"start" forState:UIControlStateNormal];
        [self.camera stop];
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
//    [self.camera start];
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
