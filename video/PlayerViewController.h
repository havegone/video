//
//  PlayerViewController.h
//  video
//
//  Created by Tommy on 14-2-24.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface PlayerViewController : UIViewController

@property(nonatomic,strong) AVPlayer* player;

//@property(nonatomic,weak)



- (instancetype)initWithPath:(NSString*)path;






- (void) play;
- (void) setVolume:(CGFloat)volume;





@end
