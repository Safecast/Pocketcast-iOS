//
//  LocationBuffer.c
//
//  Created by Nicholas Dolezal on 4/18/15.
//

#include "LocationBuffer.h"

// =======================================
// LocationBuffer_CURRENT_TIMESTAMP_MS_S64
// =======================================
//
// Returns the current timestamp as milliseconds since 1970, as a 64-bit
// signed integer.
//
int64_t LocationBuffer_CURRENT_TIMESTAMP_MS_S64()
{
    struct timeval te;
    
    gettimeofday(&te, NULL);
    
    int64_t ss = (int64_t)te.tv_sec;
    int64_t us = (int64_t)te.tv_usec;
    
    return (us / 1000LL) + ss * 1000LL;
}//LocationBuffer_CURRENT_TIMESTAMP_MS_S64


void LocationBuffer_Init(LocationBuffer* src,
                         const size_t    n)
{
    src->sys_times     = malloc(sizeof(int64_t) * n);
    src->xyz_times     = malloc(sizeof(int64_t) * n);
    src->xs            = malloc(sizeof(double)  * n);
    src->ys            = malloc(sizeof(double)  * n);
    src->zs            = malloc(sizeof(double)  * n);
    src->xy_precisions = malloc(sizeof(double)  * n);
    src->z_precisions  = malloc(sizeof(double)  * n);
    
    src->n            = n;
    src->max_idx      = 0;
    src->idx          = 0;
}//LocationBuffer_Init


void LocationBuffer_Destroy(LocationBuffer* src)
{
    free(src->sys_times);
    free(src->xyz_times);
    free(src->xs);
    free(src->ys);
    free(src->zs);
    free(src->xy_precisions);
    free(src->z_precisions);
    
    src->sys_times     = NULL;
    src->xyz_times     = NULL;
    src->xs            = NULL;
    src->ys            = NULL;
    src->zs            = NULL;
    src->xy_precisions = NULL;
    src->z_precisions  = NULL;
    
    src->n       = 0;
    src->max_idx = 0;
    src->idx     = 0;
}//LocationBuffer_Destroy



void LocationBuffer_Push(LocationBuffer* src,
                         const int64_t   xyz_time,
                         const double    x,
                         const double    y,
                         const double    z,
                         const double    xy_precision,
                         const double    z_precision)
{
    const size_t idx        = src->idx;
    
    src->sys_times[idx]     = LocationBuffer_CURRENT_TIMESTAMP_MS_S64();
    src->xyz_times[idx]     = xyz_time;
    src->xs[idx]            = x;
    src->ys[idx]            = y;
    src->zs[idx]            = z;
    src->xy_precisions[idx] = xy_precision;
    src->z_precisions[idx]  = z_precision;
    
    src->idx                = src->idx < src->n - 1   ? src->idx + 1 : 0;
    src->max_idx            = src->idx > src->max_idx ? src->idx     : src->max_idx;
}//LocationBuffer_Push




// =================================
// LocationBuffer_vssubabs_minvi_s64
// =================================
//
// Vector-scalar subtract, absolute value, and minima find.
//
// Returns the smallest absolute difference between elements in src and
// scalar value x for n elements, optionally skipping index skip_idx.
//
// If no match is found (eg, no elements to search), UINT32_MAX is returned
// as the index.
//
static inline void LocationBuffer_vssubabs_minvi_s64(const int64_t* src,
                                                     const int64_t  x,
                                                     const size_t   skip_idx,
                                                     int64_t*       val,
                                                     size_t*        idx,
                                                     const size_t   n)
{
    int64_t min_diff = INT32_MAX;
    size_t  min_idx  = UINT32_MAX;
    int64_t diff;
    
    for (size_t i = 0; i < n; i++)
    {
        diff = llabs(src[i] - x);
        
        if (diff < min_diff)
        {
            min_diff = diff;
            min_idx  = i;
        }//if
    }//for
    
    *val = min_diff;
    *idx = min_idx;
}//LocationBuffer_vssubabs_minvi_s64


// ====================
// LocationBuffer_LerpD
// ====================
//
// Returns a linear interpolation of a value between x and y, given normalized
// position p.
//
static inline double LocationBuffer_LerpD(const double p,
                                          const double x,
                                          const double y)
{
    return x + (y - x) * p;
}//LocationBuffer_LerpD


