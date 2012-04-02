//
//  UIView+FirstResponder.m
//  Blockchain
//
//  Created by Ben Reeves on 02/04/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "UIView+FirstResponder.h"

@implementation UIView (FirstResponder)

- (UIView *)findFirstResponder
{
    if (self.isFirstResponder) {
        return self;     
    }
    for (UIView *subView in self.subviews) {
		UIView * responder = [subView findFirstResponder];
        if (responder)
            return responder;
    }
    return nil;
}

@end
