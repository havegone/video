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
//AVFileTypeQuickTimeMovie
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

//
//*****
//now the block did not has function,will be implement later
//
//
- (void)startRecord:(StartRecordBlock)block;
- (void)stopRecord:(FinishRecordBlock)block;
- (BOOL)pauseRecord;
- (BOOL)resumeRecord;


@end
