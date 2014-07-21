//
//  NSString+NSString_EscapeQuotes.m
//  Blockchain
//
//  Created by Ben Reeves on 21/07/2014.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import "NSString+NSString_EscapeQuotes.h"

@implementation NSString (NSString_EscapeQuotes)

-(NSString*)escapeDoubleQuotes {
    return [self stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
}

@end
