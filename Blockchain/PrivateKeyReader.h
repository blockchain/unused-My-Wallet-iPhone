//
//  PairingCodeDelegate.h
//  Blockchain
//
//  Created by Ben Reeves on 22/07/2014.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import "Wallet.h"
#import <AVFoundation/AVFoundation.h>

@interface PrivateKeyReader : UIViewController<AVCaptureMetadataOutputObjectsDelegate>

@property(nonatomic, copy) void (^success)(NSString*);
@property(nonatomic, copy) void (^error)(NSString*);

- (id)initWithSuccess:(void (^)(NSString*))__success error:(void (^)(NSString*))__error;

@end
