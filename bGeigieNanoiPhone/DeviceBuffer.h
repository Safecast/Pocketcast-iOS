//
//  DeviceBuffer.h
//
//  Created by Nicholas Dolezal on 4/28/15.
//
// *** WORK IN PROGRESS, NOT USABLE ***

#ifndef __Safecast__DeviceBuffer__
#define __Safecast__DeviceBuffer__

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <sys/time.h>   // posix
#include <stdbool.h>


typedef struct SimpleDeviceBuffer
{
    size_t   n;                 // number of elements in buffer
    size_t   idx;               // current index [0 ... n]
    size_t   max_idx;           // maximum value of idx for this LocationBuffer
    int64_t* sys_times;         // system timestamp of xyzs, ms since 1970
    int*     device_ids;        // Rx data - device_id
    double*  cpms;              // Rx data - CPM
    double*  cp5s;              // Rx data - cp5s
    double*  totalcounts;       // Rx data - total counts
    bool*    is_rad_valid;      // Rx data - is radiation valid?  (A/V)
    double*  battery_status;    // Rx data - battery status (mV?  mA?  mW?  percent?)
} SimpleDeviceBuffer;


typedef int DeviceCh_ChTypeID; enum
{
    kDeviceCh_ChType_NULL     = 0,
    kDeviceCh_ChType_None     = 1,
    kDeviceCh_ChType_Hardware = 2,
    kDeviceCh_ChType_Derived  = 3
};



typedef int DeviceChCal_CoefficientTypeID; enum
{
    kDeviceChCal_CoefficientType_NULL                            = 0,
    kDeviceChCal_CoefficientType_None                            = 1,
    kDeviceChCal_CoefficientType_Radiation_CPM_to_uSvh           = 2,
    kDeviceChCal_CoefficientType_Radiation_InherentBackgroundCPM = 3,
    kDeviceChCal_CoefficientType_Radiation_DeadTimeUS            = 4
};

typedef int DeviceChCal_StandardTypeID; enum
{
    kDeviceCh_Cal_Standard_NULL              = 0,
    kDeviceCh_Cal_Standard_None              = 1,
    kDeviceCh_Cal_Standard_Radiation_kEV     = 2
};




typedef int DeviceCh_PropertyID; enum
{
    kDeviceCh_Property_NULL                              = 0,
    kDeviceCh_Property_None                              = 1,
    kDeviceCh_Property_Radiation_GMTubeEnergyCompensated = 2,
    kDeviceCh_Property_Temp_Ambient                      = 3,
    kDeviceCh_Property_Temp_Pyrometer                    = 4,
    kDeviceCh_Property_Temp_DeviceCase                   = 5,
    kDeviceCh_Property_Temp_DeviceCPU                    = 6,
    kDeviceCh_Property_Temp_DeviceBattery                = 7,
    kDeviceCh_Property_Temp_RemoteAtmospheric            = 8,
    kDeviceCh_Property_Sensor_XAxis                      = 9,
    kDeviceCh_Property_Sensor_YAxis                      = 10,
    kDeviceCh_Property_Sensor_ZAxis                      = 11,
    kDeviceCh_Property_DeviceBatteryStatus               = 12
};


typedef int DeviceCh_UnitID; enum
{
    kDeviceCh_Unit_NULL                     = 0,   // (do not use, DB ROWID starts with 1)
    kDeviceCh_Unit_None                     = 1,
    kDeviceCh_Unit_Unknown                  = 2,
    
    kDeviceCh_Unit_Percent                  = 3,    // ID more specifically with property
    
    kDeviceCh_Unit_Radiation_CPM            = 4,
    kDeviceCh_Unit_Radiation_CPS            = 5,
    kDeviceCh_Unit_Radiation_CP5s           = 6,
    
    kDeviceCh_Unit_Radiation_CountTotal     = 7,
    kDeviceCh_Unit_Radiation_CountDelta     = 8,
    
    kDeviceCh_Unit_Radiation_nSvh           = 9,
    kDeviceCh_Unit_Radiation_uSvh           = 10,
    kDeviceCh_Unit_Radiation_mSvh           = 11,
    kDeviceCh_Unit_Radiation_Svh            = 12,
    
    kDeviceCh_Unit_Radiation_nSv            = 13,
    kDeviceCh_Unit_Radiation_uSv            = 14,
    kDeviceCh_Unit_Radiation_mSv            = 15,
    kDeviceCh_Unit_Radiation_Sv             = 16,
    
    kDeviceCh_Unit_Timestamp_UnixTimeSS     = 17,
    kDeviceCh_Unit_Timestamp_RFC3339        = 18,
    
    kDeviceCh_Unit_Energy_nV                = 19,
    kDeviceCh_Unit_Energy_mV                = 20,
    kDeviceCh_Unit_Energy_V                 = 21,
    kDeviceCh_Unit_Energy_KV                = 22,
    kDeviceCh_Unit_Energy_nA                = 23,
    kDeviceCh_Unit_Energy_mA                = 24,
    kDeviceCh_Unit_Energy_A                 = 25,
    kDeviceCh_Unit_Energy_nW                = 26,
    kDeviceCh_Unit_Energy_mW                = 27,
    kDeviceCh_Unit_Energy_W                 = 28,
    kDeviceCh_Unit_Energy_KW                = 39,
    kDeviceCh_Unit_Energy_mWh               = 30,
    kDeviceCh_Unit_Energy_Wh                = 31,
    kDeviceCh_Unit_Energy_KWh               = 32,
    kDeviceCh_Unit_Device_BatteryPercent    = 33,
    kDeviceCh_Unit_Device_ChargeStatus      = 34,
    kDeviceCh_Unit_Device_IsExternalPower   = 35,
    
    kDeviceCh_Unit_Temp_C                   = 36,
    
    kDeviceCh_Unit_Humidity_PercentRH       = 37,
    
    kDeviceCh_Unit_Pressure_mbar            = 38,
    
    kDeviceCh_Unit_Altitude_m               = 39,
    kDeviceCh_Unit_Altitude_km              = 40,
    
    kDeviceCh_Unit_Magnetic_nT              = 41,
    
    kDeviceCh_Unit_Luminance_Lux            = 42,
    
    kDeviceCh_Unit_Acceleration_G           = 43,

    kDeviceCh_Unit_Movement_DegsPerSec      = 44,
    
    kDeviceCh_Unit_Radio_RSSI               = 45,
    
    kDeviceCh_Unit_Device_DeviceSerialID    = 46,
    kDeviceCh_Unit_Device_DeviceModelID     = 47,
    kDeviceCh_Unit_Device_Device_Ver_HW     = 48,
    kDeviceCh_Unit_Device_Device_Ver_FW     = 49,
    kDeviceCh_Unit_Device_Device_Ver_SW     = 50,
    kDeviceCh_Unit_Device_DeviceOwner       = 51,
    kDeviceCh_Unit_Device_DeviceMetadata    = 52,
    
    kDeviceCh_Unit_DeviceIO_ChecksumXOR     = 53,
    kDeviceCh_Unit_DeviceIO_RowOrdinal      = 54,
    kDeviceCh_Unit_DeviceIO_RowsInBufferN   = 55,
    kDeviceCh_Unit_DeviceIO_RowIntervalMS   = 56,
    kDeviceCh_Unit_DeviceIO_RowIntervalSS   = 57,
    kDeviceCh_Unit_DeviceIO_RowsAgeMS       = 58,
    kDeviceCh_Unit_DeviceIO_RowsAgeSS       = 59,
    kDeviceCh_Unit_DeviceIO_DataBytes       = 60    // only for BLOB types
};

