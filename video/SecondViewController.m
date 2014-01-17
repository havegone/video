//
//  SecondViewController.m
//  video
//
//  Created by Tommy on 14-1-16.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import "SecondViewController.h"
#import "VideoCamera.h"
#import "ImageCamera.h"

@interface SecondViewController ()
@property (nonatomic,strong)ImageCamera* camera;
@end

@implementation SecondViewController{
    UIButton * takePhotoBtn;
    UIImageView* photoImageView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.camera = [[ImageCamera alloc]initWithParentView:self.view];
    [self.camera buildSession];
    
    takePhotoBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    takePhotoBtn.frame = CGRectMake(0,20, 50, 30);
    // torchBtn.backgroundColor = [UIColor redColor];
    //     torchBtn.titleLabel.text = @"torch";
    [takePhotoBtn setTitle:@"take" forState:UIControlStateNormal];
    
    [takePhotoBtn addTarget:self action:@selector(takePhotoHandler) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:takePhotoBtn];
    
    
    photoImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0,50, 50,50)];
    photoImageView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:photoImageView];
    

	// Do any additional setup after loading the view, typically from a nib.
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.camera start];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self.camera stop];
}

- (void)takePhotoHandler{
    DefineWeakSelf();
    [self.camera takePicture:^(UIImage *image, NSError *error) {
        if(image){
            [photoImageView setImage:image];
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
