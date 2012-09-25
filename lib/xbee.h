//
//  xbee.h
//  XBee
//
//  Created by Jagor Lavonienka on 7.4.12.
//  Copyright (c) 2012 Jagor Lavonienka. All rights reserved.
//

#ifndef __XBEE_H__
#define __XBEE_H__

#include <stdlib.h>
#include <stdint.h>

typedef enum {
    XBeeAPINormal,
    XBeeAPIEscaped
} XBeeAPIMode;


typedef enum  __attribute__ ((__packed__)) {
    XBeeFrameATCommand = 0x08,
    XBeeFrameATCommandQueueParameter = 0x09,
    XBeeFrameTransmitRequest = 0x10,
    XBeeFrameExplicitAddressingCommand = 0x11,
    XBeeFrameRemoteCommandRequest = 0x17,
    XBeeFrameATCommandResponse = 0x88,
    XBeeFrameModemStatus = 0x8A,
    XBeeFrameTransmitStatus = 0x8B,
    XBeeFrameReceivePacket = 0x90,
    XBeeFrameExplicitRxIndicator = 0x91,
    XBeeFrameIODataSampleRxIndicator = 0x92,
    XBeeFrameSensorReadIndicator = 0x94,
    XBeeFrameNodeIdentificationIndicator = 0x95,
    XBeeFrameRemoteATCommandResponse = 0x97,
    XBeeFrameOverTheAirFirmwareUpdateStatus = 0xA0,
    XBeeFrameRouteRecordIndicator = 0xA1,
    XBeeFrameManyToOneRouteRequestIndicator = 0xA3
} XBeeFrameType;

typedef uint8_t XBeeFrameId;
typedef uint8_t XBeeChecksum;
typedef uint8_t ZigBeeEndpoint;
typedef uint16_t ZigBeeCluster;
typedef uint16_t ZigBeeProfile;
typedef uint8_t ZigBeeBroadcastRadius;

typedef union {
    struct {
        uint32_t low;
        uint32_t high;
    };
    uint64_t full;
} ZigBeeLongAddress;

typedef uint16_t ZigBeeShortAddress;

#define ZigBeeShortAddressUnknown 0xFFFE
#define ZigBeeShortAddressCoordinatorWith64Bit 0x0000


typedef enum {
  XBeeATParameter8bit,
  XBeeATParameter16bit,
  XBeeATParameter32bit,
  XBeeATParameter64bit,
  XBeeATParameterString20
} XBeeATParameterType;

typedef struct {
    XBeeATParameterType type;
    union {
        uint8_t u8;
        uint16_t u16;
        uint32_t u32;
        uint64_t u64;
        char string20[21];
    } value;
} XBeeATParameter;

typedef enum __attribute__ ((__packed__)) {
    XBeeTransmitOptionsNone = 0x00,
    XBeeTransmitOptionDisableACK = 0x01,
    XBeeTransmitOptionEnableAPSEncryption = 0x20,
    XBeeTransmitOptionUseExtendedTransmissionTimeout = 0x40
} XBeeTransmitOptions;

typedef enum __attribute__ ((__packed__)) {
    XBeeRemoteATCommandOptionsNone = 0x00,
    XBeeRemoteATCommandOptionDisableACK = 0x01,
    XBeeRemoteATCommandOptionApplyChangesOnRemote = 0x20,
    XBeeRemoteATCommandOptionUseExtendedTransmissionTimeout = 0x40
} XBeeRemoteATCommandOptions;

typedef enum __attribute__ ((__packed__)) {
    XBeeATCommandOk = 0x00,
    XBeeATCommandError = 0x01,
    XBeeATCommandInvalidCommand = 0x02,
    XBeeATCommandInvalidParameter = 0x03,
    XBeeATCommandTxFailure = 0x04
} XBeeATCommandStatus;

typedef enum __attribute__ ((__packed__)) {
    XBeeModemHardwareReset = 0x00,
    XBeeModemWatchdogTimerReset = 0x01,
    XBeeModemJoinedNetwork = 0x02,
    XBeeModemDisassociated = 0x03,
    XBeeModemCoordinatorStarted = 0x06,
    XBeeModemNetworkSecurityKeyWasUpdated = 0x07,
    XBeeModemVoltageSupplyLimitExceeded = 0xD0,
    XBeeModemConfigurationChangedWhileJoinInProgress = 0x11,
    XBeeModemStackError = 0x80
} XBeeModemStatus;

