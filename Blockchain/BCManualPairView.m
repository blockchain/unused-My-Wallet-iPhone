//
//  ManualPairView.m
//  Blockchain
//
//  Created by Mark Pfluger on 9/25/14.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import "BCManualPairView.h"
#import "AppDelegate.h"

@implementation BCManualPairView

-(IBAction)didEndWalletIdentifier:(id)sender
{
    [self.passwordTextField becomeFirstResponder];
}

-(IBAction)didEndPassword:(id)sender
{
    [self continueClicked:sender];
}

-(IBAction)continueClicked:(id)sender
{
    NSString * guid = walletIdentifierTextField.text;
    NSString * password = self.passwordTextField.text;
    
    if ([guid length] != 36) {
        [app standardNotify:BC_STRING_ENTER_YOUR_CHARACTER_WALLET_IDENTIFIER title:BC_STRING_INVALID_IDENTIFIER delegate:nil];
        return;
    }
    
    [app.wallet loadGuid:guid];
    
    app.wallet.password = password;
    
    app.wallet.delegate = app;
    
    [app closeModalWithTransition:kCATransitionFade];
}

@end
