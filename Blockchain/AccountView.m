//
//  AccountView.m
//  Blockchain
//
//  Created by Mark Pfluger on 11/17/14.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import "AccountView.h"
#import "AppDelegate.h"

#define HEIGHT_SLIDER 30

#define HEIGHT_MINIMIZED HEIGHT_SLIDER
#define HEIGHT_DEFAULT 90
#define HEIGHT_MAXIMIZED 420

@implementation AccountView

UIView *contentView;
UIView *accountsView;
UIButton *balanceBigButton;
UIButton *balanceSmallButton;
UIButton *sliderButton;

DisplayState displayState;
DisplayState lastDisplayState;

BOOL isAccountsDisplayed = NO;

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
        accountsView.clipsToBounds = YES;
        [self addSubview:accountsView];
        
        // Balance
        balanceBigButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 5, appFrame.size.width - 40, 42)];
        balanceBigButton.titleLabel.font = [UIFont boldSystemFontOfSize:34.0];
        [balanceBigButton.titleLabel setMinimumScaleFactor:.5f];
        [balanceBigButton.titleLabel setAdjustsFontSizeToFitWidth:YES];
        [balanceBigButton addTarget:app action:@selector(toggleSymbol) forControlEvents:UIControlEventTouchUpInside];
        [accountsView addSubview:balanceBigButton];
        
        balanceSmallButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 40, appFrame.size.width - 40, 27)];
        balanceSmallButton.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [balanceSmallButton.titleLabel setMinimumScaleFactor:.5f];
        [balanceSmallButton.titleLabel setAdjustsFontSizeToFitWidth:YES];
        [balanceSmallButton addTarget:app action:@selector(toggleSymbol) forControlEvents:UIControlEventTouchUpInside];
        [accountsView addSubview:balanceSmallButton];
        
        sliderButton = [[UIButton alloc] initWithFrame:CGRectMake(0, HEIGHT_DEFAULT - HEIGHT_SLIDER, appFrame.size.width, HEIGHT_SLIDER)];
        sliderButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
//        sliderButton.backgroundColor = COLOR_BLOCKCHAIN_LIGHT_BLUE;
        [sliderButton addTarget:self action:@selector(toggleDisplayStateClicked:) forControlEvents:UIControlEventTouchUpInside];
        [contentView addSubview:sliderButton];
        
        // Swipe gesture recognizer to pull down the account view
        UIGestureRecognizer* recognizer = [[UIPanGestureRecognizer alloc]
                                           initWithTarget:self
                                           action:@selector(handlePan:)];
        recognizer.delegate = self;
        // TODO no gesture for now
//        [sliderButton addGestureRecognizer:recognizer];
        
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
    [self setDisplayState:_displayState completion:nil];
}

- (void)setDisplayState:(DisplayState)_displayState completion:(void (^)(BOOL))completion
{
    lastDisplayState = displayState;
    displayState = _displayState;
    
    switch (displayState) {
        case DisplayStateMinimized:
            [self setHeight:HEIGHT_MINIMIZED completion:completion];
            break;
            
        case DisplayStateDefault:
            [self setHeight:HEIGHT_DEFAULT completion:completion];
            break;
            
        case DisplayStateMaximized:
            [self setHeight:HEIGHT_MAXIMIZED completion:completion];
            break;
    }
}

- (void)setHeight:(int)height
{
    [self setHeight:height completion:nil];
}

- (void)setHeight:(int)height completion:(void (^)(BOOL))completion
{
    // TODO let the parent viewController know about the change and resize accordingly for small and default sizes
    
    // TODO partial solution for gestures, but not quite there yet
//    float oldHeight = contentView.frame.size.height;
//    if ((oldHeight < HEIGHT_DEFAULT && height > HEIGHT_DEFAULT) ||
//        (oldHeight > HEIGHT_DEFAULT && height < HEIGHT_DEFAULT)) {
//        height = HEIGHT_DEFAULT;
//    }
//    
//    if (height > HEIGHT_DEFAULT) {
//        accountsView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
//    }
//    else {
//        accountsView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
//    }
    
    // TODO only works for click, not for gesture resizing
    if ((lastDisplayState == DisplayStateDefault && displayState == DisplayStateMaximized) ||
        (lastDisplayState == DisplayStateMaximized && displayState == DisplayStateDefault)) {
        accountsView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    }
    else {
        accountsView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    }
    
    CGRect frame = contentView.frame;
    frame.size.height = height;
    
    // TODO only animate when not touching anymore for gestures
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        self.frame = frame;
        contentView.frame = frame;
    } completion:completion];
}

