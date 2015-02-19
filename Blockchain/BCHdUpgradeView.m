//
//  BCHdUpgradeView.m
//  Blockchain
//
//  Created by Mark Pfluger on 2/19/15.
//  Copyright (c) 2015 Qkos Services Ltd. All rights reserved.
//

#import "BCHdUpgradeView.h"

#import "AppDelegate.h"
#import "LocalizationConstants.h"

#define BUTTON_HEIGHT 40

@implementation BCHdUpgradeView

UIImageView *imageView;
Boolean shouldShowAnimation;

-(id)init
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UIWindow *window = appDelegate.window;
    
    shouldShowAnimation = true;
    
    self = [super initWithFrame:CGRectMake(0, 0, window.frame.size.width, window.frame.size.height - 20)];
    
    if (self) {
        self.backgroundColor = COLOR_BLOCKCHAIN_BLUE;
        
        // Logo
        UIImage *logo = [UIImage imageNamed:@"blockchain_b"];
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake((window.frame.size.width -logo.size.width) / 2, 80, logo.size.width, logo.size.height)];
        imageView.image = logo;
        
        [self addSubview:imageView];
        
        // Text
        
        UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 150, 240, 60)];
        textLabel.textColor = [UIColor whiteColor];
        textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        textLabel.numberOfLines = 2;
        textLabel.textAlignment = NSTextAlignmentCenter;
        textLabel.font = [UIFont boldSystemFontOfSize:14];
        textLabel.text = @"We've designed a whole new\nwallet experience for you";
        [self addSubview:textLabel];
        
        // Buttons
        self.upgradeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.upgradeButton.frame = CGRectMake(40, self.frame.size.height - 220, 240, BUTTON_HEIGHT);
        self.upgradeButton.layer.cornerRadius = 16;
        self.upgradeButton.titleLabel.font = [UIFont boldSystemFontOfSize:15];
        [self.upgradeButton setTitleColor:COLOR_BLOCKCHAIN_BLUE forState:UIControlStateNormal];
        [self.upgradeButton setTitle:[BC_STRING_UPGRADE_NOW uppercaseString] forState:UIControlStateNormal];
        [self.upgradeButton setBackgroundColor:[UIColor whiteColor]];
        [self addSubview:self.upgradeButton];
        
        self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.cancelButton.titleLabel.font = [UIFont boldSystemFontOfSize:15];
        [self.cancelButton setTitle:BC_STRING_DONT_UPGRADE forState:UIControlStateNormal];
        self.cancelButton.frame = CGRectMake(20, self.frame.size.height - 160, 280, BUTTON_HEIGHT);
        [self.cancelButton setBackgroundColor:COLOR_BLOCKCHAIN_BLUE];
        [self addSubview:self.cancelButton];
    }
    
    return self;
}

@end
