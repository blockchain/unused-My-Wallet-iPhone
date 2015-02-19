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
#import "BCCreateAccountView.h"
#import "BCEditAccountView.h"
#import "AccountTableCell.h"
#import "BCLine.h"

#define SECTION_HEADER_HEIGHT 44

#define MENU_ENTRY_HEIGHT 54
#define BALANCE_ENTRY_HEIGHT 58

@interface SideMenuViewController ()

@property (strong, readwrite, nonatomic) UITableView *tableView;

@end

@implementation SideMenuViewController

ECSlidingViewController *sideMenu;

int menuEntries = 4;
int balanceEntries = 0;
int accountEntries = 0;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    sideMenu = app.slidingViewController;
    
    self.tableView = ({
        UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - sideMenu.anchorLeftPeekAmount, MENU_ENTRY_HEIGHT * menuEntries) style:UITableViewStylePlain];
        tableView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.opaque = NO;
        tableView.backgroundColor = [UIColor clearColor];
        tableView.backgroundView = nil;
        tableView;
    });
    
    [self.view addSubview:self.tableView];
    
    // Blue background for bounce area
    CGRect frame = self.view.bounds;
    frame.origin.y = -frame.size.height;
    UIView* blueView = [[UIView alloc] initWithFrame:frame];
    blueView.backgroundColor = COLOR_BLOCKCHAIN_BLUE;
    [self.tableView addSubview:blueView];
    // Make sure the refresh contorl is in front of the blue area
    blueView.layer.zPosition -= 1;
    
    sideMenu.delegate = self;
}

// Reset the swipe gestures when view disappears - we have to wait until it's gone and can't do it in the delegate
- (void)viewDidDisappear:(BOOL)animated
{
    [self resetSideMenuGestures];
}

- (void)resetSideMenuGestures
{
    // Show status bar again
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:YES];
    
    // Reset Pan gestures
    for (UIView *view in app.tabViewController.activeViewController.view.subviews) {
        [view setUserInteractionEnabled:YES];
    }
    
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
    // Total entries: 1 entry for the total balance, 1 for each HD account, 1 for the total legacy addresses balance (if needed)
    balanceEntries = [app.wallet getAccountsCount] + ([app.wallet hasLegacyAddresses] ? 1 : 0);
    accountEntries = [app.wallet getAccountsCount];
    
    menuEntries = [app.wallet getAccountsCount] > 0 ? 4 : 5;
    
    // Resize table view
    self.tableView.frame = CGRectMake(0, 0, self.view.frame.size.width - sideMenu.anchorLeftPeekAmount, MENU_ENTRY_HEIGHT * menuEntries + BALANCE_ENTRY_HEIGHT * (balanceEntries + 1) + SECTION_HEADER_HEIGHT);
    
    // If the tableView is bigger than the screen, enable scrolling and resize table view to screen size
    if (self.tableView.frame.size.height > self.view.frame.size.height ) {
        self.tableView.frame = CGRectMake(0, 0, self.view.frame.size.width - sideMenu.anchorLeftPeekAmount, self.view.frame.size.height);
        
        // Add some extra space to bottom of tableview so things look nicer when scrolling all the way down
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, SECTION_HEADER_HEIGHT, 0);
        
        self.tableView.scrollEnabled = YES;
    }
    else {
        self.tableView.scrollEnabled = NO;
    }
    
    [self.tableView reloadData];
}

#pragma mark - SlidingViewController Delegate

- (id<UIViewControllerAnimatedTransitioning>)slidingViewController:(ECSlidingViewController *)slidingViewController animationControllerForOperation:(ECSlidingViewControllerOperation)operation topViewController:(UIViewController *)topViewController
{
    // SideMenu will slide in
    if (operation == ECSlidingViewControllerOperationAnchorRight) {
        // No status bar
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:NO];
        
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
    if (indexPath.section != 2) {
        return;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSInteger row = indexPath.row;
    
    const int settings = 0;
    const int news = 1;
    const int changePin = 2;
    const int logout = 3;
    const int upgradeToHD = 4;
    
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
        
        case upgradeToHD:
            [app showHdUpgrade];
            break;
            
        default:
            break;
    }
    
    [self resetSideMenuGestures];
    
    [app toggleSideMenu];
}

