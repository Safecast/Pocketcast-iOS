//
//  ViewController.m
//  bGeigieNanoiPhone
//
//  Created by Chen Yongping on 1/7/14.
//  Copyright (c) 2014 Eyes, JAPAN. All rights reserved.
//

// 2015-04-25 ND: + Fix potential memory leak in legacy code
//                + Only use CoreLocation when device is connecting/connected
//                  (or for simulated data)
//                + Enable power management for CoreLocation:
//                  -kCLLocationAccuracyNearestTenMeters
//                  -CLActivityTypeFitness
// 2015-04-24 ND: + Fix timezone/UTC conversions
// 2015-04-18 ND: + Add ring buffer + interpolation for CoreLocation data.
//                  This replaces all older single-value location ivars.
// 2015-04-16 ND: + Bugfix, horizontal accuracy in meters -> HDOP
// 2015-04-16 ND: + Add location HDOP from CoreLocation
//                + Init values for elevation, lat, lon, HDOP.
// 2015-03-30 ND: + Integrate Mitsuo Okada's simulation code
//                + Various nitpicky formatting
// 2015-03-24 ND: + Added CLLocationManager to get location from iPhone
//                + Added NMEA conversion (not verified)
//                + Added last value caching + test string replace (untested)

#import "ViewController.h"

@implementation ViewController

@synthesize locationManager;

- (void)viewDidLoad
{
    [super viewDidLoad];

    _isStart         = false;
    _isStartSimulate = false;
    _centralManager  = NULL;    // 2015-04-24 ND: fix potential memory leak
    
    LocationBuffer_Init(&_locBuf, 256); // 2015-04-18 ND: required init for ring buffer
    
    [self InitLocationManager];
}//viewDidLoad


// 2015-04-18 ND: free C mallocs
- (void)viewDidDisappear:(BOOL)animated
{
    LocationBuffer_Destroy(&_locBuf);
}//viewDidDisappear



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}//didReceiveMemoryWarning

- (IBAction)pushStartbGeigieSimulateButton:(id)sender
{
    if (_isStartSimulate)
    {
        [self stopSimulate];
    }//if
    else
    {
        [self startSimulate];
    }//else
}//pushStartbGeigieSimulateButton

- (IBAction)pushClearButton:(id)sender
{
    [_messageOutputTextView setText:@""];
}//pushClearButton

- (void)sendSimulatedbGeigieData:(NSTimer *)timer
{
    // send dummy data Like BLE Posted
    NSLog(@"sendSimulatedbGeigieData");
    
    NSString* nmea = @"BNRDD,1053,2015-04-14T12:34:02Z,34,3,531,A,3539.3513,N,13941.7015,E,41.00,A,13,76*43";
    
    [self showPeripheralData:nmea];
    
    NSString* eol = @"$";
    [self showPeripheralData:eol];
}//sendSimulatedbGeigieData

- (void)startSimulate
{
    // start bGeigie simulate
    [_startbGeigieSimulateButton setTitle:@"Stop bGeigie Simulate"
                                 forState:UIControlStateNormal];
    
    // 2015-04-24 ND: Only use CoreLocation when a device is connected, or
    //                when app is attempting to connect.
    [self StartLocationManagerUpdates];
    
    _isStartSimulate   = true;
    
    // start timer interval 5 sec
    NSLog(@"start simulate");
    
    _timer = [NSTimer
              scheduledTimerWithTimeInterval:5.0f
              target:self
              selector:@selector(sendSimulatedbGeigieData:)
              userInfo:NULL
              repeats:true];
}//startSimulate


- (void)stopSimulate
{
    // stop timer
    if ([_timer isValid])
    {
        [_timer invalidate];
    }//if
    
    // change label
    [_startbGeigieSimulateButton setTitle:@"Start bGeigie Simulate"
                                 forState:UIControlStateNormal];
    
    // 2015-04-24 ND: Only use CoreLocation when a device is connected, or
    //                when app is attempting to connect.
    [self StopLocationManagerUpdates];
    
    _isStartSimulate   = false;
}//stopSimulate



