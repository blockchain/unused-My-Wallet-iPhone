//
//  NSString+SHA256.h
//  Blockchain
//
//  Created by Ben Reeves on 18/03/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (SHA256)

-(NSString*)SHA256;
-(NSString*)SHA256:(int)rounds;

@end
