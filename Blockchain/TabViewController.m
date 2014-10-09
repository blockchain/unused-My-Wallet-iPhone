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

#define TAB_SEND 0
#define TAB_TRANSACTIONS 1
#define TAB_RECEIVE 2

CGPoint arrowPositions[3] = {
    0.0f, 50.0f,
    106.0f, 50.0f,
    213.0f, 50.0f
};

@implementation TabViewcontroller

@synthesize oldViewController;
@synthesize activeViewController;
@synthesize contentView;

- (void) keyboardWillShow:(NSNotification *)note
{
    [[note.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardRect];
}

- (void) keyboardWillHide:(NSNotification *)note
{
    [self moveDown];
}

- (void)moveDown
{
    if (contentView.frame.origin.y != originalOffset.y) {
        [UIView beginAnimations:@"MoveUp" context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        contentView.frame = CGRectMake(contentView.frame.origin.x, originalOffset.y, contentView.frame.size.width, contentView.frame.size.height);
        [UIView commitAnimations];
    }
}

// Move contentview up when keyboard is covering the first responder
// Useful on 3.5 inch screens
- (void)responderMayHaveChanged
{
    UIView * responder = [contentView findFirstResponder];
    
    if (responder) {
        CGRect responderRect = [app.window convertRect:responder.frame fromView:[responder superview]];
        
        float moveUpY = (app.window.frame.size.height - keyboardRect.size.height) - (responderRect.origin.y  + 65.0f);
        
        if (moveUpY < 0) {
            [UIView beginAnimations:@"MoveUp" context:nil];
            [UIView setAnimationCurve:UIViewAnimationCurveLinear];
            contentView.frame = CGRectMake(contentView.frame.origin.x, contentView.frame.origin.y+moveUpY,  contentView.frame.size.width,  contentView.frame.size.height);
            [UIView commitAnimations];
        }
    }
}

- (void)awakeFromNib
{
    // TODO keyboard size changed in iOS 8 - can't hardcode this anymore
    keyboardRect = CGRectMake(0, 264, 320, 216);
    
    backButton.enabled = NO;
    backButton.alpha = 0.0f;
    nextButton.enabled = NO;
    nextButton.alpha = 0.0f;
    
    selectedIndex = TAB_TRANSACTIONS;
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(keyboardWillHide:)
     name:UIKeyboardWillHideNotification
     object:nil];
    
    //Swipe between tabs for fun
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:app action:@selector(swipeLeft)];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:app action:@selector(swipeRight)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    
    [contentView addGestureRecognizer:swipeLeft];
    [contentView addGestureRecognizer:swipeRight];
}

- (void)setActiveViewController:(UIViewController *)nviewcontroller
{
    [self setActiveViewController:nviewcontroller animated:NO index:selectedIndex];
}

- (void)insertActiveView
{
    if ([[contentView subviews] count] > 0) {
        [[[contentView subviews] objectAtIndex:0] removeFromSuperview];
    }
    
    [contentView addSubview:activeViewController.view];
    
    //Resize the View Sub Controller
    activeViewController.view.frame = CGRectMake(activeViewController.view.frame.origin.x, activeViewController.view.frame.origin.y, contentView.frame.size.width, activeViewController.view.frame.size.height);
    
    [activeViewController.view setNeedsLayout];
}

- (void)viewDidAppear:(BOOL)animated
{
    originalOffset = contentView.frame.origin;
}

- (UIView*)textFieldResponder
{
    for (UIView * sview in activeViewController.view.subviews) {
        if ([sview isKindOfClass:[UITextField class]] && sview.isFirstResponder)
            return sview;
    }
    
    return nil;
}

- (int)selectedIndex
{
    return selectedIndex;
}

