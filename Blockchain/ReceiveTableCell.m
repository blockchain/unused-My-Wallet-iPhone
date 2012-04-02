//
//  ReceiveTableCell.m
//  Blockchain
//
//  Created by Ben Reeves on 19/03/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "ReceiveTableCell.h"

@implementation ReceiveTableCell

@synthesize balanceLabel;
@synthesize labelLabel;
@synthesize addressLabel;
@synthesize watchLabel;

-(void)dealloc {
    [labelLabel release];
    [balanceLabel release];
    [watchLabel release];
    [addressLabel release];
    [super dealloc];
}

@end
