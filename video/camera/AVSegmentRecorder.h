//
//  AVRecorder+Segment.h
//  video
//
//  Created by Tommy on 14-2-19.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import "AVRecorder.h"

typedef void(^RecorderStatusBlock)(void);

@interface AVSegmentRecorder:AVRecorder

@property(nonatomic,strong)NSString *filePath;

- (instancetype)initWithParentView:(UIView *)parent andFilePath:(NSString*)path;

- (void) deletePrev;

+ (void)mergeFiles:(NSArray*)files toFile:(NSURL *)finalVideoLocationURL withVideoSize:(CGSize)videoSize withPreset:(NSString *)preset withCompletionHandler:(void (^)(NSError *error))completionHandler;
@end
