//
//  ImagesToMovieEncoder.h
//  video
//
//  Created by Tommy on 14-1-27.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import "MovieEncoder.h"


@interface ImagesToMovieEncoder : MovieEncoder


@property(nonatomic)NSArray *images;
@property(nonatomic,assign)NSInteger fps;
@property(nonatomic,assign)CGSize size;
@property(nonatomic,assign)NSInteger duration;
@property(nonatomic)AVAssetWriterInputPixelBufferAdaptor *adaptor;



- (id)initWithImages:(NSArray*)images toFile:(NSString*)filePath withDurarion:(NSInteger)duration andFPS:(NSInteger)fps andSize:(CGSize)size;
- (void)start:(MovieEncoderStatusChangeBlock)statusChangeBlock;


@end
