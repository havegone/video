//
//  PlayerViewController.m
//  video
//
//  Created by Tommy on 14-2-24.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import "PlayerViewController.h"
#import "UIImage+AVAsset.h"
#import "AVAsset+Audio.h"

@interface PlayerViewController ()


@property (strong, nonatomic) IBOutlet UIImageView *videoImage;
@property (strong,nonatomic) UIImage* previewImage;

@property(nonatomic) NSURL* path;

@end

@implementation PlayerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.previewImage = [UIImage imageFromVideoURL:self.path];
    [self.videoImage setImage:self.previewImage];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (instancetype)initWithPath:(NSString*)path{
    
    if(self = [super init]){
        
        self.path = [NSURL fileURLWithPath:path];
        
    }
    return  self;
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];

}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if([keyPath isEqualToString:@"status"]){
        
        if(AVPlayerItemStatusReadyToPlay == self.player.currentItem.status){
            [self.player play];
        }else{
            NSLog(@"%d,%@",self.player.currentItem.status,self.player.currentItem.error);
        }
        
    }
}

//- (void) setVolume:(CGFloat)volume{
//    [self.player setVolume:volume];
//}
- (IBAction)play:(id)sender {
    
    AVPlayerItem * playItem =  [AVPlayerItem playerItemWithURL:self.path];
    self.player = [[AVPlayer alloc]initWithPlayerItem:playItem];
    AVPlayerLayer * playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    
    playerLayer.frame = self.view.layer.bounds;
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    
    [self.view.layer addSublayer:playerLayer];
    
    [playItem addObserver:self forKeyPath:@"status" options:0 context:nil];
    
 //   [self.player play];
}
- (IBAction)mute:(id)sender {
    //
    static BOOL mute = NO;
    static CGFloat volume = 0.5;
    
    mute = !mute;
    
    if(mute){
        volume = self.player.volume;
        [self setVolume:0.0f];
    }else{
        [self setVolume:volume];
    }
    
}
-(void) setVolume:(float)volume{
    
    if(volume>1.0){
        volume = 1.0;
    }
    
    if(volume<0.0f){
        volume = 0.0f;
    }
    
    AVAsset *asset = [[self.player currentItem] asset];
    NSArray *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
    
    // Mute all the audio tracks
    NSMutableArray *allAudioParams = [NSMutableArray array];
    for (AVAssetTrack *track in audioTracks) {
        AVMutableAudioMixInputParameters *audioInputParams =    [AVMutableAudioMixInputParameters audioMixInputParameters];
        [audioInputParams setVolume:volume atTime:kCMTimeZero];
        [audioInputParams setTrackID:[track trackID]];
        [allAudioParams addObject:audioInputParams];
    }
    AVMutableAudioMix *audioZeroMix = [AVMutableAudioMix audioMix];
    [audioZeroMix setInputParameters:allAudioParams];
    
    [[self.player currentItem] setAudioMix:audioZeroMix];
    
    [self.player setVolume:volume];
}
- (IBAction)upVolume:(id)sender {
    
    [self setVolume:self.player.volume + 0.1];

    //[self]
}
- (IBAction)downVolume:(id)sender {
    [self setVolume:self.player.volume - 0.1];
}

- (IBAction)seekPlay:(id)sender {
    
//    [self.player.currentItem seekToTime:]
    [self.player play];
}

- (IBAction)close:(id)sender {
//    [self.navigationController popToRootViewControllerAnimated:YES];
    [self.player pause];
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        
    }];
}


- (IBAction)mixMusic:(id)sender{
    

    NSURL* audioPath = [[NSBundle mainBundle] URLForResource:@"test" withExtension:@"mp3"];
    
    AVMutableAudioMix * mix = [AVMutableAudioMix audioMix];
    AVMutableComposition* composition =  [AVAsset compositeAudio:audioPath andVideo:self.path volume:0.1 replaceOrgAudio:NO repeatAudio:NO audioMix:mix];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectoryPath = [paths objectAtIndex:0];
    NSString *archives = documentsDirectoryPath;
    //NSDate* currentTime = [NSDate date];
    
    NSString *outputpathofmovie = [[archives stringByAppendingPathComponent:@"export"] stringByAppendingString:@".mp4"];
    

    [AVAsset exportComposition:composition audioMix:mix toPath:outputpathofmovie withCompleteBlock:^(NSError*error){
       
        NSLog(@"export complete;%@",error);
    }];
    
    
    
    

    
    
}







@end
