//
//  AVRecorder+Segment.m
//  video
//
//  Created by Tommy on 14-2-19.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//
#import "AVRecorder.h"
#import "MovieEncoder.h"
#import "AVSegmentRecorder.h"
#import "AVAssetStitcher.h"





@interface AVSegmentRecorder (){
    long uniqueTimestamp;
    int currentRecordingSegment;
}

@property(nonatomic,strong)NSMutableArray* tempFiles;
@property(nonatomic) BOOL pause;

@end

@implementation AVSegmentRecorder{
    BOOL _stop;
    int  _inFlightWrites;
}
- (instancetype)initWithParentView:(UIView *)parent{
    if(self = [super initWithParentView:parent]){
        self.filePath = [AVRecorder genFilePath];
        self.tempFiles = [NSMutableArray new];
        _inFlightWrites = 0;
    }
    return self;
}
- (instancetype)initWithParentView:(UIView *)parent andFilePath:(NSString*)path{
    if(self = [super initWithParentView:parent]){
        self.filePath = path;
        _stop = NO;
        
        self.tempFiles = [NSMutableArray new];
        _inFlightWrites = 0;
    }
    
    return self;
}
- (instancetype)initWithParentView:(UIView *)parent andEncoder:(MovieEncoder *)encoder{
    NSAssert(0, @"use initWithParentView:andFilePath:");
    return nil;
}


- (void) deletePrev{
    unlink([self.filePath UTF8String]);
    [self.tempFiles removeLastObject];
    
}

- (void) _startRecord{
    _stop = NO;
    ++_inFlightWrites;
    DefineWeakSelf();
    MovieEncoder* encoder = [[MovieEncoder alloc]initWithPath:[self genTempFilePath] statusChangeBlock:^(MovieEncoder*encoder, MovieEncoderStatus status){
        switch (status) {
            case MovieEncoderStatusStop:
                --_inFlightWrites;
                [wself.tempFiles addObject:[NSURL fileURLWithPath:[encoder path]]];
                if(wself.encoder == encoder){
                    wself.encoder = nil;
                }
                NSLog(@"%f",[encoder duration]);
                if(_stop){
                    [wself mergeToOutputFilePath];
                }
                break;
                
            default:
                break;
        }
    }];
    self.encoder = encoder;
    
    [super startRecord];
}

- (void) _stopRecord{
    [super stopRecord];
    
}

- (void) startRecord{

    uniqueTimestamp = [[NSDate date] timeIntervalSince1970];
    currentRecordingSegment = 0;
    [self _startRecord];
    
}

- (void) stopRecord{
    if(!_stop){
        _stop = YES;
        if(self.pause){
            [self mergeToOutputFilePath];
        }else{
            [self _stopRecord];
        }
        self.pause = NO;
    }
    
}

- (void) pauseRecord{
    if (!self.pause) {
        [self _stopRecord];
        self.pause = YES;
    }

}
- (void) resumeRecord{
    if(self.pause){
        currentRecordingSegment++;
        [self _startRecord];
        self.pause = NO;
    }
}

- (NSString*)genTempFilePath{
    return [NSString stringWithFormat:@"%@%@-%ld-%d.mov", NSTemporaryDirectory(), @"recordingsegment", uniqueTimestamp, currentRecordingSegment];
}

- (void) cleanTemporaryFiles{

    [self.tempFiles enumerateObjectsUsingBlock:^(NSURL* filePath, NSUInteger idx, BOOL *stop) {
        unlink([filePath.path  UTF8String]);
    }];
}

- (void) mergeToOutputFilePath{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"start merge");
        CGSize vSize =  CGSizeMake(self.width, self.height);
        [self finalizeRecordingToFile:[NSURL fileURLWithPath:self.filePath] withVideoSize:vSize withPreset:AVAssetExportPreset640x480 withCompletionHandler:^(NSError *error) {
            
            if(!error){
                [self cleanTemporaryFiles];
                [self.tempFiles removeAllObjects];
            }
            
            NSLog(@"error:%@",error);
            NSLog(@"end merge");
            
        }];
    });
