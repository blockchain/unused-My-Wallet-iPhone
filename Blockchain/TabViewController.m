//
//  MainViewController.m
//  Tube Delays
//
//  Created by Ben Reeves on 10/11/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TabViewcontroller.h"
#include <math.h>
#import <QuartzCore/QuartzCore.h>
#import "AppDelegate.h"
#import "UIView+FirstResponder.h"

#define PI 3.14159265

CGPoint arrowPositions[4] = {28.0f, 29.0f,
    107.0f, 20.0f,
    190.0f, 19.0f,
    270.0f, 27.0f};

@implementation TabViewcontroller

@synthesize oldViewController;
@synthesize activeViewController; 

-(void)moveArrow {
	
	if (desiredIndex == selectedIndex)
		return;
	else if (desiredIndex > selectedIndex) {
		++selectedIndex;
	} else {
		--selectedIndex;
	}
	
	[UIView beginAnimations:@"MoveArrow" context:nil];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDuration:arrowStepDuration];
	[UIView setAnimationCurve:UIViewAnimationCurveLinear];
	[UIView setAnimationDidStopSelector:@selector(arrowAnimationStopped)];
	whiteDownArrow.frame = CGRectMake(arrowPositions[selectedIndex].x, arrowPositions[selectedIndex].y, whiteDownArrow.frame.size.width, whiteDownArrow.frame.size.height);
	[UIView commitAnimations];
}


