//
//  SensorsManager.m
//  iNoCry
//
//  Created by Egor Leonenko on 26.4.10.
//  Copyright 2010 iTransition. All rights reserved.
//

#import "XBeeManager.h"

@interface XBeeManager()

-(void) setNewXBee:(XBee*) newXB;

@end



@implementation XBeeManager
@synthesize atCommands;
@synthesize atValue;
@synthesize xbs, xbDelegate;


+ (NSSet *)keyPathsForValuesAffectingXbConnected
{
    return  [NSSet setWithObjects:@"xb", nil];
}

-(void) stop {
    for (USBSerialDeviceManager* serialManager in serialManagers) {
        [serialManager stop];
    }
}

- (IBAction)getATValue:(id)sender {

}

- (IBAction)setATValue:(id)sender {
}

-(void) start {
    serialManagers = [[NSArray alloc] initWithObjects:
                      [[[USBSerialDeviceManager alloc] initWithDelegate: self
                                                              forVendor: 0x0403
                                                                product: 0x6001] autorelease],
                      
                      nil];
}

-(id) init {
    if (self = [super init]) {
        xbs = [[NSArray alloc] init];
        [self performSelector:@selector(start) withObject:nil afterDelay:1.0];
    }
    return self;
}

-(void) dealloc {
    [xbs release];
    [super dealloc];
}

-(void) tryConnect:(NSArray*) data {
    XBee* newXB = [data objectAtIndex: 0];
    [newXB setDelegate: xbDelegate];
    NSNumber* triesLeft = [data objectAtIndex: 1];
	if ([newXB connect]) {
        [self setNewXBee: newXB];
	} else {
        if ([triesLeft intValue] > 0) {
            [self performSelector: @selector(tryConnect:)
                       withObject: [NSArray arrayWithObjects: newXB, [NSNumber numberWithInt: [triesLeft intValue] - 1], nil]
                       afterDelay: 0.5];
        }
    }
}

-(BOOL) usbSerialDeviceManager:(USBSerialDeviceManager*) manager
                foundNewDevice:(USBSerialDevice*) device {
    if ([device.name isEqualToString: @"XBee Explorer"]) {
        XBee* newXB = [[XBee alloc] initWithBaseDevice: device];
        
        [self tryConnect: [NSArray arrayWithObjects: newXB, [NSNumber numberWithInt: 10], nil]];
        
        [newXB release];
        return YES;
    }
    return NO;
}

-(void) setXbDelegate:(NSObject<XBeeDelegate>*) d {
    xbDelegate = d;
    for (XBee* xb in xbs) {
        [xb setDelegate: xbDelegate];        
    }
}

-(void) setNewXBee:(XBee*) newXB {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:_cmd withObject: newXB waitUntilDone: YES];
        return;
    }
    NSLog(@"Sensor on %@ connected.", newXB.device);
    XBee* xb = [newXB retain];

    [self willChangeValueForKey:@"xbs"];
    [xbs release];
    xbs = [[xbs arrayByAddingObject: xb] retain];
    [self didChangeValueForKey:@"xbs"];    
}

-(void) removeDevice:(USBDevice*) aDevice {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:_cmd withObject: aDevice waitUntilDone: YES];
        return;
    }
    
    NSMutableArray* newXbs = [NSMutableArray arrayWithCapacity: [xbs count] - 1];
    for (XBee* xb in xbs) {
        if (xb.device == aDevice) {
            [xb disconnect];
            [xb release];
        } else {
            [newXbs addObject: xb];
        }        
    }
    [self willChangeValueForKey:@"xbs"];
    [xbs release];
    xbs = [[NSArray alloc] initWithArray: newXbs];
    [self didChangeValueForKey:@"xbs"];
}

-(void) usbSerialDeviceManager:(USBSerialDeviceManager*) manager
                    lostDevice:(USBSerialDevice*) aDevice {
    [self removeDevice: aDevice];
}

@end
