//
//  USBDevice.h
//  iNoCry
//
//  Created by Egor Leonenko on 29.4.10.
//  Copyright 2010 iTransition. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "USBDevice.h"

@interface USBSerialDevice : USBDevice {
    NSString* portName;
}

@property(readonly) NSString* portName;

+(USBSerialDevice*) newFromIOService:(io_service_t) serialDevice;
@end
