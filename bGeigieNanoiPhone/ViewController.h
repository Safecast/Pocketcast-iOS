//
//  ViewController.h
//  bGeigieNanoiPhone
//
//  Created by Chen Yongping on 1/7/14.
//  Copyright (c) 2014 Eyes, JAPAN. All rights reserved.
//

// 2015-04-18 ND: + Add Import for LocationBuffer, a ring buffer implementation
//                  which interpolates the closest locations in time.

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "LocationBuffer.h" // 2015-04-18 ND: Added to implement ring buffer

//#define TRANSFER_SERVICE_UUID       @"79008485-8612-909D-5EBB-8344D8E81258"
#define TRANSFER_SERVICE_UUID       @"EF080D8C-C3BE-41FF-BD3F-05A5F4795D7F"
#define RX_CHARACTERISTIC_UUID      @"A1E8F5B1-696B-4E4C-87C6-69DFE0B0093B"
#define TX_CHARACTERISTIC_UUID      @"1494440E-9A58-4CC0-81E4-DDEA7F74F623"

@interface ViewController : UIViewController <CLLocationManagerDelegate, CBCentralManagerDelegate, CBPeripheralDelegate>
{
    // 2015-03-30 ND: Note: The actual pGeigie data will be sent in a ring buffer,
    //                      which means that these single scalar values will not suffice.
    //                      To support that, a local ring buffer of values should be used,
    //                      with linear interpolation between lat/lon/elevation based upon
    //                      whatever the sampling interval from the pGeigie ends up being.
    
    //double userLat;
    //double userLon;
    //double gpsEle;
    //double gpsHDOP;
    CLLocationManager* locationManager;
    NSTimer* _timer;
    
    LocationBuffer _locBuf;
}

@property (strong, nonatomic) CBCentralManager      *centralManager;
@property (strong, nonatomic) CBPeripheral          *connectingPeripheral;
@property (nonatomic, assign) BOOL                  isStart;
@property (nonatomic, assign) BOOL                  isStartSimulate;
@property (nonatomic, retain) NSString              *dataRecord;

//@property (nonatomic, retain) NSString              *lastNMEA;
//@property (nonatomic, retain) NSString              *lastGMT;

@property (weak, nonatomic) IBOutlet UISwitch *txSwitch;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIButton *startbGeigieSimulateButton;
@property (weak, nonatomic) IBOutlet UIButton *clearButton;

@property (weak, nonatomic) IBOutlet UITextView *messageOutputTextView;

@property (nonatomic, retain) CLLocationManager *locationManager;

- (IBAction)pushStartButton:(id)sender;
- (IBAction)pushStartbGeigieSimulateButton:(id)sender;
- (IBAction)pushClearButton:(id)sender;

@end
