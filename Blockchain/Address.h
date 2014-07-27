//
//  Address.h
//  Blockchain
//
//  Created by Ben Reeves on 13/01/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Address : NSObject {

}

@property(nonatomic, retain) NSString * address;
@property(nonatomic, assign) uint64_t total_received;
@property(nonatomic, assign) uint64_t total_sent;
@property(nonatomic, assign) uint64_t final_balance;
@property(nonatomic, assign) uint32_t n_transactions;

@end
