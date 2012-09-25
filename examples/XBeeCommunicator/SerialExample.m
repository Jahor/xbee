//
//  SerialExample.m
//  Arduino Serial Example
//
//  Created by Gabe Ghearing on 6/30/09.
//

#import "SerialExample.h"
#import "XBee.h"
#import "XBeeOverUdp.h"

@interface SerialExample()<XBeeDelegate>
@end


@implementation SerialExample {
    XBee* xb;
}
@synthesize color;
@synthesize ledsCount;
@synthesize selectedXBees, xb, remoteXb;


-(void) setSelectedXBees:(NSIndexSet *)newSelectedXBees {
    NSLog(@"XBees selected: %@", newSelectedXBees);
    [selectedXBees autorelease];
    selectedXBees = [newSelectedXBees retain];
    [self willChangeValueForKey:@"xb"];
    if ([selectedXBees count] == 0) {
        [xb release];
        xb = nil;
    } else {
        xb = [[[xbManager xbs] objectAtIndex: [selectedXBees firstIndex]] retain];
    }
    
    [self didChangeValueForKey:@"xb"];
}


// executes after everything in the xib/nib is initiallized
- (void)awakeFromNib {
//    [self performSelector:@selector(initRemoteXb) withObject: nil afterDelay: 2.0];
}

-(void) initRemoteXb {
    [self willChangeValueForKey:@"remoteXb"];
	remoteXb = [[XBeeOverUdp alloc] initWithAddress:@"192.168.1.177" port: 8888];
    remoteXb.delegate = self;
    [remoteXb connect];
    [self didChangeValueForKey:@"remoteXb"];
}

- (IBAction)ledsCountChanged:(id) sender {
    CGFloat r, g, b, a;
    [color.color getRed:&r green:&g blue:&b alpha:&a];
//    r *= a;
//    g *= a;
//    b *= a;
    
    uint8_t data[] = {1, [ledsCount intValue], 127 * r, 127 * g, 127 * b};
    [xb sendPacket:[NSData dataWithBytes: data length:sizeof(data)] to: 0x0013A200402D7D6ALL];
}

- (IBAction)colorChanged:(id)sender {
    [self ledsCountChanged: sender];
}

- (IBAction) serialPortSelected: (id) cntrl {
    
}


-(void) appendHTML:(NSString*) text {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread: _cmd withObject:text waitUntilDone: YES];
        return;
    }
    NSAttributedString* attrString = [[NSMutableAttributedString alloc] initWithHTML:[text dataUsingEncoding: NSUTF8StringEncoding] documentAttributes: NULL];
    NSTextStorage *textStorage = [serialOutputArea textStorage];
    [textStorage beginEditing];
    [textStorage appendAttributedString:attrString];
    [textStorage endEditing];
    [attrString release];
    
    // scroll to the bottom
    NSRange myRange;
    myRange.length = 1;
    myRange.location = [textStorage length];
    [serialOutputArea scrollRangeToVisible:myRange]; 
}

-(void) xbee:(XBee *)lxb info:(NSString *)message {
    [self appendHTML:[NSString stringWithFormat:@"<span style='font-weight: bold'>%@</span>: <span style='color:black'>%@</span><br/>", lxb.name, message]];
}

-(void) xbee:(XBee *)lxb error:(NSString *)message {
    [self appendHTML:[NSString stringWithFormat:@"<span style='font-weight: bold'>%@</span>: <span style='color:red'>%@</span><br/>", lxb.name, message]];
}

// action from baud rate change
- (IBAction) baudAction: (id) cntrl {
	/*if (serialFileDescriptor != -1) {
		speed_t baudRate = [baudInputField intValue];
		
		// if the new baud rate isn't possible, refresh the serial list
		//   this will also deselect the current serial port
		if(ioctl(serialFileDescriptor, IOSSIOSPEED, &baudRate)==-1) {
//			[self refreshSerialList:@"Error: Baud Rate out of bounds"];
			[self log:@"Error: Baud Rate out of bounds"];
		}
	}*/
}


@end
