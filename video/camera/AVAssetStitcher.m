//
// Copyright (c) 2013 Carson McDonald
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
// and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions
// of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
// TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
// CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
//

#import "AVAssetStitcher.h"

@implementation AVAssetStitcher
{
    CGSize outputSize;
    
    AVMutableComposition *composition;
    AVMutableCompositionTrack *compositionVideoTrack;
    AVMutableCompositionTrack *compositionAudioTrack;
    
    NSMutableArray *instructions;
}

- (id)initWithOutputSize:(CGSize)outSize
{
    self = [super init];
    if (self != nil)
    {
        outputSize = outSize;
        
        composition = [AVMutableComposition composition];
        compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
        instructions = [[NSMutableArray alloc] init];
    }
    return self;
}


- (void)_addAsset:(AVURLAsset *)asset withTransform:(CGAffineTransform (^)(AVAssetTrack *videoTrack))transformToApply withErrorHandler:(void (^)(NSError *error))errorHandler
{
    AVAssetTrack *videoTrack;
    AVAssetTrack *audioTrack;
    
    if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
        videoTrack = [asset tracksWithMediaType:AVMediaTypeVideo][0];
    }
    if ([[asset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
        audioTrack = [asset tracksWithMediaType:AVMediaTypeAudio][0];
    }
    
    CMTime videoTime = asset.duration;
    CMTime audioTime = asset.duration;
    if (videoTrack && audioTrack) {
        float videoDuration = CMTimeGetSeconds(videoTrack.timeRange.duration);
        float audioDuration = CMTimeGetSeconds(audioTrack.timeRange.duration);
        if (audioDuration - videoDuration > 0.00001) {
            audioTime = videoTrack.timeRange.duration;
            videoTime = videoTrack.timeRange.duration;
        }
        if (videoDuration - audioDuration > 0.00001) {
            audioTime = audioTrack.timeRange.duration;
            videoTime = audioTrack.timeRange.duration;
        }
    }
    
    NSError *error;
    if (videoTrack) {
        [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoTime)
                                       ofTrack:videoTrack atTime:kCMTimeZero error:&error];
    }
    if (audioTrack && videoTrack) {
        [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioTime)
                                       ofTrack:audioTrack atTime:kCMTimeZero error:&error];
    }
    NSLog(@"v = %f, a = %f",CMTimeGetSeconds(videoTime), CMTimeGetSeconds(audioTime));
    if (videoTrack) {
        __block CMTime startTime = kCMTimeZero;
        AVMutableVideoCompositionInstruction *instruction =
        [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        AVMutableVideoCompositionLayerInstruction *layerInstruction =
        [AVMutableVideoCompositionLayerInstruction
         videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];
        
        if(transformToApply){
            [layerInstruction setTransform:
             CGAffineTransformConcat(videoTrack.preferredTransform,transformToApply(videoTrack))
                                    atTime:kCMTimeZero];
        }else{
            [layerInstruction setTransform:videoTrack.preferredTransform atTime:kCMTimeZero];
        }
        instruction.layerInstructions = @[layerInstruction];
        [instructions enumerateObjectsUsingBlock:
         ^(AVMutableVideoCompositionInstruction *previousInstruction, NSUInteger idx, BOOL *stop) {
             startTime = CMTimeAdd(startTime, previousInstruction.timeRange.duration);
         }];
        instruction.timeRange = CMTimeRangeMake(startTime, videoTime);
        [instructions addObject:instruction];
    }
}


- (void)addAsset:(AVURLAsset *)asset withTransform:(CGAffineTransform (^)(AVAssetTrack *videoTrack))transformToApply withErrorHandler:(void (^)(NSError *error))errorHandler
{
    return [self _addAsset:asset withTransform:transformToApply withErrorHandler:errorHandler];
    
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];
    
    //
    // Apply a transformation to the video if one has been given. If a transformation is given it is combined
    // with the preferred transform contained in the incoming video track.
    //
    if(transformToApply)
    {
        [layerInstruction setTransform:CGAffineTransformConcat(videoTrack.preferredTransform, transformToApply(videoTrack))
                                atTime:kCMTimeZero];
    }
    else
    {
        [layerInstruction setTransform:videoTrack.preferredTransform
                                atTime:kCMTimeZero];
    }
    
    instruction.layerInstructions = @[layerInstruction];
    
    __block CMTime startTime = kCMTimeZero;
    [instructions enumerateObjectsUsingBlock:^(AVMutableVideoCompositionInstruction *previousInstruction, NSUInteger idx, BOOL *stop) {
        startTime = CMTimeAdd(startTime, previousInstruction.timeRange.duration);
    }];
    instruction.timeRange = CMTimeRangeMake(startTime, asset.duration);
    
    [instructions addObject:instruction];
    
    NSError *error;
    
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:videoTrack atTime:kCMTimeZero error:&error];
    
    if(error)
    {
        errorHandler(error);
        return;
    }
    
    AVAssetTrack *audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    
    [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:audioTrack atTime:kCMTimeZero error:&error];
    
    if(error)
    {
        errorHandler(error);
        return;
    }
}

- (void)exportTo:(NSURL *)outputFile withPreset:(NSString *)preset withCompletionHandler:(void (^)(NSError *error))completionHandler
{
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.instructions = instructions;
    videoComposition.renderSize = outputSize;
    videoComposition.frameDuration = CMTimeMake(1, 30);
    
    AVAssetExportSession *exporter = [AVAssetExportSession exportSessionWithAsset:composition presetName:preset];
    NSParameterAssert(exporter != nil);
    
    NSString *type = [[[UIDevice currentDevice] systemVersion] intValue] <= 5 ? AVFileTypeQuickTimeMovie : AVFileTypeMPEG4;
    exporter.outputFileType = type;
    exporter.videoComposition = videoComposition;
    exporter.outputURL = outputFile;

    
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        
        switch([exporter status])
        {
            case AVAssetExportSessionStatusFailed:
            {
                completionHandler(exporter.error);
            } break;
            case AVAssetExportSessionStatusCancelled:
            case AVAssetExportSessionStatusCompleted:
            {
                completionHandler(nil);
            } break;
            default:
            {
                completionHandler([NSError errorWithDomain:@"Unknown export error" code:100 userInfo:nil]);
            } break;
        }
        
    }];
    
    
}


@end

