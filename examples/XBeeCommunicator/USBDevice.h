//
//  USBDevice.h
//  iNoCry
//
//  Created by Egor Leonenko on 29.4.10.
//  Copyright 2010 iTransition. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <IOKit/usb/IOUSBLib.h>

@protocol USBDeviceDelegate;

@interface USBDevice : NSObject {
    UInt16 vendorId;
    UInt16 productId;
    NSString* name;
    NSString* serial;
    
    BOOL available;

    IOUSBDeviceInterface **deviceInterface;
    UInt32 locationId;
    NSObject<USBDeviceDelegate>* delegate;
}
@property(assign) NSObject<USBDeviceDelegate>* delegate;
@property(readonly) UInt16 vendorId;
@property(readonly) UInt16 productId;
@property(readonly) UInt32 locationId;
@property(readonly) NSString* name;
@property(readonly) NSString* serial;
@property(readonly) BOOL available;

-(id) initFromIOService:(io_service_t) usbDevice;

-(void) terminate;


+(USBDevice*) newFromIOService:(io_service_t) usbDevice;
@end

@protocol USBDeviceDelegate
-(void) usbDeviceTerminated:(USBDevice*) device;
@end