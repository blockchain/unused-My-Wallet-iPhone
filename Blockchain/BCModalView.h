//
//  BCModalView.h
//  Blockchain
//
//  Created by Ben Reeves on 19/07/2014.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BCModalContentView.h"

//	Modal close codes
typedef enum {
    ModalCloseTypeClose = 100,
    ModalCloseTypeBack = 200,
    ModalCloseTypeNone = 300,
}ModalCloseType;

@interface BCModalView : UIView {
    
}

@property(nonatomic, copy) void (^onDismiss)();
@property(nonatomic, copy) void (^onResume)();
@property(nonatomic, strong) IBOutlet UIView *myHolderView;
@property(nonatomic, strong) IBOutlet UIButton *closeButton;
@property(nonatomic, strong) IBOutlet UIButton *backButton;

@property(nonatomic) ModalCloseType closeType;

- (void)setModalCloseType:(ModalCloseType)closeType;
- (IBAction)closeModalClicked:(id)sender;

@end
