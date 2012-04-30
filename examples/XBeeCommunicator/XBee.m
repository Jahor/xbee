//
//  Sensor.m
//  iNoCry
//
//  Created by Egor Leonenko on 26.4.10.
//  Copyright 2010 iTransition. All rights reserved.
//

#import "XBee.h"
#include <sys/ioctl.h>
#include "../../lib/xbee.h"
#include "../../lib/xbee_utils.h"

#define BUFFER_SIZE 1500

#define BAUD_RATE B115200

@interface XBee() 

-(size_t) writeBytes: (void*) data  length: (size_t) len;
-(void) log:(NSString*) message;
-(void) error:(NSString*) message;

-(void) processATCommand: (const char*) command responseOn: (XBeeFrameId) frameId status: (XBeeATCommandStatus) status data: (void*) data length:(size_t) dataLength;

@end


static size_t XBeeWrite(xbee* xbee, void* data, size_t dataLength) {
    XBee* x = XBeeUserData(xbee);
    return [x writeBytes: data length: dataLength];;
}

static NSString* dumpString(void* data, size_t dataLength) {
    size_t buffer_length = dataLength * 3 + 1;
    char* buffer = malloc(buffer_length);
    hexDump(buffer, buffer_length, data, dataLength);
    NSString* result = [NSString stringWithFormat:@"%s", buffer];
    free(buffer);
    return result;
}

static NSString* receiveOptionsString(XBeeReceiveOptions options) {
    char buffer[17];
    XBeeReceiveOptionsString(buffer, 17, options);
    return [NSString stringWithFormat:@"%s", buffer];
}

static void XBeeOnATCommandResponseHandler(xbee* xbee, XBeeFrameId frameId, const char* atCommand, XBeeATCommandStatus status, void* data, size_t dataLength) {
    XBee* x = XBeeUserData(xbee);
    [x processATCommand: atCommand responseOn: frameId status: status data: data length: dataLength];
}

static void XBeeOnModemStatusHandler(xbee* xbee, XBeeModemStatus status) {
    XBee* x = XBeeUserData(xbee);
    [x log: [NSString stringWithFormat: @"[---] Modem status %s\n", XBeeModemStatusString(status)]];
}

static void XBeeOnZigBeeTransmitStatusHandler(xbee* xbee, XBeeFrameId frameId, ZigBeeShortAddress destinationShort, uint8_t transmitRetryCount, XBeeDeliveryStatus deliveryStatus, XBeeDiscoveryStatus discoveryStatus) {
    XBee* x = XBeeUserData(xbee);
    [x log: [NSString stringWithFormat: @"[%03d] Transmit to 0x%04X. Retries: %d. Delivery: %s. Discovery: %s \n", frameId, destinationShort, transmitRetryCount, XBeeDeliveryStatusString(deliveryStatus), XBeeDiscoveryStatusString(discoveryStatus)]];    
}

static void XBeeOnZigBeeReceivePacketHandler(xbee* xbee, ZigBeeLongAddress sourceLong, ZigBeeShortAddress sourceShort, XBeeReceiveOptions receiveOptions, void* data, size_t dataLength) {
    XBee* x = XBeeUserData(xbee);
    [x log: [NSString stringWithFormat: @"[---] Packet from 0x%08X %08X (0x%04X). Options: %@. Data:\n%@\n", sourceLong.high, sourceLong.low, sourceShort, receiveOptionsString(receiveOptions), dumpString(data, dataLength)]];
}

static void XBeeOnZigBeeExplicitRxIndicatorHandler(xbee* xbee, ZigBeeLongAddress sourceLong, ZigBeeShortAddress sourceShort, 
                                                   ZigBeeEndpoint sourceEndpoint, ZigBeeEndpoint destinationEndpoint, 
                                                   ZigBeeCluster cluster, ZigBeeProfile profile, 
                                                   XBeeReceiveOptions receiveOptions, void* data, size_t dataLength) {
    XBee* x = XBeeUserData(xbee);
    [x log: [NSString stringWithFormat: @"[---] ZigBee request from 0x%08X %08X (0x%04X). Endpoint: 0x%02X. Cluster ID: 0x%04X. Profile ID: 0x%04X. Options: %@. To Endpoint: 0x%02X. Data:\n%@\n", 
              sourceLong.high, sourceLong.low, sourceShort, sourceEndpoint, cluster, profile, receiveOptionsString(receiveOptions), destinationEndpoint, dumpString(data, dataLength)]];
}

