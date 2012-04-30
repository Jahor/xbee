//
//  xbee.c
//  XBee
//
//  Created by Jagor Lavonienka on 7.4.12.
//  Copyright (c) 2012 Jagor Lavonienka. All rights reserved.
//

#include "xbee.h"
#include <stdint.h>
#include <string.h>

#define FRAME_DELIMITER 0x7E
#define ESCAPE 0x7D
#define XON 0x11
#define XOFF 0x13

#define ESCAPE_XOR 0x20;

#define REQUEST_HEADER_LENGTH 2

#define XBEE_SENSOR_READ_AD_VALUES_COUNT 4

typedef uint16_t XBeeFrameLength;

static size_t writeNormal(xbee* xb, void* data, size_t dataLength) {
    int i;
    for (i = 0; i < dataLength; i++) {
        xb->checksum += ((uint8_t*)data)[i];
    }
    xb->write(xb, data, dataLength);
    return dataLength;
}

static size_t writeEscaped(xbee* xb, void* data, size_t dataLength) {
    int i;
    for (i = 0; i < dataLength; i++) {
        uint8_t c = ((uint8_t*) data)[i];
        xb->checksum += c;
        if (c == FRAME_DELIMITER || c == ESCAPE || c == XON || c == XOFF) {
            static uint8_t escape = ESCAPE;
            xb->write(xb, &escape, sizeof(escape));
            c ^= ESCAPE_XOR;
        }
        xb->write(xb, &c, sizeof(c));
    }
    return dataLength;
}

static inline void write(xbee* xb, void* data, size_t dataLength) {
    xb->internalWrite(xb, data, dataLength);
}

static inline void write8(xbee* xb, uint8_t data) {
    xb->internalWrite(xb, &data, sizeof(data));
}

static inline void write16(xbee* xb, uint16_t data) {
    data = htons(data);
    xb->internalWrite(xb, &data, sizeof(data));
}

static inline void write32(xbee* xb, uint32_t data) {
    data = htonl(data);
    xb->internalWrite(xb, &data, sizeof(data));
}

static inline void write64(xbee* xb, uint64_t data) {
    uint32_t h = (data >> 32) & 0xFFFFFFFF;
    write32(xb, h);
    uint32_t l = data & 0xFFFFFFFF;
    write32(xb, l);
}

static inline void writeFrameStart(xbee* xb, XBeeFrameType type, XBeeFrameLength length) {
    static uint8_t frameDelimiter = FRAME_DELIMITER;
    xb->write(xb, &frameDelimiter, sizeof(frameDelimiter));
    uint16_t fullLength = htons(REQUEST_HEADER_LENGTH + length);
    xb->write(xb, &fullLength, sizeof(fullLength));
    write8(xb, type);
    write8(xb, xb->nextFrameId);
}

static inline XBeeFrameId nextFrameId(xbee* xb) {
    XBeeFrameId r = xb->nextFrameId;
    xb->nextFrameId++;
    if (xb->nextFrameId == 0) {
        xb->nextFrameId = 1;
    }
    return r;
}

static inline void writeShortAddress(xbee* xb, ZigBeeShortAddress address) {
    write16(xb, address);
}

static inline void writeLongAddress(xbee* xb, ZigBeeLongAddress address) {
    write32(xb, address.high);
    write32(xb, address.low);
}

static inline void writeATParameter(xbee* xb, XBeeATParameter* parameter) {
    if (parameter) {
        switch (parameter->type) {
            case XBeeATParameter8bit:
                write8(xb, parameter->value.u8);
                break;
            case XBeeATParameter16bit:
                write16(xb, parameter->value.u16);
                break;
            case XBeeATParameter32bit:
                write32(xb, parameter->value.u32);
                break;
            case XBeeATParameter64bit:
                write64(xb, parameter->value.u64);
                break;
            case XBeeATParameterString20:
                write(xb, parameter->value.string20, strnlen(parameter->value.string20, sizeof(parameter->value.string20)));
                break;
        }
    }
}

static inline void writeChecksum(xbee* xb) {
    uint8_t cs = 0xFF;
    cs -= xb->checksum;
    write8(xb, cs);
    xb->checksum = 0x00;
}

