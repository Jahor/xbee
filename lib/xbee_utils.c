//
//  xbee_utils.c
//  XBee
//
//  Created by Jagor Lavonienka on 7.4.12.
//  Copyright (c) 2012 Jagor Lavonienka. All rights reserved.
//

#include "xbee_utils.h"

#include "xbee.h"
#include <string.h>

char* XBeeATCommandStatusString(XBeeATCommandStatus status) {
    switch (status) {
        case XBeeATCommandOk:
            return "OK";
        case XBeeATCommandError:
            return "Error";
        case XBeeATCommandInvalidCommand:
            return "Invalid Command";
        case XBeeATCommandInvalidParameter:
            return "Invalid Parameter";
        case XBeeATCommandTxFailure:
            return "TX Failure";
        default:
            return "!!!Unknown!!!";
    }
}

char* XBeeModemStatusString(XBeeModemStatus status) {
    switch (status) {
        case XBeeModemConfigurationChangedWhileJoinInProgress:
            return "Configuration changed while join in progress";
        case XBeeModemCoordinatorStarted:
            return "Coordinator started";
        case XBeeModemDisassociated:
            return "Disassociated";
        case XBeeModemHardwareReset:
            return "Hardware reset";
        case XBeeModemJoinedNetwork:
            return "Joined network";
        case XBeeModemVoltageSupplyLimitExceeded:
            return "Voltage supply limit exceeded";
        case XBeeModemNetworkSecurityKeyWasUpdated:
            return "Network security key was updated";
        case XBeeModemWatchdogTimerReset:
            return "Watchdog timer reset";
        default:
            if (status >= XBeeModemStackError) {
                return "Stack error";
            } else {
                return "!!!Unknown!!!";
            }
    }
}

char* XBeeDeliveryStatusString(XBeeDeliveryStatus status) {
    switch (status) {
        case XBeeDeliverySuccess:
            return "Success";
        case XBeeDeliveryAddressNotFound:
            return "Address not found";
        case XBeeDeliveryCCAFailure:
            return "CCA Failure";
        case XBeeDeliveryMACACKFailure:
            return "MAC ACK Failure";
        case XBeeDeliveryRouteNotFound:
            return "Route not found";
        case XBeeDeliverySelfAddressed:
            return "Self addressed";
        case XBeeDeliveryNotJoinedNetwork:
            return "Not joined network";
        case XBeeDeliveryNetworkACKFailure:
            return "Netork ACK Failure";
        case XBeeDeliveryDataPayloadTooLarge:
            return "Data payload too large";
        case XBeeDeliveryInvalidBindingTableIndex:
            return "Invalid binding table index";
        case XBeeDeliveryIndirectMessageUnrequested:
            return "Indirect message unrequested";
        case XBeeDeliveryInvalidDestinationEndpoint:
            return "Invalid destination Endpoint";
        case XBeeDeliveryAttemptedBroadcastWithAPSTransmission:
            return "Attempted broadcast with APS transmission";
        case XBeeDeliveryBroadcastSourceFailedToHearANeighbourRelayTheMessage:
            return "Broadcast source failed to hear a neighbour relay the message";
        case XBeeDeliveryResourceErrorLackOfFreeBuffersTimersEtc:
            return "Resource error lack of free buffers, timers, etc.";
        case XBeeDeliveryResourceErrorLackOfFreeBuffersTimersEtc2:
            return "Resource error lack of free buffers, timers, etc.";
        case XBeeDeliveryAttemptedUnicastWithAPSTransmissionButEEeq0:
            return "Attempted unicast with APS transmission but EE=0";
        default:
            return "!!!Unknown!!!";
    }
}

char* XBeeDiscoveryStatusString(XBeeDiscoveryStatus status) {
    switch (status) {
        case XBeeDiscoveryNoOverhead:
            return "No overhead";
        case XBeeDiscoveryAddress:
            return "Discovered address";
        case XBeeDiscoveryRoute:
            return "Discovered route";
        case XBeeDiscoveryAddressAndRoute:
            return "Discovered address and route";
        case XBeeDiscoveryExtendedTimeout:
            return "Extended timeout";
        default:
            return "!!!Unknown!!!";
    }
}

char* ZigBeeDeviceTypeString(ZigBeeDeviceType deviceType) {
    switch (deviceType) {
        case ZigBeeCoordinator:
            return "Coordinator";
        case ZigBeeRouter:
            return "Router";
        case ZigBeeEndDevice:
            return "End Device";
        default:
            return "!!!Unknown!!!";
    }
}

char* XBeeSourceEventString(XBeeSourceEvent sourceEvent) {
    switch (sourceEvent) {
        case XBeeSourceJoin:
            return "Join";
        case XBeeSourcePower:
            return "Power";
        case XBeeSourcePushbutton:
            return "Pushbutton";
        default:
            return "!!!Unknown!!!";
    }
}

static char hexDigit(uint8_t d) {
    return d < 0xA ? d + '0' : (d - 10) + 'A';
}

size_t hexDump(char* buffer, size_t buffer_length, const void* data, size_t dataLength) {
    if (data && dataLength && buffer_length) {
        char* slidingBuffer = buffer;
        for (int i = 0; i < dataLength; i++) {
            if (buffer_length > 3) {
                uint8_t d = ((uint8_t*)data)[i];
                uint8_t h = (d & 0xF0) >> 8;
                uint8_t l = d & 0xF;
                slidingBuffer[0] = hexDigit(h);
                slidingBuffer[1] = hexDigit(l);
                if ((i + 1) % 4 == 0) {
                    if ((i + 1) % 16 == 0) {
                        slidingBuffer[2] = '\n';
                    } else {
                        slidingBuffer[2] = '\t';
                    }
                } else {
                    slidingBuffer[2] = ' ';
                }
                slidingBuffer += 3;
                buffer_length -= 3;
            } else {
                return -1;
            }
        }
        slidingBuffer[0] = '\0';
        return strnlen(buffer, buffer_length);
    }
    return 0;
}

char* XBeeReceiveOptionString(XBeeReceiveOptions options, int i) {
    if ((options & XBeeReceivePacketAcknowledged) == XBeeReceivePacketAcknowledged) {
        if (i == 0) {
            return "ACK";
        }
        i--;
    }
    if ((options & XBeeReceivePacketWasBroadcast) == XBeeReceivePacketWasBroadcast) {
        if (i == 0) {
            return "BRD";
        }
        i--;
    }
    if ((options & XBeeReceivePacketEncryptedWithAPSEncryption) == XBeeReceivePacketEncryptedWithAPSEncryption) {
        if (i == 0) {
            return "APS";
        }
        i--;
    }
    if ((options & XBeeReceivePacketWasSentFromEndDevice) == XBeeReceivePacketWasSentFromEndDevice) {
        if (i == 0) {
            return "END";
        }
    }
    return NULL;
}

size_t XBeeReceiveOptionsString(char* buffer, size_t buffer_length, XBeeReceiveOptions options) {
    if (buffer_length == 0) {
        return 0;
    }
    buffer[0] = '\0';
    char* optionString;
    int i = 0;
    char* slidingBuffer = buffer;
    while ((optionString = XBeeReceiveOptionString(options, i))) {
        size_t optionStringLength = strlen(optionString);
        if (buffer_length > optionStringLength + 1) {
            strcat(slidingBuffer, optionString);
            slidingBuffer += optionStringLength;
            strcat(slidingBuffer, ";");
            slidingBuffer++;
            buffer_length -= optionStringLength + 1;
        } else {
            return -1;
        }
        
        i++;
    }
    return strnlen(buffer, buffer_length);
}
