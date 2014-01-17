//
//  AudioCamera.h
//  video
//
//  Created by Tommy on 14-1-17.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import "Capture.h"

@interface AudioDataCapture : Capture
@property (nonatomic,readonly) dispatch_queue_t sampleQueue;
@end