- (void)setActiveViewController:(UIViewController *)nviewcontroller animated:(BOOL)animated index:(int)newIndex
{
    if (nviewcontroller == activeViewController)
        return;
    
    self.oldViewController = activeViewController;
    
    activeViewController = nviewcontroller;
    
    [self insertActiveView];
    
    self.oldViewController = nil;
    
    if (animated) {
        CATransition *animation = [CATransition animation];
        [animation setDuration:ANIMATION_DURATION];
        [animation setType:kCATransitionPush];
        [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
        
        if (newIndex > selectedIndex)
            [animation setSubtype:kCATransitionFromRight];
        else
            [animation setSubtype:kCATransitionFromLeft];
        
        [[contentView layer] addAnimation:animation forKey:@"SwitchToView1"];
    }
    
    if (newIndex >= 0)
        [self setSelectedIndex:newIndex];
}

- (BOOL)backButtonEnabled
{
    return backButton.enabled;
}

- (BOOL)nextButtonEnabled
{
    return nextButton.enabled;
}

- (BOOL)submitButtonEnabled
{
    if ([nextButton imageForState:UIControlStateNormal] == [UIImage imageNamed:@"submit-button.png"]) {
        return YES;
    } else {
        return FALSE;
    }
}

- (void)setSubmitButtonEnabled:(BOOL)nenabled
{
    [nextButton setImage:[UIImage imageNamed:@"submit-button.png"] forState:UIControlStateNormal];
}


- (void)setNextButtonEnabled:(BOOL)nenabled
{
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

- (void)setBackButtonEnabled:(BOOL)nenabled
{
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

- (void)nextButtonAniStopped
{
    [UIView beginAnimations:@"bumpButton" context:nil];
    [UIView setAnimationDuration:0.15f];
    nextButton.frame = CGRectMake(nextButton.frame.origin.x, nextButton.frame.origin.y+10.0f, nextButton.frame.size.width, nextButton.frame.size.height);
    [UIView commitAnimations];
}

- (IBAction)nextClicked:(id)sender
{
    [UIView beginAnimations:@"bumpButton" context:nil];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDuration:0.15f];
    [UIView setAnimationDidStopSelector:@selector(nextButtonAniStopped)];
    nextButton.frame = CGRectMake(nextButton.frame.origin.x, nextButton.frame.origin.y-10.0f, nextButton.frame.size.width, nextButton.frame.size.height);
    [UIView commitAnimations];
    
    if ([activeViewController respondsToSelector:@selector(nextClicked:)])
        [(id)activeViewController nextClicked:sender];
}

- (void)backButtonAniStopped
{
    [UIView beginAnimations:@"bumpButton" context:nil];
    [UIView setAnimationDuration:0.15f];
    backButton.frame = CGRectMake(backButton.frame.origin.x, backButton.frame.origin.y+10.0f, backButton.frame.size.width, backButton.frame.size.height);
    [UIView commitAnimations];
}

- (void)setSelectedIndex:(int)nindex
{
    desiredIndex = nindex;
    
    arrowStepDuration = 0.2f / abs(desiredIndex - selectedIndex);
    
    [self moveArrow];
}

- (void)arrowAnimationStopped
{
    [self moveArrow];
}

- (void)moveArrow
{
    if (desiredIndex == selectedIndex) {
        // Makes sure the original button is highlighted on start
        if (selectedIndex == TAB_SEND)
            sendButton.highlighted = YES;
        else if (selectedIndex == TAB_TRANSACTIONS)
            homeButton.highlighted = YES;
        else if (selectedIndex == TAB_RECEIVE)
            receiveButton.highlighted = YES;
        else {
            sendButton.highlighted = NO;
            homeButton.highlighted = NO;
            receiveButton.highlighted = NO;
        }
        
        return;
    }
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
    arrow.frame = CGRectMake(arrowPositions[selectedIndex].x, arrowPositions[selectedIndex].y, arrow.frame.size.width, arrow.frame.size.height);
    [UIView commitAnimations];
    
    // Highlight the button that was clicked after the arrow animation is done
    sendButton.highlighted = NO;
    homeButton.highlighted = NO;
    receiveButton.highlighted = NO;
    sendButton.userInteractionEnabled = YES;
    homeButton.userInteractionEnabled = YES;
    receiveButton.userInteractionEnabled = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(arrowStepDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (selectedIndex == 0) {
            sendButton.highlighted = YES;
            sendButton.userInteractionEnabled = NO;
        }
        else if (selectedIndex == 1) {
            homeButton.highlighted = YES;
            homeButton.userInteractionEnabled = NO;
        }
        else {
            receiveButton.highlighted = YES;
            receiveButton.userInteractionEnabled = NO;
        }
    });
}

- (IBAction)backClicked:(id)sender
{
    [UIView beginAnimations:@"bumpButton" context:nil];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDuration:0.15f];
    [UIView setAnimationDidStopSelector:@selector(backButtonAniStopped)];
    backButton.frame = CGRectMake(backButton.frame.origin.x, backButton.frame.origin.y-10.0f, backButton.frame.size.width, backButton.frame.size.height);
    [UIView commitAnimations];
    
    if ([activeViewController respondsToSelector:@selector(backClicked:)])
        [(id)activeViewController backClicked:sender];
}

@end
