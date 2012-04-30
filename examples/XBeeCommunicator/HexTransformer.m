//
//  HexTransformer.m
//  XBeeCommunicator
//
//  Created by Jagor Lavonienka on 29.4.12.
//  Copyright (c) 2012 iTransition. All rights reserved.
//

#import "HexTransformer.h"

@implementation HexTransformer
- (int) numberOfBytes { return 16; }
+ (Class)transformedValueClass { return [NSString class]; }
+ (BOOL)allowsReverseTransformation { return NO; }
- (id)transformedValue:(id)value {
    return [NSString stringWithFormat: [NSString  stringWithFormat: @"0x%%0%dqX", [self numberOfBytes] * 2], [value unsignedLongLongValue]];
}
@end