size_t copyNormal(xbee* xb, void* data, size_t dataLength) {
    size_t toCopy = dataLength;
    size_t freeInBuffer = (XBEE_BUFFER_CAPACITY - xb->buffer.length);
    if (toCopy > freeInBuffer) {
        toCopy = freeInBuffer;
    }
    memcpy(xb->buffer.data + xb->buffer.length, data, toCopy);
    xb->buffer.length += toCopy;
    return toCopy;
}

size_t copyEscaped(xbee* xb, void* data, size_t dataLength) {
    size_t toCopy = dataLength;
    size_t freeInBuffer = (XBEE_BUFFER_CAPACITY - xb->buffer.length);
    if (toCopy > freeInBuffer) {
        toCopy = freeInBuffer;
    }
    int vi, ri;
    uint8_t* bufferData = xb->buffer.data + xb->buffer.length;
    for (vi = 0, ri = 0; vi < toCopy && ri < dataLength; ri++) {
        uint8_t b = ((uint8_t*)data)[ri];
        if (xb->buffer.lastEscaped) {
            *bufferData = b ^ ESCAPE_XOR;
            vi++;
            bufferData++;
            xb->buffer.lastEscaped = 0;
        } else if (b == ESCAPE) {
            xb->buffer.lastEscaped = 1;
        } else {
            *bufferData = b;
            vi++;
            bufferData++;
        }
    }
    xb->buffer.length += vi;
    return ri;
}

void XBeeAddData(xbee* xb, void* data, size_t dataLength) {
#define MOVE(s) do { \
                    frame += (s);\
                    dataAvailable -= (s);\
                } while(0)