- (void)setText
{
    uint64_t balance = app.latestResponse.final_balance;

    // Balance loaded
    if (app.latestResponse) {
        [balanceBigButton setTitle:[app formatMoney:balance localCurrency:app->symbolLocal] forState:UIControlStateNormal];
        [balanceSmallButton setTitle:[app formatMoney:balance localCurrency:!app->symbolLocal] forState:UIControlStateNormal];
        
        // Display HD accounts
        if (!isAccountsDisplayed) {
            [self displayAccounts];
        }
        
        // Update balances for all HD accounts
        int i = 0;
        for (; i < app.wallet.getAccountsCount; i++) {
            UIButton *accountBalanceBigButton = (UIButton *)[accountsView viewWithTag:10*(i+1)+0];
            [accountBalanceBigButton setTitle:[app formatMoney:[app.wallet getBalanceForAccount:i] localCurrency:app->symbolLocal] forState:UIControlStateNormal];
            
            UIButton *accountBalanceSmallButton = (UIButton *)[accountsView viewWithTag:10*(i+1)+1];
            [accountBalanceSmallButton setTitle:[app formatMoney:[app.wallet getBalanceForAccount:i] localCurrency:!app->symbolLocal] forState:UIControlStateNormal];
        }
        
        if ([app.wallet hasLegacyAddresses]) {
            UIButton *accountBalanceBigButton = (UIButton *)[accountsView viewWithTag:10*(i+1)+0];
            [accountBalanceBigButton setTitle:[app formatMoney:[app.wallet getTotalBalanceForActiveLegacyAddresses] localCurrency:app->symbolLocal] forState:UIControlStateNormal];
            
            UIButton *accountBalanceSmallButton = (UIButton *)[accountsView viewWithTag:10*(i+1)+1];
            [accountBalanceSmallButton setTitle:[app formatMoney:[app.wallet getTotalBalanceForActiveLegacyAddresses] localCurrency:!app->symbolLocal] forState:UIControlStateNormal];
        }
    }
    else {
        // When coming back from the background, reset the display state
        [self setDisplayState:DisplayStateDefault];
        
        [balanceBigButton setTitle:@"" forState:UIControlStateNormal];
        [balanceSmallButton setTitle:@"" forState:UIControlStateNormal];
    }
}

- (void)displayAccounts
{
    isAccountsDisplayed = YES;
    
    float y = balanceSmallButton.frame.origin.y + balanceSmallButton.frame.size.height;
    
    int i = 0;
    for (; i < app.wallet.getAccountsCount; i++) {
        UIButton *accountHeaderButton = [[UIButton alloc] initWithFrame:CGRectMake(20, y + 20, app.window.frame.size.width - 40, 27)];
        UIButton *accountBalanceBigButton = [[UIButton alloc] initWithFrame:CGRectMake(20, y + 40, app.window.frame.size.width - 40, 42)];
        UIButton *accountBalanceSmallButton = [[UIButton alloc] initWithFrame:CGRectMake(20, y + 75, app.window.frame.size.width - 40, 27)];
        y = accountBalanceSmallButton.frame.origin.y + accountBalanceSmallButton.frame.size.height;
        
        accountHeaderButton.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [accountHeaderButton.titleLabel setMinimumScaleFactor:.5f];
        [accountHeaderButton.titleLabel setAdjustsFontSizeToFitWidth:YES];
        // TOOD i18n
        NSString *label = [NSString stringWithFormat:@"%@ %@", [app.wallet getLabelForAccount:i], @"Account"];
        [accountHeaderButton setTitle:label forState:UIControlStateNormal];
        [accountHeaderButton setTitleColor:COLOR_BLOCKCHAIN_LIGHTEST_BLUE forState:UIControlStateNormal];
        [accountHeaderButton addTarget:app action:@selector(toggleSymbol) forControlEvents:UIControlEventTouchUpInside];
        [accountsView addSubview:accountHeaderButton];
        
        accountBalanceBigButton.titleLabel.font = [UIFont boldSystemFontOfSize:34.0];
        [accountBalanceBigButton.titleLabel setMinimumScaleFactor:.5f];
        [accountBalanceBigButton.titleLabel setAdjustsFontSizeToFitWidth:YES];
        [accountBalanceBigButton setTag:10*(i+1)+0];
        [accountBalanceBigButton setTitleColor:COLOR_BLOCKCHAIN_LIGHTEST_BLUE forState:UIControlStateNormal];
        [accountBalanceBigButton addTarget:app action:@selector(toggleSymbol) forControlEvents:UIControlEventTouchUpInside];
        [accountsView addSubview:accountBalanceBigButton];
        
        accountBalanceSmallButton.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [accountBalanceSmallButton.titleLabel setMinimumScaleFactor:.5f];
        [accountBalanceSmallButton.titleLabel setAdjustsFontSizeToFitWidth:YES];
        [accountBalanceSmallButton setTag:10*(i+1)+1];
        [accountBalanceSmallButton setTitleColor:COLOR_BLOCKCHAIN_LIGHTEST_BLUE forState:UIControlStateNormal];
        [accountBalanceSmallButton addTarget:app action:@selector(toggleSymbol) forControlEvents:UIControlEventTouchUpInside];
        [accountsView addSubview:accountBalanceSmallButton];
    }
    
    if ([app.wallet hasLegacyAddresses]) {
        UIButton *accountHeaderButton = [[UIButton alloc] initWithFrame:CGRectMake(20, y + 20, app.window.frame.size.width - 40, 27)];
        UIButton *accountBalanceBigButton = [[UIButton alloc] initWithFrame:CGRectMake(20, y + 40, app.window.frame.size.width - 40, 42)];
        UIButton *accountBalanceSmallButton = [[UIButton alloc] initWithFrame:CGRectMake(20, y + 75, app.window.frame.size.width - 40, 27)];
        y = accountBalanceSmallButton.frame.origin.y + accountBalanceSmallButton.frame.size.height;
        
        accountHeaderButton.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [accountHeaderButton.titleLabel setMinimumScaleFactor:.5f];
        [accountHeaderButton.titleLabel setAdjustsFontSizeToFitWidth:YES];
        // TOOD i18n
        NSString *label = @"Imported Addresses";
        [accountHeaderButton setTitle:label forState:UIControlStateNormal];
        [accountHeaderButton setTitleColor:COLOR_BLOCKCHAIN_LIGHTEST_BLUE forState:UIControlStateNormal];
        [accountHeaderButton addTarget:app action:@selector(toggleSymbol) forControlEvents:UIControlEventTouchUpInside];
        [accountsView addSubview:accountHeaderButton];
        
        accountBalanceBigButton.titleLabel.font = [UIFont boldSystemFontOfSize:34.0];
        [accountBalanceBigButton.titleLabel setMinimumScaleFactor:.5f];
        [accountBalanceBigButton.titleLabel setAdjustsFontSizeToFitWidth:YES];
        [accountBalanceBigButton setTag:10*(i+1)+0];
        [accountBalanceBigButton setTitleColor:COLOR_BLOCKCHAIN_LIGHTEST_BLUE forState:UIControlStateNormal];
        [accountBalanceBigButton addTarget:app action:@selector(toggleSymbol) forControlEvents:UIControlEventTouchUpInside];
        [accountsView addSubview:accountBalanceBigButton];
        
        accountBalanceSmallButton.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [accountBalanceSmallButton.titleLabel setMinimumScaleFactor:.5f];
        [accountBalanceSmallButton.titleLabel setAdjustsFontSizeToFitWidth:YES];
        [accountBalanceSmallButton setTag:10*(i+1)+1];
        [accountBalanceSmallButton setTitleColor:COLOR_BLOCKCHAIN_LIGHTEST_BLUE forState:UIControlStateNormal];
        [accountBalanceSmallButton addTarget:app action:@selector(toggleSymbol) forControlEvents:UIControlEventTouchUpInside];
        [accountsView addSubview:accountBalanceSmallButton];
    }
}