typedef enum __attribute__ ((__packed__)) {
    XBeeDeliverySuccess = 0x00,
    XBeeDeliveryMACACKFailure = 0x01,
    XBeeDeliveryCCAFailure = 0x02,
    XBeeDeliveryInvalidDestinationEndpoint = 0x15,
    XBeeDeliveryNetworkACKFailure = 0x21,
    XBeeDeliveryNotJoinedNetwork = 0x22,
    XBeeDeliverySelfAddressed = 0x23,
    XBeeDeliveryAddressNotFound = 0x24,
    XBeeDeliveryRouteNotFound = 0x25,
    XBeeDeliveryBroadcastSourceFailedToHearANeighbourRelayTheMessage = 0x26,
    XBeeDeliveryInvalidBindingTableIndex = 0x2B,
    XBeeDeliveryResourceErrorLackOfFreeBuffersTimersEtc = 0x2C,
    XBeeDeliveryAttemptedBroadcastWithAPSTransmission = 0x2D,
    XBeeDeliveryAttemptedUnicastWithAPSTransmissionButEEeq0 = 0x2E,
    XBeeDeliveryResourceErrorLackOfFreeBuffersTimersEtc2 = 0x32,
    XBeeDeliveryDataPayloadTooLarge = 0x74,
    XBeeDeliveryIndirectMessageUnrequested = 0x75
} XBeeDeliveryStatus;

typedef enum __attribute__ ((__packed__)) {
    XBeeDiscoveryNoOverhead = 0x00,
    XBeeDiscoveryAddress = 0x01,
    XBeeDiscoveryRoute = 0x02,
    XBeeDiscoveryAddressAndRoute = 0x03,
    XBeeDiscoveryExtendedTimeout = 0x40
} XBeeDiscoveryStatus;

typedef enum __attribute__ ((__packed__)) {
    XBeeReceivePacketAcknowledged = 0x01,
    XBeeReceivePacketWasBroadcast = 0x02,
    XBeeReceivePacketEncryptedWithAPSEncryption = 0x20,
    XBeeReceivePacketWasSentFromEndDevice = 0x40
} XBeeReceiveOptions;

typedef enum __attribute__ ((__packed__)) {
    XBeeOneWireADSensorRead = 0x01,
    XBeeOneWireTemperatureSensorRead = 0x02,
    XBeeOneWireWaterPresent = 0x60
} XBeeOneWireSensors;

typedef uint16_t XBeeADValue;
typedef uint16_t XBeeTemperature;

typedef enum __attribute__ ((__packed__)) {
    ZigBeeCoordinator = 0x00,
    ZigBeeRouter = 0x01,
    ZigBeeEndDevice = 0x02
} ZigBeeDeviceType;

typedef enum __attribute__ ((__packed__)) {
    XBeeSourcePushbutton = 0x01,
    XBeeSourceJoin = 0x02,
    XBeeSourcePower = 0x03
} XBeeSourceEvent;

typedef enum __attribute__ ((__packed__)) {
    XBeeBootloaderMessageACK = 0x06,
    XBeeBootloaderMessageNACK = 0x15,
    XBeeBootloaderMessageNoMacACK = 0x40,
    XBeeBootloaderMessageQuery = 0x51,
    XBeeBootloaderMessageQueryResponse = 0x52
} XBeeBootloaderMessageType;

typedef enum __attribute__ ((__packed__)) {
  XBeeAnalogChannel0 = (1 << 0),
  XBeeAnalogChannel1 = (1 << 1),
  XBeeAnalogChannel2 = (1 << 2),
  XBeeAnalogChannel3 = (1 << 3),
  XBeeAnalogChannelSupplyVoltage = (1 << 7)  
} XBeeAnalogChannels;

typedef enum __attribute__ ((__packed__)) {
  XBeeDigitalChannel0 = (1 << 0),
  XBeeDigitalChannel1 = (1 << 1),
  XBeeDigitalChannel2 = (1 << 2),
  XBeeDigitalChannel3 = (1 << 3),
  XBeeDigitalChannel4 = (1 << 4),
  XBeeDigitalChannel5 = (1 << 5),
  XBeeDigitalChannel6 = (1 << 6),
  XBeeDigitalChannel7 = (1 << 7), 
  XBeeDigitalChannel10 = (1 << 10),
  XBeeDigitalChannel11 = (1 << 11),
  XBeeDigitalChannel12 = (1 << 12)
} XBeeDigitalChannels;

