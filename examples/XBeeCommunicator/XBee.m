//
//  Sensor.m
//  iNoCry
//
//  Created by Egor Leonenko on 26.4.10.
//  Copyright 2010 iTransition. All rights reserved.
//

#import "XBee.h"
#include "xbee.h"
#include "xbee_utils.h"
#import "XBee_Internal.h"

static NSDictionary* atCommandsDescriptions = nil;

@interface XBee() 

-(size_t) writeBytes: (const void*) data  length: (size_t) len;
-(void) log:(NSString*) message;
-(void) error:(NSString*) message;

-(void) processATCommand: (const char*) command responseOn: (XBeeFrameId) frameId status: (XBeeATCommandStatus) status data: (void*) data length:(size_t) dataLength;

@end


static size_t XBeeWrite(xbee* xbee, const void* data, size_t dataLength) {
    XBee* x = XBeeUserData(xbee);
    return [x writeBytes: data length: dataLength];
}

static NSString* dumpString(const void* data, size_t dataLength) {
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
    xbee xb;
    
    NSObject<XBeeDelegate>* delegate;
    
    NSOperationQueue* commandsQueue;
    
    NSMutableData* transmitBuffer;
    
    uint16_t networkAddress;
    BOOL networkAddressRead;
    uint16_t parentAddress;
    BOOL parentAddressRead;
    uint64_t serialNumber;
    NSString* nodeIdentifier;
    BOOL firmwareVersionRead;
    uint16_t firmwareVersion;
    BOOL hardwareVersionRead;
    uint16_t hardwareVersion;
    BOOL supplyVoltageRead;
    uint16_t supplyVoltage;
    
}
@synthesize delegate;

+(void) initialize {
    if (!atCommandsDescriptions) {
        atCommandsDescriptions = [@{@"DH" : @"Destination Address High",
        @"DL" : @"Destination Address Low",
        @"MY" : @"16-bit Network Address",
        @"MP" : @"16-bit Parent Network Address",
        @"NC" : @"Number of Remaining Children",
        @"SH" : @"Serial Number High",
        @"SL" : @"Serial Number Low",
        @"NI" : @"Node Identifier",
        @"SE" : @"Source Endpoint",
        @"DE" : @"Destination Endpoint",
        @"CI" : @"Cluster Identifier",
        @"NP" : @"Maximum RF Payload Bytes",
        @"DD" : @"Device Type Identifier",
        @"CH" : @"Operating Channel",
        @"DA" : @"Force Disassociation",
        @"ID" : @"Extended PAN ID",
        @"OP" : @"Operating Extended PAN ID",
        @"NH" : @"Maximum Unicast Hops",
        @"BH" : @"Broadcast Hops",
        @"OI" : @"Operating 16-bit PAN ID",
        @"NT" : @"Node Discovery Timeout",
        @"NO" : @"Network Discovery options",
        @"SC" : @"Scan Channels",
        @"SD" : @"Scan Duration",
        @"ZS" : @"ZigBee Stack Profile",
        @"NJ" : @"Node Join Time",
        @"JV" : @"Channel Verification",
        @"NW" : @"Network Watchdog Timeout",
        @"JN" : @"Join Notification",
        @"AR" : @"Aggregate Routing Notification",
        @"DJ" : @"Disable Joining",
        @"II" : @"Initial ID",
        @"EE" : @"Encryption Enable",
        @"EO" : @"Encryption Options",
        @"NK" : @"Network Encryption Key",
        @"KY" : @"Link Key",
        @"PL" : @"Power Level",
        @"PM" : @"Power Mode",
        @"DB" : @"Received Signal Strength",
        @"PP" : @"Peak Power",
        @"AP" : @"API Enable",
        @"AO" : @"API Options",
        @"BD" : @"Interface Data Rate",
        @"NB" : @"Serial Parity",
        @"SB" : @"Stop Bits",
        @"RO" : @"Packetization Timeout",
        @"D7" : @"DIO7 Configuration",
        @"D6" : @"DIO6 Configuration",
        @"IR" : @"IO Sample Rate",
        @"IC" : @"IO Digital Change Detection",
        @"P0" : @"PWM0 Configuration",
        @"P1" : @"DIO11 Configuration",
        @"P2" : @"DIO12 Configuration",
        @"P3" : @"DIO13 Configuration",
        @"D0" : @"AD0/DIO0 Configuration",
        @"D1" : @"AD1/DIO1 Configuration",
        @"D2" : @"AD2/DIO2 Configuration",
        @"D3" : @"AD3/DIO3 Configuration",
        @"D4" : @"DIO4 Configuration",
        @"D5" : @"DIO5 Configuration",
        @"D8" : @"DIO8 Configuration",
        @"LT" : @"Assoc LED Blink Time",
        @"PR" : @"Pull-up Resistor",
        @"RP" : @"RSSI PWM Timer",
        @"%V" : @"Supply Voltage",
        @"V+" : @"Voltage Supply Monitoring",
        @"TP" : @"Reads the module temperature in Degrees Celsius",
        @"VR" : @"Firmware Version",
        @"HV" : @"Hardware Version",
        @"AI" : @"Association Indication",
        @"CT" : @"Command Mode Timeout",
        @"CN" : @"Exit Command Mode",
        @"GT" : @"Guard Times",
        @"CC" : @"Command Sequence Character",
        @"SM" : @"Sleep Mode Sets the sleep mode on the RF module",
        @"SN" : @"Number of Sleep Periods",
        @"SP" : @"Sleep Period",
        @"ST" : @"Time Before Sleep Sets the time before sleep timer on an end device.",
        @"SO" : @"Sleep Options",
        @"WH" : @"Wake Host",
        @"SI" : @"Sleep Immediately",
        @"PO" : @"Polling Rate",
        @"AC" : @"Apply Changes",
        @"WR" : @"Write",
        @"RE" : @"Restore Defaults",
        @"FR" : @"Software Reset",
        @"NR" : @"Network Reset",
        @"SI" : @"Sleep Immediately",
        @"CB" : @"Commissioning Pushbutton",
        @"ND" : @"Node Discover",
        @"DN" : @"Destination Node",
        @"IS" : @"Force Sample Forces a read of all enabled digital and analog input lines.",
        @"1S" : @"XBee Sensor Sample"} retain];
    }
}

