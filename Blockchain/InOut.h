//
//  InOut.h
//  Blockchain
//
//  Created by Mark Pfluger on 12/16/14.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import "AccountInOut.h"
#import "AddressInOut.h"

@interface InOut : NSObject

@property(nonatomic, strong) AccountInOut *account;
@property(nonatomic, strong) AddressInOut *externalAddresses;
@property(nonatomic, strong) NSArray *legacyAddresses;

@end
