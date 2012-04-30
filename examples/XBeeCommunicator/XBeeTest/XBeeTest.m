//
//  XBeeTest.m
//  XBeeTest
//
//  Created by Jagor Lavonienka on 8.4.12.
//  Copyright (c) 2012 iTransition. All rights reserved.
//

#import "XBeeTest.h"
#import "../../../lib/xbee.h"

size_t writeToNSData(xbee* xb, void* data, size_t dataLength) {
    [(NSMutableData*) XBeeUserData(xb) appendBytes:data length: dataLength];
    NSLog(@"Data: %@", XBeeUserData(xb));
    return dataLength;
}

void ATCommandResponseToDictionary(xbee* xb, XBeeFrameId frameId, const char* atCommand, XBeeATCommandStatus status, void* data, size_t dataLength) {
    NSMutableArray* list = XBeeUserData(xb);
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    [dict setObject: @"AT Response" forKey: @"CMD"];
    [dict setObject: [NSNumber numberWithInt: frameId] forKey: @"FrameId"];
    [dict setObject: [NSString stringWithUTF8String: atCommand] forKey: @"ATCommand"];
    NSString* statusString = nil;
    switch (status) {
        case XBeeATCommandOk:
            statusString = @"OK";
            break;
        case XBeeATCommandError:
            statusString = @"Error";
            break;
        case XBeeATCommandInvalidCommand:
            statusString = @"Invalid Command";
            break;
        case XBeeATCommandInvalidParameter:
            statusString = @"Invalid Parameter";
            break;
        case XBeeATCommandTxFailure:
            statusString = @"TX Failure";
            break;
        default:
            break;
    }
    [dict setObject: statusString forKey: @"CommandStatus"];
    if (data && dataLength) {
        [dict setObject: [NSData dataWithBytes: data length: dataLength] forKey: @"CommandData"];
    }
    [list addObject: dict];
}

NSString* receiveOptionsString(XBeeReceiveOptions options) {
    NSMutableString* receiveOptions = [NSMutableString string];
    if ((options & XBeeReceivePacketAcknowledged) == XBeeReceivePacketAcknowledged) {
        [receiveOptions appendString:@"ACK;"];
    }
    if ((options & XBeeReceivePacketWasBroadcast) == XBeeReceivePacketWasBroadcast) {
        [receiveOptions appendString:@"BRD;"];
    }
    if ((options & XBeeReceivePacketEncryptedWithAPSEncryption) == XBeeReceivePacketEncryptedWithAPSEncryption) {
        [receiveOptions appendString:@"APS;"];
    }
    if ((options & XBeeReceivePacketWasSentFromEndDevice) == XBeeReceivePacketWasSentFromEndDevice) {
        [receiveOptions appendString:@"END;"];
    }
    return receiveOptions;
}

void NetworkIdentificationIndicatorToDictionary(xbee* xb, ZigBeeLongAddress senderLong, ZigBeeShortAddress senderShort, XBeeReceiveOptions receiveOptions, 
                                                ZigBeeShortAddress sourceShort, ZigBeeLongAddress sourceLong, const char* ni, ZigBeeShortAddress parentShort, 
                                                ZigBeeDeviceType deviceType, XBeeSourceEvent sourceEvent) {
    NSMutableArray* list = XBeeUserData(xb);
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    [dict setObject: @"NII" forKey: @"CMD"];
    [dict setObject: [NSNumber numberWithLongLong: senderLong.full] forKey: @"SenderLong"];
    [dict setObject: [NSNumber numberWithInt: senderShort] forKey: @"SenderShort"];
    [dict setObject: receiveOptionsString(receiveOptions) forKey: @"ReceiveOptions"];
    [dict setObject: [NSNumber numberWithInt: sourceShort] forKey: @"SourceShort"];
    [dict setObject: [NSNumber numberWithLongLong: sourceLong.full] forKey: @"SourceLong"];
    [dict setObject: [NSString stringWithUTF8String: ni] forKey: @"NI"];
    [dict setObject: [NSNumber numberWithInt: parentShort] forKey: @"ParentShort"];
    
    NSString* deviceTypeString = nil;
    switch (deviceType) {
        case ZigBeeCoordinator:
            deviceTypeString = @"COORDINATOR";
            break;
        case ZigBeeRouter:
            deviceTypeString = @"ROUTER";
            break;
        case ZigBeeEndDevice:
            deviceTypeString = @"END";
            break;
    }
    [dict setObject: deviceTypeString forKey: @"DeviceType"];
    
    
    NSString* sourceEventString = nil;
    switch (sourceEvent) {
        case XBeeSourceJoin:
            sourceEventString = @"JOIN";
            break;
        case XBeeSourcePower:
            sourceEventString = @"POWER";
            break;
        case XBeeSourcePushbutton:
            sourceEventString = @"PUSH";
            break;
    }
    [dict setObject: sourceEventString forKey: @"SourceEvent"];
    
    [list addObject: dict];
}


