//
//  AccountTableCell.m
//  Blockchain
//
//  Created by Mark Pfluger on 12/2/14.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import "AccountTableCell.h"
#import "AppDelegate.h"
#import "ECSlidingViewController.h"
#import "BCEditAccountView.h"

@implementation AccountTableCell

- (id)init
{
    self = [super init];
    
    if (self) {
        ECSlidingViewController *sideMenu = app.slidingViewController;
        
        _labelLabel = [[UILabel alloc] initWithFrame:CGRectMake(56, 10, self.frame.size.width - sideMenu.anchorLeftPeekAmount - 30, 18)];
        _labelLabel.font = [UIFont boldSystemFontOfSize:16.0];
        _labelLabel.textColor = [UIColor whiteColor];
        [self addSubview:_labelLabel];
        
        _amountLabel = [[UILabel alloc] initWithFrame:CGRectMake(56, 24, self.frame.size.width - sideMenu.anchorLeftPeekAmount - 30, 30)];
        _amountLabel.font = [UIFont boldSystemFontOfSize:16.0];
        _amountLabel.textColor = [UIColor whiteColor];
        [self addSubview:_amountLabel];
        
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:app action:@selector(toggleSymbol)];
        [_amountLabel addGestureRecognizer:tapGestureRecognizer];
        _amountLabel.userInteractionEnabled = YES;
        
        _editButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width - sideMenu.anchorLeftPeekAmount - 30 - 30, 0, 54, 54)];
        [_editButton setImage:[UIImage imageNamed:@"account-settings"] forState:UIControlStateNormal];
        [_editButton addTarget:self action:@selector(editButtonclicked:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_editButton];
    }
    
    return self;
}

- (IBAction)editButtonclicked:(id)sender
{
    BCEditAccountView *editAccountView = [[BCEditAccountView alloc] init];
    
    editAccountView.accountIdx = self.accountIdx;
    editAccountView.labelTextField.text = [app.wallet getLabelForAccount:self.accountIdx];
    
    [app showModalWithContent:editAccountView closeType:ModalCloseTypeClose headerText:BC_STRING_EDIT_ACCOUNT];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [editAccountView.labelTextField becomeFirstResponder];
    });
}

@end
