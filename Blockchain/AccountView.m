//
//  AccountView.m
//  Blockchain
//
//  Created by Mark Pfluger on 11/17/14.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import "AccountView.h"
#import "AppDelegate.h"

#define HEIGHT_MINIMIZED 20
#define HEIGHT_DEFAULT 90
#define HEIGHT_MAXIMIZED 320

#define HEIGHT_SLIDER 10

@implementation AccountView

UIView *contentView;
UIView *accountsView;
UIButton *balanceBigButton;
UIButton *balanceSmallButton;
UIButton *sliderButton;

DisplayState displayState;
DisplayState lastDisplayState;

#pragma mark - View lifecycle

- (id)init
{
    if (self = [super init]) {
        CGRect appFrame = app.window.frame;
        
        self.frame = CGRectMake(0, 0, appFrame.size.width, HEIGHT_DEFAULT);
        
        // Content holder view
        contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, appFrame.size.width, HEIGHT_DEFAULT)];
        displayState = DisplayStateDefault;
        lastDisplayState = DisplayStateDefault;
        
        contentView.backgroundColor = COLOR_BLOCKCHAIN_BLUE;
        [self addSubview:contentView];
        
        // Accounts holder view
        accountsView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, appFrame.size.width, HEIGHT_DEFAULT - HEIGHT_SLIDER)];
        accountsView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        [self addSubview:accountsView];
        
        // Balance
        balanceBigButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 10, appFrame.size.width - 40, 42)];
        balanceBigButton.titleLabel.font = [UIFont boldSystemFontOfSize:34.0];
        [balanceBigButton.titleLabel setMinimumScaleFactor:.5f];
        [balanceBigButton.titleLabel setAdjustsFontSizeToFitWidth:YES];
        [accountsView addSubview:balanceBigButton];
        
        balanceSmallButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 45, appFrame.size.width - 40, 27)];
        balanceSmallButton.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [balanceSmallButton.titleLabel setMinimumScaleFactor:.5f];
        [balanceSmallButton.titleLabel setAdjustsFontSizeToFitWidth:YES];
        [accountsView addSubview:balanceSmallButton];
        
        sliderButton = [[UIButton alloc] initWithFrame:CGRectMake(0, HEIGHT_DEFAULT - HEIGHT_SLIDER, appFrame.size.width, HEIGHT_SLIDER)];
        sliderButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        sliderButton.backgroundColor = COLOR_BLOCKCHAIN_LIGHT_BLUE;
        [sliderButton addTarget:self action:@selector(toggleDisplayStateClicked:) forControlEvents:UIControlEventTouchUpInside];
        [contentView addSubview:sliderButton];
        
        [self reload];
    }
    
    return self;
}

//willMoveToSuperview:
//didMoveToSuperview
//willMoveToWindow:
//didMoveToWindow:

# pragma mark - Exported methods

- (void)reload
{
    [self setText];
}

# pragma mark - Helper methods

- (void)setDisplayState:(DisplayState)_displayState
{
    lastDisplayState = displayState;
    displayState = _displayState;
    
    switch (displayState) {
        case DisplayStateMinimized:
            [self setHeight:HEIGHT_MINIMIZED];
            break;
            
        case DisplayStateDefault:
            [self setHeight:HEIGHT_DEFAULT];
            break;
            
        case DisplayStateMaximized:
            [self setHeight:HEIGHT_MAXIMIZED];
            break;
    }
}

- (void)setHeight:(int)height
{
    // TODO let the parent viewController know about the change and resize accordingly for small and default sizes
    
    // TODO
    if ((lastDisplayState == DisplayStateDefault && displayState == DisplayStateMaximized) ||
        (lastDisplayState == DisplayStateMaximized && displayState == DisplayStateDefault)) {
        accountsView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    }
    else {
        accountsView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    }
    
    CGRect frame = contentView.frame;
    frame.size.height = height;
    
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        self.frame = frame;
        contentView.frame = frame;
    } completion:nil];
}

- (void)setText
{
    uint64_t balance = app.latestResponse.final_balance;

    // Balance not loaded yet
    if (app.latestResponse) {
        [balanceBigButton setTitle:[app formatMoney:balance localCurrency:app->symbolLocal] forState:UIControlStateNormal];
        [balanceSmallButton setTitle:[app formatMoney:balance localCurrency:!app->symbolLocal] forState:UIControlStateNormal];
    }
    else {
        [balanceBigButton setTitle:@"" forState:UIControlStateNormal];
        [balanceSmallButton setTitle:@"" forState:UIControlStateNormal];
    }
}

#pragma mark - Button Actions

- (IBAction)toggleDisplayStateClicked:(id)sender
{
    switch (displayState) {
        case DisplayStateMinimized:
            lastDisplayState = DisplayStateMinimized;
            displayState = DisplayStateDefault;
            [self setHeight:HEIGHT_DEFAULT];
            break;
            
        case DisplayStateDefault:
            lastDisplayState = DisplayStateDefault;
            displayState = DisplayStateMaximized;
            [self setHeight:HEIGHT_MAXIMIZED];
            break;
            
        case DisplayStateMaximized:
            // TODO this two step does not work yet and should not be used this way anyways when finalized
            lastDisplayState = DisplayStateMaximized;
            displayState = DisplayStateDefault;
            [self setHeight:HEIGHT_DEFAULT];
            
            lastDisplayState = DisplayStateMaximized;
            displayState = DisplayStateMinimized;
            [self setHeight:HEIGHT_MINIMIZED];
            break;
    }
}

@end
