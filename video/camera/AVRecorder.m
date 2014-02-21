//
//  AVRecorder.m
//  video
//
//  Created by Tommy on 14-2-18.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import "AVRecorder.h"
#import "MovieEncoder.h"

@interface AVRecorder ()

@property(nonatomic,strong)NSDictionary *videoSettings;
@property(nonatomic,strong)NSDictionary *audioSettings;
@property(nonatomic) BOOL pause;
@end



@implementation AVRecorder

-(instancetype)initWithParentView:(UIView *)parent{
    
    if(self = [super initWithParentView:parent]){
        self.pause = NO;
    }
    return self;
}

- (instancetype)initWithParentView:(UIView *)parent andEncoder:(MovieEncoder*)encoder{
    if(self = [super initWithParentView:parent]){
        self.encoder = encoder;
        self.pause = NO;
    }
    return self;
}

- (void) setDefaultValues{
    [super setDefaultValues];
    //video
    self.vbitRate = 256*1024.0;
    self.vcodec = AVVideoCodecH264;
    self.width = 640 ;
    self.height = 480;
    self.fileType = AVFileTypeQuickTimeMovie;
    
    //audio
    self.bitRate = 64000;
    self.sampleRate = 44100.0;
    self.channel = 1;
    self.format = kAudioFormatMPEG4AAC;
    
    [self _setAudioSettings];
    [self _setVideoSettings];
    
}


- (void)_setAudioSettings{
    AudioChannelLayout acl;
    bzero( &acl, sizeof(acl));
    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
    
    _audioSettings = @{AVFormatIDKey:@(self.format),
                                 AVEncoderBitRateKey:@(self.bitRate),
                                 AVSampleRateKey:@(self.sampleRate),
                                 AVNumberOfChannelsKey:@(self.channel),
                                 AVChannelLayoutKey:[NSData dataWithBytes:&acl length: sizeof(acl)]};
    
}

- (void)_setVideoSettings{
    NSDictionary *videoCompressionProps = @{AVVideoAverageBitRateKey:@(self.vbitRate)};
    _videoSettings = @{AVVideoCodecKey:self.vcodec,
                                 AVVideoWidthKey:@(self.width),
                                 AVVideoHeightKey:@(self.height),
                                 AVVideoCompressionPropertiesKey:videoCompressionProps};
}

- (void)setVideoSettings:(NSDictionary*)settings{
    _videoSettings = settings;
}
- (void)setAudioSettings:(NSDictionary*)settings{
    _audioSettings = settings;
}

- (void) _setEncoderSettings{
    
    self.encoder.audioSettings = _audioSettings;
    self.encoder.videoSettings = _videoSettings;
    
    self.encoder.fileType = self.fileType;
}

- (void)stop{
    [self stopRecord];
    [super stop];
}

- (void)startRecord{
    if(!self.isRunning){
        [self start];
    }
    
    [self _setEncoderSettings];
    [self.encoder start];
    
}

- (void)stopRecord{
    if(self.isRunning){
        [self.encoder stop];
        self.pause = NO;
    }
}

- (void)pauseRecord{
    if(self.isRunning && !self.pause){
        [self.encoder pause];
        self.pause = YES;
    }

}
- (void)resumeRecord{
    if(self.isRunning && self.pause){
        [self.encoder resume];
        self.pause = NO;
    }

}
+ (NSString *)stringFromDate:(NSDate *)date{
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //zzz表示时区，zzz可以删除，这样返回的日期字符将不包含时区信息 +0000。
    
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *destDateString = [dateFormatter stringFromDate:date];
    [dateFormatter RELEASE];
    
    return destDateString;
}

+ (NSString*)genFilePath{
    NSString * time = [self stringFromDate:[NSDate date]];
    NSString *betaCompressionDirectory = [NSHomeDirectory()stringByAppendingPathComponent:@"Documents"];
    NSString* filePath = [betaCompressionDirectory stringByAppendingFormat:@"/%@.mp4",time];
    unlink([filePath UTF8String]);
    return filePath;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    
    @synchronized(self){
        if(self.encoder){
            BOOL isVideo = YES;
            if(captureOutput == self.audioOutput){
                isVideo = NO;
            }
            
            [self.encoder captureOutputSampleBuffer:sampleBuffer isVideo:isVideo];
        }
    }
}

- (CGFloat)duration{
    
    return [self.encoder duration];
}

- (NSString*)filePath{
    return self.encoder.path;
}
@end
