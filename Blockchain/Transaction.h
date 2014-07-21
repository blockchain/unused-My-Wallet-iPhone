//
//  Transaction.h
//  Blockchain
//
//  Created by Ben Reeves on 10/01/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Wallet;

@interface Transaction : NSObject {

@public
    NSString * hash;
    uint32_t size;
    uint32_t tx_index;
    int64_t result;
    uint64_t time;
    uint32_t block_height;
    NSArray * inputs;
    NSArray * outputs;
}

-(NSString*)hash;
-(NSArray*)inputs;
-(NSArray*)outputs;

-(NSArray*)inputsNotFromAddresses:(NSArray*)addresses;
-(NSArray*)outputsNotToAddresses:(NSArray*)adresses;

+(Transaction*)fromJSONDict:(NSDictionary*)dict;
 
@end
