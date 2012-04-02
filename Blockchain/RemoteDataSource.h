/*
 * 
 * Copyright (c) 2012, Ben Reeves. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301  USA
 */


#import <Foundation/Foundation.h>

@interface CurrencySymbol : NSObject
@property(nonatomic, strong) NSString * code;
@property(nonatomic, strong) NSString * symbol;
@property(nonatomic, strong) NSString * name;
@property(nonatomic, assign) uint64_t conversion;
@property(nonatomic, assign) BOOL symbolappearsAfter;
@end

@interface LatestBlock : NSObject
@property(nonatomic, strong) NSString * hash;
@property(nonatomic, assign) uint32_t blockIndex;
@property(nonatomic, assign) uint32_t height;
@property(nonatomic, assign) uint64_t time;
@end

@interface MulitAddressResponse : NSObject {
    NSMutableArray * transactions;
    NSMutableDictionary * addresses;
    
    uint64_t total_received;
    uint64_t total_sent;
    uint64_t final_balance;
    uint32_t n_transactions;
}

@property(nonatomic, retain) NSMutableArray * transactions;
@property(nonatomic, retain) NSMutableDictionary * addresses;
@property(nonatomic, assign) uint64_t total_received;
@property(nonatomic, assign) uint64_t total_sent;
@property(nonatomic, assign) uint64_t final_balance;
@property(nonatomic, assign) uint32_t n_transactions;

@property(nonatomic, strong) CurrencySymbol * symbol;
@property(nonatomic, strong) LatestBlock * latestBlock;

@end


@protocol RemoteDataSourceDelagate <NSObject>
-(void)didGetMultiAddr:(MulitAddressResponse*)response;
-(void)didGetWalletData:(NSData*)data;
-(void)walletDataNotModified;
@end

@interface RemoteDataSource : NSObject 

@property(nonatomic, strong) id<RemoteDataSourceDelagate> delegate;
@property(nonatomic, assign) double lastWalletSync;

-(void)insertWallet:(NSString*)walletIdentifier sharedKey:(NSString*)sharedKey payload:(NSString*)payload catpcha:(NSString*)captcha;

-(void)saveWallet:(NSString*)walletIdentifier sharedKey:(NSString*)apiKey payload:(NSString*)payload;

-(void)multiAddr:(NSString*)walletIdentifier addresses:(NSArray*)addresses;

-(void)getWallet:(NSString*)walletIdentifier sharedKey:(NSString*)apiKey checksum:(NSString*)checksum;

-(MulitAddressResponse*)parseMultiAddr:(NSData*)data;

@end
