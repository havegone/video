//
//  UIImage+AVAsset.h
//  video
//
//  Created by Tommy on 14-2-25.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AVAsset;

@interface UIImage (AVAsset)

+ (UIImage*)imageFromVideoURL:(NSURL*)url;

@end