typedef struct xbee xbee;

typedef size_t (*XBeeDataWrite)(xbee* xbee, const void* buf, size_t length);


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

#define XBEE_BUFFER_CAPACITY 255

struct xbee {
    XBeeFrameId nextFrameId;
    XBeeChecksum checksum;
    XBeeDataWrite write;
    XBeeDataWrite internalWrite;
    XBeeDataWrite internalCopy;
    void* userData;
    struct {
        uint8_t data[XBEE_BUFFER_CAPACITY];
        uint16_t length; 
        uint8_t lastEscaped;
    } buffer;
    
    XBeeOnATCommandResponse onATCommandResponse;
    XBeeOnModemStatus onModemStatus;
    XBeeOnZigBeeTransmitStatus onTransmitStatus;
    XBeeOnZigBeeReceivePacket onReceivePacket;
    XBeeOnZigBeeExplicitRxIndicator onExplicitRxIndicator;
    XBeeOnZigBeeIODataSampleRxIndicator onIODataSampleRxIndicator;
    XBeeOnXBeeSensorReadIndicator onXBeeSensorReadIndicator;
    XBeeOnNodeIdentificationIndicator onNodeIdentificationIndicator;
    XBeeOnRemoteATCommandResponse onRemoteATCommandResponse;
    XBeeOnOverTheAirFirmwareUpdateStatus onOverTheAirFirmwareUpdateStatus;
    XBeeOnRouteRecordIndicator onRouteRecordIndicator;
    XBeeOnManyToOneRouteRequestIndicator onManyToOneRouteRequestIndicator;
};

void XBeeInit(xbee* xbee, XBeeAPIMode apiMode, XBeeDataWrite write, void* userData);

void* XBeeUserData(xbee* xbee);

void XBeeAddData(xbee* xbee, const void* data, size_t dataLength);

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


void XBeeRegisterOnATCommandResponse(xbee* xbee, XBeeOnATCommandResponse handler);
void XBeeRegisterOnModemStatus(xbee* xbee, XBeeOnModemStatus handler);
void XBeeRegisterOnTransmitStatus(xbee* xbee, XBeeOnZigBeeTransmitStatus handler);
void XBeeRegisterOnReceivePacket(xbee* xbee, XBeeOnZigBeeReceivePacket handler);
void XBeeRegisterOnExplicitRxIndicator(xbee* xbee, XBeeOnZigBeeExplicitRxIndicator handler);
void XBeeRegisterOnIODataSampleRxIndicator(xbee* xbee, XBeeOnZigBeeIODataSampleRxIndicator handler);
void XBeeRegisterOnXBeeSensorReadIndicator(xbee* xbee, XBeeOnXBeeSensorReadIndicator handler);
void XBeeRegisterOnNodeIdentificationIndicator(xbee* xbee, XBeeOnNodeIdentificationIndicator handler);
void XBeeRegisterOnRemoteATCommandResponse(xbee* xbee, XBeeOnRemoteATCommandResponse handler);
void XBeeRegisterOnOverTheAirFirmwareUpdateStatus(xbee* xbee, XBeeOnOverTheAirFirmwareUpdateStatus handler);
void XBeeRegisterOnRouteRecordIndicator(xbee* xbee, XBeeOnRouteRecordIndicator handler);
void XBeeRegisterOnManyToOneRouteRequestIndicator(xbee* xbee, XBeeOnManyToOneRouteRequestIndicator handler);


ZigBeeLongAddress ZigBeeLongAddressMake(uint32_t h, uint32_t l);

#define ZigBeeLongAddressUnknown ZigBeeLongAddressMake(0xFFFFFFFF, 0xFFFFFFFF)
#define ZigBeeLongAddressBroadcast ZigBeeLongAddressMake(0x00000000, 0x0000FFFF)
#define ZigBeeLongAddressCoordinator ZigBeeLongAddressMake(0x00000000, 0x00000000)

#endif
