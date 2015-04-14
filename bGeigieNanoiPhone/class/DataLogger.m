//
//  DataLogger.m
//  bGeigieNanoiPhone
//
//  Created by Mitsuo Okada on 4/13/14.
//  Copyright (c) 2014 Eyes, JAPAN. All rights reserved.
//

// 2015-04-13 ND: + Added Class Bone

#import "DataLogger.h"

@implementation DataLogger

const int RING_BUFFER_SIZE = 100;

// constructor
- (id)init
{
    self = [super init];
    if ( self ) {
        [self initialize];
    }
    return self;
}

- (void)dealloc
{
}


// initialize
-(void)initialize{
    NSLog(@"initialize");
}

// save data file
-(void)save{
    NSLog(@"save");
}

// Clear Ring Buffer
-(void)clearRingBuffer{
    NSLog(@"clearRingBuffer");
}

// Append DataLog
-(void)appendDataLog:(NSString *)nmea{
    NSLog(@"clearRingBuffer");
}

@end