-(void) keyboardWillShow:(NSNotification *)note
{		
    [[note.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardRect];
}

-(void) keyboardWillHide:(NSNotification *)note {	
    
    if (contentView.frame.origin.y != originalOffset.y) {
        [UIView beginAnimations:@"MoveUp" context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        contentView.frame =  CGRectMake(contentView.frame.origin.x, originalOffset.y,  contentView.frame.size.width,  contentView.frame.size.height);
        [UIView commitAnimations];
    }
}

-(void)responderMayHaveChanged {
        
	UIView * responder = [app.window findFirstResponder];

    
    NSLog(@"Responder %@", responder);
    
    CGPoint offset = contentView.frame.origin;

    printf("keyboard height : %f\n", keyboardRect.size.height);
    printf("reponder y : %f\n", responder.frame.origin.y);
    

    offset.y -= keyboardRect.size.height - (contentView.frame.size.height - responder.frame.origin.y) + 29.0f;
	
    printf("y: %f\n", offset.y);
           
    if (offset.y < 0) {
        [UIView beginAnimations:@"MoveUp" context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        contentView.frame = CGRectMake(contentView.frame.origin.x, offset.y,  contentView.frame.size.width,  contentView.frame.size.height);
        [UIView commitAnimations];
    }
	
}

-(void)setSelectedIndex:(int)nindex {
	desiredIndex = nindex;
		
	arrowStepDuration = 0.3f / abs(desiredIndex - selectedIndex);
	
	[self moveArrow];
}

-(void)arrowAnimationStopped {
	[self moveArrow];
}

-(void)awakeFromNib {
	
	keyboardRect = CGRectMake(0, 264, 320, 216);

	backButton.enabled = NO;
	backButton.alpha = 0.0f;
	nextButton.enabled = NO;
	nextButton.alpha = 0.0f;
	
	whiteDownArrow.frame = CGRectMake(arrowPositions[0].x, arrowPositions[0].y, whiteDownArrow.frame.size.width, whiteDownArrow.frame.size.height);
	selectedIndex = 0;
    
    [[NSNotificationCenter defaultCenter]
	 addObserver:self
	 selector:@selector(keyboardWillHide:)
	 name:UIKeyboardWillHideNotification
	 object:nil];
}

-(void)setActiveViewController:(UIViewController *)nviewcontroller {
	[self setActiveViewController:nviewcontroller animated:NO index:selectedIndex];	
}

-(void)insertActiveView {
	
	if ([[contentView subviews] count] > 0) {
		[[[contentView subviews] objectAtIndex:0] removeFromSuperview];
	}
	
	[contentView addSubview:activeViewController.view];	
	
	//Resize the View Sub Controller
	activeViewController.view.frame = CGRectMake(activeViewController.view.frame.origin.x, activeViewController.view.frame.origin.y, contentView.frame.size.width, activeViewController.view.frame.size.height);
	
    [activeViewController.view setNeedsLayout];
    
    originalOffset = contentView.frame.origin;
}

-(UIView*)textFieldResponder {
	for (UIView * sview in activeViewController.view.subviews) {
		if ([sview isKindOfClass:[UITextField class]] && sview.isFirstResponder)
			return sview;
	}
	
	return nil;
}

-(int)selectedIndex {
    return selectedIndex;
}

-(void)setActiveViewController:(UIViewController *)nviewcontroller animated:(BOOL)animated index:(int)index {
		
	if (nviewcontroller == activeViewController)
		return;
    
    NSLog(@"Set activ %d", index);
    		
	originalOffset = CGPointZero;
	
	self.oldViewController = activeViewController;

	[activeViewController release];
	activeViewController = nviewcontroller;
	[activeViewController retain];

    [oldViewController viewWillDisappear:animated];
    [activeViewController viewWillAppear:animated];
    
    [self insertActiveView];
   
    [oldViewController viewDidDisappear:animated];
    [activeViewController viewDidAppear:animated];
    
    self.oldViewController = nil;
    
    if (animated) {
        CATransition *animation = [CATransition animation]; 
        [animation setDuration:0.3f];
        [animation setType:kCATransitionPush]; 
        
        if (index > selectedIndex)
            [animation setSubtype:kCATransitionFromRight];
        else
            [animation setSubtype:kCATransitionFromLeft];

        [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
        
        [[contentView layer] addAnimation:animation forKey:@"SwitchToView1"]; 
    }
    
    if (index < 0) {
        [whiteDownArrow setHidden:TRUE];
    } else {
        [whiteDownArrow setHidden:FALSE];
    }

    // Hide arrow for now.
    [whiteDownArrow setHidden:TRUE];
    
    [self setSelectedIndex:index];

}

-(BOOL)backButtonEnabled {
	return backButton.enabled; 
}

-(BOOL)nextButtonEnabled {
	return nextButton.enabled; 
}

-(BOOL)submitButtonEnabled {
	if ([nextButton imageForState:UIControlStateNormal] == [UIImage imageNamed:@"submit-button.png"]) {
		return YES;
	} else {
		return FALSE;
	}
}

-(void)setSubmitButtonEnabled:(BOOL)nenabled {
	[nextButton setImage:[UIImage imageNamed:@"submit-button.png"] forState:UIControlStateNormal];
}


-(void)setNextButtonEnabled:(BOOL)nenabled {
	
	[UIView beginAnimations:@"setnextbutton" context:nil];
	[UIView setAnimationDuration:0.5f];
	if (nenabled) {
		
		[nextButton setImage:[UIImage imageNamed:@"next-button.png"] forState:UIControlStateNormal];
		
		nextButton.alpha = 1.0f;
		nextButton.enabled = YES;
	} else {
		nextButton.alpha = 0.0f;
		nextButton.enabled = NO;
	}
	[UIView commitAnimations];
}

-(void)setBackButtonEnabled:(BOOL)nenabled {
	
	[UIView beginAnimations:@"setbackbutton" context:nil];
	[UIView setAnimationDuration:0.5f];
	if (nenabled) {
		backButton.alpha = 1.0f;
		backButton.enabled = YES;
	} else {
		backButton.alpha = 0.0f;
		backButton.enabled = NO;
	}
	[UIView commitAnimations];

}

-(void)nextButtonAniStopped {
	[UIView beginAnimations:@"bumpButton" context:nil];
	[UIView setAnimationDuration:0.15f];
	nextButton.frame = CGRectMake(nextButton.frame.origin.x, nextButton.frame.origin.y+10.0f, nextButton.frame.size.width, nextButton.frame.size.height);
	[UIView commitAnimations];
}

-(IBAction)nextClicked:(id)sender {
	
	[UIView beginAnimations:@"bumpButton" context:nil];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDuration:0.15f];
	[UIView setAnimationDidStopSelector:@selector(nextButtonAniStopped)];
	nextButton.frame = CGRectMake(nextButton.frame.origin.x, nextButton.frame.origin.y-10.0f, nextButton.frame.size.width, nextButton.frame.size.height);
	[UIView commitAnimations];
	
#warning where is submitClicked:?
	if ([self submitButtonEnabled]) {
		if ([activeViewController respondsToSelector:@selector(submitClicked:)])
			[(id)activeViewController performSelector:@selector(submitClicked:) withObject:sender];		
	} else {
		if ([activeViewController respondsToSelector:@selector(nextClicked:)])
			[(id)activeViewController nextClicked:sender];	
	}
}

-(void)backButtonAniStopped {
	[UIView beginAnimations:@"bumpButton" context:nil];
	[UIView setAnimationDuration:0.15f];
	backButton.frame = CGRectMake(backButton.frame.origin.x, backButton.frame.origin.y+10.0f, backButton.frame.size.width, backButton.frame.size.height);
	[UIView commitAnimations];
}

-(IBAction)backClicked:(id)sender {
	
	[UIView beginAnimations:@"bumpButton" context:nil];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDuration:0.15f];
	[UIView setAnimationDidStopSelector:@selector(backButtonAniStopped)];
	backButton.frame = CGRectMake(backButton.frame.origin.x, backButton.frame.origin.y-10.0f, backButton.frame.size.width, backButton.frame.size.height);
	[UIView commitAnimations];
	
	if ([activeViewController respondsToSelector:@selector(backClicked:)])
		[(id)activeViewController backClicked:sender];	
}

-(void)dealloc {
	[oldViewController release];
	[activeViewController release];
	[super dealloc];
}


@end
