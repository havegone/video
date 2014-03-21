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
#import "TMGPUImageMovie.h"
#import <GPUImage.h>
//#import <AVFoundation/AVFoundation.h>
//#import <AssetsLibrary/AssetsLibrary.h>
//#import <MobileCoreServices/MobileCoreServices.h>
#import <MobileCoreServices/UTCoreTypes.h>

@interface PlayerViewController ()<GPUImageMovieDelegate>{
    GPUImageMovie *movieFile;
    GPUImageOutput<GPUImageInput> *filter;
    GPUImageMovieWriter *movieWriter;
}


@property (strong, nonatomic) IBOutlet UIImageView *videoImage;
@property (strong,nonatomic) UIImage* previewImage;
@property (strong,nonatomic)GPUImageView* gpuView;

@property(nonatomic) NSURL* path;

@end

@implementation PlayerViewController{
    GPUImageMovieWriter * _writer;
    GPUImageMovie* gpuImageInput;
}

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
    
    self.gpuView = [[GPUImageView alloc]initWithFrame:CGRectMake(0, 20, 200, 200)];
    [self.view addSubview:self.gpuView];
    
    self.navigationController.navigationBarHidden = YES;
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
    [self setupGPUImageFileter];
    return;
    
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

#pragma mark -
#pragma mark gpu image