- (IBAction)pushStartButton:(id)sender
{
    if (_isStart)
    {
        [self stop];
    }//if
    else
    {
        [self start];
    }//else
}//pushStartButton


#pragma mark - start and stop
-(void)start
{
    // 2015-04-24 ND: fix potential memory leak
    if (_centralManager == NULL)
    {
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:NULL];
    }//if
    
    [_startButton setTitle:@"Stop" forState:UIControlStateNormal];
    
    // 2015-04-24 ND: Only use CoreLocation when a device is connected, or
    //                when app is attempting to connect.
    //                Todo: May need to hook into BT events if device dies.
    
    [self StartLocationManagerUpdates];
    
    _isStart = true;
}//start

-(void)stop
{
    if (_connectingPeripheral)
    {
        [_centralManager cancelPeripheralConnection:_connectingPeripheral];
        _connectingPeripheral = NULL;
    }//if
    
    // 2015-04-24 ND: Only use CoreLocation when a device is connected, or
    //                when app is attempting to connect.
    //                Todo: May need to hook into BT events if device dies.
    
    [self StopLocationManagerUpdates];
    
    [_startButton setTitle:@"Start" forState:UIControlStateNormal];
    
    _isStart = false;
}//stop


#pragma mark -add string to text view
- (void)addStringToTextView:(NSString *)message
{
    //To change the properties of UI object, need to return to main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *textViewContent = [_messageOutputTextView text];
        
        NSDateFormatter *dateFormate = [[NSDateFormatter alloc] init];
        [dateFormate setDateFormat:@"yyyy-MM-dd HH:mm:ss zzz"];
        [dateFormate setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"ja_JP"]];
        NSString *dateString = [dateFormate stringFromDate:[NSDate date]];
        
        textViewContent = [NSString stringWithFormat:@"%@:%@\n%@",dateString, message, textViewContent];
        [_messageOutputTextView setText:textViewContent];
    });
}//addStringToTextView


-(NSString *)getSwitchValue
{
    /*
    NSString *selectedUUID;
    if (_txSwitch.on) {
        selectedUUID = TX_CHARACTERISTIC_UUID;
        NSLog(@"switch to TX");
    }else{
        selectedUUID = RX_CHARACTERISTIC_UUID;
        NSLog(@"switch to RX");

    }
    return selectedUUID;
     */
    return RX_CHARACTERISTIC_UUID;
}//getSwitchValue


#pragma mark - delegate methods
// centralManagerDidUpdateState is a required protocol method.
//  Usually, you'd check for other states to make sure the current device supports LE, is powered on, etc.
//  In this instance, we're just using it to wait for CBCentralManagerStatePoweredOn, which indicates
//  the Central is ready to be used.
//
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state != CBCentralManagerStatePoweredOn)
    {
        //if the centralmanage power off, set the state
        [self stop];
        [self addStringToTextView: @"BLE is not power on"];
        
        return;
    }//if
    
    //if central manager power on, change the state
    [_centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]
                                            options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @NO }];
}//centralManagerDidUpdateState


// This callback comes whenever a peripheral that is advertising the TRANSFER_SERVICE_UUID is discovered.
//  We check the RSSI, to make sure it's close enough that we're interested in it, and if it is,
//  we start the connection process
//
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if (!_connectingPeripheral)
    {
        [_centralManager stopScan];
        
        _connectingPeripheral = peripheral;
        
        [self.centralManager connectPeripheral:peripheral options:NULL];
        [self addStringToTextView:@"request to connect peripheral"];
    }//if
}//centralManager didDiscoverPeripheral


// If the connection fails for whatever reason, we need to deal with it.
//
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    [self addStringToTextView:[NSString stringWithFormat:@"Failed to connect to %@. (%@)", peripheral, [error localizedDescription]]];

    NSLog(@"Central node Failed to connect to %@. (%@)", peripheral, error);
}//centralManager didFailToConnectPeripheral