#pragma mark - UITableView Datasource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != 2) {
        return BALANCE_ENTRY_HEIGHT;
    }
    return MENU_ENTRY_HEIGHT;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 1 && accountEntries > 0) {
        return SECTION_HEADER_HEIGHT;
    }
    
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    // My Accounts
    if (section == 1 && accountEntries > 0) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, SECTION_HEADER_HEIGHT)];
        view.backgroundColor = COLOR_BLOCKCHAIN_BLUE;
        
        BCLine *topSeparator = [[BCLine alloc] initWithFrame:CGRectMake(56, 0, self.tableView.frame.size.width, 1.0/[UIScreen mainScreen].scale)];
        topSeparator.backgroundColor = [UIColor whiteColor];
        [view addSubview:topSeparator];
        
        UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"wallet.png"]];
        icon.frame = CGRectMake(18, 13, 20, 18);
        [view addSubview:icon];
        
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(56, 0, self.tableView.frame.size.width - 56, SECTION_HEADER_HEIGHT)];
        headerLabel.text = BC_STRING_MY_ACCOUNTS;
        headerLabel.textColor = [UIColor whiteColor];
        headerLabel.font = [UIFont boldSystemFontOfSize:17.0];
        [view addSubview:headerLabel];
        
        UIButton *addButton = [[UIButton alloc] initWithFrame:CGRectMake(self.tableView.frame.size.width - sideMenu.anchorLeftPeekAmount + 2, 2, 40, 40)];
        [addButton setImage:[UIImage imageNamed:@"new"] forState:UIControlStateNormal];
        [addButton addTarget:self action:@selector(addAccountClicked:) forControlEvents:UIControlEventTouchUpInside];
        [view addSubview:addButton];
        
        BCLine *bottomSeparator = [[BCLine alloc] initWithFrame:CGRectMake(56, SECTION_HEADER_HEIGHT, self.tableView.frame.size.width, 1.0/[UIScreen mainScreen].scale)];
        bottomSeparator.backgroundColor = [self.tableView separatorColor];
        [view addSubview:bottomSeparator];
        
        return view;
    }
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    if (sectionIndex == 0) {
        return 1;
    }
    if (sectionIndex == 1) {
        return menuEntries;
    }
    
    return balanceEntries;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier;
    
    if (indexPath.section == 2) {
        cellIdentifier = @"CellMenu";
        
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
        }
        
        NSMutableArray *titles;
        NSMutableArray *images;
        titles = [NSMutableArray arrayWithArray:@[BC_STRING_SETTINGS, BC_STRING_NEWS_PRICE_CHARTS, BC_STRING_CHANGE_PIN, BC_STRING_LOGOUT]];
        images = [NSMutableArray arrayWithArray:@[@"settings_icon", @"news_icon.png", @"lock_icon", @"logout_icon"]];
        
        if ([app.wallet getAccountsCount] == 0 ) {
            [titles addObject:BC_STRING_UPGRADE_TO_HD];
            [images addObject:@"settings_icon"];
        }
        
        cell.textLabel.text = titles[indexPath.row];
        cell.imageView.image = [UIImage imageNamed:images[indexPath.row]];
        
        if (indexPath.row == 0 && app.showEmailWarning) {
            cell.detailTextLabel.font = [UIFont systemFontOfSize:12.0];
            cell.detailTextLabel.textColor = [UIColor redColor];
            cell.detailTextLabel.text = BC_STRING_ADD_EMAIL;
        }
        else {
            cell.detailTextLabel.text = nil;
        }
        
        return cell;
    }
    else {
        cellIdentifier = @"CellBalance";
        
        AccountTableCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if (cell == nil) {
            cell = [[AccountTableCell alloc] init];
            cell.backgroundColor = COLOR_BLOCKCHAIN_BLUE;
            
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        // Total balance
        if (indexPath.section == 0 && indexPath.row == 0) {
            uint64_t totalBalance = app.latestResponse.final_balance;
            
            cell.amountLabel.text = [app formatMoney:totalBalance localCurrency:app->symbolLocal];
            cell.labelLabel.text = BC_STRING_TOTAL_BALANCE;
            cell.editButton.hidden = YES;
        }
        // Account balances
        else if (indexPath.row < accountEntries) {
            int accountIdx = (int) indexPath.row;
            uint64_t accountBalance = [app.wallet getBalanceForAccount:accountIdx];
            
            cell.amountLabel.text = [app formatMoney:accountBalance localCurrency:app->symbolLocal];
            cell.labelLabel.text = [app.wallet getLabelForAccount:accountIdx];
            cell.accountIdx = accountIdx;
        }
        // Total legacy balance
        else {
            uint64_t legacyBalance = [app.wallet getTotalBalanceForActiveLegacyAddresses];
            
            [cell.iconImage setImage:[UIImage imageNamed:@"importedaddress"]];
            cell.amountLabel.text = [app formatMoney:legacyBalance localCurrency:app->symbolLocal];
            cell.labelLabel.text = BC_STRING_IMPORTED_ADDRESSES;
            cell.editButton.hidden = YES;
        }
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Custom separator inset
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        float leftInset = (indexPath.section != 2) ? 56 : 15;
        [cell setSeparatorInset:UIEdgeInsetsMake(0, leftInset, 0, 0)];
    }
    
    // No separator for last entry of each section
    if ((indexPath.section == 1 && indexPath.row == balanceEntries - 1) ||
        (indexPath.section == 2 && indexPath.row == menuEntries - 1)) {
        [cell setSeparatorInset:UIEdgeInsetsMake(0, 15, 0, CGRectGetWidth(cell.bounds)-15)];
    }
}

# pragma mark - Button actions

- (IBAction)addAccountClicked:(id)sender
{
    BCCreateAccountView *createAccountView = [[BCCreateAccountView alloc] init];
    
    [app showModalWithContent:createAccountView closeType:ModalCloseTypeClose headerText:BC_STRING_CREATE_ACCOUNT];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [createAccountView.labelTextField becomeFirstResponder];
    });
}

@end
