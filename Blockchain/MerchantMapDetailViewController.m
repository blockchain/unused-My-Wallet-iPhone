//
//  MerchantMapDetailViewController.m
//  Blockchain
//
//  Created by User on 1/2/15.
//  Copyright (c) 2015 Qkos Services Ltd. All rights reserved.
//

#import "MerchantMapDetailViewController.h"

#import "AppDelegate.h"

#import "Merchant.h"

#import <MapKit/MapKit.h>

@interface MerchantMapDetailViewController ()

@property (weak, nonatomic) IBOutlet UILabel *businessNameLbl;
@property (weak, nonatomic) IBOutlet UILabel *addressLbl;
@property (weak, nonatomic) IBOutlet UILabel *cityLbl;
@property (weak, nonatomic) IBOutlet UIControl *addressControl;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLbl;
@property (weak, nonatomic) IBOutlet UIButton *phoneNumber;
@property (weak, nonatomic) IBOutlet UIButton *webURL;

@end

@implementation MerchantMapDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.frame = CGRectMake(0, 0, app.window.frame.size.width, app.window.frame.size.height - DEFAULT_HEADER_HEIGHT);
    
    UIView *topBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, DEFAULT_HEADER_HEIGHT)];
    topBarView.backgroundColor = COLOR_BLOCKCHAIN_BLUE;
    [self.view addSubview:topBarView];
    
    UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"top_menu_logo.png"]];
    logo.frame = CGRectMake(88, 22, 143, 40);
    [topBarView addSubview:logo];
    
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 70, 15, 80, 51)];
    [closeButton setTitle:BC_STRING_CLOSE forState:UIControlStateNormal];
    [closeButton setTitleColor:[UIColor colorWithWhite:0.56 alpha:1.0] forState:UIControlStateHighlighted];
    closeButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [closeButton addTarget:self action:@selector(closeButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [topBarView addSubview:closeButton];
    
    self.businessNameLbl.text = self.merchant.name;
    self.addressLbl.text = self.merchant.address;
    self.cityLbl.text = self.merchant.city;
    self.descriptionLbl.text = self.merchant.merchantDescription;
    [self.phoneNumber setTitle:self.merchant.telephone forState:UIControlStateNormal];
}

@synthesize merchant = _merchant;

- (void)setMerchant:(Merchant *)merchant
{
    _merchant = merchant;
    
    self.businessNameLbl.text = _merchant.name;
    self.addressLbl.text = _merchant.address;
    self.cityLbl.text = _merchant.city;
    self.descriptionLbl.text = _merchant.merchantDescription;
    [self.phoneNumber setTitle:_merchant.telephone forState:UIControlStateNormal];
}

#pragma mark - Actions

- (IBAction)phoneNumberAction:(id)sender
{
    NSString *phoneNumber = [NSString stringWithFormat:@"tel://%@", self.merchant.telephone];
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:phoneNumber]]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumber]];
    }
}

- (void)closeButtonClicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
