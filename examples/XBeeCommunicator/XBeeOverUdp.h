//
//  XBeeOverUdp.h
//  XBeeCommunicator
//
//  Created by Jagor Lavonienka on 13.5.12.
//  Copyright (c) 2012 iTransition. All rights reserved.
//

#import "XBee.h"

@interface XBeeOverUdp : XBee
-(id) initWithAddress:(NSString*) addr port:(uint16_t) port;
@end