typedef int kDeviceCh_DataType; enum
{
    kDeviceCh_DataType_NULL  = 0,   // NULL (do not use, DB ROWID starts with 1)
    kDeviceCh_DataType_None  = 1,   // NULL
    
    kDeviceCh_DataType_u08   = 2,   // uint8_t
    kDeviceCh_DataType_u16   = 3,   // uint16_t
    kDeviceCh_DataType_u32   = 4,   // uint32_t
    kDeviceCh_DataType_u64   = 5,   // uint64_t
    
    kDeviceCh_DataType_s08   = 6,   // int8_t
    kDeviceCh_DataType_s16   = 7,   // int16_t
    kDeviceCh_DataType_s32   = 8,   // int32_t
    kDeviceCh_DataType_s64   = 9,   // int64_t

    kDeviceCh_DataType_f16   = 10,  // half (uint16_t in this implementation)
    kDeviceCh_DataType_f32   = 11,  // float
    kDeviceCh_DataType_f64   = 12,  // double
    
    kDeviceCh_DataType_UTF8  = 13,  // char
    kDeviceCh_DataType_UTF16 = 14,  // wchar_t (?)
    
    kDeviceCh_DataType_BLOB  = 15   // void
};

typedef struct DeviceChCal
{
    double calibrationCoefficient;  // eg, 0.0028571429
    double calibrationStandard;     // eg, 667.3
    int    coefficientTypeId;       // eg, kDeviceChCal_CoefficientType_Radiation_CPM_to_uSvh
    int    standardTypeId;          // eg, kDeviceCh_Cal_Standard_Radiation_kEV
} DeviceChCal;


typedef struct DeviceCh
{
    void*        data;                  // data from device, any unit
    size_t       data_n;                // number of elements in above
    
    int          dataTypeId;            // primitive (mostly) data type
    int          unitTypeId;            // SI unit of channel (etc)
    int*         properties;            // may be NULL.  1-to-many DeviceCh_PropertyIDs
    
    DeviceChCal* calibration;           // may be NULL.  1-to-many DeviceChCals.
    
    size_t*      bytesPerElements;      // bytes per element, BLOB/text only
    size_t       bytesPerElements_n;    // number of elements in above
} DeviceCh;

// ============
// DeviceBuffer
// ============
//
// A struct representing the ring buffer entries and indices for measurement
// data received from a device.
//
// You should not access the internal values directly.
//
typedef struct DeviceBuffer
{
    size_t   n;             // number of elements in buffer
    size_t   idx;           // current index [0 ... n]
    size_t   max_idx;       // maximum value of idx for this LocationBuffer
    int64_t* sys_times;     // system timestamp of xyzs, ms since 1970
    int64_t* dev_times;     // device timestamp (if any), ms since 1970
    double*  xs;            // longitude, WGS84 decimal degrees
    double*  ys;            // latitude,  WGS84 decimal degrees
    double*  zs;            // altitude, meters
    double*  xy_precisions; // horizontal precision, meters (negative=invalid)
    double*  z_precisions;  // vertical precision, meters (negative=invalid)
} DeviceBuffer;


// =====================================
// DeviceBuffer_CURRENT_TIMESTAMP_MS_S64
// =====================================
//
// Returns the current timestamp, in UTC milliseconds since 1970-01-01 00:00:00.
//
int64_t DeviceBuffer_CURRENT_TIMESTAMP_MS_S64();


#endif
