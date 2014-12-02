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
    
    self = [super initWithFrame:CGRectMake(0, DEFAULT_HEADER_HEIGHT, window.frame.size.width, window.frame.size.height - DEFAULT_FOOTER_HEIGHT - DEFAULT_FOOTER_HEIGHT)];
    
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, window.frame.size.width - 40, 30)];
        headerLabel.text = BC_STRING_CREATE_ACCOUNT;
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
        [self addSubview:_labelTextField];

        UIButton *createAccountButton = [UIButton buttonWithType:UIButtonTypeCustom];
        createAccountButton.frame = CGRectMake(window.frame.size.width - 20 - 120, 130, 120, 40);
        createAccountButton.backgroundColor = COLOR_BUTTON_GRAY;
        [createAccountButton setTitle:BC_STRING_DONE forState:UIControlStateNormal];
        [createAccountButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        createAccountButton.titleLabel.font = [UIFont systemFontOfSize:17.0];
        createAccountButton.layer.cornerRadius = 5;
        [self addSubview:createAccountButton];
        
        [createAccountButton addTarget:self action:@selector(createAccountClicked:) forControlEvents:UIControlEventTouchUpInside];
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
    
    [app.wallet createAccountWithLabel:label];
    
    [app closeModalWithTransition:kCATransitionFade];
    
    // TODO refresh list
}

@end
