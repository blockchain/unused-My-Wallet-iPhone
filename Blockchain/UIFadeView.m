//
//  UIFadeView.m
//  Blockchain
//
//  Created by Ben Reeves on 16/03/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "UIFadeView.h"

@implementation UIFadeView

- (void)fadeIn {
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    [UIView setAnimationDelegate:self];
    self.alpha = 1.0;
    [UIView commitAnimations];
}

- (void)fadeOut {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    [UIView setAnimationDidStopSelector:@selector(removeModalView)];
    self.alpha = 0.0;
    [UIView commitAnimations];
}

- (void)removeModalView {
    [self removeFromSuperview];
}

@end
