//
//  SideMenuViewController.m
//  Blockchain
//
//  Created by Mark Pfluger on 10/3/14.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import "SideMenuViewController.h"
#import "AppDelegate.h"
#import "ECSlidingViewController.h"

@interface SideMenuViewController ()

@property (strong, readwrite, nonatomic) UITableView *tableView;

@end

@implementation SideMenuViewController

int menuEntries = 4;
int accountEntries = 0;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIView *topBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, DEFAULT_HEADER_HEIGHT)];
    topBarView.backgroundColor = COLOR_BLOCKCHAIN_BLUE;
    [self.view addSubview:topBarView];
    
    UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"top_menu_logo.png"]];
    logo.frame = CGRectMake(88, 22, 143, 40);
    [topBarView addSubview:logo];
    
    self.tableView = ({
        UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, DEFAULT_HEADER_HEIGHT, self.view.frame.size.width, 54 * menuEntries) style:UITableViewStylePlain];
        tableView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.opaque = NO;
        tableView.backgroundColor = [UIColor clearColor];
        tableView.backgroundView = nil;
        tableView.bounces = NO;
        tableView;
    });
    
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    [self.view addSubview:self.tableView];
    
    ECSlidingViewController *sideMenu = app.slidingViewController;
    sideMenu.delegate = self;
}

// Reset the swipe gestures when view disappears - we have to wait until it's gone and can't do it in the delegate
- (void)viewDidDisappear:(BOOL)animated
{
    [self reset];
}

- (void)reset
{
    // Reset Pan gestures
    for (UIView *view in app.tabViewController.activeViewController.view.subviews) {
        [view setUserInteractionEnabled:YES];
    }
    
    ECSlidingViewController *sideMenu = app.slidingViewController;
    [app.tabViewController.activeViewController.view removeGestureRecognizer:sideMenu.panGesture];
    
    [app.tabViewController.menuSwipeRecognizerView setUserInteractionEnabled:YES];
    [app.tabViewController.menuSwipeRecognizerView addGestureRecognizer:sideMenu.panGesture];
    
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:app action:@selector(swipeLeft)];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:app action:@selector(swipeRight)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    
    [app.tabViewController.activeViewController.view addGestureRecognizer:swipeLeft];
    [app.tabViewController.activeViewController.view addGestureRecognizer:swipeRight];
}

- (void)reload
{
    // Account entries: 1 entry for the total balance, 1 for each HD account, 1 for the total legacy addresses balance (if needed)
    accountEntries = 1 + app.wallet.getAccountsCount + ([app.wallet hasLegacyAddresses] ? 1 : 0);
    
    self.tableView.frame = CGRectMake(0, DEFAULT_HEADER_HEIGHT, self.view.frame.size.width, 54 * (menuEntries + accountEntries));
    
    [self.tableView reloadData];
}

#pragma mark - SlidingViewController Delegate

