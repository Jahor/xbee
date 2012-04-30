//
//  USBDevice.m
//  iNoCry
//
//  Created by Egor Leonenko on 29.4.10.
//  Copyright 2010 iTransition. All rights reserved.
//

#import "USBDevice.h"
#import <IOKit/IOBSD.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/IOCFPlugIn.h>

@implementation USBDevice

@synthesize vendorId, productId, name, locationId, available, delegate, serial;

-(void) dealloc {
	[name release];
    if (deviceInterface) {
        (*deviceInterface)->Release(deviceInterface);
    }
    
    [super dealloc];
}

-(NSString*) description {
    return [NSString stringWithFormat:@"%@ (0x%04lx:0x%04lx) @ %lu", name, vendorId, productId, locationId];
}

-(id) initFromIOService:(io_service_t) usbDevice {
    
    if(self = [super init]) {
        IOCFPlugInInterface	**plugInInterface = NULL;
        SInt32				score;
        HRESULT 			res;
        io_name_t       deviceName;
        kern_return_t		kr;
        
        // Get the USB device's name.
        kr = IORegistryEntryGetName(usbDevice, deviceName);
        if (KERN_SUCCESS != kr) {
            deviceName[0] = '\0';
        }
        
        name = [[NSString alloc] initWithUTF8String: deviceName];
        // Dump our data to stderr just to see what it looks like.
        //NSLog(@"deviceName: %@", name);    
        
        
        // Now, get the locationID of this device. In order to do this, we need to create an IOUSBDeviceInterface 
        // for our device. This will create the necessary connections between our userland application and the 
        // kernel object for the USB Device.
        kr = IOCreatePlugInInterfaceForService(usbDevice, kIOUSBDeviceUserClientTypeID, kIOCFPlugInInterfaceID,
                                               &plugInInterface, &score);
        
        if ((kIOReturnSuccess != kr) || !plugInInterface) {
            NSLog(@"IOCreatePlugInInterfaceForService returned 0x%08x.\n", kr);
            return nil;
        }
        
        // Use the plugin interface to retrieve the device interface.
        res = (*plugInInterface)->QueryInterface(plugInInterface, CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID),
                                                 (LPVOID*) &deviceInterface);
        
        // Now done with the plugin interface.
        (*plugInInterface)->Release(plugInInterface);
        
        if (res || deviceInterface == NULL) {
            NSLog(@"QueryInterface returned %d.", (int) res);
            return nil;
        }
        
        // Now that we have the IOUSBDeviceInterface, we can call the routines in IOUSBLib.h.
        // In this case, fetch the locationID. The locationID uniquely identifies the device
        // and will remain the same, even across reboots, so long as the bus topology doesn't change.
        
        kr = (*deviceInterface)->GetLocationID(deviceInterface, &locationId);
        if (KERN_SUCCESS != kr) {
            NSLog(@"GetLocationID returned 0x%08x.", kr);
            return nil;
        }
        else {
            //NSLog(@"Location ID: 0x%08lx", locationId);
        }
        
        kr = (*deviceInterface)->GetDeviceProduct(deviceInterface, &productId);
        if (KERN_SUCCESS != kr) {
            NSLog(@"GetDeviceProduct returned 0x%08x.", kr);
            return nil;
        }
        else {
            //NSLog(@"Product ID: 0x%04lx", productId);
        }
        
        kr = (*deviceInterface)->GetDeviceVendor(deviceInterface, &vendorId);
        if (KERN_SUCCESS != kr) {
            NSLog(@"GetDeviceVendor returned 0x%08x.", kr);
            return nil;
        }
        else {
            //NSLog(@"Vendor ID: 0x%04lx", vendorId);
        }
        
        available = true;
                
    }
    return self;
}

-(void) terminate {
    available = false;
    [delegate usbDeviceTerminated: self];
}

+(USBDevice*) newFromIOService:(io_service_t) usbDevice {
    return [[USBDevice alloc] initFromIOService: usbDevice];
}
@end
