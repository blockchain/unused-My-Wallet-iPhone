//
//  WelcomeView.h
//  Blockchain
//
//  Created by Mark Pfluger on 9/23/14.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BCModalContentView.h"

@interface BCWelcomeView : BCModalContentView

@property (nonatomic, strong) UIButton *createWalletButton, *existingWalletButton;

@end
