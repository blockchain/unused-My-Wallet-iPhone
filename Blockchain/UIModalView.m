//
//  UIModalView.m
//  Blockchain
//
//  Created by Ben Reeves on 19/07/2014.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import "UIModalView.h"
#import "AppDelegate.h"

@implementation MyUIModalView

-(void)dealloc {
    self.closeButtonBackground = nil;
    self.closeButton = nil;
    self.onDismiss = nil;
    self.onResume = nil;
    self.modalContentView = nil;
    [super dealloc];
}

-(void)setIsClosable:(BOOL)__isClosable {
    _isClosable = __isClosable;
    
    //[self.closeButton setEnabled:_isClosable];

    [self.closeButtonBackground setHidden:!_isClosable];
    [self.closeButton setHidden:!_isClosable];
}

-(IBAction)closeModalClicked:(id)sender {
    if (self.isClosable || self.modalContentView == nil) {
        [app closeModal];
    }
}

@end
