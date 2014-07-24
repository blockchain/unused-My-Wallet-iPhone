//
//  NSString+NSString_EscapeQuotes.m
//  Blockchain
//
//  Created by Ben Reeves on 21/07/2014.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import "NSString+NSString_EscapeQuotes.h"

@implementation NSString (NSString_EscapeQuotes)


-(NSString *)escapeStringForJS {
    
    NSMutableString * string = [self mutableCopy];
    
    [string replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:NSLiteralSearch range:NSMakeRange(0, [string length])];
    [string replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:NSLiteralSearch range:NSMakeRange(0, [string length])];
    [string replaceOccurrencesOfString:@"\'" withString:@"\\\'" options:NSLiteralSearch range:NSMakeRange(0, [string length])];
    [string replaceOccurrencesOfString:@"\n" withString:@"\\n" options:NSLiteralSearch range:NSMakeRange(0, [string length])];
    [string replaceOccurrencesOfString:@"\r" withString:@"\\r" options:NSLiteralSearch range:NSMakeRange(0, [string length])];
    [string replaceOccurrencesOfString:@"\f" withString:@"\\f" options:NSLiteralSearch range:NSMakeRange(0, [string length])];
    
    return string;
}


@end
