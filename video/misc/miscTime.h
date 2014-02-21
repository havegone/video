//
//  time.h
//  video
//
//  Created by Tommy on 14-2-20.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#ifndef miscTime_h
#define miscTime_h

#include <mach/mach.h>
#include <mach/mach_time.h>


static inline uint64_t GetTickCount(void)
{
    static mach_timebase_info_data_t sTimebaseInfo;
    uint64_t machTime = mach_absolute_time();
    
    // Convert to nanoseconds - if this is the first time we've run, get the timebase.
    if (sTimebaseInfo.denom == 0 )
    {
        (void) mach_timebase_info(&sTimebaseInfo);
    }
    
    // Convert the mach time to milliseconds
    uint64_t millis = ((machTime / 1000000) * sTimebaseInfo.numer) / sTimebaseInfo.denom;
    return millis;
}



#endif  //miscTime_h
