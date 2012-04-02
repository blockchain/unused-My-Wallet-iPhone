//
//  NSString+URLEncode.m
//  Tube Delays
//
//  Created by Ben Reeves on 13/11/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NSString+URLEncode.h"


@implementation NSString (URLEncode)

-(NSString *) urlencode
{
	NSString * string = [self stringByReplacingOccurrencesOfString:@" " withString:@"+"];
	
    NSString *encoded = [(NSString *)CFURLCreateStringByAddingPercentEscapes(
																			NULL,
																			(CFStringRef)string,
																			NULL,
																			CFSTR(":/?#[]@!$&’()*+,;="),
											 								kCFStringEncodingUTF8 ) autorelease];
	
	return encoded;
}

@end
