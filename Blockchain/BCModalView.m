//
//  BCModalView.m
//  Blockchain
//
//  Created by Ben Reeves on 19/07/2014.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import "BCModalView.h"
#import "AppDelegate.h"
#import "LocalizationConstants.h"

@implementation BCModalView

- (id)init
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UIWindow *window = appDelegate.window;
    
    self = [super initWithFrame:CGRectMake(0, 0, window.frame.size.width, window.frame.size.height)];
    
    if (self) {
        UIView *topBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, window.frame.size.width, 66)];
        topBarView.backgroundColor = COLOR_BLOCKCHAIN_BLUE;
        [self addSubview:topBarView];
        
        UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"top_menu_logo.png"]];
        logo.frame = CGRectMake(88, 22, 143, 40);
        [topBarView addSubview:logo];
        
        self.backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.backButton.frame = CGRectMake(0, 15, 65, 51);
        [self.backButton.titleLabel setFont:[UIFont systemFontOfSize:15]];
        [self.backButton setTitle:[NSString stringWithFormat:@"❮ %@", BC_STRING_BACK] forState:UIControlStateNormal];
        [self.backButton addTarget:self action:@selector(closeModalClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.backButton setHidden:YES];
        [topBarView addSubview:self.backButton];
        
        self.closeButton = [[UIButton alloc] initWithFrame:CGRectMake(window.frame.size.width - 70, 15, 80, 51)];
        [self.closeButton setTitle:BC_STRING_CLOSE forState:UIControlStateNormal];
        self.closeButton.titleLabel.font = [UIFont systemFontOfSize:15];
        [self.closeButton addTarget:self action:@selector(closeModalClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.closeButton setHidden:YES];
        [topBarView addSubview:self.closeButton];
        
        self.backgroundColor = COLOR_BLOCKCHAIN_BLUE;
        
        self.myHolderView = [[UIView alloc] initWithFrame:CGRectMake(0, 20, window.frame.size.width, window.frame.size.height - 20)];
        [self addSubview:self.myHolderView];
        
        [self bringSubviewToFront:topBarView];
    }
    
    return self;
}

- (void)setModalCloseType:(ModalCloseType)closeType
{
    self.closeType = closeType;
    
    if (closeType == ModalCloseTypeBack) {
        // The close button is inside a UIView (the top bar)
        [self.backButton.superview setHidden:NO];
        [self.backButton setHidden:NO];
    }
    else if (closeType == ModalCloseTypeClose) {
        // The close button is inside a UIView (the top bar)
        [self.closeButton.superview setHidden:NO];
        [self.closeButton setHidden:NO];
    }
    else {
        [self.closeButton.superview setHidden:YES];
        [self.backButton.superview setHidden:YES];
        [self.closeButton.superview setHidden:YES];
    }
    
    // If it is closable, move the content view further down to accomodate the close button with bar
    if (closeType != ModalCloseTypeNone) {
        CGRect frame = self.myHolderView.frame;
        frame.origin.y += 46;
        frame.size.height -= 46;
        self.myHolderView.frame = frame;
    }
}

- (IBAction)closeModalClicked:(id)sender
{
    if (self.closeType != ModalCloseTypeNone) {
        // Not pretty but works
        if ([self.myHolderView.subviews[0] respondsToSelector:@selector(prepareForModalDismissal)]) {
            [self.myHolderView.subviews[0] prepareForModalDismissal];
        }
        if ([self.myHolderView.subviews[0] respondsToSelector:@selector(modalWasDismissed)]) {
            [self.myHolderView.subviews[0] modalWasDismissed];
        }
        
        if (self.closeType == ModalCloseTypeBack) {
            [app closeModalWithTransition:kCATransitionFromLeft];
        }
        else {
            [app closeModalWithTransition:kCATransitionFade];
        }
    }
}

@end
