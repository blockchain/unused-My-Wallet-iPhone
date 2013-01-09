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
-(void)walletDidLoad:(Wallet*)wallet;
-(void)walletFailedToDecrypt:(Wallet*)wallet;
-(void)walletJSReady;
-(void)didSubmitTransaction;
@end

@interface Wallet : NSObject <UIWebViewDelegate> {
    NSDictionary * document;
}

@property(nonatomic, strong) id<WalletDelegate> delegate;
@property(nonatomic, retain) NSString * secondPassword;
@property(nonatomic, retain) NSData * encrypted_payload;
@property(nonatomic, retain) NSString * password;
@property(nonatomic, strong) UIWebView * webView;
@property(nonatomic, strong) NSDictionary * document;

-(NSString*)guid;
-(void)setGuid:(NSString *)guid;
-(NSString*)sharedKey;
-(void)setSharedKey:(NSString *)sharedKey;
-(BOOL)doubleEncryption;
-(NSDictionary*)keys;
-(NSDictionary*)addressBook;
-(NSString*)dPasswordHash;

-(Key*)parsePrivateKey:(NSString*)key;

+(NSString *)generateUUID;

-(void)setLabel:(NSString*)label ForAddress:(NSString*)address;

-(void)archiveAddress:(NSString*)address;

-(void)unArchiveAddress:(NSString*)address;

-(void)removeAddress:(NSString*)address;

-(id)initWithPassword:(NSString*)password; //Create a new Wallet

-(void)loadData:(NSData*)data password:(NSString*)password;

-(id)initWithData:(NSData*)string password:(NSString*)password; //Restore wallet from base64 data

-(void)sendPaymentTo:(NSString*)toAddress from:(NSString*)fromAddress value:(NSString*)value;

-(Key*)generateNewKey;

-(NSString*)labelForAddress:(NSString*)address;

-(void)addToAddressBook:(NSString*)address label:(NSString*)label;

-(BOOL)isValidAddress:(NSString*)string;

-(NSString*)jsonString;

-(NSString*)encryptedString;

-(void)cancelTxSigning;

-(void)addKey:(Key*)key;

-(NSArray*)activeAddresses;

@end