static void XBeeOnZigBeeIODataSampleRxIndicatorHandler(xbee* xbee, ZigBeeLongAddress sourceLong, ZigBeeShortAddress sourceShort, XBeeReceiveOptions receiveOptions,
                                                       XBeeDigitalChannels digitalMask, XBeeAnalogChannels analogMask, XBeeDigitalChannels digitalSamples, XBeeADValue *analogSamples) {
    XBee* x = XBeeUserData(xbee);
    [x log: @"ZigBeeIODataSampleRxIndicator"];
}

static void XBeeOnXBeeSensorReadIndicatorHandler(xbee* xbee, ZigBeeLongAddress sourceLong, ZigBeeShortAddress sourceShort, XBeeReceiveOptions receiveOptions, 
                                                 XBeeOneWireSensors oneWireSensors, XBeeADValue *ad, int adCount, XBeeADValue temperature) {
    XBee* x = XBeeUserData(xbee);
    [x log: @"XBeeSensorReadIndicator"];
}

static void XBeeOnNodeIdentificationIndicatorHandler(xbee* xbee, ZigBeeLongAddress senderLong, ZigBeeShortAddress senderShort, XBeeReceiveOptions receiveOptions, 
                                                     ZigBeeShortAddress sourceShort, ZigBeeLongAddress sourceLong, const char* ni, ZigBeeShortAddress parentShort, ZigBeeDeviceType deviceType, XBeeSourceEvent sourceEvent) {
    XBee* x = XBeeUserData(xbee);
    [x log: [NSString stringWithFormat: @"[---] Node Identification from 0x%08X %08X (0x%04X). Options: %@. %s 0x%08X %08X (0x%04X) - '%s'. Parent: 0x%04X. Event: %s\n", 
              senderLong.high, senderLong.low, senderShort, receiveOptionsString(receiveOptions), 
              ZigBeeDeviceTypeString(deviceType), sourceLong.high, sourceLong.low, sourceShort, ni, parentShort, XBeeSourceEventString(sourceEvent)]];
}

static void XBeeOnRemoteATCommandResponseHandler(xbee* xbee, XBeeFrameId frameId, ZigBeeLongAddress sourceLong, ZigBeeShortAddress sourceShort, const char* atCommand,
                                                 XBeeATCommandStatus status, void* data, size_t dataLength) {
    XBee* x = XBeeUserData(xbee);
    [x log: [NSString stringWithFormat: @"[%03d] AT Command on 0x%08X %08X (0x%04X) %s: %s. Data: \n%@\n", frameId, sourceLong.high, sourceLong.low, sourceShort, atCommand, XBeeATCommandStatusString(status), dumpString(data, dataLength)]];
}

static void XBeeOnOverTheAirFirmwareUpdateStatusHandler(xbee* xbee, ZigBeeLongAddress sourceLong, ZigBeeShortAddress updaterShort, XBeeReceiveOptions receiveOptions, XBeeBootloaderMessageType bootloaderMessageType,
                                                        uint8_t blockNumber, ZigBeeLongAddress targetLong) {
    XBee* x = XBeeUserData(xbee);
    [x log: @"OverTheAirFirmwareUpdateStatus"];
}

static void XBeeOnRouteRecordIndicatorHandler(xbee* xbee, ZigBeeLongAddress sourceLong, ZigBeeShortAddress sourceShort, XBeeReceiveOptions receiveOptions, uint8_t numberOfAddresses,
                                              ZigBeeShortAddress *addresses) {
    XBee* x = XBeeUserData(xbee);
    [x log: @"RouteRecordIndicator"];
}

static void XBeeOnManyToOneRouteRequestIndicatorHandler(xbee* xbee, ZigBeeLongAddress sourceLong, ZigBeeShortAddress sourceShort) {
    XBee* x = XBeeUserData(xbee);
    [x log: @"ManyToOneRouteRequestIndicator"];
}

@implementation XBee {
    BOOL readThreadRunning;
    xbee xb;
}
@synthesize delegate, device;


#pragma mark General functionality
-(NSString*) name {
    return self.device.name;
}

-(void) error:(NSString*) message {
    NSLog(@"Error: %@", message);
    if([delegate respondsToSelector: @selector(xbee:error:)]) {
        [delegate xbee: self
                 error: message];
    }
}

-(void) log:(NSString*) message {
    NSLog(@"%@", message);
    if([delegate respondsToSelector: @selector(xbee:error:)]) {
        [delegate xbee: self
                 info: message];
    }
}

-(BOOL) connected {
    return serialFileDescriptor != -1;
}

