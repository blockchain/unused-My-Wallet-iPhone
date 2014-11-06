//
//  MerchantViewController.h
//  Blockchain
//
//  Created by Ben Reeves on 29/07/2014.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "JSBridgeWebView.h"

@interface MerchantViewController : UIViewController <UIWebViewDelegate, JSBridgeWebViewDelegate, CLLocationManagerDelegate> {
    IBOutlet JSBridgeWebView *webView;
    CLLocationManager *locationManager;
    
    IBOutlet UIButton *coffeeButton;
    IBOutlet UIButton *drinkButton;
    IBOutlet UIButton *foodButton;
    IBOutlet UIButton *spendButton;
    IBOutlet UIButton *atmButton;
    
    NSTimeInterval lastLoadedMap;
    BOOL didLoadGoogleMaps;
}

- (void)setLocation:(float)latitude long:(float)longitude;

- (IBAction)coffeeClicked:(UIButton*)sender;
- (IBAction)drinkClicked:(UIButton*)sender;
- (IBAction)foodClicked:(UIButton*)sender;
- (IBAction)spendClicked:(UIButton*)sender;
- (IBAction)atmClicked:(UIButton*)sender;

- (void)refresh;

@end
