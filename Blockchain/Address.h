//
//  Address.h
//  Blockchain
//
//  Created by Ben Reeves on 13/01/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Address : NSObject {

@public
    NSString * address;
    uint64_t total_received;
    uint64_t total_sent;
    uint64_t final_balance;
    uint32_t n_transactions;
}

-(NSString*)getAddress;


@end
