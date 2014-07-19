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
#import "JSBridgeWebView.h"
#import "MultiAddressResponse.h"

@interface Key : NSObject {
    int tag;
}
@property(nonatomic, strong) NSString * addr;
@property(nonatomic, strong) NSString * priv;
@property(nonatomic, strong) NSString * label;
@property(nonatomic, assign) int tag;
@end

@class Wallet;

@protocol WalletDelegate <NSObject>
@optional
-(void)didSetLatestBlock:(LatestBlock*)block;
-(void)didGetMultiAddressResponse:(MulitAddressResponse*)response;
-(void)walletDidLoad:(Wallet*)wallet;
-(void)walletFailedToDecrypt:(Wallet*)wallet;
-(void)walletJSReady;
-(void)didSubmitTransaction;
@end

@interface Wallet : NSObject <UIWebViewDelegate, JSBridgeWebViewDelegate> {
}

//Core Wallet Init Properties
@property(nonatomic, retain) NSString * guid;
@property(nonatomic, retain) NSString * sharedKey;
@property(nonatomic, retain) NSString * password;
@property(nonatomic, retain) NSString * secondPassword;

@property(nonatomic, strong) id<WalletDelegate> delegate;
@property(nonatomic, strong) JSBridgeWebView * webView;

@property(nonatomic) uint64_t final_balance;
@property(nonatomic) uint64_t total_sent;
@property(nonatomic) uint64_t total_received;

//TODO remove
@property(nonatomic, retain) NSDictionary * keys;

#pragma mark Init Methods
-(id)initWithGuid:(NSString*)_guid sharedKey:(NSString*)_sharedKey password:(NSString*)_password;
-(id)initWithGuid:(NSString *)_guid password:(NSString*)_sharedKey;
-(id)initWithPassword:(NSString*)password; //Create a new Wallet
-(id)initWithEncryptedQRString:(NSString*)encryptedQRString;

-(NSDictionary*)addressBook;
-(NSString*)dPasswordHash;

+(NSString*)generateUUID;

-(void)setLabel:(NSString*)label ForAddress:(NSString*)address;

-(void)archiveAddress:(NSString*)address;

-(void)unArchiveAddress:(NSString*)address;

-(void)removeAddress:(NSString*)address;

-(void)loadData:(NSData*)data password:(NSString*)password;
-(void)sendPaymentTo:(NSString*)toAddress from:(NSString*)fromAddress value:(NSString*)value;

-(void)generateNewKey:(void (^)(Key * key))callback;

-(NSString*)labelForAddress:(NSString*)address;

-(void)addToAddressBook:(NSString*)address label:(NSString*)label;

-(BOOL)isValidAddress:(NSString*)string;

-(NSString*)jsonString;

-(NSString*)encryptedString;

-(void)cancelTxSigning;

-(BOOL)addKey:(NSString*)privateKeyString;

-(NSArray*)activeAddresses;
-(NSArray*)allAddresses;

-(BOOL)isDoubleEncrypted;

-(void)getHistory;

-(uint64_t)getAddressBalance:(NSString*)address;


@end
