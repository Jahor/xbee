//
//  XBee_Internal.h
//  XBeeCommunicator
//
//  Created by Jagor Lavonienka on 13.5.12.
//  Copyright (c) 2012 iTransition. All rights reserved.
//

#ifndef XBeeCommunicator_XBee_Internal_h
#define XBeeCommunicator_XBee_Internal_h

#import "XBee.h"

@interface XBee ()

@end

@interface XBee (Internal)
-(size_t) write:(NSData*) data;

-(void) addData:(NSData*) data;

-(NSString*) internalConnect;
-(BOOL) internalDisconnect;
@end

#endif