#define FILL(v) do {\
    v = *((typeof(v)*) frame);\
    if (sizeof(v) == 2) {\
        v = ntohs(v);\
    } else if (sizeof(v) == 4) {\
        v = ntohl(v);\
    }\
    frame += sizeof(v);\
    dataAvailable -= sizeof(v);\
} while(0)
#define FILL_LA(a) do {\
    FILL(a.high);\
    FILL(a.low);\
} while(0)
    size_t dataProcessed = 0;
    while (dataProcessed < dataLength) {
        dataProcessed += xb->internalCopy(xb, data + dataProcessed, dataLength - dataProcessed); 

        char processed;
        do {
            size_t start = 0;
            while (xb->buffer.data[start] != FRAME_DELIMITER && start < xb->buffer.length) {
                start++;
            }
            
            size_t dataAvailable = xb->buffer.length - start;
            if (dataAvailable > sizeof(XBeeFrameLength) + sizeof(XBeeChecksum) && xb->buffer.data[start] == FRAME_DELIMITER) {
                uint8_t* frame = xb->buffer.data + start;
                MOVE(sizeof(uint8_t));
                XBeeFrameLength frameLength;
                FILL(frameLength);
                if (frameLength + 1 <= dataAvailable) { // Need one more byte for checksum
                    int i;
                    dataAvailable = frameLength;
                    XBeeChecksum frameChecksum = *((XBeeChecksum*)(frame + frameLength));
                    XBeeChecksum frameDataChecksum = 0x00;
                    for (i = 0; i < frameLength; i++) {
                        frameDataChecksum += frame[i];
                    }
                    frameDataChecksum = 0xFF - frameDataChecksum;
                    if (frameDataChecksum == frameChecksum) {
                        XBeeFrameType frameType; FILL(frameType);
                        switch (frameType) {
                            case XBeeFrameATCommandResponse:
                                if (xb->onATCommandResponse) {
                                    XBeeFrameId frameId; FILL(frameId);
                                    char atCommand[3];
                                    memcpy(atCommand, frame, 2);
                                    atCommand[2] = '\0';
                                    MOVE(2);
                                    XBeeATCommandStatus status; FILL(status);
                                    xb->onATCommandResponse(xb, frameId, atCommand, status, dataAvailable ? frame : NULL, dataAvailable);
                                }
                                break;
                            case XBeeFrameModemStatus:
                                if (xb->onModemStatus) {
                                    XBeeModemStatus status; FILL(status);
                                    xb->onModemStatus(xb, status);
                                }
                                break;                        
                            case XBeeFrameTransmitStatus:
                                if (xb->onTransmitStatus) {
                                    XBeeFrameId frameId; FILL(frameId);
                                    ZigBeeShortAddress destinationShort; FILL(destinationShort);
                                    uint8_t transmitRetryCount; FILL(transmitRetryCount);
                                    XBeeDeliveryStatus deliveryStatus; FILL(deliveryStatus);
                                    XBeeDiscoveryStatus discoveryStatus; FILL(discoveryStatus);
                                    xb->onTransmitStatus(xb, frameId, destinationShort, transmitRetryCount, deliveryStatus, discoveryStatus);
                                }
                                break;                        
                            case XBeeFrameReceivePacket:
                                if (xb->onReceivePacket) {
                                    ZigBeeLongAddress sourceLong; FILL_LA(sourceLong);
                                    ZigBeeShortAddress sourceShort; FILL(sourceShort);
                                    XBeeReceiveOptions receiveOptions; FILL(receiveOptions);
                                    xb->onReceivePacket(xb, sourceLong, sourceShort, receiveOptions, dataAvailable ? frame : NULL, dataAvailable);
                                }
                                break;
                            case XBeeFrameExplicitRxIndicator:
                                if (xb->onExplicitRxIndicator) {
                                    ZigBeeLongAddress sourceLong; FILL_LA(sourceLong);
                                    ZigBeeShortAddress sourceShort; FILL(sourceShort);
                                    ZigBeeEndpoint sourceEndpoint; FILL(sourceEndpoint);
                                    ZigBeeEndpoint destinationEndpoint; FILL(destinationEndpoint);
                                    ZigBeeCluster cluster; FILL(cluster);
                                    ZigBeeProfile profile; FILL(profile);
                                    XBeeReceiveOptions receiveOptions; FILL(receiveOptions);
                                    xb->onExplicitRxIndicator(xb, sourceLong, sourceShort, sourceEndpoint, destinationEndpoint, cluster, profile, receiveOptions, dataAvailable ? frame : NULL, dataAvailable);
                                }
                                break;
                            case XBeeFrameIODataSampleRxIndicator:
                                if (xb->onIODataSampleRxIndicator) {
                                    ZigBeeLongAddress sourceLong; FILL_LA(sourceLong);
                                    ZigBeeShortAddress sourceShort; FILL(sourceShort);
                                    XBeeReceiveOptions receiveOptions; FILL(receiveOptions);
                                    MOVE(1);
                                    XBeeDigitalChannels digitalMask; FILL(digitalMask);
                                    XBeeAnalogChannels analogMask; FILL(analogMask);
                                    XBeeDigitalChannels digitalSamples = 0;
                                    if (digitalMask) {
                                        FILL(digitalSamples);
                                    }
                                    xb->onIODataSampleRxIndicator(xb, sourceLong, sourceShort, receiveOptions, digitalMask, analogMask, digitalSamples, (XBeeADValue*) frame);
                                }
                                break;
                            case XBeeFrameSensorReadIndicator:
                                if (xb->onXBeeSensorReadIndicator) {
                                    ZigBeeLongAddress sourceLong; FILL_LA(sourceLong);
                                    ZigBeeShortAddress sourceShort; FILL(sourceShort);
                                    XBeeReceiveOptions receiveOptions; FILL(receiveOptions);
                                    XBeeOneWireSensors oneWireSensors; FILL(oneWireSensors);
                                    XBeeADValue* adValues = (XBeeADValue*) frame;
                                    XBeeADValue temperature = adValues[XBEE_SENSOR_READ_AD_VALUES_COUNT];
                                    xb->onXBeeSensorReadIndicator(xb, sourceLong, sourceShort, receiveOptions, oneWireSensors, adValues, XBEE_SENSOR_READ_AD_VALUES_COUNT, temperature);
                                }
                                break;
                            case XBeeFrameNodeIdentificationIndicator:
                                if (xb->onNodeIdentificationIndicator) {
                                    ZigBeeLongAddress senderLong; FILL_LA(senderLong);
                                    ZigBeeShortAddress senderShort; FILL(senderShort);
                                    XBeeReceiveOptions receiveOptions; FILL(receiveOptions);
                                    ZigBeeShortAddress sourceShort; FILL(sourceShort);
                                    ZigBeeLongAddress sourceLong; FILL_LA(sourceLong);
                                    const char* ni = (char*) frame;
                                    int nil = strnlen(ni, dataAvailable);
                                    MOVE(nil + 1);
                                    ZigBeeShortAddress parentShort; FILL(parentShort);
                                    ZigBeeDeviceType deviceType; FILL(deviceType);
                                    XBeeSourceEvent sourceEvent; FILL(sourceEvent);
                                    xb->onNodeIdentificationIndicator(xb, senderLong, senderShort, receiveOptions, sourceShort, sourceLong, ni, parentShort, deviceType, sourceEvent);
                                }
                                break;
                            case XBeeFrameRemoteATCommandResponse:
                                if (xb->onRemoteATCommandResponse) {
                                    XBeeFrameId frameId; FILL(frameId);
                                    ZigBeeLongAddress sourceLong; FILL_LA(sourceLong);
                                    ZigBeeShortAddress sourceShort; FILL(sourceShort);
                                    char atCommand[3];
                                    memcpy(atCommand, frame, 2);
                                    atCommand[2] = '\0';
                                    MOVE(2);
                                    XBeeATCommandStatus status; FILL(status);
                                    xb->onRemoteATCommandResponse(xb, frameId, sourceLong, sourceShort, atCommand, status, dataAvailable ? frame : NULL, dataAvailable); 
                                }
                                break;
                            case XBeeFrameOverTheAirFirmwareUpdateStatus:
                                if (xb->onOverTheAirFirmwareUpdateStatus) {
                                    ZigBeeLongAddress sourceLong; FILL_LA(sourceLong);
                                    ZigBeeShortAddress updaterShort; FILL(updaterShort);
                                    XBeeReceiveOptions receiveOptions; FILL(receiveOptions);
                                    XBeeBootloaderMessageType bootloaderMessageType; FILL(bootloaderMessageType);
                                    uint8_t blockNumber; FILL(blockNumber);
                                    ZigBeeLongAddress targetLong; FILL_LA(targetLong);
                                    xb->onOverTheAirFirmwareUpdateStatus(xb, sourceLong, updaterShort, receiveOptions, bootloaderMessageType, blockNumber, targetLong);
                                }
                                break;
                            case XBeeFrameRouteRecordIndicator:
                                if (xb->onRouteRecordIndicator) {
                                    ZigBeeLongAddress sourceLong; FILL_LA(sourceLong);
                                    ZigBeeShortAddress sourceShort; FILL(sourceShort);
                                    XBeeReceiveOptions receiveOptions; FILL(receiveOptions);
                                    uint8_t numberOfAddresses; FILL(numberOfAddresses);
                                    xb->onRouteRecordIndicator(xb, sourceLong, sourceShort, receiveOptions, numberOfAddresses,
                                                                 (ZigBeeShortAddress*) frame);
                                }
                                break;
                            case XBeeFrameManyToOneRouteRequestIndicator:
                                if (xb->onManyToOneRouteRequestIndicator) {
                                    ZigBeeLongAddress sourceLong; FILL_LA(sourceLong);
                                    ZigBeeShortAddress sourceShort; FILL(sourceShort);
                                    xb->onManyToOneRouteRequestIndicator(xb, sourceLong, sourceShort);
                                }
                                break;
                            default:
                                break;
                        }
                        start += sizeof(uint8_t) + sizeof(XBeeFrameLength) + sizeof(XBeeChecksum) + frameLength;
                    } else {
                        start++;
                    }
                }
            }
            if (start != 0) {
                processed = 1;
                memmove(xb->buffer.data, xb->buffer.data + start, xb->buffer.length - start);
                xb->buffer.length -= start;
            } else {
                processed = 0;
            }
        } while (processed);
    }
