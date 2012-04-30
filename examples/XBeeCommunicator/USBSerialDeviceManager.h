//
//  USBDeviceManager.h
//  iNoCry
//
//  Created by Egor Leonenko on 29.4.10.
//  Copyright 2010 iTransition. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "USBSerialDevice.h"

@protocol USBSerialDeviceManagerDelegate;

@interface USBSerialDeviceManager : NSObject {
    UInt16 usbVendor;    
    UInt16 usbProduct;
    NSObject<USBSerialDeviceManagerDelegate>* delegate;
}

-(id) initWithDelegate: (NSObject<USBSerialDeviceManagerDelegate>*) aDelegate
             forVendor:(long) anUsbVendor
               product:(long) anUsbProduct;

-(void) stop;

@property(assign) NSObject<USBSerialDeviceManagerDelegate>* delegate;
@end

@protocol USBSerialDeviceManagerDelegate 

-(BOOL) usbSerialDeviceManager:(USBSerialDeviceManager*) manager
                foundNewDevice:(USBSerialDevice*) device;

-(void) usbSerialDeviceManager:(USBSerialDeviceManager*) manager
                    lostDevice:(USBSerialDevice*) device;
                          
@end