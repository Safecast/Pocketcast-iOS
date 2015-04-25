//
//  LocationBuffer.h
//
//  Created by Nicholas Dolezal on 4/18/15.
//

// LocationBuffer
// ==============
//
// Abstract: Ring buffer struct and related functions for storing and
//           interpolating locations from a timestamp.
//
//     Use:  An instance of LocationBuffer should be initialized and retained.
//           When finished, pass its pointer to the destroy function.
//
// Platform: CoreLocation convention: negated precision = invalid location.
//           Uses Posix functions for timestamps.
//
//     NOTE: The time values used by LocationBuffer are UTC milliseconds since
//           1970, *not* seconds.  This is to allow for greater potential
//           precision.

#ifndef __Safecast__LocationBuffer__
#define __Safecast__LocationBuffer__

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <sys/time.h>   // posix

#define LOCATIONBUFFER_STALE_MS 86400000LL    // 24 hours before flagged bad

// ==============
// LocationBuffer
// ==============
//
// A struct representing the ring buffer entries and indices.
//
// You should not access the internal values directly.
//
typedef struct LocationBuffer
{
    size_t   n;             // number of elements in buffer
    size_t   idx;           // current index [0 ... n]
    size_t   max_idx;       // maximum value of idx for this LocationBuffer
    int64_t* sys_times;     // system timestamp of xyzs, ms since 1970
    int64_t* xyz_times;     // CoreLocation timestamp of xyzs, ms since 1970
    double*  xs;            // longitude, WGS84 decimal degrees
    double*  ys;            // latitude,  WGS84 decimal degrees
    double*  zs;            // altitude, meters
    double*  xy_precisions; // horizontal precision, meters (negative=invalid)
    double*  z_precisions;  // vertical precision, meters (negative=invalid)
} LocationBuffer;

// =======================================
// LocationBuffer_CURRENT_TIMESTAMP_MS_S64
// =======================================
//
// Returns the current timestamp, in UTC milliseconds since 1970-01-01 00:00:00.
//
// NOTE: This is affected by the system timezone.
//
int64_t LocationBuffer_CURRENT_TIMESTAMP_MS_S64();

// ===================
// LocationBuffer_Init
// ===================
//
// Initializes a pointer to a LocationBuffer struct and allocates memory for
// the data vectors, for n elements.

void LocationBuffer_Init(LocationBuffer* src,
                         const size_t     n);

// ======================
// LocationBuffer_Destroy
// ======================
//
// Frees the data vectors in a LocationBuffer and sets their pointers to NULL.
// Zeroes all scalar values.

void LocationBuffer_Destroy(LocationBuffer* src);

// ===================
// LocationBuffer_Push
// ===================
//
// Adds location data to the ring buffer and increments the internal index.

void LocationBuffer_Push(LocationBuffer* src,
                         const int64_t   xyz_time,
                         const double    x,
                         const double    y,
                         const double    z,
                         const double    xy_precision,
                         const double    z_precision);

// ==========================
// LocationBuffer_Interpolate
// ==========================
//
// Given an input timestamp, returns a location derived from the linear
// interpolation of the two nearest stored locations in time.
//
// If the returned xy_precision is negated, the lat/lon is invalid.
// If the returned z_precision is negated, the altitude is invalid.

void LocationBuffer_Interpolate(const LocationBuffer* src,
                                const int64_t         xyz_time,
                                double*               x,
                                double*               y,
                                double*               z,
                                double*               xy_precision,
                                double*               z_precision);

#endif
