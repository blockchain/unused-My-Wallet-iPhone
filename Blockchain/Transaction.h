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

}

-(NSArray*)inputsNotFromAddresses:(NSArray*)addresses;
-(NSArray*)outputsNotToAddresses:(NSArray*)adresses;

+(Transaction*)fromJSONDict:(NSDictionary*)dict;

@property(nonatomic, strong) NSString * hash;
@property(nonatomic, strong) NSArray * inputs;
@property(nonatomic, strong) NSArray * outputs;
@property(nonatomic, assign) uint32_t size;
@property(nonatomic, assign) uint32_t tx_index;
@property(nonatomic, assign) int64_t result;
@property(nonatomic, assign) uint64_t time;
@property(nonatomic, assign) uint32_t block_height;

@end