#undef MOVE
#undef FILL
}

static inline XBeeFrameLength XBeeATParameterLength(XBeeATParameter* parameter) {
    if (parameter) {
        switch (parameter->type) {
            case XBeeATParameter8bit:
                return sizeof(uint8_t);
            case XBeeATParameter16bit:
                return sizeof(uint16_t);
            case XBeeATParameter32bit:
                return sizeof(uint32_t);
            case XBeeATParameter64bit:
                return sizeof(uint64_t);
            case XBeeATParameterString20:
                return strnlen(parameter->value.string20, sizeof(parameter->value.string20));
        }
    }
    return 0;
}

void XBeeInit(xbee* xb, XBeeAPIMode apiMode, XBeeDataWrite write, void* userData) {
    memset(xb, 0, sizeof(xbee));
    xb->internalWrite = apiMode == XBeeAPINormal ? writeNormal : writeEscaped;
    xb->internalCopy = apiMode == XBeeAPINormal ? copyNormal : copyEscaped;
    xb->write = write;
    xb->userData = userData;
    xb->buffer.length = 0;
    xb->nextFrameId = 1;
}

void* XBeeUserData(xbee* xb) {
    return xb->userData;
}

static inline XBeeFrameId XBeeSendATCommandInternal(xbee* xb, const char* atCommand, XBeeATParameter* parameter, char queue) {
    writeFrameStart(xb, queue ? XBeeFrameATCommandQueueParameter : XBeeFrameATCommand, sizeof(uint8_t) * 2 + XBeeATParameterLength(parameter));
    write8(xb, atCommand[0]);
    write8(xb, atCommand[1]);
    writeATParameter(xb, parameter);
    writeChecksum(xb);
    return nextFrameId(xb);
}