#pragma mark General functionality
-(NSString*) name {
    return @"XBee";
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

-(BOOL) connect {
    NSString* errorMessage = [self internalConnect];
	
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
    
	[delegate xbee:self info: @"Connected"];
    return YES;
}

-(size_t) writeBytes: (const void*) data length: (size_t) len {
    if (data && len) {
        [transmitBuffer appendBytes: data length: len];
    } else {
        NSLog(@"Write: %@", dumpString([transmitBuffer bytes], [transmitBuffer length]));
        [self write: transmitBuffer];
        [transmitBuffer setLength: 0];
    }
	return len;	
}

-(void) dealloc {
	//[self cancelCommand];
    [self disconnect];
    
	[commandsQueue release];
	commandsQueue = nil;
    
    [transmitBuffer release];
    transmitBuffer = nil;
	
    [nodeIdentifier release];
    nodeIdentifier = nil;
    
    [super dealloc];
}

-(id) init {
    if(self = [super init]) {
        commandsQueue = [[NSOperationQueue alloc] init];
        [commandsQueue setMaxConcurrentOperationCount: 1];
        
        transmitBuffer = [[NSMutableData alloc] init];
	}
    return self;
}

-(BOOL) disconnect {
    [delegate xbee:self info: @"Disconnected"];
    return [self internalDisconnect];	
}

-(void) addData:(NSData *)receivedData {
    NSLog(@"Received data: \n %@\n", dumpString([receivedData bytes], [receivedData length]));
    XBeeAddData(&xb, [receivedData bytes], [receivedData length]);
}

#pragma mark XBee Properties

-(NSString*) nodeIdentifier {
    if (!nodeIdentifier) {
        XBeeSendATCommand(&xb, "NI", NULL);
    }
    return nodeIdentifier;
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

-(uint16_t) firmwareVersion {
    if (!firmwareVersionRead) {
        XBeeSendATCommand(&xb, "VR", NULL);
    }
    return firmwareVersion;
}

-(uint16_t) hardwareVersion {
    if (!hardwareVersionRead) {
        XBeeSendATCommand(&xb, "HV", NULL);
    }
    return hardwareVersion;
}

-(uint16_t) supplyVoltage {
    if (!supplyVoltageRead) {
        XBeeSendATCommand(&xb, "%V", NULL);
    }
    return supplyVoltage;
}

/*
@property(assign, nonatomic) uint64_t address;
@property(readonly, nonatomic) uint16_t networkAddress;
@property(readonly, nonatomic) uint16_t parentAddress;
@property(readonly, nonatomic) uint64_t serialNumber;
@property(copy, nonatomic) NSString* nodeIdentifier;*/

-(void) processATCommand: (const char*) command responseOn: (XBeeFrameId) frameId status: (XBeeATCommandStatus) status data: (void*) data length:(size_t) dataLength {
    [self log: [NSString stringWithFormat: @"[%03d] AT Command %s (%@): %s. Data: \n%@\n", frameId, command, atCommandsDescriptions[[NSString stringWithFormat:@"%s", command]], XBeeATCommandStatusString(status), dumpString(data, dataLength)]];
    if (status == XBeeATCommandOk) {
        if (strcmp(command, "NI") == 0) {
            if (data && dataLength > 0) {
                [self willChangeValueForKey:@"nodeIdentifier"];
                nodeIdentifier = [[NSString alloc] initWithBytes: data length: dataLength encoding: NSUTF8StringEncoding];
                [self didChangeValueForKey:@"nodeIdentifier"];
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
        } else if (strcmp(command, "VR") == 0) {
            if (data && dataLength == sizeof(uint16_t)) {
                uint64_t value = ntohs(*((uint16_t*)data));
                [self willChangeValueForKey:@"firmwareVersion"];
                firmwareVersion = value;
                firmwareVersionRead = YES;
                [self didChangeValueForKey:@"firmwareVersion"];
            }
        } else if (strcmp(command, "HV") == 0) {
            if (data && dataLength == sizeof(uint16_t)) {
                uint64_t value = ntohs(*((uint16_t*)data));
                [self willChangeValueForKey:@"hardwareVersion"];
                hardwareVersion = value;
                hardwareVersionRead = YES;
                [self didChangeValueForKey:@"hardwareVersion"];
            }
        } else if (strcmp(command, "%V") == 0) {
            if (data && dataLength == sizeof(uint16_t)) {
                uint64_t value = ntohs(*((uint16_t*)data)) * 1200 / 1024;
                [self willChangeValueForKey:@"supplyVoltage"];
                supplyVoltage = value;
                supplyVoltageRead = YES;
                [self didChangeValueForKey:@"supplyVoltage"];
            }
        }
    }
}

@end
