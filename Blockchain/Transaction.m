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

-(NSString*)hash {
    return hash;
}

-(NSArray*)inputs {
    return inputs;
}

-(NSArray*)outputs {
    return outputs;
}


+(Transaction*)fromJSONDict:(NSDictionary*)transactionDict {
    
    Transaction * transaction = [[[Transaction alloc] init] autorelease];
    transaction->inputs = [[NSMutableArray alloc] init];
    transaction->outputs = [[NSMutableArray alloc] init];
    transaction->hash = [[transactionDict objectForKey:@"hash"] retain];
    transaction->size = [[transactionDict objectForKey:@"size"] intValue];
    transaction->tx_index = [[transactionDict objectForKey:@"tx_index"] intValue];
    transaction->result = [[transactionDict objectForKey:@"result"] longLongValue];
    transaction->time =[[transactionDict objectForKey:@"time"] longLongValue];
    transaction->block_height = [[transactionDict objectForKey:@"block_height"] intValue];
    
    
    NSArray * inputsJSONArray = [transactionDict objectForKey:@"inputs"];
    for (NSDictionary * inputDict in inputsJSONArray) {
        NSDictionary * prev_out_dict = [inputDict objectForKey:@"prev_out"];
        
        Input * input = [[[Input alloc] init] autorelease];
        Output * prev_out = [[Output alloc] init];
        prev_out->value = [[prev_out_dict objectForKey:@"value"] longLongValue];
        prev_out->addr = [[prev_out_dict objectForKey:@"addr"] retain];
        input->prev_out = prev_out;
        
        [((NSMutableArray*)transaction->inputs) addObject:input];
    }
    
    NSArray * outputsJSONArray = [transactionDict objectForKey:@"out"];
    for (NSDictionary * outputDict in outputsJSONArray) {
        Output * output = [[[Output alloc] init] autorelease];
        output->value = [[outputDict objectForKey:@"value"] longLongValue];
        output->addr = [[outputDict objectForKey:@"addr"] retain];
        [((NSMutableArray*)transaction->outputs) addObject:output];
    }
    
    return transaction;
}

-(void)dealloc {
    [inputs release];
    [outputs release];
    [hash release];
    [super dealloc];
}

-(NSArray*)inputsNotFromWallet:(Wallet*)wallet {
    NSMutableArray * array = [NSMutableArray array];
    for (Input * input in inputs) {
        if ([wallet.keys objectForKey:[[input prev_out] addr]])
            continue;
        
        [array addObject:input];
    }
    return array;
}

-(NSArray*)outputsNotToWallet:(Wallet*)wallet {
    NSMutableArray * array = [NSMutableArray array];
    for (Output * output in outputs) {
        if ([wallet.keys objectForKey:[output addr]])
            continue;
        
        [array addObject:output];
    }
    return array;
}

@end