XBeeFrameId XBeeSendATCommand(xbee* xb, const char* atCommand, XBeeATParameter* parameter) {
    return XBeeSendATCommandInternal(xb, atCommand, parameter, 0);
}

XBeeFrameId XBeeSendATCommandQueueParameterValue(xbee* xb, const char* atCommand, XBeeATParameter* parameter) {
    return XBeeSendATCommandInternal(xb, atCommand, parameter, 1);
}

XBeeFrameId XBeeSendZigBeeTransmitRequest(xbee* xb, ZigBeeLongAddress destinationLong, ZigBeeShortAddress destinationShort, 
                                          ZigBeeBroadcastRadius broadcastRadius, XBeeTransmitOptions options, void* data, size_t dataLength) {
    writeFrameStart(xb, XBeeFrameTransmitRequest, sizeof(ZigBeeLongAddress) + sizeof(ZigBeeShortAddress) + sizeof(ZigBeeBroadcastRadius) + sizeof(XBeeTransmitOptions) + dataLength);
    writeLongAddress(xb, destinationLong);
    writeShortAddress(xb, destinationShort);
    write8(xb, broadcastRadius);
    write8(xb, options);
    write(xb, data, dataLength);
    writeChecksum(xb);
    return nextFrameId(xb);
}

XBeeFrameId XBeeSendExplicitAddressingZigBeeCommandFrame(xbee* xb, ZigBeeLongAddress destinationLong, ZigBeeShortAddress destinationShort, 
                                                         ZigBeeEndpoint sourceEndpoint, ZigBeeEndpoint destinationEndpoint, 
                                                         ZigBeeCluster cluster, ZigBeeProfile profile, ZigBeeBroadcastRadius broadcastRadius, 
                                                         XBeeTransmitOptions options, void* data, size_t dataLength) {
    writeFrameStart(xb, XBeeFrameTransmitRequest, sizeof(ZigBeeLongAddress) + sizeof(ZigBeeShortAddress) + sizeof(ZigBeeLongAddress) + 
                    sizeof(ZigBeeEndpoint) + sizeof(ZigBeeEndpoint) + sizeof(ZigBeeCluster) + sizeof(ZigBeeProfile) +
                    sizeof(ZigBeeBroadcastRadius) + sizeof(XBeeTransmitOptions) + dataLength);
    writeLongAddress(xb, destinationLong);
    writeShortAddress(xb, destinationShort);
    write8(xb, sourceEndpoint);
    write8(xb, destinationEndpoint);
    write16(xb, cluster);
    write16(xb, profile);
    write8(xb, broadcastRadius);
    write8(xb, options);
    write(xb, data, dataLength);
    writeChecksum(xb);
    return nextFrameId(xb);
}

