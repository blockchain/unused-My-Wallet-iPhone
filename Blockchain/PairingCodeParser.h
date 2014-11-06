//
//  PairingCodeDelegate.h
//  Blockchain
//
//  Created by Ben Reeves on 22/07/2014.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#import "Wallet.h"

@interface PairingCodeParser : UIViewController<WalletDelegate, AVCaptureMetadataOutputObjectsDelegate>

@property(nonatomic, copy) void (^success)(NSDictionary*);
@property(nonatomic, copy) void (^error)(NSString*);

- (id)initWithSuccess:(void (^)(NSDictionary*))__success error:(void (^)(NSString*))__error;

@end