// We've connected to the peripheral, now we need to discover the services and
// characteristics to find the 'transfer' characteristic.
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [self addStringToTextView:@"Peripheral Connected"];
    
    NSLog(@"Central node Peripheral Connected");
    
    // Make sure we get the discovery callbacks
    peripheral.delegate = self;
    
    // Search only for services that match our UUID
    [self addStringToTextView:@"discover service"];
    
    [peripheral discoverServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]];
}//centralManager didConnectPeripheral


-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    
}//centralManager didDisconnectPeripheral


// The Transfer Service was discovered
//
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error)
    {
        [self addStringToTextView:[NSString stringWithFormat:@"Error discovering services: %@", error]];
        NSLog(@"Central node Error discovering services: %@", error);
        
        return;
    }//if
    
    // Loop through the newly filled peripheral.services array, just in case there's more than one.
    for (CBService *service in peripheral.services)
    {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:[self getSwitchValue]]] forService:service];
    }//for
}//peripheral didDiscoverServices


// The Transfer characteristic was discovered.
//  Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains
//
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    // Deal with errors (if any)
    if (error)
    {
        [self addStringToTextView:[NSString stringWithFormat:@"Error discovering characteristics: %@", [error localizedDescription]]];
        NSLog(@"Central node　Error discovering characteristics: %@", [error localizedDescription]);
        
        return;
    }//if
    
    // Again, we loop through the array, just in case.
    for (CBCharacteristic *characteristic in service.characteristics)
    {
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:[self getSwitchValue]]])
        {
            [peripheral setNotifyValue:true forCharacteristic:characteristic];
        }//if
    }//for
}//peripheral didDiscoverCharacteristicsForService



// The peripheral letting us know whether our subscribe/unsubscribe happened or not
//
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        NSLog(@"Central node Error changing notification state: %@", error.localizedDescription);
    }//if
    
    // Exit if it's not the transfer characteristic
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:[self getSwitchValue]]])
    {
        return;
    }//if
    
    // Notification has started
    if (characteristic.isNotifying)
    {
        NSLog(@"Central node Notification began on %@", characteristic);
    }//if
    else
    {
        // Notification has stopped so disconnect from the peripheral
        NSLog(@"Central node Notification stopped on %@.  Disconnecting", characteristic);
    }//else
}//peripheral didUpdateNotificationStateForCharacteristic







// This callback lets us know more data has arrived via notification on the characteristic
//
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        [self addStringToTextView:[NSString stringWithFormat:@"Error when reading characteristics: %@", [error localizedDescription]]];
        NSLog(@"Central node Error when reading characteristics: %@", [error localizedDescription]);
        
        return;
    }//if
    
    NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    
    [self showPeripheralData:stringFromData];
}//peripheral didUpdateValueForCharacteristic


- (void)showPeripheralData:(NSString *)stringFromData
{
    if ([stringFromData isEqualToString:@"$"])
    {
        _dataRecord = [self HackString:_dataRecord]; // 2015-03-30 ND: hack to substitute GPS + time from iPhone
        
        [self addStringToTextView: _dataRecord];
        
        _dataRecord = @"";
    }//if
    
    if (stringFromData)
    {
        _dataRecord = [_dataRecord stringByAppendingString:stringFromData];
    }//if
}//showPeripheralData







/*
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        [self addStringToTextView:[NSString stringWithFormat:@"Error when reading characteristics: %@", [error localizedDescription]]];
        NSLog(@"Central node Error when reading characteristics: %@", [error localizedDescription]);
        return;
    }
    NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    
    //[self addStringToTextView: stringFromData];
    if ([stringFromData isEqualToString:@"$"])
    {
        _dataRecord = [self HackString:_dataRecord];
        
        [self addStringToTextView: _dataRecord];
        
        _dataRecord = @"";
    }
    
    if (stringFromData)
    {
        _dataRecord = [_dataRecord stringByAppendingString:stringFromData];
    }
}
*/


