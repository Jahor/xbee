//
//  xbee_utils.h
//  XBee
//
//  Created by Jagor Lavonienka on 7.4.12.
//  Copyright (c) 2012 Jagor Lavonienka. All rights reserved.
//

#ifndef __XBEE_UTILS__
#define __XBEE_UTILS__

#include "xbee.h"


char* XBeeATCommandStatusString(XBeeATCommandStatus status);

char* XBeeModemStatusString(XBeeModemStatus status);

char* XBeeDeliveryStatusString(XBeeDeliveryStatus status);

char* XBeeDiscoveryStatusString(XBeeDiscoveryStatus status);

char* ZigBeeDeviceTypeString(ZigBeeDeviceType deviceType);

char* XBeeSourceEventString(XBeeSourceEvent sourceEvent);

size_t hexDump(char* buffer, size_t buffer_length, const void* data, size_t dataLength);

char* XBeeReceiveOptionString(XBeeReceiveOptions options, int i);

size_t XBeeReceiveOptionsString(char* buffer, size_t buffer_length, XBeeReceiveOptions options);

#endif
