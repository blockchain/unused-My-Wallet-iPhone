//
//  NewAccountView.m
//  Blockchain
//
//  Created by Ben Reeves on 18/03/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "NewAccountView.h"
#import "AppDelegate.h"
#import "BCWebViewController.h"

#define IS_568_SCREEN (fabs((double)[[UIScreen mainScreen]bounds].size.height - (double)568) < DBL_EPSILON)

#define SCROLL_HEIGHT_SMALL_SCREEN 58

@implementation NewAccountView

-(void)awakeFromNib {
    [activity startAnimating];
    
    // Make sure the button is in front of everything else
    [self bringSubviewToFront:createButton];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField*)aTextField {
    [aTextField resignFirstResponder];
    
    // If we return from the password confirm textfield, create the account
    if (aTextField == password2TextField) {
        [self createAccountClicked:aTextField];
    }
    
    return YES;
}

-(IBAction)didEndEmail:(id)sender
{
    [passwordTextField becomeFirstResponder];
}

-(IBAction)didEndPassword1:(id)sender
{
    [password2TextField becomeFirstResponder];
}

-(IBAction)didEndPassword2:(id)sender
{
    // Do nothing
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	[app.tabViewController responderMayHaveChanged];
    
    // Scroll up to fit all entry fields on small screens
    if (!IS_568_SCREEN) {
        CGRect frame = self.frame;
        
        frame.origin.y = -SCROLL_HEIGHT_SMALL_SCREEN;
        self.frame = frame;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [app.tabViewController responderMayHaveChanged];
}

// Move up create wallet button when keyboard is shown
- (void)keyboardWillShow:(NSNotification *)notification
{
    CGRect keyboardFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect createButtonFrame = createButton.frame;
    createButtonFrame.origin.y = keyboardFrame.size.height + createButtonFrame.size.height + 14 - (!IS_568_SCREEN ? SCROLL_HEIGHT_SMALL_SCREEN : 0);
    
    [UIView animateWithDuration:ANIMATION_DURATION
                     animations:^{
                         createButton.frame = createButtonFrame;
                     }
                     completion:nil];
}

# pragma mark - Wallet Delegate method
-(void)walletJSReady {
    [app.wallet newAccount:self.tmpPassword email:emailTextField.text];
}

// Get here from New Account and also when manually pairing
-(IBAction)createAccountClicked:(id)sender
{
    // Make sure we leave the textfields
    [emailTextField resignFirstResponder];
    [passwordTextField resignFirstResponder];
    [password2TextField resignFirstResponder];
    
    // Reset scrolling on small screens
    if (!IS_568_SCREEN) {
        CGRect frame = self.frame;
        
        frame.origin.y = 0;
        self.frame = frame;
    }
    
    // Move create wallet button back to original position at bottom of screen
    CGRect createButtonFrame = createButton.frame;
    createButtonFrame.origin.y = self.frame.size.height - createButtonFrame.size.height;
    [UIView animateWithDuration:ANIMATION_DURATION
                     animations:^{
                         createButton.frame = createButtonFrame;
                     }
                     completion:nil];
    
    self.tmpPassword = passwordTextField.text;
    
    if ([self.tmpPassword length] < 10 || [self.tmpPassword length] > 255) {
        [app standardNotify:BC_STRING_PASSWORD_MUST_10_CHARACTERS_OR_LONGER];
        return;
    }
    
    if (![self.tmpPassword isEqualToString:[password2TextField text]]) {
        [app standardNotify:BC_STRING_PASSWORDS_DO_NOT_MATCH];
        return;
    }

    if (emailTextField.text.length > 0 && [emailTextField.text rangeOfString:@"@"].location == NSNotFound) {
        [app standardNotify:BC_STRING_INVALID_EMAIL_ADDRESS];
        return;
    }
    
    [app.wallet loadBlankWallet];
    
    // Get callback when wallet is done loading
    app.wallet.delegate = self;
}

-(void)networkActivityStart {
    [app networkActivityStart];
}

-(void)networkActivityStop {
    [app networkActivityStop];
}

-(IBAction)termsOfServiceClicked:(id)sender
{
    BCWebViewController *webViewController = [[BCWebViewController alloc] init];
    NSString *url = [NSString stringWithFormat:@"%@terms_of_service", WebROOT];
    
    [webViewController loadURL:url];
    
    [app.tabViewController presentViewController:webViewController animated:YES completion:nil];
}

-(void)didCreateNewAccount:(NSString*)guid sharedKey:(NSString*)sharedKey password:(NSString*)password {
    [app forgetWallet];
    
    [app clearPin];
        
    [app.wallet loadGuid:guid sharedKey:sharedKey];
    
    app.wallet.password = password;
    
    app.wallet.delegate = app;
    
    [app standardNotify:[NSString stringWithFormat:BC_STRING_DID_CREATE_NEW_ACCOUNT_DETAIL] title:BC_STRING_DID_CREATE_NEW_ACCOUNT_TITLE delegate:nil];
}

-(void)errorCreatingNewAccount:(NSString*)message {
    [app standardNotify:message];
}

@end