-(BOOL) connect {
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
	
	// make sure the port is closed if a problem happens
	if ((serialFileDescriptor != -1) && (errorMessage != nil)) {
        close(serialFileDescriptor);
        serialFileDescriptor = -1;
	}
	
    if (errorMessage) {
        NSLog(@"Error: %@", errorMessage);
        [self error: errorMessage];
        return NO;
    }
    
    XBeeInit(&xb, XBeeAPIEscaped, XBeeWrite, self);
    
    XBeeRegisterOnATCommandResponse(&xb, XBeeOnATCommandResponseHandler);
    XBeeRegisterOnModemStatus(&xb, XBeeOnModemStatusHandler);
    XBeeRegisterOnTransmitStatus(&xb, XBeeOnZigBeeTransmitStatusHandler);
    XBeeRegisterOnReceivePacket(&xb, XBeeOnZigBeeReceivePacketHandler);
    XBeeRegisterOnExplicitRxIndicator(&xb, XBeeOnZigBeeExplicitRxIndicatorHandler);
    XBeeRegisterOnIODataSampleRxIndicator(&xb, XBeeOnZigBeeIODataSampleRxIndicatorHandler);
    XBeeRegisterOnXBeeSensorReadIndicator(&xb, XBeeOnXBeeSensorReadIndicatorHandler);
    XBeeRegisterOnNodeIdentificationIndicator(&xb, XBeeOnNodeIdentificationIndicatorHandler);
    XBeeRegisterOnRemoteATCommandResponse(&xb, XBeeOnRemoteATCommandResponseHandler);
    XBeeRegisterOnOverTheAirFirmwareUpdateStatus(&xb, XBeeOnOverTheAirFirmwareUpdateStatusHandler);
    XBeeRegisterOnRouteRecordIndicator(&xb, XBeeOnRouteRecordIndicatorHandler);
    XBeeRegisterOnManyToOneRouteRequestIndicator(&xb, XBeeOnManyToOneRouteRequestIndicatorHandler);
	

    [self performSelectorInBackground:@selector(incomingTextUpdateThread:) withObject:[NSThread currentThread]];
    
	[delegate xbee:self info: @"Connected"];
    return YES;
}

-(size_t) writeBytes: (void*) data length: (size_t) len {
	if (serialFileDescriptor > 0) {
        NSLog(@"Write: %@", dumpString(data, len));
		return write(serialFileDescriptor, data, len);
	}
	return 0;	
}

// This selector/function will be called as another thread...
//  this thread will read from the serial port and exits when the port is closed
- (void)incomingTextUpdateThread: (NSThread *) parentThread {
	

	
	// mark that the thread is running
	readThreadRunning = TRUE;
	
	char byte_buffer[BUFFER_SIZE]; // buffer for holding incoming data
	int numBytes=0; // number of bytes read during read
	
	// assign a high priority to this thread
	[NSThread setThreadPriority:1.0];
	
	// this will loop unitl the serial port closes
	while(TRUE) {
        // create a pool so we can use regular Cocoa stuff
        //   child threads can't re-use the parent's autorelease pool
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		// read() blocks until some data is available or the port is closed
		numBytes = read(serialFileDescriptor, byte_buffer, BUFFER_SIZE); // read up to the size of the buffer
		if(numBytes>0) {
            NSLog(@"Received data: \n %@\n", dumpString(byte_buffer,  numBytes));
            XBeeAddData(&xb, byte_buffer, numBytes);
		} else {
			break; // Stop the thread if there is an error
		}
        [pool release];
	}
	
	// make sure the serial port is closed
	if (serialFileDescriptor != -1) {
		close(serialFileDescriptor);
		serialFileDescriptor = -1;
	}
	
	// mark that the thread has quit
	readThreadRunning = FALSE;
	// give back the pool
	
}

-(void) dealloc {
	//[self cancelCommand];
    [self disconnect];
    
	[commandsQueue release];
	commandsQueue = nil;
	
	[device release];
	device = nil;
    
    [super dealloc];
}

-(id) initWithBaseDevice:(USBSerialDevice*) aDevice {
    if(self = [super init]) {
        
        commandsQueue = [[NSOperationQueue alloc] init];
        [commandsQueue setMaxConcurrentOperationCount: 1];
        
        serialFileDescriptor = -1;
        device = [aDevice retain];
        device.delegate = self;
        readThreadRunning = NO;
	}
    return self;
}

-(void) usbDeviceTerminated:(USBDevice*) aDevice {
    [self disconnect];
	device = nil;
}

