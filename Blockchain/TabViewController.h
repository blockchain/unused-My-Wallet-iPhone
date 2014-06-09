//
//  MainViewController.h
//  Tube Delays
//
//  Created by Ben Reeves on 10/11/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TabViewcontroller : UIViewController  {
	IBOutlet UIView * header;
	IBOutlet UIView * footer;
	IBOutlet UIView * contentView;
	IBOutlet UIImageView * whiteDownArrow;

	IBOutlet UIButton * nextButton;
	IBOutlet UIButton * backButton;
	
	CGRect keyboardRect;
	UIViewController * activeViewController;
	UIViewController * oldViewController;
	int selectedIndex;
	int desiredIndex;
    int defaultPin;
	double arrowStepDuration;
	CGPoint originalOffset;
}

@property(nonatomic, retain) UIViewController * activeViewController;
@property(nonatomic, retain) UIViewController * oldViewController;
@property(nonatomic, assign) BOOL backButtonEnabled;
@property(nonatomic, assign) BOOL nextButtonEnabled;
@property(nonatomic, assign) BOOL submitButtonEnabled;

-(void)setActiveViewController:(UIViewController *)nviewcontroller animated:(BOOL)animated index:(int)index;
-(IBAction)nextClicked:(id)sender;
-(IBAction)backClicked:(id)sender;
-(int)selectedIndex;
-(void)responderMayHaveChanged;

@end