//    NSOperationQueue * queue = [[NSOperationQueue alloc]init];
//    [queue addOperationWithBlock:^{
//        
//        NSLog(@"start merge");
//        CGSize vSize =  CGSizeMake(self.width, self.height);
//        [self finalizeRecordingToFile:[NSURL fileURLWithPath:self.filePath] withVideoSize:vSize withPreset:AVAssetExportPresetMediumQuality withCompletionHandler:^(NSError *error) {
//            
//            NSLog(@"error:%@",error);
//            NSLog(@"end merge");
//            
//        }];
//    }];
}

- (void)finalizeRecordingToFile:(NSURL *)finalVideoLocationURL withVideoSize:(CGSize)videoSize withPreset:(NSString *)preset withCompletionHandler:(void (^)(NSError *error))completionHandler{
    
    if(_inFlightWrites!=0){
        completionHandler([NSError errorWithDomain:@"Can't finalize recording unless all sub-recorings are finished." code:106 userInfo:nil]);
    }
     return [AVSegmentRecorder mergeFiles:self.tempFiles toFile:[NSURL fileURLWithPath:self.filePath] withVideoSize:videoSize withPreset:preset withCompletionHandler:completionHandler];
}


+ (void)mergeFiles:(NSArray*)files toFile:(NSURL *)finalVideoLocationURL withVideoSize:(CGSize)videoSize withPreset:(NSString *)preset withCompletionHandler:(void (^)(NSError *error))completionHandler{
    
    NSError *error;
    if([finalVideoLocationURL checkResourceIsReachableAndReturnError:&error])
    {
        completionHandler([NSError errorWithDomain:@"Output file already exists." code:104 userInfo:nil]);
        return;
    }

    
    AVAssetStitcher *stitcher = [[AVAssetStitcher alloc] initWithOutputSize:videoSize];
    
    __block NSError *stitcherError;
    [files enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSURL *outputFileURL, NSUInteger idx, BOOL *stop) {
        
        [stitcher addAsset:[AVURLAsset assetWithURL:outputFileURL] withTransform:^CGAffineTransform(AVAssetTrack *videoTrack) {
            
            //
            // The following transform is applied to each video track. It changes the size of the
            // video so it fits within the output size and stays at the correct aspect ratio.
            //
            
            CGFloat ratioW = videoSize.width / videoTrack.naturalSize.width;
            CGFloat ratioH = videoSize.height / videoTrack.naturalSize.height;
            if(ratioW < ratioH)
            {
                // When the ratios are larger than one, we must flip the translation.
                float neg = (ratioH > 1.0) ? 1.0 : -1.0;
                CGFloat diffH = videoTrack.naturalSize.height - (videoTrack.naturalSize.height * ratioH);
                return CGAffineTransformConcat( CGAffineTransformMakeTranslation(0, neg*diffH/2.0), CGAffineTransformMakeScale(ratioH, ratioH) );
            }
            else
            {
                // When the ratios are larger than one, we must flip the translation.
                float neg = (ratioW > 1.0) ? 1.0 : -1.0;
                CGFloat diffW = videoTrack.naturalSize.width - (videoTrack.naturalSize.width * ratioW);
                return CGAffineTransformConcat( CGAffineTransformMakeTranslation(neg*diffW/2.0, 0), CGAffineTransformMakeScale(ratioW, ratioW) );
            }
            
        } withErrorHandler:^(NSError *error) {
            
            stitcherError = error;
            
        }];
        
    }];
    
    if(stitcherError)
    {
        completionHandler(stitcherError);
        return;
    }
    
    [stitcher exportTo:finalVideoLocationURL withPreset:preset withCompletionHandler:^(NSError *error) {
        
        if(error)
        {
            completionHandler(error);
        }
        else
        {
            completionHandler(nil);
        }
        
        
    }];
    
}





@end
