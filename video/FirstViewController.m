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
#import "MovieEncoder.h"
#import "AVRecorder.h"

UIImageView * g_imageView;



@interface FirstViewController ()

@property (nonatomic,strong)AVRecorder* recorder;


@end

@implementation FirstViewController{
    UIButton* torchBtn;
    UIButton* recordBtn;
    UIButton* pauseBtn;
    UIButton* muteBtn;
    
    UIImageView* _imageView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
//    self.camera = [[MovieFileCapture alloc]initWithParentView:self.view];
//    self.camera = [[VACapture alloc]initWithParentView:self.view];
//    self.camera = [[VideoDataCapture alloc]initWithParentView:self.view];
//    self.camera.defaultFPS = 15;
//    self.camera.sessionPreset = AVCaptureSessionPreset640x480;
//    self.camera.presetGravity = CameraPresetGravityResize;
//    self.camera.useAVCaptureVideoPreviewLayer = NO;
    NSString* path = nil;
//    self.camera.encoder = [[MovieEncoder alloc]initWithPath:path statusChangeBlock:^(MovieEncoderStatus status){
//        NSLog(@"status:%d",status);
//    }];
//    [self.camera buildSession];
    
    self.recorder = [[AVRecorder alloc]initWithParentView:self.view andEncoder:[[MovieEncoder alloc]initWithPath:[AVRecorder genFilePath] statusChangeBlock:^(MovieEncoderStatus status){
        NSLog(@"status:%d",status);
    }]];
    [self.recorder buildSession];

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
    
    
    pauseBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    pauseBtn.frame = CGRectMake(200,20, 50, 30);
    pauseBtn.backgroundColor = [UIColor blueColor];
    //    switchCameraBtn.titleLabel.text = @"switch";
    [pauseBtn setTitle:@"pause" forState:UIControlStateNormal];
    [pauseBtn addTarget:self action:@selector(pauseHandler) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:pauseBtn];
    
    
    muteBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    muteBtn.frame = CGRectMake(260,20, 50, 30);
    muteBtn.backgroundColor = [UIColor blueColor];
    //    switchCameraBtn.titleLabel.text = @"switch";
    [muteBtn setTitle:@"no" forState:UIControlStateNormal];
    [muteBtn addTarget:self action:@selector(muteHandler) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:muteBtn];
    
     _imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 50, 100, 100)];
    [_imageView setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:_imageView];

    g_imageView = _imageView;
    
  
}

- (void)torchHandler{
    static BOOL torchOn = NO;
    torchOn = !torchOn;
    [self.recorder turnOnTorchAndFlash:torchOn];
}
- (void)switchCameraHandler{
    [self.recorder switchCamera];
   
    [torchBtn setEnabled:[self.recorder hasTorch]];
}
- (void)recordHandler{
    static BOOL record = NO;
    record = !record;
    if(record){
        [recordBtn setTitle:@"stop" forState:UIControlStateNormal];
//        [self.camera generateFilePath];
//        [self.camera startRecord:nil];
        
        
        [self.recorder startRecord];
    }else{
        [recordBtn setTitle:@"start" forState:UIControlStateNormal];
        [self.recorder stopRecord];
//        [self.camera stopRecord:nil];
    }
}
- (void)pauseHandler{
    static BOOL record = NO;
    record = !record;
    if(record){
        [self.recorder pauseRecord];
//        if([self.camera pauseRecord])
            [pauseBtn setTitle:@"resume" forState:UIControlStateNormal];

    }else{
        [self.recorder resumeRecord];
        //if([self.camera resumeRecord])
            [pauseBtn setTitle:@"pause" forState:UIControlStateNormal];
    }
}
- (void)muteHandler{
    static BOOL mute = NO;
    mute = !mute;
    if(mute){

            [muteBtn setTitle:@"not" forState:UIControlStateNormal];
        
    }else{

            [muteBtn setTitle:@"mute" forState:UIControlStateNormal];
    }
//    [self.camera enableMute:mute];
}


- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
//    [self.camera start];
//    [self.camera resumeRecord];
    //[self.camera turnOnFlash:YES];
//    [self.camera switchCamera];
//    [self.camera turnOnTorchAndFlash:YES];
    
    [self.recorder start];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
//    [self.camera turnOnTorchAndFlash:NO];
//    [self.camera pauseRecord];
//    [self.camera stop];
    
    [self.recorder stop];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
