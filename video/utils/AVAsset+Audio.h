//
//  AVAsset+Audio.h
//  video
//
//  Created by Tommy on 14-2-27.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

typedef void(^ExportCompleteBlock)(NSError* );

@interface AVAsset (Audio)


+ (AVMutableComposition*) compositeAudio:(NSURL*)audioUrl andVideo:(NSURL*)videoUrl volume:(CGFloat)volume replaceOrgAudio:(BOOL)replace repeatAudio:(BOOL)repeat audioMix:(AVMutableAudioMix*)mix;

+ (void) exportComposition:(AVMutableComposition*)composition audioMix:(AVMutableAudioMix*)mix toPath:(NSString*)exportPath withCompleteBlock:(ExportCompleteBlock)block;

@end