- (void)setupGPUImageFileter{
    
    [self xxxd];
    return;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectoryPath = [paths objectAtIndex:0];
    NSString *archives = documentsDirectoryPath;
    //NSDate* currentTime = [NSDate date];
    
    NSString *outputpathofmovie = [[archives stringByAppendingPathComponent:@"writer"] stringByAppendingString:@".mp4"];
    CGSize size = CGSizeMake(640, 480);
    
    unlink([outputpathofmovie UTF8String]);
    NSURL* pathURL = [NSURL fileURLWithPath:outputpathofmovie];
    
    
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
    unlink([pathToMovie UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    
    NSURL *sampleURL = [[NSBundle mainBundle] URLForResource:@"sample_iPod" withExtension:@"m4v"];
    self.path =sampleURL;
    
    NSMutableDictionary *outputSettings = [NSMutableDictionary dictionary];
    NSMutableDictionary * compressionProperties = [[NSMutableDictionary alloc] init];
    [outputSettings setObject:AVVideoCodecH264 forKey:AVVideoCodecKey];
    [outputSettings setObject:[NSNumber numberWithInt:size.width] forKey:AVVideoWidthKey];
    [outputSettings setObject:[NSNumber numberWithInt:size.height] forKey:AVVideoHeightKey];
    [compressionProperties setObject:[NSNumber numberWithInt:256*1024.0]
                              forKey:AVVideoAverageBitRateKey];
    [compressionProperties setObject:[NSNumber numberWithInt: 24]
                              forKey:AVVideoMaxKeyFrameIntervalKey];
    
    [outputSettings setObject:compressionProperties forKey:AVVideoCompressionPropertiesKey];
    
    
    AudioChannelLayout channelLayout;
    memset(&channelLayout, 0, sizeof(AudioChannelLayout));
    channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
    
    NSDictionary *audioSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [ NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
                                   [ NSNumber numberWithInt: 2 ], AVNumberOfChannelsKey,
                                   [ NSNumber numberWithFloat: 16000.0 ], AVSampleRateKey,
                                   [ NSData dataWithBytes:&channelLayout length: sizeof( AudioChannelLayout ) ], AVChannelLayoutKey,
                                   [ NSNumber numberWithInt: 32000 ], AVEncoderBitRateKey,
                                   nil];
    
    
    //_writer = [[GPUImageMovieWriter alloc] initWithMovieURL:pathURL size:size fileType:AVFileTypeMPEG4 outputSettings:outputSettings];
//               outputSettings];
    _writer = [[GPUImageMovieWriter alloc] initWithMovieURL:pathURL size:CGSizeMake(640.0, 480.0)];
    _writer.encodingLiveVideo = YES;
    _writer.shouldPassthroughAudio = NO;
    [_writer setHasAudioTrack:TRUE audioSettings:audioSettings];
    
    gpuImageInput = [[TMGPUImageMovie alloc]initWithURL:self.path];
    GPUImageView* outputView = self.gpuView;
//    GPUImageMovieWriter* writer = nil;
    GPUImageFilter * filter  = [[GPUImagePixellateFilter alloc]init];//
    //[[GPUImagePixellateFilter alloc] init];// [[GPUImageSoftEleganceFilter alloc]init];
    

    
//    GPUImageFalseColorFilter *filter2 = [[GPUImageFalseColorFilter alloc] init];
//  
//    //GPUImageView *filteredVideoView = [[GPUImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, viewWidth, viewHeight)];
//    
//    GPUImageFilterPipeline *pipeline = [[GPUImageFilterPipeline alloc]initWithOrderedFilters:@[filter] input:gpuImageInput output:outputView];
    
    
    [gpuImageInput addTarget:filter];
    [filter addTarget:outputView];
    [filter addTarget:_writer];
    

    [gpuImageInput enableSynchronizedEncodingUsingMovieWriter:_writer];
    
    gpuImageInput.audioEncodingTarget = _writer;
//    gpuImageInput.delegate = self;
    gpuImageInput.playAtActualSpeed = YES;
//    gpuImageInput.runBenchmark = YES;
    [_writer startRecording];
    [gpuImageInput startProcessing];
    
    
    __block __weak GPUImageMovieWriter *ww = _writer;
    [_writer setCompletionBlock:^{
  //      [_writer finishRecording];
        [ww finishRecordingWithCompletionHandler:^{
            
            NSLog(@"finishRecordingWithCompletionHandler");
//            if (block) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    block(ww.assetWriter.outputURL, nil);
//                });
//            }
        }];
    }];
    [_writer setFailureBlock:^(NSError *error) {
        
        NSLog(@"setFailureBlock");
//        if (block) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                block(nil, error);
//            });
//        }
    }];

    

}
- (void)xxxd{
    CGSize size = CGSizeMake(640, 480);
    NSMutableDictionary *outputSettings = [NSMutableDictionary dictionary];
    NSMutableDictionary * compressionProperties = [[NSMutableDictionary alloc] init];
    [outputSettings setObject:AVVideoCodecH264 forKey:AVVideoCodecKey];
    [outputSettings setObject:[NSNumber numberWithInt:size.width] forKey:AVVideoWidthKey];
    [outputSettings setObject:[NSNumber numberWithInt:size.height] forKey:AVVideoHeightKey];
    [compressionProperties setObject:[NSNumber numberWithInt:256*1024.0]
                              forKey:AVVideoAverageBitRateKey];
    [compressionProperties setObject:[NSNumber numberWithInt: 24]
                              forKey:AVVideoMaxKeyFrameIntervalKey];
    
    [outputSettings setObject:compressionProperties forKey:AVVideoCompressionPropertiesKey];
    
    NSURL *sampleURL = [[NSBundle mainBundle] URLForResource:@"sample_iPod" withExtension:@"m4v"];
    sampleURL = self.path;
    movieFile = [[TMGPUImageMovie alloc] initWithURL:sampleURL];
    movieFile.runBenchmark = NO;
    movieFile.playAtActualSpeed = NO;
    filter =  [[GPUImagePixellateFilter alloc] init];
    //    filter = [[GPUImageUnsharpMaskFilter alloc] init];
    
    [movieFile addTarget:filter];
    
    // Only rotate the video for display, leave orientation the same for recording
    GPUImageView *filterView = self.gpuView;//(GPUImageView *)self.view;
    [filter addTarget:filterView];
    
    // In addition to displaying to the screen, write out a processed version of the movie to disk
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.mp4"];
    unlink([pathToMovie UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(640.0, 480.0)];
    //movieWriter =    [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:size fileType:AVFileTypeMPEG4 outputSettings:outputSettings];
    
    [filter addTarget:movieWriter];
    
    // Configure this for video from the movie file, where we want to preserve all video frames and audio samples
    movieWriter.shouldPassthroughAudio = NO;
    movieWriter.encodingLiveVideo = NO;
    movieFile.audioEncodingTarget = movieWriter;
    [movieFile enableSynchronizedEncodingUsingMovieWriter:movieWriter];
    
    [movieWriter startRecording];
    [movieFile startProcessing];
    
    [movieWriter setCompletionBlock:^{
        [filter removeTarget:movieWriter];
        [movieWriter finishRecording];
        
        NSLog(@"complete");
    }];
}

- (void)didCompletePlayingMovie{
    gpuImageInput.delegate = nil;
    [_writer finishRecording];
    //gpuImageInput = nil;
    NSLog(@"didCompletePlayingMovie");
}







@end
