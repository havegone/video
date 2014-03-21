//
//  VACapture.h
//  video
//
//  Created by Tommy on 14-1-17.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import "VideoDataCapture.h"

typedef void(^StartRecordBlock)(void);
typedef void(^FinishRecordBlock)(void);



@class MovieEncoder;

@interface VACapture : VideoDataCapture

@property (nonatomic,copy) NSDictionary* audioSettings;
@property (nonatomic,strong) AVAssetWriter *writer;
@property (nonatomic,strong) AVAssetWriterInput *videoWriterInput;
@property (nonatomic,strong) AVAssetWriterInput *audioWriterInput;
@property (nonatomic,copy) NSDictionary *videoWriterSettings;
@property (nonatomic,copy) NSDictionary *audioWriterSettings;
@property (nonatomic,strong)AVAssetWriterInputPixelBufferAdaptor* adaptor;
@property (nonatomic,strong)NSString            *filePath;

@property (nonatomic,copy) StartRecordBlock startBlock;
@property (nonatomic,copy) FinishRecordBlock finishBlock;
@property (nonatomic,assign,readonly)BOOL isRecording;
@property (nonatomic,assign,readonly)BOOL isMute;

@property (nonatomic)MovieEncoder* encoder;


//acl
//default 64000
@property (nonatomic,assign) int bitRate;
//default 44100.0
@property (nonatomic,assign) int sampleRate;
//default 1
@property (nonatomic,assign) int channel;
//default kAudioFormatMPEG4AAC
@property (nonatomic,assign) int format;

//video
//AVFileTypeMPEG4
@property (nonatomic,strong) NSString* const fileType;
//default 128.0*1024.0;
@property (nonatomic,assign) CGFloat vbitRate;
//default AVVideoCodecH264
@property (nonatomic,strong) NSString* const vcodec;
//default 640
@property (nonatomic,assign) int       vwidth;
//default 480
@property (nonatomic,assign) int       vheight;


- (void)initWriter;
- (void)initVideoWriter;
- (void)initAudioWriter;

- (NSString*)generateFilePath;

//reset segmental record
- (void)startWithReset;
- (void)startRecord:(StartRecordBlock)block;
- (void)stopRecord:(FinishRecordBlock)block;
- (BOOL)pauseRecord;
- (BOOL)resumeRecord;

- (void)enableMute:(BOOL)mute;


//delete last segment
- (BOOL) deleteLastSegment;
- (BOOL) deleteSegmentAtIndex:(NSInteger)index;

//construct video with image
- (void)writeImageAsMovie:(NSArray*)imageArray toPath:(NSString*)path size:(CGSize)size duration:(int)duration;

//data
- (void) startRecordWithData:(StartRecordBlock)block;
- (void) stopRecordWithData:(FinishRecordBlock)block;
- (BOOL) pauseRecordWithData;
- (BOOL) resumeRecordWithData;



@end
