//
//  arc.h
//  video
//
//  Created by Tommy on 14-1-16.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#ifndef video_arc_h
#define video_arc_h

#if __has_feature(objc_arc_weak)                //objc_arc_weak

    #define WEAK        weak
    #define __WEAK      __weak
    #define STRONG      strong

    #define AUTORELEASE self
    #define RELEASE     self
    #define RETAIN      self
    #define CFTYPECAST(exp) (__bridge exp)
    #define TYPECAST(exp) (__bridge_transfer exp)
    #define CFRELEASE(exp) CFRelease(exp)
    #define DEALLOC     self

#elif __has_feature(objc_arc)                   //objc_arc

    #define WEAK        unsafe_unretained
    #define __WEAK      __unsafe_unretained
    #define STRONG      strong

    #define AUTORELEASE self
    #define RELEASE     self
    #define RETAIN      self
    #define CFTYPECAST(exp) (__bridge exp)
    #define TYPECAST(exp) (__bridge_transfer exp)
    #define CFRELEASE(exp) CFRelease(exp)
    #define DEALLOC     self

#else                                           //none
    #define WEAK        assign
    #define __WEAK
    #define STRONG      retain

    #define AUTORELEASE autorelease
    #define RELEASE     release
    #define RETAIN      retain
    #define CFTYPECAST(exp) (exp)
    #define TYPECAST(exp)   (exp)
    #define CFRELEASE(exp)  CFRelease(exp)
    #define DEALLOC         dealloc

#endif



#if  __has_feature(objc_arc)

#define DISPATCH_RELEASE(exp) self

#else

#define DISPATCH_RELEASE(exp)      dispatch_release(exp)


#endif

#define BlockWeakObject(o) __block __weak __typeof__(o)
#define BlockWeakSelf   BlockWeakObject(self)
#define DefineWeakSelf()  BlockWeakSelf wself=self;






#endif
