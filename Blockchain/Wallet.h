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
    UIWebView * _webView;
    NSString * _password;
    NSData * _encrypted_payload;
    NSDictionary * dictionary;
}

@property(nonatomic, strong) id<WalletDelegate> delegate;
@property(nonatomic, strong) NSString * guid;
@property(nonatomic, strong) NSString * sharedKey;
@property(nonatomic, strong) NSString * dPasswordHash;
@property(nonatomic, assign) BOOL doubleEncryption;
@property(nonatomic, strong) NSMutableDictionary * keys;
@property(nonatomic, strong) NSMutableDictionary * addressBook;
@property(nonatomic, strong) NSString * secondPassword;
@property(nonatomic, strong) NSData * encrypted_payload;
@property(nonatomic, strong) NSString * password;

+ (NSString *)generateUUID;

-(void)removeAddress:(NSString*)address;

-(id)initWithPassword:(NSString*)password; //Create a new Wallet

-(void)loadData:(NSData*)data password:(NSString*)password;

-(id)initWithData:(NSData*)string password:(NSString*)password; //Restore wallet from base64 data

-(void)sendPaymentTo:(NSString*)toAddress from:(NSString*)fromAddress value:(double)value;

-(Key*)generateNewKey;

-(NSString*)labelForAddress:(NSString*)address;

-(UIWebView*)webView;

-(NSString*)jsonString;

-(NSString*)encryptedString;

-(void)cancelTxSigning;

@end
