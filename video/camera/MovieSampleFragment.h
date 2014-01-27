//
//  MovieSampleFragment.h
//  video
//
//  Created by Tommy on 14-1-21.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreFoundation/CoreFoundation.h>



@interface VideoSample : NSObject

@property(nonatomic,assign)CGImageRef image;
@property(nonatomic,assign)CMTime pts;


+ (VideoSample*)sampleFromCMSampleBuffer:(CMSampleBufferRef)sampleBuffer;
- (CVPixelBufferRef)pixelBuffer;


- (void)destoryImage;


@end
//
//
//

@interface SampleFragment : NSObject

//@property (nonatomic,assign) CFMutableArrayRef sampleArray;
@property(nonatomic,strong)NSMutableArray* sampleArray;
@property(nonatomic) CMTime timeOffset;
@property(nonatomic,assign) BOOL isVideo;
@property (nonatomic,strong)AVAssetWriterInputPixelBufferAdaptor* adaptor;

- (void)writeToInput:(AVAssetWriterInput *)input;
- (void)appendSample:(CMSampleBufferRef)sampleBuffer;
- (void)adjustTime:(CMTime)timeOffset;

@end

//
//
//

@interface MovieSampleFragment : NSObject

@property(nonatomic) CMTime videoTimeStamp;
@property(nonatomic) CMTime audioTimeStamp;


@property(nonatomic,strong)SampleFragment* videoSampleFragment;
@property(nonatomic,strong)SampleFragment* audioSampleFragment;
@property (nonatomic) CMTime timeOffset;
@property (nonatomic,strong)AVAssetWriterInputPixelBufferAdaptor* adaptor;



- (id)initWithTimeOffset:(CMTime)offset;
- (void)writeToVideoInput:(AVAssetWriterInput *)videoWriterInput andAudioInput:(AVAssetWriterInput *)audioWriterInput;
- (void)adjustSampleTime:(CMTime)timeOffset;
- (void)appendSample:(CMSampleBufferRef)sampleBuffer isVideo:(BOOL)isVideo;
- (void)reset;


@end


//
//
//

typedef void (^FinishWriteBlock)(void);
@interface MovieSampleFragmentMgr : NSObject


@property (nonatomic) NSMutableArray * fragmentArray;
@property (nonatomic,copy)FinishWriteBlock finishBlock;
@property (nonatomic,strong) AVAssetWriterInput *videoWriterInput;
@property (nonatomic,strong) AVAssetWriterInput *audioWriterInput;
@property (nonatomic,strong)AVAssetWriterInputPixelBufferAdaptor* adaptor;

- (id) initWithVideoInput:(AVAssetWriterInput *)videoWriterInput andAudioInput:(AVAssetWriterInput *)audioWriterInput;
- (void) addFragment:(MovieSampleFragment*)fragment;
- (void) removeFragmentAtIndex:(NSInteger)index;
- (void) writeToInputs:(FinishWriteBlock)block;
- (void) removeAll;


@end
