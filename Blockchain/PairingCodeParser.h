//
//  PairingCodeDelegate.h
//  Blockchain
//
//  Created by Ben Reeves on 22/07/2014.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Wallet.h"
#import "ZBarSDK.h"

@interface PairingCodeParser : NSObject<WalletDelegate, ZBarReaderViewDelegate>

@property(nonatomic, strong) Wallet * wallet;
@property(nonatomic, copy) void (^success)(NSDictionary*);
@property(nonatomic, copy) void (^error)(NSString*);
@property(nonatomic, strong) ZBarReaderView * readerView;

-(void)scanAndParse:(void (^)(NSDictionary*))success error:(void (^)(NSString*))error;

@end
