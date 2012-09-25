//
//  SerialExample.h
//  Arduino Serial Example
//
//  Created by Gabe Ghearing on 6/30/09.
//

#import <Cocoa/Cocoa.h>

// import IOKit headers
#include <IOKit/IOKitLib.h>
#include <IOKit/serial/IOSerialKeys.h>
#include <IOKit/IOBSD.h>
#include <IOKit/serial/ioss.h>
#include <sys/ioctl.h>
#import "XBeeOverSerialManager.h"

@interface SerialExample : NSObject {
	IBOutlet NSTextView *serialOutputArea;
	IBOutlet NSTextField *baudInputField;
	IBOutlet XBeeOverSerialManager *xbManager;
}
@property (assign) IBOutlet NSColorWell *color;
@property (assign) IBOutlet NSSlider *ledsCount;
@property(retain, nonatomic) IBOutlet NSIndexSet* selectedXBees;
@property(readonly, nonatomic) IBOutlet XBee* xb;
@property(readonly, nonatomic) IBOutlet XBee* remoteXb;
- (IBAction) ledsCountChanged:(id)sender;
- (IBAction) colorChanged:(id)sender;
- (IBAction) serialPortSelected: (id) cntrl;
- (IBAction) baudAction: (id) cntrl;
@end