// ==========
// HackString
// ==========
//
// A useless method that substitutes device time / NMEA location for the values in
// the bGeigie string.  This is to simulate doing this for a pGeigie which will
// not have GPS or time.
//
- (NSString*)HackString:(NSString*)src
{
    NSString* base_str;
    base_str = [src stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    NSArray* ar = [base_str componentsSeparatedByString:@","];
    
    if (ar.count != 15)
    {
        NSLog(@"HackString: ERR: CSV did not contain 15 elements.  Aborting.");
        return src;
    }//if
    
    NSString* header = [ar[0] substringFromIndex:1]; // cut '$'

    // 2015-04-18 ND: Replace single-value ivars with ring buffer
    
    double x;
    double y;
    double z;
    double xy_precision;
    double z_precision;
    int64_t current_timestamp_ms = LocationBuffer_CURRENT_TIMESTAMP_MS_S64();
    
    LocationBuffer_Interpolate(&_locBuf, current_timestamp_ms, &x, &y, &z, &xy_precision, &z_precision);
    
    double gpsHDOP = xy_precision / 6.0;
    
    NSString* rfc_date = [self.class GetRfcDateForUnixTimestamp:current_timestamp_ms / 1000LL];
    NSString* nmea     = [self.class GetNmeaLocationForLat:y lon:x];
    
    
    // 2015-04-16 ND: Simulate A/V of of "gpsIsValid" bGeigie log column.  The way the GPS
    //                chipset determines this is unknown.  Therefore, the way CoreLocation
    //                determines validity will be used; invalid is defined as HDOP < 0.0.
    NSString* gpsIsValid = gpsHDOP >= 0.0 ? @"A" : @"V"; // A = ok, V = fail
    
    // 2015-04-16 ND: Simulate number of satellites column.  Again, very basic approximation.
    NSString* numSats    = gpsHDOP >= 0.0 ? @"8" : @"0";
    
    NSString* hdop       = [NSString stringWithFormat:@"%1.2f", gpsHDOP];
    
    NSString* prepare_dest = [NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@",
                      header, ar[1],
                      rfc_date,
                      ar[3], ar[4], ar[5], ar[6],
                      nmea,
                      [NSString stringWithFormat:@"%1.1f", z],
                      gpsIsValid,
                      numSats,
                      hdop];
    
    // get checksum
    const char checksum = [self getCheckSum:(char*)[prepare_dest UTF8String]
                                     length:(int)[prepare_dest length]];

    // make destination26.00,A,140,7*4D
    NSString* dest = [NSString stringWithFormat:@"$%@*%x", prepare_dest, checksum];
    
    return dest;
}//HackString

// https://github.com/Safecast/bGeigieNanoKit/wiki/Nano-Operation-Manual

// 2015-03-30 13:47:03 GMT-6:$
// $BNXRDD,300,2012-12-16T17:58:24Z,31,9,115,A,4618.9996,N,00658.4623,E,587.6,A,77.2,1*1A

// $BNRDD,300,2012-12-16T17:58:31Z,30,1,116,A,4618.9612,N,00658.4831, E, 443.7, A, 5, 1.28*6D
//      0   1                    2  3 4   5 6         7 8          9 10     11 12 13  14

// Header, DeviceID, Date, CPM, CPM5s, TC, RadIsValid, Lat, NS, Lon, EW, Alt, GpsIsValid, NumSats, HDOP, ChkSum



-(void)peripheralDidInvalidateServices:(CBPeripheral *)peripheral
{
    NSLog(@"Central node peripheralDidInvalidateServices");
}//peripheralDidInvalidateServices








- (void)InitLocationManager
{
    self.locationManager                 = [[CLLocationManager alloc] init];
    self.locationManager.delegate        = self;
    
    self.locationManager.distanceFilter  = kCLDistanceFilterNone; // Any movement.
    
    // 2015-04-24 ND: Test kCLLocationAccuracyBest -> kCLLocationAccuracyNearestTenMeters
    //                Test CLActivityTypeFitness
    self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    self.locationManager.activityType    = CLActivityTypeFitness;
    
    // NB: It's possible that CLActivityTypeFitness may fail in a vehicle, or
    //     that the vehicle version would fail for a pedestrian.  This needs
    //     more testing.
}//InitLocationManager


// 2015-04-24 ND: Adding StartLocationManagerUpdates for supporting BT events
//                eventually.
//
//                The location updates should stop if BT is lost for more than
//                time X.
//
//                NOTE: There may be issues with restarting location services
//                      if the app is running in the background.
- (void)StartLocationManagerUpdates
{
    if (   [self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)] // iOS 7 compatibility
        && [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined)
    {
        [self.locationManager requestWhenInUseAuthorization]; // or should be always?
    }//if
    
    if (   [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized
        || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways
        || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse)
    {
        [self.locationManager startUpdatingLocation];
    }//if
    else
    {
        NSLog(@"Can't start CoreLocation: Not authorized: %d.", [CLLocationManager authorizationStatus]);
    }//else
}//StartLocationManagerUpdates

- (void)StopLocationManagerUpdates
{
    // todo: add some check here
    [self.locationManager stopUpdatingLocation];
}//StopLocationManagerUpdates



// callback for GPS infos
/*
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
*/
// 2015-04-24 ND: replace deprecated CoreLocation delegate method
- (void)locationManager:(CLLocationManager*)manager
     didUpdateLocations:(NSArray*)locations
{
    NSTimeInterval xyz_time_ss = 0;
    int64_t        xyz_time_ms = 0;
    CLLocation*    newLocation = NULL;
    
    for (size_t i=0; i<locations.count; i++)
    {
        newLocation = locations[i];
        
        xyz_time_ss = [self.class GetUnixSsForDate:newLocation.timestamp];
        xyz_time_ms = xyz_time_ss * 1000.0;
        
        LocationBuffer_Push(&_locBuf,
                            xyz_time_ms,
                            newLocation.coordinate.longitude,
                            newLocation.coordinate.latitude,
                            newLocation.altitude,
                            newLocation.horizontalAccuracy,
                            newLocation.verticalAccuracy);
        
        
        
        
        // **** debug crap ****
        if (_locBuf.max_idx == 1)
        {
            // only show this once on-device
            
            NSString *m;
            m = [NSString stringWithFormat:@"CoreLocation: { (%1.4f, :%1.4f) alt:%1.0f, time:%@ [Precision: h:%1.1f, v:%1.1f] }",
                 newLocation.coordinate.latitude,
                 newLocation.coordinate.longitude,
                 newLocation.altitude,
                 newLocation.timestamp,
                 newLocation.horizontalAccuracy,
                 newLocation.verticalAccuracy];
            
            [self addStringToTextView:m];
            
            // old debug for timezone conversions, etc.
            /*
            const int64_t   sys_time_ms = [self.class GetUnixMsForCurrentDate];
            const int64_t posix_time_ms = LocationBuffer_CURRENT_TIMESTAMP_MS_S64();
            
            NSString* nssXyzTime   = [self.class GetRfcDateForUnixTimestamp:xyz_time_ms/1000LL];
            NSString* nssSysTime   = [self.class GetRfcDateForUnixTimestamp:sys_time_ms/1000LL];
            NSString* nssPosixTime = [self.class GetRfcDateForUnixTimestamp:posix_time_ms/1000LL];
            
            m = [NSString stringWithFormat:@"Timestamps: { xyz:%lld, sys:%lld, posix:%lld } -> { xyz:%@, sys:%@, posix:%@ }",
                   xyz_time_ms / 1000LL,
                   sys_time_ms / 1000LL,
                 posix_time_ms / 1000LL,
                 nssXyzTime,
                 nssSysTime,
                 nssPosixTime];
            
            [self addStringToTextView:m];
            
            NSLog(@"%@", m);
            */
        }//if
        
        NSLog(@"New Location: %1.8f, %1.8f (Alt:%1.0f) (Time: %@) (hp: %1.2f) (vp: %1.2f)",
              newLocation.coordinate.latitude,
              newLocation.coordinate.longitude,
              newLocation.altitude,
              newLocation.timestamp,
              newLocation.horizontalAccuracy,
              newLocation.verticalAccuracy);
    }//for (each location)
}//locationManager


// This delegate method is invoked when the location managed encounters an error condition.
- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    if ([error code] == kCLErrorDenied)
    {
        NSLog(@"Access denied by user.");
        [manager stopUpdatingHeading];
        [manager stopUpdatingLocation];
        
        // TODO: This represents a system failure condition.
        //       Stronger action must be taken to inform the user they have
        //       denied permissions, and that nothing will work as a result.
    }//if
    else if ([error code] == kCLErrorHeadingFailure)
    {
        NSLog(@"kCLErrorHeadingFailure");
        // This error indicates that the heading could not be determined, most likely because of strong magnetic interference.
    }//else
}//locationManager didFailWithError





// ========================== Static / Class Methods ==========================

// returns the current date as milliseconds since 1970 (UTC)
+ (int64_t)GetUnixMsForCurrentDate
{
    NSDate* src = [NSDate date];
    
    NSTimeInterval dest_ss = [src timeIntervalSince1970];
    
    int64_t dest_ms = dest_ss * 1000.0;
    
    return dest_ms;
}//GetUnixMsForCurrentDate

// Converts NSDate to seconds since 1970 (UTC)
+ (NSTimeInterval)GetUnixSsForDate:(NSDate*)src
{
    NSTimeInterval dest = [src timeIntervalSince1970];
    
    return dest;
}//GetUnixSsForDate

// Converts unix timestamp to RFC3337 string representation used by the log.
+ (NSString*)GetRfcDateForUnixTimestamp:(const int64_t)timeSS
{
    NSDate* src = [NSDate dateWithTimeIntervalSince1970:timeSS];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    [dateFormatter setTimeZone:gmt];
    
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    NSString *dest = [dateFormatter stringFromDate:src];
    
    return dest;
}//GetRfcDateForUnixTimestamp

// converts lat/lon to a NMEA string representation as used by the log.
+ (NSString*)GetNmeaLocationForLat:(const double)lat
                               lon:(const double)lon
{
    NSString* slat = [NSString stringWithFormat:@"%1.16f", lat];
    NSString* slon = [NSString stringWithFormat:@"%1.16f", lon];
    
    char nmea[25];
    
    deg2nmea((char*)slat.UTF8String, (char*)slon.UTF8String, nmea);
    
    NSString* dest = [NSString stringWithFormat:@"%s", nmea];
    
    return dest;
}//GetNmeaALocationForLat

// from bGeigie firmware source
void deg2nmea(char *lat, char *lon, char *lat_lon_nmea)
{
    double lat_f = strtod(lat, NULL);
    double lon_f = strtod(lon, NULL);
    
    char NS = (lat_f >= 0) ? 'N' : 'S';
    lat_f = (lat_f >= 0) ? lat_f : -lat_f;
    int lat_d = (int)fabs(lat_f);
    double lat_min = (lat_f - lat_d)*60.;
    
    char lat_min_str[9];
    
    snprintf(lat_min_str, 8, "%1.4f", lat_min); // not 100% sure if correct
    //dtostrf(lat_min, 2, 4, lat_min_str);
    
    char EW = (lon_f >= 0) ? 'E' : 'W';
    lon_f = (lon_f >= 0) ? lon_f : -lon_f;
    int lon_d = (int)fabs(lon_f);
    double lon_min = (lon_f - lon_d)*60.;
    
    char lon_min_str[9];
    //dtostrf(lon_min, 2, 4, lon_min_str);
    snprintf(lon_min_str, 8, "%1.4f", lon_min); // not 100% sure if correct
    
    snprintf(lat_lon_nmea, 25, "%02d%s,%c,%03d%s,%c", lat_d, lat_min_str, NS, lon_d, lon_min_str, EW);
}//deg2nmea

// from bGeigie firmware source
-(char)getCheckSum:(char *)s length:(int )N
{
    int i = 0;
    char chk = s[0];
    
    for (i=1 ; i < N ; i++)
        chk ^= s[i];
    
    return chk;
}//getCheckSum




@end
