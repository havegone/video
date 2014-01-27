//
//  AbstractEncoder.h
//  video
//
//  Created by Tommy on 14-1-22.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>


typedef void(^StopDidBlock)(void);

@protocol EncoderDelegate <NSObject>
- (void)captureOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer isVideo:(BOOL)isVideo;
@end


@interface MovieEncoder:NSObject<EncoderDelegate>

@property(nonatomic)AVAssetWriter *writer;
@property(nonatomic)AVAssetWriterInput *videoWriterInput;
@property(nonatomic)AVAssetWriterInput *audioWriterInput;
@property(nonatomic)NSString *path;
@property(nonatomic)NSString* fileType;

@property(nonatomic,readonly,getter = isRunning) BOOL running;
@property(nonatomic)NSDictionary* audioSettings;
@property(nonatomic)NSDictionary* videoSettings;

@property(nonatomic,copy)StopDidBlock stopDidBlock;

- (id) initWithPath:(NSString*)filePath;
- (void) start;
- (void) stop:(StopDidBlock)block;
- (void) pause;
- (void) resume;

- (void) rLock;
- (void) rUnlock;

@end






