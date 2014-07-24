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
    
    NSString * slashEscape = [self stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];

    NSString * quoteEscape = [slashEscape stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];

    return quoteEscape;
}

-(NSString *)addBackslashes {
    /*
     
     Escape characters so we can pass a string via stringByEvaluatingJavaScriptFromString
     
     */
    
    NSMutableString * string = [self mutableCopy];
        
    [string replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:NSLiteralSearch range:NSMakeRange(0, [string length])];
    [string replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:NSLiteralSearch range:NSMakeRange(0, [string length])];
    [string replaceOccurrencesOfString:@"\'" withString:@"\\\'" options:NSLiteralSearch range:NSMakeRange(0, [string length])];
    [string replaceOccurrencesOfString:@"\n" withString:@"\\n" options:NSLiteralSearch range:NSMakeRange(0, [string length])];
    [string replaceOccurrencesOfString:@"\r" withString:@"\\r" options:NSLiteralSearch range:NSMakeRange(0, [string length])];
    [string replaceOccurrencesOfString:@"\f" withString:@"\\f" options:NSLiteralSearch range:NSMakeRange(0, [string length])];
    [string replaceOccurrencesOfString:@"%" withString:@"%%" options:NSLiteralSearch range:NSMakeRange(0, [string length])];
    
    return string;
}

- (NSString *)stringEscapedForJavasacript {
    // valid JSON object need to be an array or dictionary
    NSArray* arrayForEncoding = @[self];
    NSString* jsonString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:arrayForEncoding options:0 error:nil] encoding:NSUTF8StringEncoding];
    
    NSString* escapedString = [jsonString substringWithRange:NSMakeRange(2, jsonString.length - 4)];
    return escapedString;
}

-(NSString*)escapeASCII {
    const char *chars = [self UTF8String];
    NSMutableString *escapedString = [NSMutableString string];
    while (*chars)
    {
        if (*chars == '\\')
         [escapedString appendString:@"\\\\"];
        else if (*chars == '"')
         [escapedString appendString:@"\\\""];
        else if (*chars < 0x1F || *chars == 0x7F)
         [escapedString appendFormat:@"\\u%04X", (int)*chars];
        else
         [escapedString appendFormat:@"%c", *chars];
        ++chars;
    }
    
    return escapedString;
}


@end
