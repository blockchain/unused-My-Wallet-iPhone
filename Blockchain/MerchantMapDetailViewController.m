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
    
    [self syncViewsWithMerchant];
}

- (void)syncViewsWithMerchant
{
    self.businessNameLbl.text = _merchant.name;
    
    NSString *infoNotAvailable = @"N/A";
    UIColor *textColor = nil;
    NSString *textValue = @"";
    
    if ([_merchant.address length] > 0) {
        textValue = _merchant.address;
        textColor = UIColorFromRGB(0x0f79fb);
    } else {
        textValue = infoNotAvailable;
        textColor = [UIColor blackColor];
    }
    self.addressLbl.text = textValue;
    self.addressLbl.textColor = textColor;
    
    if ([_merchant.city length] > 0) {
        textValue = _merchant.city;
        textColor = UIColorFromRGB(0x0f79fb);
    } else {
        textValue = infoNotAvailable;
        textColor = [UIColor blackColor];
    }
    self.cityLbl.text = textValue;
    self.cityLbl.textColor = textColor;
    
    self.addressControl.userInteractionEnabled = [_merchant.city length] > 0 || [_merchant.address length] > 0;
    
    textColor = [UIColor blackColor];
    if ([_merchant.merchantDescription length] > 0) {
        textValue = _merchant.merchantDescription;
    } else {
        textValue = infoNotAvailable;
    }
    self.descriptionLbl.text = textValue;
    self.descriptionLbl.textColor = textColor;
    
    if ([_merchant.telephone length] > 0) {
        [self.phoneNumber setTitle:_merchant.telephone forState:UIControlStateNormal];
        [self.phoneNumber setTitleColor:UIColorFromRGB(0x0f79fb) forState:UIControlStateNormal];
        self.phoneNumber.userInteractionEnabled = YES;
    } else {
        [self.phoneNumber setTitle:infoNotAvailable forState:UIControlStateNormal];
        [self.phoneNumber setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        self.phoneNumber.userInteractionEnabled = NO;
    }
    
    if ([_merchant.urlString length] > 0) {
        [self.webURL setTitle:_merchant.urlString forState:UIControlStateNormal];
        [self.webURL setTitleColor:UIColorFromRGB(0x0f79fb)forState:UIControlStateNormal];
        self.webURL.userInteractionEnabled = YES;
    } else {
        [self.webURL setTitle:infoNotAvailable forState:UIControlStateNormal];
        [self.webURL setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        self.webURL.userInteractionEnabled = NO;
    }
}

@synthesize merchant = _merchant;

- (void)setMerchant:(Merchant *)merchant
{
    _merchant = merchant;
    
    [self syncViewsWithMerchant];
}

#pragma mark - Actions

- (IBAction)phoneNumberAction:(id)sender
{
    NSString *phoneNumber = [NSString stringWithFormat:@"tel://%@", self.merchant.telephone];
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:phoneNumber]]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumber]];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Operation Not Supported" message:@"This device does not support making phone calls."  delegate:self cancelButtonTitle:BC_STRING_OK otherButtonTitles: nil];
        [alert show];
    }
}

- (IBAction)webURLAction:(id)sender
{
    if ([self.merchant.urlString length] > 0) {
        NSString *merchantURL = self.merchant.urlString;
        NSRange httpRange = [merchantURL rangeOfString:@"http://"];
        if (httpRange.length == 0) {
            merchantURL = [NSString stringWithFormat:@"%@%@", @"http://", merchantURL];
        }
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:merchantURL]]) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:merchantURL]];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Operation Not Supported" message:@"This device does not support this operation."  delegate:self cancelButtonTitle:BC_STRING_OK otherButtonTitles: nil];
            [alert show];
        }
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Address" message:@"We are having troubles opening this Merchant address."  delegate:self cancelButtonTitle:BC_STRING_OK otherButtonTitles: nil];
        [alert show];
    }
}

static NSString *const kMerchantDetailAppleMapsURL = @"http://maps.apple.com";
- (IBAction)openAddressAction:(id)sender
{
    NSString *urlString = @"";
    NSString *queryString = [self.merchant latLongQueryString];
    queryString = @"";
    if ([queryString length] > 0) {
        Class mapItemClass = [MKMapItem class];
        if (mapItemClass && [mapItemClass respondsToSelector:@selector(openMapsWithItems:launchOptions:)])
        {
            CLLocationCoordinate2D coordinate =
            CLLocationCoordinate2DMake([self.merchant.latitude floatValue],[self.merchant.longitude floatValue]);
            MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:coordinate
                                                           addressDictionary:nil];
            MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
            [mapItem setName:self.merchant.name];
            // Get the "Current User Location" MKMapItem
            MKMapItem *currentLocationMapItem = [MKMapItem mapItemForCurrentLocation];
            // Pass the current location and destination map items to the Maps app
            // Set the direction mode in the launchOptions dictionary
            [MKMapItem openMapsWithItems:@[currentLocationMapItem, mapItem]
                           launchOptions:nil];
            urlString = @"";
        } else {
            urlString = [NSString stringWithFormat:@"%@/?ll=%@", kMerchantDetailAppleMapsURL, queryString];
        }
    } else {
        queryString = [self.merchant addressQueryString];
        if ([queryString length] > 0) {
            urlString = [NSString stringWithFormat:@"%@/?q=%@", kMerchantDetailAppleMapsURL, queryString];
        }
    }
    
    if ([urlString length] > 0) {
        urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
    }
}

- (void)closeButtonClicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
