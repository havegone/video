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
#import "AVSegmentRecorder.h"

UIImageView * g_imageView;



@interface FirstViewController ()

@property (nonatomic,strong)AVSegmentRecorder* recorder;
@property (nonatomic,strong)NSString*  filePath;

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
    
    DefineWeakSelf();
    
    self.filePath = [AVRecorder genFilePath];
    
//    self.recorder = [[AVRecorder alloc]initWithParentView:self.view andEncoder:[[MovieEncoder alloc]initWithPath:self.filePath statusChangeBlock:^(MovieEncoder*encoder, MovieEncoderStatus status){
//        
//        switch (status) {
//            case MovieEncoderStatusStop:
//                NSLog(@"stop duration:%f",[wself.recorder duration]);
//                [wself queryMovieDuration];
//                break;
//            case MovieEncoderStatusPause:
//                NSLog(@"pause duration:%f",[wself.recorder duration]);
//                break;
//                
//            default:
//                break;
//        }
//
//        NSLog(@"status:%d",status);
//    }]];
//    
    
    
    
    
    
    
    self.recorder = [[AVSegmentRecorder alloc]initWithParentView:self.view andFilePath:self.filePath];
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
        
        self.recorder.filePath = [AVRecorder genFilePath];
        [self.recorder startRecord];
    }else{
        [recordBtn setTitle:@"start" forState:UIControlStateNormal];
        [self.recorder stopRecord];
//        recordBtn.enabled = NO;
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
//    NSDocumentDirectory
   
    
    NSMutableArray* files = [NSMutableArray new];
                        
    //枚举目录中的内容
    NSArray *dirArray;
    NSFileManager *fm = [[NSFileManager alloc]init];
    NSString *dirPath = NSTemporaryDirectory();//[fm currentDirectoryPath];  //当前目录
    NSDirectoryEnumerator *dirEnum = [fm enumeratorAtPath:dirPath]; //开始枚举过程,将其存入dirEnum中.
    
    //向dirEnum发送nextObject消息,返回下一个文件路径,当没有可供枚举时,返回nil.
    //enumeratorAtPath:方法会递归打印.
    NSString *file;
    while ((file = [dirEnum nextObject])) {
        //if ([[file pathExtension] isEqualToString: @"doc"])
        { //找出目录下面所有的doc文件
            NSString *fullPath = [dirPath stringByAppendingPathComponent:file];
            [files addObject:[NSURL fileURLWithPath:fullPath]];
            NSLog(@"%@",fullPath);
        }
    }
    
//    dirArray = [fm contentsOfDirectoryAtPath:[fm currentDirectoryPath] error:NULL];
//    NSLog(@"内容为:"); //使用contentsOfDirectoryAtPath:方法枚举当前路径中的文件并存入数组dirArray.
//    for (NSString *path in dirArray){  //快速枚举数组中的内容并打印.
//        NSLog(@"%@",path);
//    }
//    NSArray* files = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:NSTemporaryDirectory() error:nil];
    NSString* outFile = [AVRecorder genFilePath];
    [AVSegmentRecorder mergeFiles:files toFile:[NSURL fileURLWithPath:outFile] withVideoSize:CGSizeMake(640, 480) withPreset:AVAssetExportPreset640x480 withCompletionHandler:^(NSError *error) {
        
        NSLog(@"%@",error);
    }];
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

- (void) queryMovieDuration{
    NSURL * fileUrl = [NSURL fileURLWithPath:self.filePath];
    AVAsset * asset = [AVAsset assetWithURL:fileUrl];
    CMTime duration = asset.duration;
    
    NSLog(@"duration:%f",CMTimeGetSeconds(duration));
}

@end
