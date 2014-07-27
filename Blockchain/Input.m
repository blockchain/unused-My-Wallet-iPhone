//
//  Input.m
//  Blockchain
//
//  Created by Ben Reeves on 10/01/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "Input.h"

@implementation Input

-(void)dealloc {
    self.prev_out = nil;
    [super dealloc];
}

@end
