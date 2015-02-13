//
//  MainViewController.h
//  Tube Delays
//
//  Created by Ben Reeves on 10/11/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

@interface TabViewcontroller : UIViewController  {
    IBOutlet UIButton *sendButton;
    IBOutlet UIButton *homeButton;
    IBOutlet UIButton *receiveButton;
	
	UIViewController *activeViewController;
	UIViewController *oldViewController;
    
	int selectedIndex;
}

@property(nonatomic, retain) UIViewController *activeViewController;
@property(nonatomic, retain) UIViewController *oldViewController;
@property(nonatomic, retain) IBOutlet UIView *contentView;
@property(nonatomic, retain) UIView *menuSwipeRecognizerView;

- (void)setActiveViewController:(UIViewController *)nviewcontroller animated:(BOOL)animated index:(int)index;
- (int)selectedIndex;

@end
