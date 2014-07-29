//
//  BCAlertView.m
//  Blockchain
//
//  Created by Matt Tuzzolo on 7/30/14.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import "BCAlertView.h"

@implementation BCAlertView

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id) initWithTitle:(NSString *)title
             message:(NSString *)message
            delegate:(id)delegate
   cancelButtonTitle:(NSString *)cancelButtonTitle
   otherButtonTitles:(NSString *)otherButtonTitles, ...
{
    self = [super initWithTitle:title
                        message:message
                       delegate:delegate
              cancelButtonTitle:cancelButtonTitle
              otherButtonTitles:otherButtonTitles, nil];
    
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(dismiss:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
    }
    
    return self;
}

- (void) dismiss:(NSNotification *)notication {
    [self dismissWithClickedButtonIndex:[self cancelButtonIndex] animated:YES];
}


@end
