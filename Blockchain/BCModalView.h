//
//  BCModalView.h
//  Blockchain
//
//  Created by Ben Reeves on 19/07/2014.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BCModalContentView.h"

@interface BCModalView : UIView {
 
}

@property(nonatomic, copy) void (^onDismiss)();
@property(nonatomic, copy) void (^onResume)();
@property(nonatomic, strong) IBOutlet UIView *myHolderView;
@property(nonatomic, strong) IBOutlet UIButton * closeButton;

@property(nonatomic) BOOL isClosable;

-(IBAction)closeModalClicked:(id)sender;

@end
