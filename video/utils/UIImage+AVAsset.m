//
//  UIImage+AVAsset.m
//  video
//
//  Created by Tommy on 14-2-25.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import "UIImage+AVAsset.h"
#import <AVFoundation/AVFoundation.h>


@implementation UIImage (AVAsset)

+ (UIImage*)imageFromVideoURL:(NSURL*)videoURL{
    NSError *error = nil;
    NSFileManager *manager = [NSFileManager defaultManager];
    if([manager fileExistsAtPath:videoURL.path])
    {
        NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
        AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:videoURL options:opts];
        AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:urlAsset];
        generator.appliesPreferredTrackTransform = YES;
        CGImageRef img = [generator copyCGImageAtTime:CMTimeMake(0, 30) actualTime:NULL error:&error];
        if (!img) {
            return nil;
        }
        UIImage *image = [UIImage imageWithCGImage:img];
        return image;
    }
    return nil;
}

@end