// TODO: refactor to be less long
void LocationBuffer_Interpolate(const LocationBuffer* src,
                                const int64_t         xyz_time,
                                double*               x,
                                double*               y,
                                double*               z,
                                double*               xy_precision,
                                double*               z_precision)
{
    int64_t min_diff0, min_diff1;
    size_t  min_idx0 = UINT32_MAX;
    size_t  min_idx1 = UINT32_MAX;
    
    double _x = 0.0;
    double _y = 0.0;
    double _z = 0.0;
    double _xy_precision = -1.0;
    double _z_precision  = -1.0;
    
    // 0. Handle cases where only a single location value is present thus far.
    
    if (src->idx == 1 && src->max_idx == 1)
    {
        _x = src->xs[0];
        _y = src->ys[0];
        _z = src->zs[0];
        _xy_precision = src->xy_precisions[0];
        _z_precision  = src->z_precisions[0];
        
        // a nearest-neighbor match to a single value is kinda dodgy.
        // negate the precision if too long has elapsed since that
        // location was captured.
        
        if (llabs(xyz_time - src->xyz_times[0]) > LOCATIONBUFFER_STALE_MS)
        {
            if (_xy_precision > 0.0)
            {
                _xy_precision = 0.0 - _xy_precision;
            }//if
            
            if (_z_precision > 0.0)
            {
                _z_precision = 0.0 - _z_precision;
            }//if
        }//if
    }//if
    else
    {
        // 1. find the nearest element in time
        
        LocationBuffer_vssubabs_minvi_s64(src->xyz_times,
                                          xyz_time,
                                          UINT64_MAX,
                                          &min_diff0,
                                          &min_idx0,
                                          src->max_idx < src->n - 1 ? src->max_idx
                                                                    : src->n);
        
        // 2. find the second nearest element in time
        //    (this could probably be more efficient, it should be right next to
        //     the above)
        
        LocationBuffer_vssubabs_minvi_s64(src->xyz_times,
                                          xyz_time,
                                          min_idx0,
                                          &min_diff1,
                                          &min_idx1,
                                          src->max_idx < src->n - 1 ? src->max_idx
                                                                    : src->n);
    }//else (find nearest times)

    
    // 3. interpolate and return results as output parameters

    // only interpolate if:
    // 1. it found valid indices (eg, app startup would fail)
    // 2. xyz_time is between the two timestamps
    
    // note: this may need more edge case handling, eg:
    // - what if the two matches are insanely far apart in spatial distance?
    // - what if the CoreLocation timestamp(s) is/are really old?
    
    if (   min_idx0 != UINT32_MAX
        && min_idx1 != UINT32_MAX)
    {
        int64_t t0, t1;
        size_t  i0, i1;
        
        // get actual timestamps
        
        t0 = src->xyz_times[min_idx0];
        i0 = min_idx0;
        t1 = src->xyz_times[min_idx1];
        i1 = min_idx1;
        
        // reorder chronologically if needed
        if (t0 > t1)
        {
            i0 = min_idx1;
            i1 = min_idx0;
            t0 = src->xyz_times[min_idx1];
            t1 = src->xyz_times[min_idx0];
        }//if
        
        // verify xyz_time is between the two timestamps
        if (   t0 <= xyz_time
            && t1 >= xyz_time)
        {
            // offset to first time and normalize
            double dx = xyz_time - t0;
            double d1 = t1 - t0;
            double dn = dx / d1;
            
            // interpolate location and precision
            
            _x            = LocationBuffer_LerpD(dn, src->xs[i0],
                                                 src->xs[i1]);
            
            _y            = LocationBuffer_LerpD(dn, src->ys[i0],
                                                 src->ys[i1]);
            
            _z            = LocationBuffer_LerpD(dn, src->zs[i0],
                                                 src->zs[i1]);
            
            _xy_precision = LocationBuffer_LerpD(dn, src->xy_precisions[i0],
                                                 src->xy_precisions[i1]);
            
            _z_precision  = LocationBuffer_LerpD(dn, src->z_precisions[i0],
                                                 src->z_precisions[i1]);
            
            // make sure a negated precision is reflected in the output
            
            if (_xy_precision >= 0.0
                && (   src->xy_precisions[i0] < 0.0
                    || src->xy_precisions[i1] < 0.0))
            {
                _xy_precision = 0.0 - _xy_precision;
            }//if
            
            if (_z_precision >= 0.0
                && (   src->z_precisions[i0] < 0.0
                    || src->z_precisions[i1] < 0.0))
            {
                _z_precision = 0.0 - _z_precision;
            }//if
            
        }//if (between timestamps)
        else
        {
            // Special Case: The requested time wasn't between the two closest
            //               matches.  This could happen if, for example,
            //               location events stopped being received.
            //
            //               For now, this will be handled via nearest neighbor
            //               to the closest single match, and will be flagged
            //               with a negated precision if longer than a second
            //               has elapsed.
            
            const size_t nnidx = min_diff0 <= min_diff1 ? min_idx0 : min_idx1;
            
            _x = src->xs[nnidx];
            _y = src->ys[nnidx];
            _z = src->zs[nnidx];
            _xy_precision = src->xy_precisions[nnidx];
            _z_precision  = src->z_precisions[nnidx];
            
            // A nearest-neighbor match to a single value is kinda dodgy.
            // Negate the precision if too long has elapsed since that
            // location was captured.
            
            if (llabs(xyz_time - src->xyz_times[nnidx]) > LOCATIONBUFFER_STALE_MS)
            {
                if (_xy_precision > 0.0)
                {
                    _xy_precision = 0.0 - _xy_precision;
                }//if
                
                if (_z_precision > 0.0)
                {
                    _z_precision = 0.0 - _z_precision;
                }//if
            }//if
        }//else (special case handling)
    }//if (valid indices)
    
    *x            = _x;
    *y            = _y;
    *z            = _z;
    *xy_precision = _xy_precision;
    *z_precision  = _z_precision;
}//LocationBuffer_Interpolate




















