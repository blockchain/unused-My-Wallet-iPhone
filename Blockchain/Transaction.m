//
//  Transaction.m
//  Blockchain
//
//  Created by Ben Reeves on 10/01/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "Transaction.h"
#import "AccountInOut.h"
#import "AddressInOut.h"

@implementation Transaction


+ (Transaction*)fromJSONDict:(NSDictionary *)transactionDict {
    
    Transaction * transaction = [[Transaction alloc] init];
    
    transaction.from = [[InOut alloc] init];
    transaction.to = [[InOut alloc] init];

    transaction.block_height = [[transactionDict objectForKey:@"block_height"] intValue];
    transaction.confirmations = [[transactionDict objectForKey:@"confirmations"] intValue];
    transaction.fee = [[transactionDict objectForKey:@"fee"] longLongValue];
    transaction.myHash = [transactionDict objectForKey:@"hash"];
    transaction.intraWallet = [[transactionDict objectForKey:@"intraWallet"] boolValue];
    transaction.note = [transactionDict objectForKey:@"note"];
    transaction.result = [[transactionDict objectForKey:@"result"] longLongValue];
    transaction.size = [[transactionDict objectForKey:@"size"] intValue];
    transaction.time =[[transactionDict objectForKey:@"txTime"] longLongValue];
    transaction.tx_index = [[transactionDict objectForKey:@"tx_index"] intValue];
    
    NSDictionary *fromDict = [transactionDict objectForKey:@"from"];
    
    AccountInOut *fromAccount = nil;
    if ([fromDict objectForKey:@"account"] != [NSNull null]) {
        fromAccount = [[AccountInOut alloc] init];
        NSDictionary *fromAccountDict = [fromDict objectForKey:@"account"];
        
        fromAccount.accountIndex = [[fromAccountDict objectForKey:@"index"] intValue];
        fromAccount.amount = [[fromAccountDict objectForKey:@"amount"] longLongValue];
    }
    transaction.from.account = fromAccount;
    
    AddressInOut *fromExternalAddresses = nil;
    if ([fromDict objectForKey:@"externalAddresses"] != [NSNull null]) {
        fromExternalAddresses = [[AddressInOut alloc] init];
        NSDictionary *fromExternalAddressesDict = [fromDict objectForKey:@"externalAddresses"];
        
        fromExternalAddresses.address = [fromExternalAddressesDict objectForKey:@"address"];
        fromExternalAddresses.amount = [[fromExternalAddressesDict objectForKey:@"amount"] longLongValue];
    }
    transaction.from.externalAddresses = fromExternalAddresses;
    
    NSMutableArray *fromLegacyAddresses = nil;
    if ([fromDict objectForKey:@"legacyAddresses"] != [NSNull null]) {
        fromLegacyAddresses = [[NSMutableArray alloc] init];
        NSArray *fromLegacyAddressesArray = [fromDict objectForKey:@"legacyAddresses"];
        
        for (NSDictionary *inputDict in fromLegacyAddressesArray) {
            AddressInOut *addressInOut = [[AddressInOut alloc] init];
            addressInOut.address = [inputDict objectForKey:@"address"];
            addressInOut.amount = [[inputDict objectForKey:@"amount"] longLongValue];
            
            [fromLegacyAddresses addObject:addressInOut];
        }
    }
    transaction.from.legacyAddresses = fromLegacyAddresses;
    
    return transaction;
}

@end