@implementation XBeeTest {
    
}

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testSendATCommandNormal
{
    xbee xbee;
    NSMutableData* buffer = [NSMutableData data];
    XBeeInit(&xbee, XBeeAPINormal, writeToNSData, buffer);
    xbee.nextFrameId = 0x52;
    XBeeSendATCommand(&xbee, "NJ", NULL);

    uint8_t expectedFrame[] = {0x7E, 0x00, 0x04, 0x08, 0x52, 0x4E, 0x4A, 0x0D};
    STAssertEqualObjects([NSData dataWithBytes: expectedFrame length: sizeof(expectedFrame)], buffer, nil);
}

- (void)testSendATCommandSetValueNormal
{
    xbee xbee;
    NSMutableData* buffer = [NSMutableData data];
    XBeeInit(&xbee, XBeeAPINormal, writeToNSData, buffer);
    XBeeATParameter parameter = {.type = XBeeATParameter8bit, {.u8 = 0x11}};
    XBeeSendATCommand(&xbee, "NJ", &parameter);
    uint8_t expectedFrame[] = {0x7E, 0x00, 0x05, 0x08, 0x01, 0x4E, 0x4A, 0x11, 0x4D};
    STAssertEqualObjects([NSData dataWithBytes: expectedFrame length: sizeof(expectedFrame)], buffer, nil);
}

- (void)testSendATCommandSetValueEscaped
{
    xbee xbee;
    NSMutableData* buffer = [NSMutableData data];
    XBeeInit(&xbee, XBeeAPIEscaped, writeToNSData, buffer);
    XBeeATParameter parameter = {.type = XBeeATParameter8bit, {.u8 = 0x11}};
    XBeeSendATCommand(&xbee, "NJ", &parameter);
    uint8_t expectedFrame[] = {0x7E, 0x00, 0x05, 0x08, 0x01, 0x4E, 0x4A, 0x7D, 0x31, 0x4D};
    STAssertEqualObjects([NSData dataWithBytes: expectedFrame length: sizeof(expectedFrame)], buffer, nil);
}

- (void)testReceiveATCommandResponseNormalFull
{
    xbee xbee;
    NSMutableArray* list = [NSMutableArray array];
    XBeeInit(&xbee, XBeeAPINormal, writeToNSData, list);
    XBeeRegisterOnATCommandResponse(&xbee, ATCommandResponseToDictionary);
    uint8_t frame[] = {0x7E, 0x00, 0x05, 0x88, 0x01, 0x42, 0x44, 0x00, 0xF0};
    XBeeAddData(&xbee, frame, sizeof(frame) / sizeof(frame[0]));
    STAssertEquals((NSUInteger)1, [list count], @"Number of commands");
    NSDictionary* buffer = [list objectAtIndex: 0];
    STAssertEqualObjects(@"AT Response", [buffer objectForKey: @"CMD"], @"CMD");
    STAssertEqualObjects([NSNumber numberWithInt: 1], [buffer objectForKey: @"FrameId"], @"FrameId");
    STAssertEqualObjects(@"BD", [buffer objectForKey: @"ATCommand"], @"ATCommand");
    STAssertEqualObjects(@"OK", [buffer objectForKey: @"CommandStatus"], @"CommandStatus");
    STAssertNil([buffer objectForKey: @"CommandData"], @"CommandData");
}   

