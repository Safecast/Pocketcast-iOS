//
//  DeviceBuffer.c
//
//  Created by Nicholas Dolezal on 4/28/15.
//
// *** WORK IN PROGRESS, NOT USABLE ***

#include "DeviceBuffer.h"

// =====================================
// DeviceBuffer_CURRENT_TIMESTAMP_MS_S64
// =====================================
//
// Returns the current timestamp as milliseconds since 1970, as a 64-bit
// signed integer.
//
int64_t DeviceBuffer_CURRENT_TIMESTAMP_MS_S64()
{
    struct timeval te;
    
    gettimeofday(&te, NULL);
    
    int64_t ss = (int64_t)te.tv_sec;
    int64_t us = (int64_t)te.tv_usec;
    
    return (us / 1000LL) + ss * 1000LL;
}//DeviceBuffer_CURRENT_TIMESTAMP_MS_S64