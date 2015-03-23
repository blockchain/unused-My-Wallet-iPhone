//
//  NewAccountView.m
//  Blockchain
//
//  Created by Ben Reeves on 18/03/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "BCCreateWalletView.h"

#import "AppDelegate.h"
#import "BCEntropyChecker.h"

#define IS_568_SCREEN (fabs((double)[[UIScreen mainScreen]bounds].size.height - (double)568) < DBL_EPSILON)

#define SCROLL_HEIGHT_SMALL_SCREEN 18

@implementation BCCreateWalletView

- (void)awakeFromNib
{
    UIButton *createButton = [UIButton buttonWithType:UIButtonTypeCustom];
    createButton.frame = CGRectMake(0, 0, self.window.frame.size.width, 46);
    createButton.backgroundColor = COLOR_BLOCKCHAIN_BLUE;
    [createButton setTitle:BC_STRING_CONTINUE forState:UIControlStateNormal];
    [createButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    createButton.titleLabel.font = [UIFont systemFontOfSize:17.0];
    
    [createButton addTarget:self action:@selector(createAccountClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    emailTextField.inputAccessoryView = createButton;
    passwordTextField.inputAccessoryView = createButton;
    password2TextField.inputAccessoryView = createButton;
}

- (void)prepareForModalPresentation
{
    emailTextField.delegate = self;
    passwordTextField.delegate = self;
    password2TextField.delegate = self;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Scroll up to fit all entry fields on small screens
        if (!IS_568_SCREEN) {
            CGRect frame = self.frame;
            
            frame.origin.y = -SCROLL_HEIGHT_SMALL_SCREEN;
            
            self.frame = frame;
        }
        
        [emailTextField becomeFirstResponder];
    });
}

- (void)prepareForModalDismissal
{
    emailTextField.delegate = nil;
    passwordTextField.delegate = nil;
    password2TextField.delegate = nil;
}

- (void)modalWasDismissed {
    passwordTextField.text = nil;
    password2TextField.text = nil;
    
    passwordStrengthView.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:1];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == emailTextField) {
        [passwordTextField becomeFirstResponder];
    }
    else if (textField == passwordTextField) {
        [password2TextField becomeFirstResponder];
    }
    else {
        [self createAccountClicked:textField];
    }
    
    return YES;
}

#pragma mark - Wallet Delegate method

- (void)walletJSReady
{
    [app.wallet newAccount:self.tmpPassword email:emailTextField.text];
}

// Get here from New Account and also when manually pairing
- (IBAction)createAccountClicked:(id)sender
{
    if ([emailTextField.text length] == 0) {
        [app standardNotify:BC_STRING_PLEASE_PROVIDE_AN_EMAIL_ADDRESS];
        [emailTextField becomeFirstResponder];
        return;
    }
    
    if ([emailTextField.text rangeOfString:@"@"].location == NSNotFound) {
        [app standardNotify:BC_STRING_INVALID_EMAIL_ADDRESS];
        [emailTextField becomeFirstResponder];
        return;
    }
    
    self.tmpPassword = passwordTextField.text;
    
    if ([self.tmpPassword length] < 10 || [self.tmpPassword length] > 255) {
        [app standardNotify:BC_STRING_PASSWORD_MUST_10_CHARACTERS_OR_LONGER];
        [passwordTextField becomeFirstResponder];
        return;
    }
    
    if (![self.tmpPassword isEqualToString:[password2TextField text]]) {
        [app standardNotify:BC_STRING_PASSWORDS_DO_NOT_MATCH];
        [password2TextField becomeFirstResponder];
        return;
    }
    
    [emailTextField resignFirstResponder];
    [passwordTextField resignFirstResponder];
    [password2TextField resignFirstResponder];
    
    [app.wallet loadBlankWallet];
    
    // Get callback when wallet is done loading
    app.wallet.delegate = self;
}

- (IBAction)termsOfServiceClicked:(id)sender
{
    [app pushWebViewController:[WebROOT stringByAppendingString:@"terms_of_service"] title:BC_STRING_TERMS_OF_SERVICE];
    [emailTextField becomeFirstResponder];
}

- (void)didCreateNewAccount:(NSString*)guid sharedKey:(NSString*)sharedKey password:(NSString*)password
{
    emailTextField.text = nil;
    passwordTextField.text = nil;
    password2TextField.text = nil;
    
    [app forgetWallet];
    
    [app.wallet loadWalletWithGuid:guid sharedKey:sharedKey password:password];
    
    app.wallet.delegate = app;
    
    [app standardNotify:[NSString stringWithFormat:BC_STRING_DID_CREATE_NEW_ACCOUNT_DETAIL]
                  title:BC_STRING_DID_CREATE_NEW_ACCOUNT_TITLE
               delegate:nil];
}

- (void)errorCreatingNewAccount:(NSString*)message
{
    [app standardNotify:message];
}

#pragma mark - Textfield Delegates

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField != passwordTextField) {
        return YES;
    }
    
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    CGFloat passwordStrength = [[BCEntropyChecker sharedInstance] entropyStrengthForWord:newString];
    
    CGFloat greenValue = passwordStrength/100.0;
    CGFloat redValue = 1.0 - greenValue;
    
    passwordStrengthView.backgroundColor = [UIColor colorWithRed:redValue green:greenValue blue:0 alpha:1];
    
    return YES;
}

@end
