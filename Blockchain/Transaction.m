//
//  Transaction.m
//  Blockchain
//
//  Created by Ben Reeves on 10/01/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "Transaction.h"
#import "AppDelegate.h"
#import "Input.h"
#import "Output.h"

@implementation Transaction


+(Transaction*)fromJSONDict:(NSDictionary*)transactionDict {
    
    Transaction * transaction = [[Transaction alloc] init];
    transaction.inputs = [[NSMutableArray alloc] init];
    transaction.outputs = [[NSMutableArray alloc] init];
    transaction.hash = [transactionDict objectForKey:@"hash"];
    transaction.size = [[transactionDict objectForKey:@"size"] intValue];
    transaction.tx_index = [[transactionDict objectForKey:@"tx_index"] intValue];
    
    transaction.time =[[transactionDict objectForKey:@"time"] longLongValue];
    transaction.block_height = [[transactionDict objectForKey:@"blockHeight"] intValue];
    
    
    NSArray * inputsJSONArray = [transactionDict objectForKey:@"inputs"];
    for (NSDictionary * inputDict in inputsJSONArray) {
        NSDictionary * prev_out_dict = [inputDict objectForKey:@"prev_out"];
        
        Input * input = [[Input alloc] init];
        Output * prev_out = [[Output alloc] init];
        prev_out.value = [[prev_out_dict objectForKey:@"value"] longLongValue];
        prev_out.addr = [prev_out_dict objectForKey:@"addr"];
        input.prev_out = prev_out;
        
        [((NSMutableArray*)transaction.inputs) addObject:input];
    }
    
    NSArray * outputsJSONArray = [transactionDict objectForKey:@"out"];
    for (NSDictionary * outputDict in outputsJSONArray) {
        Output * output = [[Output alloc] init];
        output.value = [[outputDict objectForKey:@"value"] longLongValue];
        output.addr = [outputDict objectForKey:@"addr"];
        [((NSMutableArray*)transaction.outputs) addObject:output];
    }
    
    
    NSString * result = [transactionDict objectForKey:@"result"];
    if (result) {
        transaction.result = [result longLongValue];
    } else {
        for (Output * out in transaction.outputs) {
            transaction.result += out.value;
        }
    }
    return transaction;
}


-(NSArray*)inputsNotFromAddresses:(NSArray*)addresses {
    NSMutableArray * array = [NSMutableArray array];
    for (Input * input in self.inputs) {
        if ([addresses containsObject:[[input prev_out] addr]])
            continue;
        
        [array addObject:input];
    }
    return array;
}

-(NSArray*)outputsNotToAddresses:(NSArray*)addresses {
    NSMutableArray * array = [NSMutableArray array];
    for (Output * output in self.outputs) {
        if ([addresses containsObject:[output addr]])
            continue;
        
        [array addObject:output];
    }
    return array;
}

@end
