//
//  USBDevice.m
//  iNoCry
//
//  Created by Egor Leonenko on 29.4.10.
//  Copyright 2010 iTransition. All rights reserved.
//

#import "USBSerialDevice.h"
#include <IOKit/IOKitLib.h>
#include <IOKit/IOCFPlugIn.h>
#import <IOKit/serial/IOSerialKeys.h>
#import "USBDevice.h"


kern_return_t findUSBParent(io_registry_entry_t child, io_registry_entry_t* usbDevice) {
    kern_return_t kr;
    io_registry_entry_t parent;
    kr = IORegistryEntryGetParentEntry(child, kIOServicePlane, &parent);
    if (KERN_SUCCESS != kr) {
        return kr;
    } else {
        io_name_t       parentClass;
        kr = IOObjectGetClass(parent, parentClass);
        if (KERN_SUCCESS != kr) {
            return kr;
        }
        if (strcmp(parentClass, "IOUSBDevice") == 0) {
            *usbDevice = parent;
            return KERN_SUCCESS;
        }
        kr = findUSBParent(parent, usbDevice);
        IOObjectRelease(parent);
        return kr;
    }
    
}

@implementation USBSerialDevice

@synthesize portName;

-(id) initWithPort: (NSString*) aPortName
         usbParent: (io_service_t) usbDeivce {
    if(self = [super initFromIOService: usbDeivce]) {
        portName = aPortName;
    }
    return self;
}

-(NSString*) description {
    return [NSString stringWithFormat:@"%@ Port: %@", [super description], portName];
}

-(void) dealloc {
	[portName release];
	[super dealloc];
}

-(id) initFromIOService:(io_service_t)serialDevice {
    kern_return_t		kr;
    io_registry_entry_t parent;
    kr = findUSBParent(serialDevice, &parent);
    if (KERN_SUCCESS != kr) {
        [self dealloc];
        return nil;
    }
    
    if (self = [super initFromIOService: parent]) {
        portName = (NSString*)IORegistryEntryCreateCFProperty(serialDevice, CFSTR(kIOCalloutDeviceKey),  kCFAllocatorDefault, 0);
        //NSLog(@"serial port: %@", portName);    
    }
    IOObjectRelease(parent);
    return self;
}

+(USBSerialDevice*) newFromIOService:(io_service_t) serialDevice {
    return [[USBSerialDevice alloc] initFromIOService:serialDevice];
}
@end