- (void)testReceiveATCommandResponseNormal2Parts
{
    xbee xbee;
    NSMutableArray* list = [NSMutableArray array];
    XBeeInit(&xbee, XBeeAPINormal, writeToNSData, list);
    XBeeRegisterOnATCommandResponse(&xbee, ATCommandResponseToDictionary);
    uint8_t frame1[] = {0x7E, 0x00, 0x05, 0x88};
    XBeeAddData(&xbee, frame1, sizeof(frame1) / sizeof(frame1[0]));
    uint8_t frame2[] = {0x01, 0x42, 0x44, 0x00, 0xF0};
    XBeeAddData(&xbee, frame2, sizeof(frame2) / sizeof(frame2[0]));
    STAssertEquals((NSUInteger)1, [list count], @"Number of commands");
    NSDictionary* buffer = [list objectAtIndex: 0];
    STAssertEqualObjects(@"AT Response", [buffer objectForKey: @"CMD"], @"CMD");
    STAssertEqualObjects([NSNumber numberWithInt: 1], [buffer objectForKey: @"FrameId"], @"FrameId");
    STAssertEqualObjects(@"BD", [buffer objectForKey: @"ATCommand"], @"ATCommand");
    STAssertEqualObjects(@"OK", [buffer objectForKey: @"CommandStatus"], @"CommandStatus");
    STAssertNil([buffer objectForKey: @"CommandData"], @"CommandData");
}  

- (void)testReceiveATCommandResponseNormal3Commands
{
    xbee xbee;
    NSMutableArray* list = [NSMutableArray array];
    XBeeInit(&xbee, XBeeAPINormal, writeToNSData, list);
    XBeeRegisterOnATCommandResponse(&xbee, ATCommandResponseToDictionary);
    XBeeRegisterOnNodeIdentificationIndicator(&xbee, NetworkIdentificationIndicatorToDictionary);
    uint8_t frame1[] = {0x7E, 0x00, 0x05, 0x88};
    XBeeAddData(&xbee, frame1, sizeof(frame1) / sizeof(frame1[0]));
    uint8_t frame2[] = {0x01, 0x42, 0x44, 0x00, 0xF0, 0x7E, 0x00};
    XBeeAddData(&xbee, frame2, sizeof(frame2) / sizeof(frame2[0]));
    uint8_t frame3[] = {0x06, 0x88, 0x01, 0x4E, 0x4A, 0x00, 0x11, 0xCD, 0x7E, 0x00, 0x20, 0x95, 0x00, 0x13, 0xA2, 0x00};
    XBeeAddData(&xbee, frame3, sizeof(frame3) / sizeof(frame3[0]));
    uint8_t frame4[] = {0x40, 0x52, 0x2B, 0xAA, 0x7D, 0x84, 0x02, 0x7D, 0x84, 0x00, 0x13, 0xA2, 0x00, 0x40, 0x52, 0x2B};
    XBeeAddData(&xbee, frame4, sizeof(frame4) / sizeof(frame4[0]));
    uint8_t frame5[] = {0xAA, 0x20, 0x00, 0xFF, 0xFE, 0x01, 0x01, 0xC1, 0x05, 0x10, 0x1E, 0x1B};
    XBeeAddData(&xbee, frame5, sizeof(frame5) / sizeof(frame5[0]));

    STAssertEquals((NSUInteger)3, [list count], @"Number of commands");
    NSDictionary* buffer = [list objectAtIndex: 0];
    STAssertEqualObjects(@"AT Response", [buffer objectForKey: @"CMD"], @"CMD");
    STAssertEqualObjects([NSNumber numberWithInt: 1], [buffer objectForKey: @"FrameId"], @"FrameId");
    STAssertEqualObjects(@"BD", [buffer objectForKey: @"ATCommand"], @"ATCommand");
    STAssertEqualObjects(@"OK", [buffer objectForKey: @"CommandStatus"], @"CommandStatus");
    STAssertNil([buffer objectForKey: @"CommandData"], @"CommandData");
    
    buffer = [list objectAtIndex: 1];
    STAssertEqualObjects(@"AT Response", [buffer objectForKey: @"CMD"], @"CMD");
    STAssertEqualObjects([NSNumber numberWithInt: 1], [buffer objectForKey: @"FrameId"], @"FrameId");
    STAssertEqualObjects(@"NJ", [buffer objectForKey: @"ATCommand"], @"ATCommand");
    STAssertEqualObjects(@"OK", [buffer objectForKey: @"CommandStatus"], @"CommandStatus");
    uint8_t data[] = {0x11};
    STAssertEqualObjects([NSData dataWithBytes: data length:sizeof(data)], [buffer objectForKey: @"CommandData"], @"CommandData");
    
    buffer = [list objectAtIndex: 2];
    STAssertEqualObjects(@"NII", [buffer objectForKey: @"CMD"], @"CMD");
    STAssertEqualObjects([NSNumber numberWithInt: 0x7D84], [buffer objectForKey: @"SenderShort"], @"SenderShort");
    STAssertEqualObjects([NSNumber numberWithLongLong: 0x0013A20040522BAALL], [buffer objectForKey: @"SenderLong"], @"SenderLong");
    STAssertEqualObjects(@"BRD;", [buffer objectForKey: @"ReceiveOptions"], @"ReceiveOptions");
    STAssertEqualObjects([NSNumber numberWithLongLong: 0x0013A20040522BAALL], [buffer objectForKey: @"SourceLong"], @"SourceLong");
    STAssertEqualObjects([NSNumber numberWithInt: 0x7D84], [buffer objectForKey: @"SourceShort"], @"SourceShort");
    STAssertEqualObjects(@" ", [buffer objectForKey: @"NI"], @"NI");    
    STAssertEqualObjects([NSNumber numberWithInt: 0xFFFE], [buffer objectForKey: @"ParentShort"], @"ParentShort");
    STAssertEqualObjects(@"ROUTER", [buffer objectForKey: @"DeviceType"], @"DeviceType");
    STAssertEqualObjects(@"PUSH", [buffer objectForKey: @"SourceEvent"], @"SourceEvent");
}  

