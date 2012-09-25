//
//  Sensor.h
//  iNoCry
//
//  Created by Egor Leonenko on 26.4.10.
//  Copyright 2010 iTransition. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol XBeeDelegate;

@interface XBee : NSObject

@property(readonly, nonatomic) NSString* name;
@property(assign, nonatomic) NSObject<XBeeDelegate>* delegate;

-(BOOL) connect;
-(BOOL) disconnect;

@property(readonly, nonatomic) uint16_t networkAddress;
@property(readonly, nonatomic) uint16_t parentAddress;
@property(readonly, nonatomic) uint64_t serialNumber;
@property(readonly, nonatomic) NSString* nodeIdentifier;
@property(readonly, nonatomic) uint16_t firmwareVersion;
@property(readonly, nonatomic) uint16_t hardwareVersion;
@property(readonly, nonatomic) uint16_t supplyVoltage;

-(void) sendPacket:(NSData*) data to:(uint64_t) address;

/*

XBeeFrameId XBeeSendATCommand(xbee* xbee, const char* atCommand, XBeeATParameter* parameter);
XBeeFrameId XBeeSendATCommandQueueParameterValue(xbee* xbee, const char* atCommand, XBeeATParameter* parameter);
XBeeFrameId XBeeSendZigBeeTransmitRequest(xbee* xbee, ZigBeeLongAddress destinationLong, ZigBeeShortAddress destinationShort, 
                                          ZigBeeBroadcastRadius broadcastRadius, XBeeTransmitOptions options, void* data, size_t dataLength);
XBeeFrameId XBeeSendExplicitAddressingZigBeeCommandFrame(xbee* xbee, ZigBeeLongAddress destinationLong, ZigBeeShortAddress destinationShort, 
                                                         ZigBeeEndpoint sourceEndpoint, ZigBeeEndpoint destinationEndpoint, 
                                                         ZigBeeCluster cluster, ZigBeeProfile profile, ZigBeeBroadcastRadius broadcastRadius, 
                                                         XBeeTransmitOptions options, void* data, size_t dataLength);
XBeeFrameId XBeeSendRemoteATCommandRequest(xbee* xbee, ZigBeeLongAddress destinationLong, ZigBeeShortAddress destinationShort,
                                           XBeeRemoteATCommandOptions options, const char* atCommand, XBeeATParameter* parameter);
XBeeFrameId XBeeCreateSourceRoute(xbee* xbee, ZigBeeLongAddress destinationLong, ZigBeeShortAddress destinationShort,
                                  uint8_t numberOfAddresses, ZigBeeShortAddress *addresses);
*/
/*
 
 typedef void (*XBeeOnATCommandResponse)(xbee* xbee, XBeeFrameId frameId, const char* atCommand, XBeeATCommandStatus status, void* data, size_t dataLength);
 typedef void (*XBeeOnModemStatus)(xbee* xbee, XBeeModemStatus status);
 typedef void (*XBeeOnZigBeeTransmitStatus)(xbee* xbee, XBeeFrameId frameId, ZigBeeShortAddress destinationShort, uint8_t transmitRetryCount, XBeeDeliveryStatus deliveryStatus, XBeeDiscoveryStatus discoveryStatus);
 typedef void (*XBeeOnZigBeeReceivePacket)(xbee* xbee, ZigBeeLongAddress sourceAddress, ZigBeeShortAddress sourceShort, XBeeReceiveOptions receiveOptions, void* data, size_t dataLength);
 typedef void (*XBeeOnZigBeeExplicitRxIndicator)(xbee* xbee, ZigBeeLongAddress sourceLong, ZigBeeShortAddress sourceShort, ZigBeeEndpoint sourceEndpoint, ZigBeeEndpoint destinationEndpoint, 
 ZigBeeCluster cluster, ZigBeeProfile profile, XBeeReceiveOptions receiveOptions, void* data, size_t dataLength);
 typedef void (*XBeeOnZigBeeIODataSampleRxIndicator)(xbee* xbee, ZigBeeLongAddress sourceLong, ZigBeeShortAddress sourceShort, XBeeReceiveOptions receiveOptions, 
 XBeeDigitalChannels digitalMask, XBeeAnalogChannels analogMask, XBeeDigitalChannels digitalSamples, XBeeADValue *analogSamples);
 typedef void (*XBeeOnXBeeSensorReadIndicator)(xbee* xbee, ZigBeeLongAddress sourceLong, ZigBeeShortAddress sourceShort, XBeeReceiveOptions receiveOptions, 
 XBeeOneWireSensors oneWireSensors, XBeeADValue *ad, int adCount, XBeeADValue temperature);
 typedef void (*XBeeOnNodeIdentificationIndicator)(xbee* xbee, ZigBeeLongAddress senderLong, ZigBeeShortAddress senderShort, XBeeReceiveOptions receiveOptions, 
 ZigBeeShortAddress sourceShort, ZigBeeLongAddress sourceLong, const char* ni, ZigBeeShortAddress parentShort, ZigBeeDeviceType deviceType, XBeeSourceEvent sourceEvent);
 typedef void (*XBeeOnRemoteATCommandResponse)(xbee* xbee, XBeeFrameId frameId, ZigBeeLongAddress sourceLong, ZigBeeShortAddress sourceShort, const char* atCommand,
 XBeeATCommandStatus status, void* data, size_t dataLength);
 typedef void (*XBeeOnOverTheAirFirmwareUpdateStatus)(xbee* xbee, ZigBeeLongAddress sourceLong, ZigBeeShortAddress updaterShort, XBeeReceiveOptions receiveOptions, XBeeBootloaderMessageType bootloaderMessageType,
 uint8_t blockNumber, ZigBeeLongAddress targetLong);
 typedef void (*XBeeOnRouteRecordIndicator)(xbee* xbee, ZigBeeLongAddress sourceLong, ZigBeeShortAddress sourceShort, XBeeReceiveOptions receiveOptions, uint8_t numberOfAddresses,
 ZigBeeShortAddress *addresses);
 typedef void (*XBeeOnManyToOneRouteRequestIndicator)(xbee* xbee, ZigBeeLongAddress sourceLong, ZigBeeShortAddress sourceShort);
 
 */

@end


@protocol XBeeDelegate 
-(void) xbee:(XBee*) xb
       error:(NSString*) message;

-(void) xbee:(XBee*) xb
        info:(NSString*) message;

@end
