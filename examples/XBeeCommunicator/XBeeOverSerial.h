//
//  XBeeOverSerial.h
//  XBeeCommunicator
//
//  Created by Jagor Lavonienka on 13.5.12.
//  Copyright (c) 2012 iTransition. All rights reserved.
//

#import "XBee.h"
#include <IOKit/serial/ioss.h>
#import "USBSerialDevice.h"

@interface XBeeOverSerial : XBee<USBDeviceDelegate>

-(id) initWithBaseDevice:(USBSerialDevice*) device;

@property(readonly) USBSerialDevice* device;

@end
