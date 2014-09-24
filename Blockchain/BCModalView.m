//
//  BCModalView.m
//  Blockchain
//
//  Created by Ben Reeves on 19/07/2014.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import "BCModalView.h"
#import "AppDelegate.h"

@implementation BCModalView

-(id)init
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UIWindow *window = appDelegate.window;
    
    self = [super initWithFrame:CGRectMake(0, 0, window.frame.size.width, window.frame.size.height)];
    
    if (self) {
        
        self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.closeButton.frame = CGRectMake(10, 30, 80, 30);
        // XXX localize
        [self.closeButton setTitle:@"Close" forState:UIControlStateNormal];
        [self.closeButton setBackgroundColor:[UIColor orangeColor]];
        [self.closeButton addTarget:self action:@selector(closeModalClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.closeButton];
        
        self.backgroundColor = COLOR_BLOCKCHAIN_BLUE;
        
        self.modalContentView = [[UIView alloc] initWithFrame:CGRectMake(0, 20, window.frame.size.width, window.frame.size.height - 20)];
        [self addSubview:self.modalContentView];
        
        [self bringSubviewToFront:self.closeButton];
    }
    
    return self;
}

-(void)setIsClosable:(BOOL)__isClosable {
    _isClosable = __isClosable;

    [self.closeButton setHidden:!_isClosable];
}

-(IBAction)closeModalClicked:(id)sender {
    if (self.isClosable || self.modalContentView == nil) {
        [app closeModal];
    }
}

@end
