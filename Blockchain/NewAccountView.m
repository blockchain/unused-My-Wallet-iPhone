//
//  NewAccountView.m
//  Blockchain
//
//  Created by Ben Reeves on 18/03/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "NewAccountView.h"
#import "AppDelegate.h"

@implementation NewAccountView

@synthesize wallet;

-(void)dealloc {
    self.wallet = nil;
    
    [createButton release];
    [activity release];
    [passwordTextField release];
    [password2TextField release];
    [super dealloc];
}

- (BOOL)textFieldShouldReturn:(UITextField*)aTextField {
    [aTextField resignFirstResponder];
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	[app.tabViewController responderMayHaveChanged];
}

-(void)awakeFromNib {
    [activity startAnimating];
}

# pragma mark - Wallet Delegate method
-(void)walletJSReady {
    [self.wallet newAccount:self.tmpPassword email:emailTextField.text];
}

// Get here from New Account and also when manually pairing
-(IBAction)createAccountClicked:(id)sender {
    
    self.tmpPassword = passwordTextField.text;
    
    if ([self.tmpPassword length] < 10 || [self.tmpPassword length] > 255) {
        [app standardNotify:@"Password must 10 characters or longer"];
        return;
    }
    
    if (![self.tmpPassword isEqualToString:[password2TextField text]]) {
        [app standardNotify:@"Passwords do not match"];
        return;
    }

    if ([emailTextField.text isEqualToString:@""]) {
        [app standardNotify:@"Please provide an email address."];
        return;
    }

    if ([emailTextField.text rangeOfString:@"@"].location == NSNotFound) {
        [app standardNotify:@"Invalid email address."];
        return;
    }
    
    // Load the wallet (webview + js)
    self.wallet = [[[Wallet alloc] init] autorelease];
    
    // Get callback when wallet is done loading
    wallet.delegate = self;
}

-(void)networkActivityStart {
    [app networkActivityStart];
}

-(void)networkActivityStop {
    [app networkActivityStop];
}

-(void)didCreateNewAccount:(NSString*)guid sharedKey:(NSString*)sharedKey password:(NSString*)password {
    [app forgetWallet];
    
    [app clearPin];
    
    [app showPinModal];
    
    app.wallet = [[Wallet alloc] initWithGuid:guid sharedKey:sharedKey password:password];
    
    app.wallet.delegate = app;
    
    [app standardNotify:[NSString stringWithFormat:@"Before accessing your wallet, please choose a pin number to use to unlock your wallet. It's important you remember this pin as it cannot be reset or changed without first unlocking the app."] title:@"Your wallet was successfully created." delegate:nil];
}

-(void)errorCreatingNewAccount:(NSString*)message {
    [app standardNotify:message];
}

@end
