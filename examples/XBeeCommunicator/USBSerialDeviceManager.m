//
//  USBDeviceManager.m
//  iNoCry
//
//  Created by Egor Leonenko on 29.4.10.
//  Copyright 2010 iTransition. All rights reserved.
//

#import "USBSerialDeviceManager.h"

#include <IOKit/IOMessage.h>
#import <IOKit/serial/IOSerialKeys.h>

static IONotificationPortRef   gNotifyPort;


typedef struct {
    USBSerialDeviceManager* manager;
    USBSerialDevice* device;
    io_object_t notification;
} ManagerDevice;

@interface USBSerialDeviceManager()

-(void) deviceRemoved:(USBSerialDevice*) device;
-(BOOL) deviceAdded:(USBSerialDevice*) device;

@end


//================================================================================================
//
//	DeviceNotification
//
//	This routine will get called whenever any kIOGeneralInterest notification happens.  We are
//	interested in the kIOMessageServiceIsTerminated message so that's what we look for.  Other
//	messages are defined in IOMessage.h.
//
//================================================================================================
static void DeviceNotification(void *refCon, io_service_t service, natural_t messageType, void *messageArgument)
{

    ManagerDevice *info = (ManagerDevice *) refCon;
    
    if (messageType == kIOMessageServiceIsTerminated) {
		NSLog(@"Serial device %u (%p) is about to be removed.", info->notification, info);
		if (info->notification > 0) {
			NSLog(@"Serial Device %@ removed.", info->device);
			[info->manager deviceRemoved: info->device];
			[info->device release];
			IOObjectRelease(info->notification);
			free(info);
		}
    }
}

//================================================================================================
//
//	DeviceAdded
//
//	This routine is the callback for our IOServiceAddMatchingNotification.  When we get called
//	we will look at all the devices that were added and we will:
//
//	1.  Create some private data to relate to each device (in this case we use the service's name
//	    and the location ID of the device
//	2.  Submit an IOServiceAddInterestNotification of type kIOGeneralInterest for this device,
//	    using the refCon field to store a pointer to our private data.  When we get called with
//	    this interest notification, we can grab the refCon and access our private data.
//
//================================================================================================
static void DeviceAdded(void *refCon, io_iterator_t iterator)
{
    kern_return_t		kr;
    io_service_t		serialDevice;

    
    while ((serialDevice = IOIteratorNext(iterator))) {
        
        USBSerialDevice *device = [[USBSerialDevice alloc] initFromIOService: serialDevice];
        if(device != nil) {
            USBSerialDeviceManager* manager = (USBSerialDeviceManager*) refCon;
            NSLog(@"Serial Device %@ added.", device);
            if ([manager deviceAdded: device]) {
                ManagerDevice* info = (ManagerDevice*)calloc(1, sizeof(ManagerDevice));
                info->device = [device retain];
                info->manager = (USBSerialDeviceManager*)refCon;
                // Register for an interest notification of this device being removed. Use a reference to our
                // private data as the refCon which will be passed to the notification callback.
                kr = IOServiceAddInterestNotification(gNotifyPort,						// notifyPort
                                                      serialDevice,						// service
                                                      kIOGeneralInterest,				// interestType
                                                      DeviceNotification,				// callback
                                                      info,                         // refCon
                                                      &(info->notification)         // notification
                                                      );
				NSLog(@"Serial device %u(%p) was added.", info->notification, info);
                if (KERN_SUCCESS != kr) {
                    NSLog(@"IOServiceAddInterestNotification returned 0x%08x.", kr);
                }
            } else {
                NSLog(@"Device %@ is not valid for manager.", device);
                [device release];
            }
        } 
        
        IOObjectRelease(serialDevice);
    }
}

@interface USBSerialDeviceManager()

-(BOOL) initializeSerialDeviceNotifications;

@end


@implementation USBSerialDeviceManager

@synthesize delegate;

-(id) initWithDelegate: (NSObject<USBSerialDeviceManagerDelegate>*) aDelegate
             forVendor: (long) anUsbVendor
               product: (long) anUsbProduct {
    if (self = [super init]) {
        delegate = aDelegate;
        usbVendor = anUsbVendor;
        usbProduct = anUsbProduct;
        if (![self initializeSerialDeviceNotifications]) {
            NSLog(@"Could not create USB Device manager");
            [self dealloc];
            return nil;
        }
    }
    return self;
}

-(BOOL) initializeSerialDeviceNotifications {
    CFMutableDictionaryRef  matchingDict;
    CFRunLoopSourceRef      runLoopSource;
    io_iterator_t           gAddedIter;
    
    matchingDict = IOServiceMatching(kIOSerialBSDServiceValue);	// Interested in instances of class
    // IOUSBDevice and its subclasses
    if (matchingDict == NULL) {
        NSLog(@"IOServiceMatching returned NULL.\n");
        return NO;
    }
    
    // Create a notification port and add its run loop event source to our run loop
    // This is how async notifications get set up.
    
    gNotifyPort = IONotificationPortCreate(kIOMasterPortDefault);
    runLoopSource = IONotificationPortGetRunLoopSource(gNotifyPort);
    
    CFRunLoopRef gRunLoop = [[NSRunLoop currentRunLoop] getCFRunLoop];
    
    CFRunLoopAddSource(gRunLoop, runLoopSource, kCFRunLoopDefaultMode);

    // Now set up a notification to be called when a device is first matched by I/O Kit.
    IOServiceAddMatchingNotification(gNotifyPort,					// notifyPort
                                          kIOFirstMatchNotification,	// notificationType
                                          matchingDict,					// matching
                                          DeviceAdded,					// callback
                                          self,							// refCon
                                          &gAddedIter					// notification
                                          );		
    
    // Iterate once to get already-present devices and arm the notification    
    DeviceAdded(self, gAddedIter);	
    
    return YES;
}

-(void) stop {
    
}

-(void) deviceRemoved:(USBSerialDevice*) device {
    [delegate usbSerialDeviceManager: self
                          lostDevice: device];    
}

-(BOOL) deviceAdded:(USBSerialDevice*) device {
    if(device.vendorId == usbVendor &&
       device.productId == usbProduct) {
        if([delegate usbSerialDeviceManager: self
                             foundNewDevice: device]) {
            NSLog(@"Device %@ was found", device);
            return YES;
        }

    }
    return NO;
}


@end