- (id<UIViewControllerAnimatedTransitioning>)slidingViewController:(ECSlidingViewController *)slidingViewController animationControllerForOperation:(ECSlidingViewControllerOperation)operation topViewController:(UIViewController *)topViewController
{
    // SideMenu will slide in
    if (operation == ECSlidingViewControllerOperationAnchorRight) {
        // Enable Pan gesture to close sideMenu on tabViewController and disable all other interactions
        for (UIView *view in app.tabViewController.activeViewController.view.subviews) {
            [view setUserInteractionEnabled:NO];
        }
        [app.tabViewController.menuSwipeRecognizerView setUserInteractionEnabled:NO];
        
        [app.tabViewController.activeViewController.view setUserInteractionEnabled:YES];
        ECSlidingViewController *sideMenu = app.slidingViewController;
        [app.tabViewController.activeViewController.view addGestureRecognizer:sideMenu.panGesture];
        
        // Show shadow on current viewController in tabBarView
        UIView *castsShadowView = app.slidingViewController.topViewController.view;
        castsShadowView.layer.shadowOpacity = 0.3f;
        castsShadowView.layer.shadowRadius = 10.0f;
        castsShadowView.layer.shadowColor = [UIColor blackColor].CGColor;
        
        // Old one - shadow is over topViewController
        //        UIView *grayOverlayView = [[UIView alloc] initWithFrame:CGRectMake(0, DEFAULT_HEADER_HEIGHT, _window.frame.size.width, _window.frame.size.height)];
        //        grayOverlayView.backgroundColor = [UIColor blackColor];
        //        grayOverlayView.tag = 200;
        //        grayOverlayView.alpha = 0.0;
        //        [_tabViewController.view addSubview:grayOverlayView];
        //        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        //            grayOverlayView.alpha = 0.165;
        //        }];
        //
        //        CAGradientLayer *l = [CAGradientLayer layer];
        //        l.frame = grayOverlayView.bounds;
        //        l.colors = [NSArray arrayWithObjects:(id)[UIColor whiteColor].CGColor, (id)[UIColor clearColor].CGColor, nil];
        //        l.startPoint = CGPointMake(0.0f, 1.0f);
        //        l.endPoint = CGPointMake(0.05f, 1.0f);
        //        grayOverlayView.layer.mask = l;

    }
    // SideMenu will slide out
    else if (operation == ECSlidingViewControllerOperationResetFromRight) {
        // Everything happens in viewDidDisappear: which is called after the slide animation is done
    }
    
    return nil;
}

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        return;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSInteger row = indexPath.row;
    
    const int settings = 0;
    const int news = 1;
    const int changePin = 2;
    const int logout = 3;
    
    switch (row) {
        case settings:
            [app accountSettingsClicked:nil];
            break;
            
        case news:
            [app newsClicked:nil];
            break;
            
        case changePin:
            [app changePINClicked:nil];
            break;
            
        case logout:
            [app logoutClicked:nil];
            break;
            
        default:
            break;
    }
    
    [self reset];
    
    [app toggleSideMenu];
}

#pragma mark - UITableView Datasource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    if (sectionIndex == 0) {
        return menuEntries;
    }
    
    return accountEntries;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier;
    
    if (indexPath.section == 0) {
        cellIdentifier = @"CellMenu";
    }
    else {
        cellIdentifier = @"CellBalance";
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:17.0];
        cell.textLabel.textColor = [UIColor lightGrayColor];
        cell.textLabel.highlightedTextColor = [UIColor whiteColor];
        
        UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height)];
        [v setBackgroundColor:COLOR_BLOCKCHAIN_BLUE];
        cell.selectedBackgroundView = v;
        
        if (indexPath.section == 1) {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            cell.textLabel.font = [UIFont boldSystemFontOfSize:20.0];
            cell.textLabel.textColor = COLOR_BLOCKCHAIN_LIGHT_BLUE;
            
            cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:12.0];
            cell.detailTextLabel.textColor = COLOR_BLOCKCHAIN_LIGHT_BLUE;
        }
    }
    
    if (indexPath.section == 0) {
        NSArray *titles;
        NSArray *images;
        titles = @[BC_STRING_ACCOUNT_SETTINGS, BC_STRING_NEWS_PRICE_CHARTS, BC_STRING_CHANGE_PIN, BC_STRING_LOGOUT];
        images = @[@"settings_icon", @"news_icon.png", @"lock_icon", @"logout_icon"];
        
        cell.textLabel.text = titles[indexPath.row];
        cell.imageView.image = [UIImage imageNamed:images[indexPath.row]];
    }
    else {
        if (indexPath.row == 0) {
            uint64_t totalBalance = app.latestResponse.final_balance;
            
            cell.textLabel.text = [app formatMoney:totalBalance localCurrency:app->symbolLocal];
            cell.detailTextLabel.text = @"Total Balance";
        }
        else if (indexPath.row < accountEntries-1) {
            uint64_t accountBalance = [app.wallet getBalanceForAccount:indexPath.row-1];
            
            cell.textLabel.text = [app formatMoney:accountBalance localCurrency:app->symbolLocal];
            cell.detailTextLabel.text = [app.wallet getLabelForAccount:indexPath.row-1];
        }
        else {
            uint64_t legacyBalance = [app.wallet getTotalBalanceForActiveLegacyAddresses];
            
            cell.textLabel.text = [app formatMoney:legacyBalance localCurrency:app->symbolLocal];
            cell.detailTextLabel.text = @"Imported Addresses";
        }
    }
    
    return cell;
}

@end
