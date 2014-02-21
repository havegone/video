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


typedef enum {
    MovieEncoderStatusUnknown = 0,
    MovieEncoderStatusStart = 1,
    MovieEncoderStatusStop = 2,
    MovieEncoderStatusPause = 3,
    MovieEncoderStatusResume = 4,
}MovieEncoderStatus;

@class MovieEncoder;
typedef void(^MovieEncoderStatusChangeBlock)(MovieEncoder* encoder,MovieEncoderStatus status);

@protocol EncoderDelegate <NSObject>
- (void) start;
- (void) stop;
- (void) pause;
- (void) resume;
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

@property(nonatomic,copy)MovieEncoderStatusChangeBlock statusChangeBlock;

@property(nonatomic)BOOL isPuase;

- (instancetype) initWithPath:(NSString*)filePath statusChangeBlock:(MovieEncoderStatusChangeBlock)block;
- (void) start;
- (void) stop;
- (void) pause;
- (void) resume;

- (void) setupAudioWriterInput;
- (void) setupVideoWriterInput;
- (void) setupWriter;

- (BOOL) encodeFrame:(CMSampleBufferRef) sampleBuffer isVideo:(BOOL)isVideo;
- (void) captureOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer isVideo:(BOOL)isVideo;

- (CGFloat)duration;

@end






