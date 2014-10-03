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

int entries = 4;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIView *topBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 66)];
    topBarView.backgroundColor = COLOR_BLOCKCHAIN_BLUE;
    [self.view addSubview:topBarView];
    
//    UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"top_menu_logo.png"]];
//    logo.frame = CGRectMake(88, 22, 143, 40);
//    [topBarView addSubview:logo];
    
    self.tableView = ({
        UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 66, self.view.frame.size.width, 54 * entries) style:UITableViewStylePlain];
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
}

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSInteger row = indexPath.row;
    
    const int news = 0;
    const int settings = 1;
    const int changePin = 2;
    const int logout = 3;
    
    switch (row) {
        case news:
        {
            [app newsClicked:nil];
        }
        break;
        
        case settings:
        {
            [app accountSettingsClicked:nil];
        }
        break;
        
        case changePin:
        {
            [app changePINClicked:nil];
        }
        break;
        case logout:
        {
            [app logoutClicked:nil];
        }
        break;
        
        default:
        break;
    }
    
    [app toggleSideMenu];
}

#pragma mark - UITableView Datasource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    return entries;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    
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
    
    if (indexPath.row == 2) {
        
    }
    
    NSArray *titles;
    NSArray *images;
    // TODO i18n
    titles = @[@"News, Price & Charts", @"Wallet Settings", @"Change PIN", @"Logout"];
    images = @[@"news_icon.png", @"settings_icon", @"lock_icon", @"logout_icon"];

    cell.textLabel.text = titles[indexPath.row];
    cell.imageView.image = [UIImage imageNamed:images[indexPath.row]];
    
    return cell;
}

@end