#pragma mark - Button Actions

- (IBAction)toggleDisplayStateClicked:(id)sender
{
    switch (displayState) {
        case DisplayStateMinimized:
            [self setDisplayState:DisplayStateDefault];
            break;
            
        case DisplayStateDefault:
            [self setDisplayState:DisplayStateMaximized];
            break;
            
        case DisplayStateMaximized:
            [self setDisplayState:DisplayStateDefault completion:^(BOOL test) {
                // XCode warns that capturing self strongly in block could lead to retain cycle, but self doesn't capture the block strongly, so we should be fine
                [self setDisplayState:DisplayStateMinimized];
            }];
            break;
    }
}

#pragma mark - Gesture methods

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)recognizer
{
    // Relative movement from starting point
    CGPoint translation = [recognizer translationInView:contentView];
    // Check for the right gesture: must be a vertical gesture
    if (fabsf(translation.y) > fabsf(translation.x)) {
        CGPoint location = [recognizer locationInView:contentView];
        // Not when we are close to the left of the screen - this is reserved for the menu swipe gesture
        if (location.x < 20) {
            return NO;
        }
        
        return YES;
    }
    
    return NO;
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer
{
    // In motion - resize view
    if (recognizer.state == UIGestureRecognizerStateChanged) {
        [self setHeight:[recognizer locationInView:contentView].y];
    }
    
    // Motion finished
    else if (recognizer.state == UIGestureRecognizerStateEnded) {
        // If user moved far enough, animate to that state
        // TODO take velocity into account. Should at least go to min/max on high speed, ideally even with bounce based on speed
        float locationY = [recognizer locationInView:contentView].y;
        if (locationY < HEIGHT_DEFAULT * 0.5) {
            [self setHeight:HEIGHT_MINIMIZED];
        }
        else if (locationY < HEIGHT_MAXIMIZED * 0.7) {
            [self setHeight:HEIGHT_DEFAULT];
        }
        else {
            [self setHeight:HEIGHT_MAXIMIZED];
        }
    }
}

@end