- (void)testReceiveATCommandResponseNormal2PartsWithNoiseBefore
{
    xbee xbee;
    NSMutableArray* list = [NSMutableArray array];
    XBeeInit(&xbee, XBeeAPINormal, writeToNSData, list);
    XBeeRegisterOnATCommandResponse(&xbee, ATCommandResponseToDictionary);
    uint8_t frame1[] = {0x11, 0x13, 0x7E, 0x00, 0x05, 0x88};
    XBeeAddData(&xbee, frame1, sizeof(frame1) / sizeof(frame1[0]));
    uint8_t frame2[] = {0x01, 0x42, 0x44, 0x00, 0xF0};
    XBeeAddData(&xbee, frame2, sizeof(frame2) / sizeof(frame2[0]));
    STAssertEquals((NSUInteger)1, [list count], @"Number of commands");
    NSDictionary* buffer = [list objectAtIndex: 0];
    STAssertEqualObjects(@"AT Response", [buffer objectForKey: @"CMD"], @"CMD");
    STAssertEqualObjects([NSNumber numberWithInt: 1], [buffer objectForKey: @"FrameId"], @"FrameId");
    STAssertEqualObjects(@"BD", [buffer objectForKey: @"ATCommand"], @"ATCommand");
    STAssertEqualObjects(@"OK", [buffer objectForKey: @"CommandStatus"], @"CommandStatus");
    STAssertNil([buffer objectForKey: @"CommandData"], @"CommandData");
}  

- (void)testReceiveATCommandResponseEscapedFull
{
    xbee xbee;
    NSMutableArray* list = [NSMutableArray array];
    XBeeInit(&xbee, XBeeAPIEscaped, writeToNSData, list);
    XBeeRegisterOnATCommandResponse(&xbee, ATCommandResponseToDictionary);
    uint8_t frame[] = {0x7E, 0x00, 0x06, 0x88, 0x01, 0x4E, 0x4A, 0x00, 0x07D, 0x31, 0xCD};
    XBeeAddData(&xbee, frame, sizeof(frame) / sizeof(frame[0]));
    STAssertEquals((NSUInteger) 1, [list count], @"Number of commands");
    NSDictionary* buffer = [list objectAtIndex: 0];
    STAssertEqualObjects(@"AT Response", [buffer objectForKey: @"CMD"], @"CMD");
    STAssertEqualObjects([NSNumber numberWithInt: 1], [buffer objectForKey: @"FrameId"], @"FrameId");
    STAssertEqualObjects(@"NJ", [buffer objectForKey: @"ATCommand"], @"ATCommand");
    STAssertEqualObjects(@"OK", [buffer objectForKey: @"CommandStatus"], @"CommandStatus");
    uint8_t data[] = {0x11};
    STAssertEqualObjects([NSData dataWithBytes: data length:sizeof(data)], [buffer objectForKey: @"CommandData"], @"CommandData");
}   

