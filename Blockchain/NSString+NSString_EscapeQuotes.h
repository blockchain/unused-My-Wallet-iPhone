//
//  NSString+NSString_EscapeQuotes.h
//  Blockchain
//
//  Created by Ben Reeves on 21/07/2014.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (NSString_EscapeQuotes)

-(NSString*)escapeDoubleQuotes;

- (NSString *)stringEscapedForJavasacript;

-(NSString*)escapeASCII;

@end
