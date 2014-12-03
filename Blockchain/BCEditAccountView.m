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
    
    self = [super initWithFrame:CGRectMake(0, DEFAULT_HEADER_HEIGHT, window.frame.size.width, window.frame.size.height - DEFAULT_FOOTER_HEIGHT - DEFAULT_FOOTER_HEIGHT)];
    
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, window.frame.size.width - 40, 30)];
        headerLabel.text = BC_STRING_EDIT_ACCOUNT;
        headerLabel.textAlignment = NSTextAlignmentCenter;
        headerLabel.textColor = [UIColor darkGrayColor];
        headerLabel.font = [UIFont systemFontOfSize:21.0];
        [self addSubview:headerLabel];
        
        UILabel *labelLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 85, 60, 25)];
        labelLabel.text = BC_STRING_LABEL;
        labelLabel.textAlignment = NSTextAlignmentRight;
        labelLabel.textColor = [UIColor darkGrayColor];
        labelLabel.font = [UIFont systemFontOfSize:17.0];
        [self addSubview:labelLabel];
        
        _labelTextField = [[UITextField alloc] initWithFrame:CGRectMake(90, 82, window.frame.size.width - 20 - 90, 30)];
        _labelTextField.borderStyle = UITextBorderStyleRoundedRect;
        _labelTextField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        _labelTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        _labelTextField.spellCheckingType = UITextSpellCheckingTypeNo;
        // TODO Done keyboard return type
        [self addSubview:_labelTextField];
        
        UIButton *editAccountButton = [UIButton buttonWithType:UIButtonTypeCustom];
        editAccountButton.frame = CGRectMake(window.frame.size.width - 20 - 120, 130, 120, 40);
        editAccountButton.backgroundColor = COLOR_BUTTON_GRAY;
        [editAccountButton setTitle:BC_STRING_DONE forState:UIControlStateNormal];
        [editAccountButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        editAccountButton.titleLabel.font = [UIFont systemFontOfSize:17.0];
        editAccountButton.layer.cornerRadius = 5;
        [self addSubview:editAccountButton];
        
        [editAccountButton addTarget:self action:@selector(editAccountClicked:) forControlEvents:UIControlEventTouchUpInside];
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
    
    [app closeModalWithTransition:kCATransitionFade];
    
    // TODO refresh list
}

@end
