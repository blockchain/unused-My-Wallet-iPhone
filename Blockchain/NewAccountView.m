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
    [createButton release];
    [activity release];
    [captchaImage release];
    [passwordTextField release];
    [password2TextField release];
    [captchaTextField release];
    [super dealloc];
}

- (BOOL)textFieldShouldReturn:(UITextField*)aTextField {
    [aTextField resignFirstResponder];
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	[app.tabViewController responderMayHaveChanged];
}

-(void)refreshCaptcha {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", WebROOT, @"kaptcha.jpg"]];
        NSData *data = [NSData dataWithContentsOfURL:url];
        UIImage *img = [[[UIImage alloc] initWithData:data] autorelease];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            captchaImage.image = img;
            
            [activity stopAnimating];
        });  
    });
}

-(void)awakeFromNib {
    [activity startAnimating];
    
    [self refreshCaptcha];
}

-(void)walletJSReady {
    
    Key * key = [wallet generateNewKey];
    
    if (key) {
        [app standardNotify:[NSString stringWithFormat:@"Generated new bitcoin address %@", key.addr] title:@"Success" delegate:nil];
        
        if ([app.dataSource insertWallet:[wallet guid] sharedKey:[wallet sharedKey] payload:[wallet encryptedString] catpcha:captchaTextField.text]) {
            [app didGenerateNewWallet:wallet password:passwordTextField.text];
            
            [app closeModal];
        } else {
            [self refreshCaptcha];
        }
        
    } else {
        [app standardNotify:@"Error generating bitcoin address"];
    }
    
    [app finishTask];
    
    self.wallet = nil;
}

-(IBAction)createAccountClicked:(id)sender {
    
    if ([passwordTextField.text length] < 10 || [passwordTextField.text length] > 255) {
        [app standardNotify:@"Password must 10 characters or longer"];
    }
    
    if (![[passwordTextField text] isEqualToString:[password2TextField text]]) {
        [app standardNotify:@"Passwords do not match"];
        return;
    }
    
    if ([captchaTextField.text length] == 0) {
        [app standardNotify:@"You must enter the captcha code"];
        return;
    }
    
    [app startTask:TaskGeneratingWallet];

    self.wallet = [[[Wallet alloc] initWithPassword:passwordTextField.text] autorelease];
    
    wallet.delegate = self;

}

@end
