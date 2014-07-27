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

@interface PrivateKeyReader : NSObject<ZBarReaderViewDelegate>

@property(nonatomic, copy) void (^success)(NSString*);
@property(nonatomic, copy) void (^error)(NSString*);
@property(nonatomic, strong) ZBarReaderView * readerView;

-(void)readPrivateKey:(void (^)(NSString*))success error:(void (^)(NSString*))error;

@end
