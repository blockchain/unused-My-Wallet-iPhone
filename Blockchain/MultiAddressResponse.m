//
//  API.m
//  Blockchain
//
//  Created by Ben Reeves on 10/01/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "MultiAddressResponse.h"
#import "JSONKit.h"
#import "AppDelegate.h"
#import "Address.h"
#import "Transaction.h"
#import "Input.h"
#import "Output.h"
#import "Wallet.h"
#import "NSString+SHA256.h"
#import "NSString+URLEncode.h"
#import "APIDefines.h"

@implementation CurrencySymbol
@synthesize code;
@synthesize symbol;
@synthesize name;
@synthesize conversion;
@synthesize symbolappearsAfter;

-(void)dealloc {
    [code release];
    [symbol release];
    [name release];
    [super dealloc];
}
@end

@implementation LatestBlock
@synthesize hash;
@synthesize blockIndex;
@synthesize height;
@synthesize time;

-(void)dealloc {
    [hash release];
    [super dealloc];
}

@end

@implementation MulitAddressResponse

@synthesize transactions;
@synthesize total_received;
@synthesize total_sent;
@synthesize final_balance;
@synthesize n_transactions;
@synthesize symbol;

-(void)dealloc {
    [symbol release];
    [transactions release];
    [super dealloc];
}

@end

