//
//  BCCreateAccountView.m
//  Blockchain
//
//  Created by Mark Pfluger on 11/27/14.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import "BCCreateAccountView.h"
#import "AppDelegate.h"

@implementation BCCreateAccountView

-(id)init
{
    UIWindow *window = app.window;
    
    self = [super initWithFrame:CGRectMake(0, DEFAULT_HEADER_HEIGHT, window.frame.size.width, window.frame.size.height - DEFAULT_HEADER_HEIGHT)];
    
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        UILabel *labelLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 55, window.frame.size.width - 40, 25)];
        labelLabel.text = BC_STRING_NAME_YOUR_ACCOUNT;
        labelLabel.textColor = [UIColor darkGrayColor];
        labelLabel.font = [UIFont systemFontOfSize:17.0];
        [self addSubview:labelLabel];
        
        _labelTextField = [[UITextField alloc] initWithFrame:CGRectMake(20, 95, window.frame.size.width - 40, 30)];
        _labelTextField.borderStyle = UITextBorderStyleRoundedRect;
        _labelTextField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        _labelTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        _labelTextField.spellCheckingType = UITextSpellCheckingTypeNo;
        [self addSubview:_labelTextField];
        
        [_labelTextField setReturnKeyType:UIReturnKeyDone];
        _labelTextField.delegate = self;
        
        UIButton *createAccountButton = [UIButton buttonWithType:UIButtonTypeCustom];
        createAccountButton.frame = CGRectMake(0, 0, window.frame.size.width, 46);
        createAccountButton.backgroundColor = COLOR_BUTTON_GRAY;
        [createAccountButton setTitle:BC_STRING_SAVE forState:UIControlStateNormal];
        [createAccountButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        createAccountButton.titleLabel.font = [UIFont systemFontOfSize:17.0];
        
        [createAccountButton addTarget:self action:@selector(createAccountClicked:) forControlEvents:UIControlEventTouchUpInside];
        
        _labelTextField.inputAccessoryView = createAccountButton;
    }
    
    return self;
}

# pragma mark - Button actions

- (IBAction)createAccountClicked:(id)sender
{
    // Remove whitespace
    NSString *label = [self.labelTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (label.length == 0) {
        [app standardNotify:BC_STRING_YOU_MUST_ENTER_A_LABEL];
        return;
    }
    
    NSMutableCharacterSet *allowedCharSet = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
    [allowedCharSet formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if ([label rangeOfCharacterFromSet:[allowedCharSet invertedSet]].location != NSNotFound) {
        [app standardNotify:BC_STRING_LABEL_MUST_BE_ALPHANUMERIC];
        return;
    }
    
    [app closeModalWithTransition:kCATransitionFade];
    
    [app.wallet createAccountWithLabel:label];
}

#pragma mark - Textfield Delegates

- (BOOL)textFieldShouldReturn:(UITextField*)aTextField
{
    [self createAccountClicked:nil];
    return YES;
}

@end
