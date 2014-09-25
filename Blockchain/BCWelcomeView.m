//
//  WelcomeView.m
//  Blockchain
//
//  Created by Mark Pfluger on 9/23/14.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import "BCWelcomeView.h"
#import "AppDelegate.h"
#import "LocalizationConstants.h"

#define BUTTON_HEIGHT 50

@implementation BCWelcomeView

-(id)init
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UIWindow *window = appDelegate.window;
    
    self = [super initWithFrame:CGRectMake(0, 0, window.frame.size.width, window.frame.size.height - 20)];
    
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        UIImage *logo = [UIImage imageNamed:@"welcome_logo"];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 30, logo.size.width, logo.size.height)];
        imageView.image = logo;
        
        CGFloat halfScreenHeight = window.frame.size.height / 2 - (BUTTON_HEIGHT) - 15;
        CGFloat halfScreenWidth = window.frame.size.width / 2;
        imageView.center = CGPointMake(halfScreenWidth, halfScreenHeight);
        
        [self addSubview:imageView];
        
        self.createWalletButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.createWalletButton.frame = CGRectMake(0, self.frame.size.height - (BUTTON_HEIGHT * 2), self.frame.size.width, BUTTON_HEIGHT);
        [self.createWalletButton setTitle:BC_STRING_NEW_WALLET forState:UIControlStateNormal];
        [self.createWalletButton setBackgroundColor:COLOR_BLOCKCHAIN_BLUE];
        [self addSubview:self.createWalletButton];
        
        self.existingWalletButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.existingWalletButton setTitle:@"Existing Wallet" forState:UIControlStateNormal];
        self.existingWalletButton.frame = CGRectMake(0, self.frame.size.height - BUTTON_HEIGHT, self.frame.size.width, BUTTON_HEIGHT);
        [self.existingWalletButton setBackgroundColor:COLOR_BLOCKCHAIN_LIGHT_BLUE];
        [self addSubview:self.existingWalletButton];
    }
    
    return self;
}

@end
