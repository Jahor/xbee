//
//  xbee.h
//  XBee
//
//  Created by Jagor Lavonienka on 7.4.12.
//  Copyright (c) 2012 Jagor Lavonienka. All rights reserved.
//

#ifndef __XBEE_ZCL_H__
#define __XBEE_ZCL_H__

#include <stdlib.h>
#include <stdint.h>
#include "xbee.h"

/*
typedef enum {
    
} ZigBeeProfile;
*/

typedef enum {
    ZigBeeGeneralBasic = 0x0000, // Attributes for determining basic information about a device, setting user device information such as location, and enabling a device.
    ZigBeeGeneralPowerConfiguration = 0x0001, // Attributes for determining more detailed information about a device’s power source(s), and for configuring under/over voltage alarms.
    ZigBeeGeneralDeviceTemperatureConfiguration = 0x0002, // Attributes for determining information about a device’s internal temperature, and for configuring under/over temperature alarms.
    ZigBeeGeneralIdentify = 0x0003, // Attributes and commands for putting a device into Identification mode (e.g. flashing a light)
    ZigBeeGeneralGroups = 0x0004, // Attributes and commands for group configuration and manipulation.
    ZigBeeGeneralScenes = 0x0005, // Attributes and commands for scene configuration and manipulation.
    ZigBeeGeneralOnOff = 0x0006, // Attributes and commands for switching devices between ‘On’ and ‘Off’ states.
    ZigBeeGeneralOnOffSwitchConfiguration = 0x0007, // Attributes and commands for configuring On/Off switching devices
    ZigBeeGeneralLevelControl = 0x0008, // Attributes and commands for controlling devices that can be set to a level between fully ‘On’ and fully ‘Off’.
    ZigBeeGeneralAlarms = 0x0009, // Attributes and commands for sending notifications and configuring alarm functionality.
    ZigBeeGeneralTime = 0x000a, // Attributes and commands that provide a basic interface to a real-time clock.
    ZigBeeGeneralRSSILocation = 0x000b, // Attributes and commands that provide a means for exchanging location information and channel parameters among devices.
    ZigBeeGeneralAnalogInput = 0x000c, // An interface for reading the value of an analog measurement and accessing various characteristics of that measurement.
    ZigBeeGeneralAnalogOutput = 0x000d, //An interface for setting the value of an analog output (typically to the environment) and accessing various characteristics of that value.
    ZigBeeGeneralAnalogValue = 0x000e, // An interface for setting an analog value, typically used as a control system parameter, and accessing various characteristics of that value.
    ZigBeeGeneralBinaryInput = 0x000f, // An interface for reading the value of a binary measurement and accessing various characteristics of that measurement.
    ZigBeeGeneralBinaryOutput = 0x0010, // An interface for setting the value of a binary output (typically to the environment) and accessing various characteristics of that value.
    ZigBeeGeneralBinaryValue = 0x0011, // An interface for setting a binary value, typically used as a control system parameter, and accessing various characteristics of that value.
    ZigBeeGeneralMultistateInput = 0x0012, // An interface for reading the value of a multistate measurement and accessing various characteristics of that measurement.
    ZigBeeGeneralMultistateOutput = 0x0013, // An interface for setting the value of a multistate output (typically to the environment) and accessing various characteristics of that value.
    ZigBeeGeneralMultistateValue = 0x0014, // An interface for setting a multistate value, typically used as a control system parameter, and accessing various characteristics of that value.
    ZigBeeGeneralCommissioning = 0x0015, //Attributes and commands for commissioning and managing a ZigBee device.                
} ZigBeeGeneralCluster;


#endif
