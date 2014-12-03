//
//  MerchantViewController.m
//  Blockchain
//
//  Created by Ben Reeves on 29/07/2014.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import "MerchantViewController.h"
#import "AppDelegate.h"

@interface MerchantViewController ()

@end

@implementation MerchantViewController

- (void)viewDidLoad
{
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
    
    didLoadGoogleMaps = FALSE;
}

- (void)closeButtonClicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)webView:(UIWebView *)_webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType != UIWebViewNavigationTypeOther) {
        if ([[[request URL] host] rangeOfString:@"blockchain.info"].location != NSNotFound) {
            
            NSMutableURLRequest * mutable = [NSMutableURLRequest requestWithURL:[request URL]];
            
            [self addCookiesToRequest:mutable];
            
            [webView loadRequest:mutable];
            
        } else {
            [[UIApplication sharedApplication] openURL:[request URL]];
        }
        
        return FALSE;
    }
    
    return TRUE;
}

- (void)addCookiesToRequest:(NSMutableURLRequest*)request
{
    NSHTTPCookie *no_header_cookie = [NSHTTPCookie cookieWithProperties:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                         @"blockchain.info", NSHTTPCookieDomain,
                                                                         @"\\", NSHTTPCookiePath,  // IMPORTANT!
                                                                         @"no_header", NSHTTPCookieName,
                                                                         @"true", NSHTTPCookieValue,
                                                                         nil]];
    
    
    NSHTTPCookie *no_footer_cookie = [NSHTTPCookie cookieWithProperties:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                         @"blockchain.info", NSHTTPCookieDomain,
                                                                         @"\\", NSHTTPCookiePath,  // IMPORTANT!
                                                                         @"no_footer", NSHTTPCookieName,
                                                                         @"true", NSHTTPCookieValue,
                                                                         nil]];
    
    NSArray* cookies = [NSArray arrayWithObjects: no_header_cookie, no_footer_cookie, nil];
    
    NSDictionary * headers = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
    
    [request setAllHTTPHeaderFields:headers];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    app.loadingText = BC_STRING_LOADING_EXTERNAL_PAGE;
    
    [app networkActivityStart];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [app networkActivityStop];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [app standardNotify:[error localizedDescription]];
    
    [app networkActivityStop];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    DLog(@"LocationManager: didFailWithError: %@", [error description]);
    
    switch ([error code]) {
        case kCLErrorLocationUnknown:{
            DLog(@"LocationManager: location unknown.");
            // This also happens in airplane mode
        }
            break;
        case kCLErrorNetwork:{
            DLog(@"LocationManager: network error.");
            // This is the usual airplane mode/no connection error
        }
            break;
            
        case kCLErrorDenied:{
            DLog(@"LocationManager: denied.");
            // The user has denied location access
        }
            break;
            
        default:{
            DLog(@"LocationManager: unknown location error.");
        }
            break;
    }
    
    // Default to London
    [self setLocation:51.508663f long:-0.117380f];
}

- (void)loadMap
{
    //Throttle load requests
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    if (lastLoadedMap > now - 10.0f) {
        return;
    }
        
    lastLoadedMap = now;
    
    NSError * error = nil;
    NSString * merchantHTML = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"merchant-map" ofType:@"html"] encoding:NSUTF8StringEncoding error:&error];
    
    NSURL * baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath]];
    
    webView.JSDelegate = self;

    [webView loadHTMLString:merchantHTML baseURL:baseURL];

    [self fetchLocation];
}

- (void)didLoadGoogleMaps
{
    didLoadGoogleMaps = TRUE;
}

- (void)setLocation:(float)latitude long:(float)longitude
{
    [webView executeJS:@"MerchantMap.setLocation(%f, %f)", latitude, longitude];
    
    [webView executeJS:@"MerchantMap.zoomToOptimimum()"];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    DLog(@"locationManager didUpdateToLocation: %@", newLocation);
    
    CLLocation *currentLocation = newLocation;
    
    if (currentLocation != nil) {
        [self setLocation:currentLocation.coordinate.latitude long:currentLocation.coordinate.longitude];
    
        //We only need to fetch the location once
        locationManager.delegate = nil;
        [locationManager stopUpdatingLocation];
        locationManager = nil;
    }
}

- (void)log:(NSString*)message
{
    DLog(@"console.log: %@", [message description]);
}

- (IBAction)coffeeClicked:(UIButton*)sender
{
    [sender setSelected:![sender isSelected]];
    
    [self setFilters];
}

- (IBAction)drinkClicked:(UIButton*)sender
{
    [sender setSelected:![sender isSelected]];
    
    [self setFilters];
}

- (IBAction)foodClicked:(UIButton*)sender
{
    [sender setSelected:![sender isSelected]];
    
    [self setFilters];
}

- (IBAction)spendClicked:(UIButton*)sender
{
    [sender setSelected:![sender isSelected]];
    
    [self setFilters];
}

- (IBAction)atmClicked:(UIButton*)sender
{
    [sender setSelected:![sender isSelected]];
    
    [self setFilters];
}

//Called From Javascript
- (void)displayError:(NSString*)message
{
    [app standardNotify:message];
}

- (void)setFilters
{
    int HEADING_CAFE = 1;
    int HEADING_BAR = 2;
    int HEADING_RESTAURANT = 3;
    int HEADING_SPEND = 4;
    int HEADING_ATM = 5;
    
    NSMutableArray * array = [NSMutableArray array];
    
    if (![coffeeButton isSelected])
        [array addObject:[NSNumber numberWithInt:HEADING_CAFE]];
    
    if (![drinkButton isSelected])
        [array addObject:[NSNumber numberWithInt:HEADING_BAR]];

    if (![foodButton isSelected])
        [array addObject:[NSNumber numberWithInt:HEADING_RESTAURANT]];
    
    if (![spendButton isSelected])
        [array addObject:[NSNumber numberWithInt:HEADING_SPEND]];
    
    if (![atmButton isSelected])
        [array addObject:[NSNumber numberWithInt:HEADING_ATM]];
    
    NSMutableString * jsString = [NSMutableString stringWithString:@"["];
   
    for (NSNumber * filter in array) {
        [jsString appendFormat:@"%@,", filter];
    }
    
    if ([jsString characterAtIndex:[jsString length]-1] == ',') {
        [jsString deleteCharactersInRange:NSMakeRange([jsString length]-1, 1)];
    }
    
    [jsString appendString:@"]"];
    
    [webView executeJS:@"MerchantMap.setFilters(%@)", jsString];
}

- (void)fetchLocation
{
    locationManager = [[CLLocationManager alloc] init];
    
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    // For iOS 8 we need to request authorization to get access to the user's location
    if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [locationManager requestWhenInUseAuthorization];
    }
    
    [locationManager startUpdatingLocation];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!didLoadGoogleMaps) {
        [self loadMap];
    }
}

- (void)refresh
{
    if (didLoadGoogleMaps) {
        [self fetchLocation];
    } else {
        [self loadMap];
    }
}

@end
