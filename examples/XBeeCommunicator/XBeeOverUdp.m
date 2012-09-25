//
//  XBeeOverUdp.m
//  XBeeCommunicator
//
//  Created by Jagor Lavonienka on 13.5.12.
//  Copyright (c) 2012 iTransition. All rights reserved.
//

#import "XBeeOverUdp.h"
#import "XBee_Internal.h"

#import "AsyncUdpSocket.h"

@interface XBeeOverUdp()<AsyncUdpSocketDelegate>

@end

@implementation XBeeOverUdp {
    NSString* address;
    uint16_t port;
    AsyncUdpSocket* socket;
}

-(id) initWithAddress:(NSString *)remoteAddress port:(uint16_t) remotePort {
    if((self = [super init])) {
        address = [remoteAddress retain];
        port = remotePort;
    }
    return self;
}

-(NSString*) name {
    return [NSString stringWithFormat: @"XBee@%@:%d", address, port];
}

-(NSString*) internalConnect {
    socket = [[AsyncUdpSocket alloc] initWithDelegate: self];

    NSError* error = nil;
    if([socket bindToPort: 6000 error: &error]) {
        [socket receiveWithTimeout:-1 tag:0];
        return nil;
    } else {
        return error.localizedDescription;
    }
    return nil;
}

-(size_t) write: (NSData*) data {
	if (socket > 0) {
        [socket sendData:[data copy] toHost: address port: port withTimeout:2.0 tag: 1];
//        [socket sendData:data withTimeout:2.0 tag:0];
	}
	return 0;	
}


-(BOOL) internalDisconnect {
    if (socket) {
		[socket close];
        [socket release];
        socket = nil;
        return YES;
	}
    return NO;
}

-(void) dealloc {
    [socket release];
	socket = nil;
    [address release];
    address = nil;
    
    [super dealloc];
}

-(BOOL) onUdpSocket:(AsyncUdpSocket *)sock didReceiveData:(NSData *)data withTag:(long)tag fromHost:(NSString *)host port:(UInt16)port {
    [self addData: data];
    [socket receiveWithTimeout:-1 tag:0];
    return YES;
}

@end
