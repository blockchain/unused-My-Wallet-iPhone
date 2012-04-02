//
//  Output.m
//  Blockchain
//
//  Created by Ben Reeves on 10/01/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "Output.h"

@implementation Output

-(NSString*)addr {
    return addr;
}

-(uint64_t)value {
    return value;
}

-(void)dealloc {
    [addr release];
    [super dealloc];
}

@end
