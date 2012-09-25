//
//  XBeeOverSerial.m
//  XBeeCommunicator
//
//  Created by Jagor Lavonienka on 13.5.12.
//  Copyright (c) 2012 iTransition. All rights reserved.
//

#import "XBeeOverSerial.h"
#import "XBee_Internal.h"
#include <sys/ioctl.h>

#define BAUD_RATE B115200

@implementation XBeeOverSerial {
    BOOL readThreadRunning;
    USBSerialDevice* device;
    int serialFileDescriptor; // file handle to the serial port
    struct termios gOriginalTTYAttrs; // Hold the original termios attributes so we can reset them on quit ( best practice )
}

@synthesize device;

-(NSString*) name {
    return self.device.name;
}

-(NSString*) internalConnect {
    NSString* serialPortFile = [device portName];
    //[lineBuffer release];
    //lineBuffer = [[NSMutableString alloc] init];
    int success;
    speed_t baudRate = BAUD_RATE;
    // close the port if it is already open
	if (serialFileDescriptor != -1) {
		close(serialFileDescriptor);
		serialFileDescriptor = -1;
		// wait for the reading thread to die
		while(readThreadRunning);
		// re-opening the same port REALLY fast will fail spectacularly... better to sleep a sec
		sleep(0.5);
	}
	
	// c-string path to serial-port file
	const char *bsdPath = [serialPortFile cStringUsingEncoding:NSUTF8StringEncoding];
	
	// Hold the original termios attributes we are setting
	struct termios options;
	
	// receive latency ( in microseconds )
	unsigned long mics = 3;
	
	// error message string
	NSString *errorMessage = nil;
	// open the port
	//     O_NONBLOCK causes the port to open without any delay (we'll block with another call)
	serialFileDescriptor = open(bsdPath, O_RDWR | O_NOCTTY | O_NONBLOCK );
	
	if (serialFileDescriptor == -1) { 
		// check if the port opened correctly
		errorMessage = [NSString stringWithFormat: NSLocalizedString(@"Couldn't open serial port %@", @"Error if we could not open serial port."), serialPortFile];
	} else {
		// TIOCEXCL causes blocking of non-root processes on this serial-port
		success = ioctl(serialFileDescriptor, TIOCEXCL);
		if ( success == -1) { 
			errorMessage = NSLocalizedString(@"Couldn't obtain lock on serial port", @"Error if we could not obtain lock serial port.");
		} else {
			success = fcntl(serialFileDescriptor, F_SETFL, 0);
			if ( success == -1) {
				// clear the O_NONBLOCK flag; all calls from here on out are blocking for non-root processes
				errorMessage = NSLocalizedString(@"Couldn't obtain lock on serial port", @"Error if we could not obtain lock serial port.");
			} else {
               // success = fcntl(serialFileDescriptor, F_NOCACHE, 0);
			if ( success == -1) {
				// clear the O_NONBLOCK flag; all calls from here on out are blocking for non-root processes
				errorMessage = NSLocalizedString(@"Couldn't obtain lock on serial port", @"Error if we could not obtain lock serial port.");
			} else {
				// Get the current options and save them so we can restore the default settings later.
				success = tcgetattr(serialFileDescriptor, &gOriginalTTYAttrs);
				if ( success == -1) { 
					errorMessage = NSLocalizedString(@"Couldn't get serial attributes", @"Error if we could not get current serial port parameters.");
				} else {
					// copy the old termios settings into the current
					//   you want to do this so that you get all the control characters assigned
					options = gOriginalTTYAttrs;
					
					/*
					 cfmakeraw(&options) is equivilent to:
					 options->c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL | IXON);
					 options->c_oflag &= ~OPOST;
					 options->c_lflag &= ~(ECHO | ECHONL | ICANON | ISIG | IEXTEN);
					 options->c_cflag &= ~(CSIZE | PARENB);
					 options->c_cflag |= CS8;
					 */
					cfmakeraw(&options);
                    options.c_cflag |= CCTS_OFLOW;
					
					// set tty attributes (raw-mode in this case)
					success = tcsetattr(serialFileDescriptor, TCSANOW, &options);
					if ( success == -1) {
						errorMessage = NSLocalizedString(@"Coudln't set serial attributes", @"Error if we could not set custom serial port parameters.");
					} else {
						// Set baud rate (any arbitrary baud rate can be set this way)
						success = ioctl(serialFileDescriptor, IOSSIOSPEED, &baudRate);
						if ( success == -1) { 
							errorMessage = [NSString stringWithFormat: @"Baud rate set error: %s (%i)", strerror(errno), errno];  //NSLocalizedString(@"Baud Rate out of bounds", @"Error if selected Baud rate could not be used.");
						} else { 
							// Set the receive latency (a.k.a. don't wait to buffer data)
							success = ioctl(serialFileDescriptor, IOSSDATALAT, &mics);
							if ( success == -1) { 
								errorMessage = NSLocalizedString(@"Coudln't set serial latency", @"Error if we could not configure serial port not to wait for buffer data.");
							}
						}
					}
                }
				}
			}
		}
	}
	
	// make sure the port is closed if a problem happens
	if ((serialFileDescriptor != -1) && (errorMessage != nil)) {
        close(serialFileDescriptor);
        serialFileDescriptor = -1;
        return errorMessage;
	}
    [self performSelectorInBackground:@selector(receiveThread:) withObject:[NSThread currentThread]];
    
    return nil;
}

#define BUFFER_SIZE 300

// This selector/function will be called as another thread...
//  this thread will read from the serial port and exits when the port is closed
- (void)receiveThread: (NSThread *) parentThread {
	// mark that the thread is running
	readThreadRunning = TRUE;
	
	// assign a high priority to this thread
	[NSThread setThreadPriority: 1.0];
	
	// this will loop unitl the serial port closes
	while(TRUE) {
        
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        char byteBuffer[BUFFER_SIZE];
        int bytesRead = 0;
        NSLog(@"Read...");
        bytesRead = read(serialFileDescriptor, byteBuffer, BUFFER_SIZE); // read up to the size of the buffer
		if(bytesRead > 0) {
            NSData* receivedData = [[NSData alloc]initWithBytes: byteBuffer length:bytesRead];
            [self addData: receivedData];
            [receivedData release];
        }
        [pool release];
        
        if (read <= 0) {
            break;
        }
	}
	
    [self internalDisconnect];
	
	// mark that the thread has quit
	readThreadRunning = FALSE;
	// give back the pool
	
}

-(size_t) write: (NSData*) data {
	if (serialFileDescriptor > 0) {
		size_t l = write(serialFileDescriptor, [data bytes], [data length]);
        if (l != [data length]) {
            NSLog(@"Error");
        } else {
            fsync(serialFileDescriptor);
            sync();
        }
        return l;
	}
	return 0;	
}


-(id) initWithBaseDevice:(USBSerialDevice*) aDevice {
    if(self = [super init]) {
        
        serialFileDescriptor = -1;
        device = [aDevice retain];
        device.delegate = self;
	}
    return self;
}

-(void) usbDeviceTerminated:(USBDevice*) aDevice {
    [self disconnect];
	device = nil;
}

-(BOOL) internalDisconnect {
    if (serialFileDescriptor != -1) {
		close(serialFileDescriptor);
		serialFileDescriptor = -1;
        return YES;
	}
    return NO;
}

-(void) dealloc {
    [device release];
	device = nil;
    
    [super dealloc];
}

@end
