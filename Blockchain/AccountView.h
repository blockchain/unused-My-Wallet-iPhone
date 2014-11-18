//
//  AccountView.h
//  Blockchain
//
//  Created by Mark Pfluger on 11/17/14.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

//	Display state codes
typedef enum {
    DisplayStateMinimized = 100,
    DisplayStateDefault = 200,
    DisplayStateMaximized = 300,
} DisplayState;

@interface AccountView : UIView

- (void)reload;

@end
