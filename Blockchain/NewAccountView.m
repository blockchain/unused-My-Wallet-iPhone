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

-(void)walletJSReady {
    [self.wallet newAccount:self.tmpPassword];
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
    
    self.wallet = [[[Wallet alloc] init] autorelease];
    
    wallet.delegate = self;
}

-(void)didCreateNewAccount:(NSString*)guid sharedKey:(NSString*)sharedKey password:(NSString*)password {
    [app forgetWallet];
    
    app.wallet = [[Wallet alloc] initWithGuid:guid sharedKey:sharedKey password:password];
    
    app.wallet.delegate = app;
}

-(void)errorCreatingNewAccount:(NSString*)message {
    [app standardNotify:message];
}

@end
