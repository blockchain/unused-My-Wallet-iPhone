//
//  API.m
//  Blockchain
//
//  Created by Ben Reeves on 10/01/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "MultiAddressResponse.h"
#import "AppDelegate.h"
#import "Address.h"
#import "Transaction.h"
#import "Input.h"
#import "Output.h"
#import "Wallet.h"
#import "NSString+SHA256.h"
#import "NSString+URLEncode.h"

@implementation CurrencySymbol
@synthesize code;
@synthesize symbol;
@synthesize name;
@synthesize conversion;
@synthesize symbolappearsAfter;

+(CurrencySymbol*)symbolFromDict:(NSDictionary *)dict {
    CurrencySymbol * symbol = [[[CurrencySymbol alloc] init] autorelease];
    
    symbol.code = [dict objectForKey:@"code"];
    symbol.symbol = [dict objectForKey:@"symbol"];
    symbol.conversion = [[dict objectForKey:@"conversion"] longLongValue];
    symbol.name = [dict objectForKey:@"name"];
    symbol.symbolappearsAfter = [[dict objectForKey:@"symbolAppearsAfter"] boolValue];
    
    return symbol;
}

-(void)dealloc {
    self.code = nil;
    self.name = nil;
    self.symbol = nil;
    
    [super dealloc];
}
@end

@implementation LatestBlock
@synthesize hash;
@synthesize blockIndex;
@synthesize height;
@synthesize time;

-(void)dealloc {
    self.hash = nil;
    [super dealloc];
}

@end

@implementation MulitAddressResponse

@synthesize transactions;
@synthesize total_received;
@synthesize total_sent;
@synthesize final_balance;
@synthesize n_transactions;
@synthesize symbol_local;
@synthesize symbol_btc;

-(void)dealloc {
    self.transactions = nil;
    self.addresses = nil;
    self.symbol_btc = nil;
    self.symbol_local = nil;
    
    [super dealloc];
}

@end

