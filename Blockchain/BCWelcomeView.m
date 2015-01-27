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

UIImageView *imageView;
float moveImageDown;
Boolean shouldShowAnimation;

-(id)init
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UIWindow *window = appDelegate.window;
    
    shouldShowAnimation = true;
    
    self = [super initWithFrame:CGRectMake(0, 0, window.frame.size.width, window.frame.size.height - 20)];
    
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        // Logo
        UIImage *logo = [UIImage imageNamed:@"welcome_logo"];
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 30, logo.size.width, logo.size.height)];
        imageView.image = logo;
        imageView.alpha = 0;
        
        CGFloat halfScreenHeight = window.frame.size.height / 2 - (BUTTON_HEIGHT) - 15;
        CGFloat halfScreenWidth = window.frame.size.width / 2;
        imageView.center = CGPointMake(halfScreenWidth, halfScreenHeight);
        CGRect frame = imageView.frame;
        moveImageDown = 82;
        frame.origin.y += 82;
        imageView.frame = frame;
        
        [self addSubview:imageView];
        
        // Buttons
        self.createWalletButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.createWalletButton.frame = CGRectMake(0, self.frame.size.height - (BUTTON_HEIGHT * 2), self.frame.size.width, BUTTON_HEIGHT);
        [self.createWalletButton setTitle:BC_STRING_NEW_WALLET forState:UIControlStateNormal];
        [self.createWalletButton setBackgroundColor:COLOR_BLOCKCHAIN_BLUE];
        [self addSubview:self.createWalletButton];
        self.createWalletButton.enabled = NO;
        self.createWalletButton.alpha = 0.0;
        
        self.existingWalletButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.existingWalletButton setTitle:@"Existing Wallet" forState:UIControlStateNormal];
        self.existingWalletButton.frame = CGRectMake(0, self.frame.size.height - BUTTON_HEIGHT, self.frame.size.width, BUTTON_HEIGHT);
        [self.existingWalletButton setBackgroundColor:COLOR_BLOCKCHAIN_LIGHT_BLUE];
        [self addSubview:self.existingWalletButton];
        self.existingWalletButton.enabled = NO;
        self.existingWalletButton.alpha = 0.0;
    }
    
    return self;
}

- (void)didMoveToSuperview
{
    // If the animation has started already, don't show it again until init is called again
    if (!shouldShowAnimation) {
        return;
    }
    shouldShowAnimation = false;
    
    // Some nice animations
    [UIView animateWithDuration:2*ANIMATION_DURATION
                     animations:^{
                         // Fade in logo
                         imageView.alpha = 1.0;
                     }
                     completion:^(BOOL finished){
                         [UIView animateWithDuration:2*ANIMATION_DURATION
                                          animations:^{
                                              // Move logo up
                                              CGRect newFrame = imageView.frame;
                                              newFrame.origin.y -= moveImageDown;
                                              imageView.frame = newFrame;
                                          }
                                          completion:^(BOOL finished){
                                              [UIView animateWithDuration:2*ANIMATION_DURATION animations:^{
                                                  // Fade in controls
                                                  self.createWalletButton.alpha = 1.0;
                                                  self.existingWalletButton.alpha = 1.0;
                                              } completion:^(BOOL finished) {
                                                  // Activate controls
                                                  self.createWalletButton.enabled = YES;
                                                  self.existingWalletButton.enabled = YES;
                                              }];
                                          }];
                     }];
}

@end
