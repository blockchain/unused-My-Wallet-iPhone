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
    CurrencySymbol * symbol = [[CurrencySymbol alloc] init];
    
    symbol.code = [dict objectForKey:@"code"];
    symbol.symbol = [dict objectForKey:@"symbol"];
    symbol.conversion = [[dict objectForKey:@"conversion"] longLongValue];
    symbol.name = [dict objectForKey:@"name"];
    symbol.symbolappearsAfter = [[dict objectForKey:@"symbolAppearsAfter"] boolValue];
    
    return symbol;
}

@end

@implementation LatestBlock
@synthesize blockIndex;
@synthesize height;
@synthesize time;


@end

@implementation MultiAddressResponse

@synthesize transactions;
@synthesize total_received;
@synthesize total_sent;
@synthesize final_balance;
@synthesize n_transactions;
@synthesize symbol_local;
@synthesize symbol_btc;


@end