XBeeFrameId XBeeSendRemoteATCommandRequest(xbee* xb, ZigBeeLongAddress destinationLong, ZigBeeShortAddress destinationShort,
                                           XBeeRemoteATCommandOptions options, const char* atCommand, XBeeATParameter* parameter) {
    writeFrameStart(xb, XBeeFrameTransmitRequest, sizeof(ZigBeeLongAddress) + sizeof(ZigBeeShortAddress) + sizeof(XBeeRemoteATCommandOptions) + sizeof(uint8_t) * 2 + XBeeATParameterLength(parameter));
    writeLongAddress(xb, destinationLong);
    writeShortAddress(xb, destinationShort);
    write8(xb, options);
    write8(xb, atCommand[0]);
    write8(xb, atCommand[1]);
    writeATParameter(xb, parameter);
    writeChecksum(xb);
    return nextFrameId(xb);
}

XBeeFrameId XBeeCreateSourceRoute(xbee* xb, ZigBeeLongAddress destinationLong, ZigBeeShortAddress destinationShort,
                                  uint8_t numberOfAddresses, ZigBeeShortAddress *addresses) {
    int i;
    writeFrameStart(xb, XBeeFrameTransmitRequest, sizeof(ZigBeeLongAddress) + sizeof(ZigBeeShortAddress) + sizeof(uint8_t) + sizeof(ZigBeeShortAddress) * numberOfAddresses);
    writeLongAddress(xb, destinationLong);
    writeShortAddress(xb, destinationShort);
    write8(xb, numberOfAddresses);
    for (i = 0; i < numberOfAddresses; i++) {
        writeShortAddress(xb, addresses[0]);
    }
    writeChecksum(xb);
    return nextFrameId(xb);
}

void XBeeRegisterOnATCommandResponse(xbee* xb, XBeeOnATCommandResponse handler) {
    xb->onATCommandResponse = handler;
}
void XBeeRegisterOnModemStatus(xbee* xb, XBeeOnModemStatus handler) {
    xb->onModemStatus = handler;
}
void XBeeRegisterOnTransmitStatus(xbee* xb, XBeeOnZigBeeTransmitStatus handler) {
    xb->onTransmitStatus = handler;
}
void XBeeRegisterOnReceivePacket(xbee* xb, XBeeOnZigBeeReceivePacket handler) {
    xb->onReceivePacket = handler;
}
void XBeeRegisterOnExplicitRxIndicator(xbee* xb, XBeeOnZigBeeExplicitRxIndicator handler) {
    xb->onExplicitRxIndicator = handler;
}
void XBeeRegisterOnIODataSampleRxIndicator(xbee* xb, XBeeOnZigBeeIODataSampleRxIndicator handler) {
    xb->onIODataSampleRxIndicator = handler;
}
void XBeeRegisterOnXBeeSensorReadIndicator(xbee* xb, XBeeOnXBeeSensorReadIndicator handler) {
    xb->onXBeeSensorReadIndicator = handler;
}
void XBeeRegisterOnNodeIdentificationIndicator(xbee* xb, XBeeOnNodeIdentificationIndicator handler) {
    xb->onNodeIdentificationIndicator = handler;
}
void XBeeRegisterOnRemoteATCommandResponse(xbee* xb, XBeeOnRemoteATCommandResponse handler) {
    xb->onRemoteATCommandResponse = handler;
}
void XBeeRegisterOnOverTheAirFirmwareUpdateStatus(xbee* xb, XBeeOnOverTheAirFirmwareUpdateStatus handler) {
    xb->onOverTheAirFirmwareUpdateStatus = handler;
}
void XBeeRegisterOnRouteRecordIndicator(xbee* xb, XBeeOnRouteRecordIndicator handler) {
    xb->onRouteRecordIndicator = handler;
}
void XBeeRegisterOnManyToOneRouteRequestIndicator(xbee* xb, XBeeOnManyToOneRouteRequestIndicator handler) {
    xb->onManyToOneRouteRequestIndicator = handler;
}

ZigBeeLongAddress ZigBeeLongAddressMake(uint32_t h, uint32_t l) {
    ZigBeeLongAddress r;
    r.high = h;
    r.low = l;
    return r;
}

