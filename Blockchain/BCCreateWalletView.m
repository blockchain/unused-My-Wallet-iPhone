//
//  NewAccountView.m
//  Blockchain
//
//  Created by Ben Reeves on 18/03/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "BCCreateWalletView.h"
#import "AppDelegate.h"

#define IS_568_SCREEN (fabs((double)[[UIScreen mainScreen]bounds].size.height - (double)568) < DBL_EPSILON)

#define SCROLL_HEIGHT_SMALL_SCREEN 65

@implementation BCCreateWalletView

- (void)awakeFromNib {
    [activity startAnimating];
    
    // Make sure the button is in front of everything else
    [self bringSubviewToFront:createButton];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)prepareForModalPresentation {
    emailTextField.delegate = self;
    passwordTextField.delegate = self;
    password2TextField.delegate = self;
}

- (void)prepareForModalDismissal {
    emailTextField.delegate = nil;
    passwordTextField.delegate = nil;
    password2TextField.delegate = nil;
}

- (void)modalWasDismissed {
    CGRect createButtonFrame = createButton.frame;
    createButtonFrame.origin.y = self.frame.size.height - createButtonFrame.size.height;
    createButton.frame = createButtonFrame;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    // Scroll up to fit all entry fields on small screens
    if (!IS_568_SCREEN) {
        CGRect frame = self.frame;
        
        frame.origin.y = -SCROLL_HEIGHT_SMALL_SCREEN;
        
        [UIView animateWithDuration:ANIMATION_DURATION
                         animations:^{
                             self.frame = frame;
                         }
                         completion:nil];
    }
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

// Move up create wallet button when keyboard is shown
- (void)keyboardWillShow:(NSNotification *)notification
{
    CGRect keyboardFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect createButtonFrame = createButton.frame;
    createButtonFrame.origin.y -= keyboardFrame.size.height - (!IS_568_SCREEN ? SCROLL_HEIGHT_SMALL_SCREEN : 0);
    
    [UIView animateWithDuration:ANIMATION_DURATION
                     animations:^{
                         createButton.frame = createButtonFrame;
                     }
                     completion:nil];
}

// Move create wallet button back down when keyboard is hidden
- (void)keyboardWillHide:(NSNotification *)notification
{
    CGRect createButtonFrame = createButton.frame;
    createButtonFrame.origin.y = self.frame.size.height - createButtonFrame.size.height;
    [UIView animateWithDuration:ANIMATION_DURATION
                     animations:^{
                         createButton.frame = createButtonFrame;
                     }
                     completion:nil];
}

# pragma mark - Wallet Delegate method
- (void)walletJSReady
{
    [app.wallet newAccount:self.tmpPassword email:emailTextField.text];
}

// Get here from New Account and also when manually pairing
- (IBAction)createAccountClicked:(id)sender
{
    // Make sure we leave the textfields
    [emailTextField resignFirstResponder];
    [passwordTextField resignFirstResponder];
    [password2TextField resignFirstResponder];
    
    // Reset scrolling on small screens
    if (!IS_568_SCREEN) {
        CGRect frame = self.frame;
        
        frame.origin.y = 0;
        
        [UIView animateWithDuration:ANIMATION_DURATION
                         animations:^{
                             self.frame = frame;
                         }
                         completion:nil];
    }
    
    if ([emailTextField.text length] == 0) {
        [app standardNotify:BC_STRING_PLEASE_PROVIDE_AN_EMAIL_ADDRESS];
        return;
    }
    
    if ([emailTextField.text rangeOfString:@"@"].location == NSNotFound) {
        [app standardNotify:BC_STRING_INVALID_EMAIL_ADDRESS];
        return;
    }
    
    self.tmpPassword = passwordTextField.text;
    
    if ([self.tmpPassword length] < 10 || [self.tmpPassword length] > 255) {
        [app standardNotify:BC_STRING_PASSWORD_MUST_10_CHARACTERS_OR_LONGER];
        return;
    }
    
    if (![self.tmpPassword isEqualToString:[password2TextField text]]) {
        [app standardNotify:BC_STRING_PASSWORDS_DO_NOT_MATCH];
        return;
    }
    
    [app.wallet loadBlankWallet];
    
    // Get callback when wallet is done loading
    app.wallet.delegate = self;
}

- (void)networkActivityStart
{
    [app networkActivityStart];
}

- (void)networkActivityStop
{
    [app networkActivityStop];
}

- (IBAction)termsOfServiceClicked:(id)sender
{
    [app pushWebViewController:[WebROOT stringByAppendingString:@"terms_of_service"]];
}

- (void)didCreateNewAccount:(NSString*)guid sharedKey:(NSString*)sharedKey password:(NSString*)password
{
    [app forgetWallet];
    
    [app clearPin];
    
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

@end
