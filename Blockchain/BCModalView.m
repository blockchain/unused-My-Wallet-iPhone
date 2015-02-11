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

- (id)initWithCloseType:(ModalCloseType)closeType showHeader:(BOOL)showHeader headerText:(NSString *)headerText
{
    UIWindow *window = app.window;
    
    self = [super initWithFrame:CGRectMake(0, 0, window.frame.size.width, window.frame.size.height)];
    
    if (self) {
        self.backgroundColor = COLOR_BLOCKCHAIN_BLUE;
        self.closeType = closeType;
        
        if (showHeader) {
            UIView *topBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, window.frame.size.width, DEFAULT_HEADER_HEIGHT)];
            topBarView.backgroundColor = COLOR_BLOCKCHAIN_BLUE;
            [self addSubview:topBarView];
            
            UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 17.5, self.frame.size.width - 160, 40)];
            headerLabel.font = [UIFont systemFontOfSize:22.0];
            headerLabel.textColor = [UIColor whiteColor];
            headerLabel.textAlignment = NSTextAlignmentCenter;
            headerLabel.adjustsFontSizeToFitWidth = YES;
            headerLabel.text = headerText;
            [topBarView addSubview:headerLabel];
            
            if (closeType == ModalCloseTypeBack) {
                self.backButton = [UIButton buttonWithType:UIButtonTypeCustom];
                self.backButton.frame = CGRectMake(0, 15, 85, 51);
                self.backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
                self.backButton.contentEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 0);
                [self.backButton.titleLabel setFont:[UIFont systemFontOfSize:15]];
                [self.backButton setImage:[UIImage imageNamed:@"back_chevron_icon"] forState:UIControlStateNormal];
                [self.backButton setTitle:BC_STRING_BACK forState:UIControlStateNormal];
                [self.backButton setTitleColor:[UIColor colorWithWhite:0.56 alpha:1.0] forState:UIControlStateHighlighted];
                [self.backButton addTarget:self action:@selector(closeModalClicked:) forControlEvents:UIControlEventTouchUpInside];
                [topBarView addSubview:self.backButton];
            }
            else if (closeType == ModalCloseTypeClose) {
                self.closeButton = [[UIButton alloc] initWithFrame:CGRectMake(window.frame.size.width - 70, 15, 80, 51)];
                [self.closeButton setTitle:BC_STRING_CLOSE forState:UIControlStateNormal];
                [self.closeButton setTitleColor:[UIColor colorWithWhite:0.56 alpha:1.0] forState:UIControlStateHighlighted];
                self.closeButton.titleLabel.font = [UIFont systemFontOfSize:15];
                [self.closeButton addTarget:self action:@selector(closeModalClicked:) forControlEvents:UIControlEventTouchUpInside];
                [topBarView addSubview:self.closeButton];
            }
            
            self.myHolderView = [[UIView alloc] initWithFrame:CGRectMake(0, DEFAULT_HEADER_HEIGHT, window.frame.size.width, window.frame.size.height - DEFAULT_HEADER_HEIGHT)];
            
            [self addSubview:self.myHolderView];
            
            [self bringSubviewToFront:topBarView];
        }
        else {
            self.myHolderView = [[UIView alloc] initWithFrame:CGRectMake(0, 20, window.frame.size.width, window.frame.size.height - 20)];
            
            [self addSubview:self.myHolderView];
        }
    }
    
    return self;
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