-(BOOL) disconnect {
    [delegate xbee:self info: @"Disconnected"];
    // close serial port if open
    //portName = nil;
	if (serialFileDescriptor != -1) {
		close(serialFileDescriptor);
		serialFileDescriptor = -1;
       return YES;
	}
    return NO;
}


#pragma mark XBee Properties

-(uint64_t) address {
    if (!addressRead) {
        XBeeSendATCommand(&xb, "DH", NULL);
        XBeeSendATCommand(&xb, "DL", NULL);
    }
    return address;
}

-(uint64_t) serialNumber {
    if (serialNumber == 0) {
        XBeeSendATCommand(&xb, "SH", NULL);
        XBeeSendATCommand(&xb, "SL", NULL);
    }
    return serialNumber;
}

-(uint16_t) networkAddress {
    if (!networkAddressRead) {
        XBeeSendATCommand(&xb, "MY", NULL);
    }
    return networkAddress;
}

-(uint16_t) parentAddress {
    if (!parentAddressRead) {
        XBeeSendATCommand(&xb, "MP", NULL);
    }
    return parentAddress;
}

-(void) sendPacket:(NSData*) data to:(uint64_t) to {
    ZigBeeLongAddress addr;
    addr.full = to;
    XBeeSendZigBeeTransmitRequest(&xb, addr, ZigBeeShortAddressUnknown, 0, XBeeTransmitOptionsNone, (void*) [data bytes], [data length]);
}

/*
@property(assign, nonatomic) uint64_t address;
@property(readonly, nonatomic) uint16_t networkAddress;
@property(readonly, nonatomic) uint16_t parentAddress;
@property(readonly, nonatomic) uint64_t serialNumber;
@property(copy, nonatomic) NSString* nodeIdentifier;*/

-(void) processATCommand: (const char*) command responseOn: (XBeeFrameId) frameId status: (XBeeATCommandStatus) status data: (void*) data length:(size_t) dataLength {
    [self log: [NSString stringWithFormat: @"[%03d] AT Command %s: %s. Data: \n%@\n", frameId, command, XBeeATCommandStatusString(status), dumpString(data, dataLength)]];
    if (status == XBeeATCommandOk) {
        if (strcmp(command, "DH") == 0) {
            if (data && dataLength == sizeof(uint32_t)) {
                uint64_t value = ntohl(*((uint32_t*)data));
                [self willChangeValueForKey:@"address"];
                address = (address & 0xFFFFFFFF) | (value << 32);
                addressRead = YES;
                [self didChangeValueForKey:@"address"];
            }
        } else if (strcmp(command, "DL") == 0) {
            if (data && dataLength == sizeof(uint32_t)) {
                uint64_t value = ntohl(*((uint32_t*)data));
                [self willChangeValueForKey:@"address"];
                address = (address & 0xFFFFFFFF00000000) | value;
                addressRead = YES;
                [self didChangeValueForKey:@"address"];
            }
        } else if (strcmp(command, "SH") == 0) {
            if (data && dataLength == sizeof(uint32_t)) {
                uint64_t value = ntohl(*((uint32_t*)data));
                [self willChangeValueForKey:@"serialNumber"];
                serialNumber = (serialNumber & 0xFFFFFFFF) | (value << 32);
                [self didChangeValueForKey:@"serialNumber"];
            }
        } else if (strcmp(command, "SL") == 0) {
            if (data && dataLength == sizeof(uint32_t)) {
                uint64_t value = ntohl(*((uint32_t*)data));
                [self willChangeValueForKey:@"serialNumber"];
                serialNumber = (serialNumber & 0xFFFFFFFF00000000) | value;
                [self didChangeValueForKey:@"serialNumber"];
            }
        } else if (strcmp(command, "MY") == 0) {
            if (data && dataLength == sizeof(uint16_t)) {
                uint64_t value = ntohs(*((uint16_t*)data));
                [self willChangeValueForKey:@"networkAddress"];
                networkAddress = value;
                networkAddressRead = YES;
                [self didChangeValueForKey:@"networkAddress"];
            }
        } else if (strcmp(command, "MP") == 0) {
            if (data && dataLength == sizeof(uint16_t)) {
                uint64_t value = ntohs(*((uint16_t*)data));
                [self willChangeValueForKey:@"parentAddress"];
                parentAddress = value;
                parentAddressRead = YES;
                [self didChangeValueForKey:@"parentAddress"];
            }
        }
    }
}

@end