- (void)testReceiveATCommandResponseEscaped2Parts
{
    xbee xbee;
    NSMutableArray* list = [NSMutableArray array];
    XBeeInit(&xbee, XBeeAPIEscaped, writeToNSData, list);
    XBeeRegisterOnATCommandResponse(&xbee, ATCommandResponseToDictionary);
    uint8_t frame1[] = {0x7E, 0x00, 0x06, 0x88, 0x01, 0x4E, 0x4A, 0x00, 0x07D};
    XBeeAddData(&xbee, frame1, sizeof(frame1) / sizeof(frame1[0]));
    uint8_t frame2[] = {0x31, 0xCD};
    XBeeAddData(&xbee, frame2, sizeof(frame2) / sizeof(frame2[0]));
    STAssertEquals((NSUInteger) 1, [list count], @"Number of commands");
    NSDictionary* buffer = [list objectAtIndex: 0];
    STAssertEqualObjects(@"AT Response", [buffer objectForKey: @"CMD"], @"CMD");
    STAssertEqualObjects([NSNumber numberWithInt: 1], [buffer objectForKey: @"FrameId"], @"FrameId");
    STAssertEqualObjects(@"NJ", [buffer objectForKey: @"ATCommand"], @"ATCommand");
    STAssertEqualObjects(@"OK", [buffer objectForKey: @"CommandStatus"], @"CommandStatus");
    uint8_t data[] = {0x11};
    STAssertEqualObjects([NSData dataWithBytes: data length:sizeof(data)], [buffer objectForKey: @"CommandData"], @"CommandData");
}  

- (void)testReceiveATCommandResponseEscaped2PartsWithNoiseBefore
{
    xbee xbee;
    NSMutableArray* list = [NSMutableArray array];
    XBeeInit(&xbee, XBeeAPIEscaped, writeToNSData, list);
    XBeeRegisterOnATCommandResponse(&xbee, ATCommandResponseToDictionary);
    uint8_t frame1[] = {0x11, 0x13, 0x7E, 0x00, 0x06, 0x88, 0x01, 0x4E};
    XBeeAddData(&xbee, frame1, sizeof(frame1) / sizeof(frame1[0]));
    uint8_t frame2[] = {0x4A, 0x00, 0x07D, 0x31, 0xCD};
    XBeeAddData(&xbee, frame2, sizeof(frame2) / sizeof(frame2[0]));
    STAssertEquals((NSUInteger) 1, [list count], @"Number of commands");
    NSDictionary* buffer = [list objectAtIndex: 0];
    STAssertEqualObjects(@"AT Response", [buffer objectForKey: @"CMD"], @"CMD");
    STAssertEqualObjects([NSNumber numberWithInt: 1], [buffer objectForKey: @"FrameId"], @"FrameId");
    STAssertEqualObjects(@"NJ", [buffer objectForKey: @"ATCommand"], @"ATCommand");
    STAssertEqualObjects(@"OK", [buffer objectForKey: @"CommandStatus"], @"CommandStatus");
    uint8_t data[] = {0x11};
    STAssertEqualObjects([NSData dataWithBytes: data length:sizeof(data)], [buffer objectForKey: @"CommandData"], @"CommandData");
} 

-(void) testSendZigbeeTransmitRequest {
    xbee xb;
    NSMutableData* buffer = [NSMutableData data];
    XBeeInit(&xb, XBeeAPIEscaped, writeToNSData, buffer);
    
    char* data = "TxData0A";
    
    XBeeSendZigBeeTransmitRequest(&xb, ZigBeeLongAddressMake(0x0013A200, 0x400A0127), ZigBeeShortAddressUnknown, 0, XBeeTransmitOptionsNone, data, strlen(data));
                                  
    uint8_t expectedFrame[] = {0x7E, 0x00, 0x16, 0x10, 0x01, 0x00, 0x7D, 0x33, 0xA2, 0x00, 0x40, 0x0A, 0x01, 0x27, 0xFF, 0xFE, 0x00, 0x00, 0x54, 0x78, 0x44, 0x61, 0x74, 0x61, 0x30, 0x41, 0x7D, 0x33};
    STAssertEqualObjects([NSData dataWithBytes: expectedFrame length: sizeof(expectedFrame)], buffer, nil);
}


@end
