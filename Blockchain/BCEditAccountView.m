//
//  BCEditAccountView.m
//  Blockchain
//
//  Created by Mark Pfluger on 12/1/14.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import "BCEditAccountView.h"
#import "AppDelegate.h"

@implementation BCEditAccountView

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
        
        UIButton *editAccountButton = [UIButton buttonWithType:UIButtonTypeCustom];
        editAccountButton.frame = CGRectMake(0, 0, window.frame.size.width, 46);
        editAccountButton.backgroundColor = COLOR_BUTTON_GRAY;
        [editAccountButton setTitle:BC_STRING_SAVE forState:UIControlStateNormal];
        [editAccountButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        editAccountButton.titleLabel.font = [UIFont systemFontOfSize:17.0];
        
        [editAccountButton addTarget:self action:@selector(editAccountClicked:) forControlEvents:UIControlEventTouchUpInside];
        
        _labelTextField.inputAccessoryView = editAccountButton;
    }
    
    return self;
}

# pragma mark - Button actions

- (IBAction)editAccountClicked:(id)sender
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
    
    [app.wallet setLabelForAccount:self.accountIdx label:label];
    
    [app reload];
    
    [app closeModalWithTransition:kCATransitionFade];
}


#pragma mark - Textfield Delegates

- (BOOL)textFieldShouldReturn:(UITextField*)aTextField
{
    [self editAccountClicked:nil];
    return YES;
}

@end
