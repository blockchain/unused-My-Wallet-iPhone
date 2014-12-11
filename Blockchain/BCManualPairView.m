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

- (void)prepareForModalPresentation
{
    walletIdentifierTextField.delegate = self;
    passwordTextField.delegate = self;
    
    // Get the session id SID from the server
    [app.wallet loadWalletLogin];
}

- (void)prepareForModalDismissal
{
    walletIdentifierTextField.delegate = nil;
    passwordTextField.delegate = nil;
}

- (void)modalWasDismissed
{
    passwordTextField.text = nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == walletIdentifierTextField) {
        [passwordTextField becomeFirstResponder];
    }
    else {
        [self continueClicked:textField];
    }
    
    return YES;
}

- (IBAction)continueClicked:(id)sender
{
    NSString * guid = walletIdentifierTextField.text;
    NSString * password = passwordTextField.text;
    
    if ([guid length] != 36) {
        [app standardNotify:BC_STRING_ENTER_YOUR_CHARACTER_WALLET_IDENTIFIER title:BC_STRING_INVALID_IDENTIFIER delegate:nil];
        
        [walletIdentifierTextField becomeFirstResponder];
        
        return;
    }
    
    passwordTextField.text = @"";
    
    [app.wallet loadWalletWithGuid:guid sharedKey:nil password:password];
    
    app.wallet.delegate = app;
}

@end
