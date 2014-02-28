//
//  AVAsset+Audio.m
//  video
//
//  Created by Tommy on 14-2-27.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import "AVAsset+Audio.h"

@implementation AVAsset (Audio)

+ (AVMutableComposition*) compositeAudio:(NSURL*)audioUrl andVideo:(NSURL*)videoUrl volume:(CGFloat)volume replaceOrgAudio:(BOOL)replace repeatAudio:(BOOL)repeat audioMix:(AVMutableAudioMix*)mix{
    AVURLAsset* audioAsset = [[AVURLAsset alloc]initWithURL:audioUrl options:nil];
    AVURLAsset* videoAsset = [[AVURLAsset alloc]initWithURL:videoUrl options:nil];
    
    AVAssetTrack* assetTrackAudio = [[audioAsset tracksWithMediaType:AVMediaTypeAudio]objectAtIndex:0];
    AVAssetTrack* assetTrackOrgAudio = [[videoAsset tracksWithMediaType:AVMediaTypeAudio]objectAtIndex:0];
    AVAssetTrack* assetTrackVideo = [[videoAsset tracksWithMediaType:AVMediaTypeVideo]objectAtIndex:0];
    
    
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    
    AVMutableCompositionTrack* compVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [compVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, assetTrackVideo.timeRange.duration) ofTrack:assetTrackVideo atTime:kCMTimeZero error:nil];
    
    
    AVMutableCompositionTrack * compAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    CMTime startTime = kCMTimeZero;
    CMTime audioDuration = assetTrackAudio.timeRange.duration;
    
    while (CMTIME_COMPARE_INLINE(startTime, <, videoAsset.duration)) {
        CMTime leftTime = CMTimeSubtract(videoAsset.duration, startTime);
        CMTime needTime = audioDuration;
        if (CMTIME_COMPARE_INLINE(needTime, > , leftTime)) {
            needTime = leftTime;
        }
        
        [compAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, needTime) ofTrack:assetTrackAudio atTime:startTime error:nil];
        
        if(!repeat){
            break;
        }
        
        startTime = CMTimeAdd(startTime, needTime);
    }
    AVMutableCompositionTrack * compOrgAudioTrack = nil;
    if(!replace){
        compOrgAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
        [compOrgAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, assetTrackOrgAudio.timeRange.duration)
                               ofTrack:assetTrackOrgAudio
                                atTime:kCMTimeZero error:nil];
    }
    
    
    AVMutableAudioMixInputParameters * mixParamAudio = nil;
    if (compAudioTrack) {
        mixParamAudio = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:compAudioTrack];
        [mixParamAudio setVolume:volume atTime:kCMTimeZero];
    }
    AVMutableAudioMixInputParameters * mixParamOrgAudio = nil;
    if (compOrgAudioTrack) {
        mixParamOrgAudio = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:compOrgAudioTrack];
        [mixParamOrgAudio setVolume:(1.0 - volume) atTime:kCMTimeZero];
    }
    
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:2];
    if (mixParamAudio) {
        [array addObject:mixParamAudio];
    }
    if (mixParamOrgAudio) {
        [array addObject:mixParamOrgAudio];
    }

    mix.inputParameters = array;

    
    return mixComposition;
}

+ (void) exportComposition:(AVMutableComposition*)composition audioMix:(AVMutableAudioMix*)mix toPath:(NSString*)exportPath withCompleteBlock:(ExportCompleteBlock)completionHandler{
    
    AVAssetExportSession* exporter = [[AVAssetExportSession alloc] initWithAsset:composition
                                                                          presetName:AVAssetExportPresetMediumQuality];
                                          //AVAssetExportPresetPassthrough];
    
    NSURL    *exportUrl = [NSURL fileURLWithPath:exportPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:exportPath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:exportPath error:nil];
    }
    
    exporter.outputFileType = AVFileTypeMPEG4;//AVFileTypeQuickTimeMovie;//AVFileTypeMPEG4;
    exporter.outputURL = exportUrl;
    exporter.audioMix = mix;
//    _assetExport.shouldOptimizeForNetworkUse = YES;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^(void){
        
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
