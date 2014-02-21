//
//  AVRecorder.h
//  video
//
//  Created by Tommy on 14-2-18.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import "AVCapture.h"

@class MovieEncoder;

@interface AVRecorder : AVCapture

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
@property (nonatomic,assign) int       width;
//default 480
@property (nonatomic,assign) int       height;

@property(nonatomic,strong)MovieEncoder *encoder;

@property(nonatomic,readonly) BOOL pause;

- (instancetype)initWithParentView:(UIView *)parent andEncoder:(MovieEncoder*)encoder;

- (void)startRecord;
- (void)stopRecord;
- (void)pauseRecord;
- (void)resumeRecord;


+ (NSString*)genFilePath;

- (CGFloat)duration;
- (NSString*)filePath;

@end
