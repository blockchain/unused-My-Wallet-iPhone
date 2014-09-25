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

-(id)init
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UIWindow *window = appDelegate.window;
    
    self = [super initWithFrame:CGRectMake(0, 0, window.frame.size.width, window.frame.size.height)];
    
    if (self) {
        UIView *topBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, window.frame.size.width, 50)];
        topBarView.backgroundColor = COLOR_BLOCKCHAIN_BLUE;
        [self addSubview:topBarView];
        
//        UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"header"]];
//        logo.frame = CGRectMake(79, 18, 163, 46);
//        [topBarView addSubview:logo];
        
        self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.closeButton.frame = CGRectMake(0, 22, 80, 20);
        [self.closeButton.titleLabel setFont:[UIFont systemFontOfSize:15]];
        [self.closeButton setTitle:[NSString stringWithFormat:@"❮ %@", BC_STRING_BACK] forState:UIControlStateNormal];
        [self.closeButton addTarget:self action:@selector(closeModalClicked:) forControlEvents:UIControlEventTouchUpInside];
        [topBarView addSubview:self.closeButton];
        
        self.backgroundColor = COLOR_BLOCKCHAIN_BLUE;
        
        self.myHolderView = [[UIView alloc] initWithFrame:CGRectMake(0, 20, window.frame.size.width, window.frame.size.height - 20)];
        [self addSubview:self.myHolderView];
        
        [self bringSubviewToFront:topBarView];
    }
    
    return self;
}

-(void)setIsClosable:(BOOL)__isClosable {
    _isClosable = __isClosable;
    
    // The close button is inside a UIView (the top bar)
    [self.closeButton.superview setHidden:!_isClosable];
    
    // If it is closable, move the content view further down to accomodate the close button with bar
    if (__isClosable) {
        CGRect frame = self.myHolderView.frame;
        frame.origin.y += 30;
        frame.size.height -= 30;
        self.myHolderView.frame = frame;
    }
}

-(IBAction)closeModalClicked:(id)sender {
    if (self.isClosable) {
        // Not pretty but works
        [self.myHolderView.subviews[0] prepareForModalDismissal];
        [app closeModalWithTransition:kCATransitionMoveIn];
        [self.myHolderView.subviews[0] modalWasDismissed];
    }
}

@end
