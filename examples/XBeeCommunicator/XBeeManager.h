//
//  SensorsManager.h
//  iNoCry
//
//  Created by Egor Leonenko on 26.4.10.
//  Copyright 2010 iTransition. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "USBSerialDeviceManager.h"
#import "XBee.h"

@interface XBeeManager : NSObject<USBSerialDeviceManagerDelegate> {
    NSArray* xbs;
    io_iterator_t newMatchingServiceNotification;
    NSArray* serialManagers;
    NSObject<XBeeDelegate>* xbDelegate;
}
@property(assign, nonatomic) IBOutlet NSObject<XBeeDelegate>* xbDelegate;

@property(readonly) IBOutlet NSArray* xbs;

-(void) stop;
@property (assign) IBOutlet NSPopUpButton *atCommands;
- (IBAction)getATValue:(id)sender;
@property (assign) IBOutlet NSTextField *atValue;
- (IBAction)setATValue:(id)sender;

@end
