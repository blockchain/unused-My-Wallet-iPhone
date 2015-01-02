//
//  MerchantMapViewController.m
//  Blockchain
//
//  Created by User on 12/18/14.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import "MerchantMapViewController.h"

#import "MerchantMapDetailViewController.h"

#import "Merchant.h"

#import "MerchantLocation.h"

#import "AppDelegate.h"

#import "NSString+JSONParser_NSString.h"

#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

#define METERS_PER_MILE 1609.344

@interface MerchantMapViewController () <CLLocationManagerDelegate, UIGestureRecognizerDelegate, MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (assign, nonatomic) CLLocationCoordinate2D location;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *startLocation;

@property (strong, nonatomic) NSMutableDictionary *allMerchants;
@property (strong, nonatomic) NSMutableDictionary *merchantsLocationAnnotations;
@property (strong, nonatomic) NSArray *filteredMerchants;

@property (strong, nonatomic) NSDictionary *visibleMerchantTypes;

@property (strong, nonatomic) NSOperationQueue *merchantLocationNetworkQueue;

@property (assign, nonatomic) MKMapRect lastUserRect;

@end

@implementation MerchantMapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.merchantLocationNetworkQueue = [[NSOperationQueue alloc] init];
    [self.merchantLocationNetworkQueue setName:@"com.blockchain.merchantQueue"];
    
    self.allMerchants = [[NSMutableDictionary alloc] init];
    self.merchantsLocationAnnotations = [[NSMutableDictionary alloc] init];
    self.visibleMerchantTypes = [[NSMutableDictionary alloc] init];
    
    // Adding filter to indicate what business types to display, by default we show all of them
    // We store "merchant categories" and mark the category as visible by setting the "value" to "1".  If we want to
    // hide the category we set it to @0
    [self.visibleMerchantTypes setValue:@1 forKey:[NSString stringWithFormat:@"%lu", (unsigned long)BCMerchantLocationTypeBeverage]];
    [self.visibleMerchantTypes setValue:@1 forKey:[NSString stringWithFormat:@"%lu", BCMerchantLocationTypeBar]];
    [self.visibleMerchantTypes setValue:@1 forKey:[NSString stringWithFormat:@"%lu", BCMerchantLocationTypeFood]];
    [self.visibleMerchantTypes setValue:@1 forKey:[NSString stringWithFormat:@"%lu", BCMerchantLocationTypeBusiness]];
    [self.visibleMerchantTypes setValue:@1 forKey:[NSString stringWithFormat:@"%lu", BCMerchantLocationTypeOther]];

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

    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    
    // Needed for iOS 8 to check permissions, if the user has already accepted then the request will
    // be called back with the accepted state
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
        if (authorizationStatus != kCLAuthorizationStatusAuthorizedAlways || authorizationStatus != kCLAuthorizationStatusAuthorizedWhenInUse || authorizationStatus != kCLAuthorizationStatusAuthorized) {
            [self.locationManager requestWhenInUseAuthorization];
        } else {
            [self.locationManager startUpdatingLocation];
        }
    } else {
        // Prior to iOS 8 we can just call updating location
        self.mapView.showsUserLocation = YES;
        
        [self.locationManager startUpdatingLocation];
    }
    
    // Adding gesture recognizer so we know when to update the pin locations
    UIPanGestureRecognizer* panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(userUpdatedMapBounds:)];
    [panGestureRecognizer setDelegate:self];
    [self.mapView addGestureRecognizer:panGestureRecognizer];
}

- (void)dealloc
{
    [self.locationManager stopUpdatingLocation];
}

- (void)clearMechantAnnotations
{
    for (id <MKAnnotation> annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[MerchantLocation class]]) {
            [self.mapView removeAnnotation:annotation];
        }
    }
    [self.merchantsLocationAnnotations removeAllObjects];
}

static NSString *const kBlockchainNearByMerchantsURL = @"http://merchant-directory.blockchain.info/api/list_near_merchants.php";

- (void)updateDisplayedMerchantsAtCoordinate:(CLLocationCoordinate2D)coordinate
{
    NSString *urlString = [NSString stringWithFormat:@"%@?ULAT=%f&ULON=%f&D=5&K=1", kBlockchainNearByMerchantsURL, coordinate.latitude, coordinate.longitude];
    
    NSLog(@"%@", urlString);
    
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:self.merchantLocationNetworkQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError) {
            DLog(@"Error retrieving Merchants near location (Long)%f, (Lat)%f", coordinate.longitude, coordinate.latitude);
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *error = nil;
                NSArray *merchantData = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                for (NSDictionary *merchantDict in merchantData) {
                    Merchant *merchant = [Merchant merchantWithDict:merchantDict];
                    [self.allMerchants setObject:merchant forKey:merchant.merchantId];
                }
                [self displayFilteredMerchants];
            });
        }
    }];
}

- (void)displayFilteredMerchants
{
    // Filtering out displayable merchants from all the merchants we know about
    NSMutableArray *merchantsToAdd = [NSMutableArray arrayWithArray:[self.allMerchants allValues]];
    NSMutableArray *merchantsToRemove = [NSMutableArray new];
    for (Merchant *merchant in [self.allMerchants allValues]) {
        NSString *merchantType = [NSString stringWithFormat:@"%lu", merchant.locationType];
        if ([[self.visibleMerchantTypes objectForKey:merchantType]  isEqual: @0]) {
            [merchantsToRemove addObject:merchant];
        }
    }
    
    // Removing the merchant from our collection and the mapview
    for (Merchant *merchant in merchantsToRemove) {
        MerchantLocation *location = [self.merchantsLocationAnnotations objectForKey:merchant.merchantId];
        [self.mapView removeAnnotation:location];
        [merchantsToAdd removeObject:merchant];
        [self.merchantsLocationAnnotations removeObjectForKey:merchant.merchantId];
    }
    
    self.filteredMerchants = [merchantsToAdd copy];
    
    // Adding new merchant annotations back to the map if they aren't on the map already
    dispatch_async(dispatch_get_main_queue(), ^{
        for (Merchant *merchant in self.filteredMerchants) {
            if (![self.merchantsLocationAnnotations objectForKey:merchant.merchantId]) {
                MerchantLocation *location = [[MerchantLocation alloc] init];
                location.merchant = merchant;
                [self.merchantsLocationAnnotations setObject:location forKey:merchant.merchantId];
                [self.mapView addAnnotation:location];
            }
        }
    });
}

#pragma mark Actions

- (void)closeButtonClicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)cafeAction:(id)sender
{
    [self toggleFilterForMerchantType:BCMerchantLocationTypeBeverage imageName:@"cafe" sender:sender];
}

- (IBAction)drinkAction:(id)sender
{
    [self toggleFilterForMerchantType:BCMerchantLocationTypeBar imageName:@"drink" sender:sender];
}

- (IBAction)eatAction:(id)sender
{
    [self toggleFilterForMerchantType:BCMerchantLocationTypeFood imageName:@"eat" sender:sender];
}

- (IBAction)spendAction:(id)sender
{
    [self toggleFilterForMerchantType:BCMerchantLocationTypeBusiness imageName:@"spend" sender:sender];
}

- (IBAction)atmAction:(id)sender
{
    [self toggleFilterForMerchantType:BCMerchantLocationTypeOther imageName:@"atm" sender:sender];
}

- (void)toggleFilterForMerchantType:(BCMerchantLocationType)locationType imageName:(NSString *)imageName sender:(id)sender
{
    UIButton *button = (UIButton *)sender;
    NSString *merchantType = [NSString stringWithFormat:@"%lu", locationType];
    if ([[self.visibleMerchantTypes objectForKey:merchantType]  isEqual: @1]) {
        // We need to deactivate it
        [self.visibleMerchantTypes setValue:@0 forKey:merchantType];
        [button setImage:[UIImage imageNamed:[NSString stringWithFormat:@"marker_%@_off", imageName]] forState:UIControlStateNormal];
    } else {
        // Activate it
        [self.visibleMerchantTypes setValue:@1 forKey:merchantType];
        [button setImage:[UIImage imageNamed:[NSString stringWithFormat:@"marker_%@", imageName]] forState:UIControlStateNormal];
    }
    [self displayFilteredMerchants];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

// These minimum delta values are in projected map values
static const CGFloat kMerchantMapMinimumHorizontalDelta = 15000;
static const CGFloat kMerchantMapMinimumVerticalDelta = 15000;

- (void)userUpdatedMapBounds:(UIGestureRecognizer*)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded){
        MKMapRect currentMapRect = self.mapView.visibleMapRect;
        
        if (abs(currentMapRect.origin.x - self.lastUserRect.origin.x) > kMerchantMapMinimumHorizontalDelta || abs(currentMapRect.origin.y - self.lastUserRect.origin.y) > kMerchantMapMinimumVerticalDelta) {
            [self updateDisplayedMerchantsAtCoordinate:self.mapView.centerCoordinate];
            
            self.lastUserRect = currentMapRect;
        }
    }
}

#pragma mark - CCLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status != kCLAuthorizationStatusDenied) {
        self.mapView.showsUserLocation = YES;

        [self.locationManager startUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    DLog(@"LocationManager: didFailWithError: %@", [error description]);
    
    [self.locationManager stopUpdatingLocation];

    switch ([error code]) {
        case kCLErrorLocationUnknown:{
            // This also happens in airplane mode
            DLog(@"LocationManager: location unknown.");
        }
        break;
        case kCLErrorNetwork:{
            // This is the usual airplane mode/no connection error
            DLog(@"LocationManager: network error.");
        }
        break;
        case kCLErrorDenied:{
            // The user has denied location access
            DLog(@"LocationManager: denied.");
        }
        break;
        default:{
            DLog(@"LocationManager: unknown location error.");
        }
        break;
    }
    
    // Default to London
    CLLocationCoordinate2D londonCoordinate;
    londonCoordinate.latitude = 51.508663f;
    londonCoordinate.longitude = -0.117380f;
    [self showUserOnMapAtLocation:londonCoordinate];
    [self updateDisplayedMerchantsAtCoordinate:londonCoordinate];
}

- (void)showUserOnMapAtLocation:(CLLocationCoordinate2D)location
{
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(location, 0.2 * METERS_PER_MILE, 5 * METERS_PER_MILE);
    [_mapView setRegion:viewRegion animated:YES];
}

#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if (!self.startLocation) {
        self.startLocation = userLocation.location;
        
        // We need to update the merchant locations on the map
        CLLocationCoordinate2D userLocationCoordinate;
        
        userLocationCoordinate.latitude = userLocation.coordinate.latitude;
        userLocationCoordinate.longitude = userLocation.coordinate.longitude;
        
        [self showUserOnMapAtLocation:userLocationCoordinate];
        [self updateDisplayedMerchantsAtCoordinate:userLocationCoordinate];
    }
}

- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView
{
    DLog(@"MapView didFinishLoadingMap");
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    static NSString *identifier = @"MerchantLocation";
    
    if ([annotation isKindOfClass:[MerchantLocation class]]) {
        UIImage *pinImage;
        MKAnnotationView *annotationView = (MKAnnotationView *) [_mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (annotationView == nil) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
            annotationView.enabled = YES;
            annotationView.canShowCallout = YES;
            UIButton* infoButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            [infoButton setFrame:CGRectMake(0, 0, CGRectGetWidth(infoButton.frame) + 10, CGRectGetHeight(infoButton.frame))];
            [infoButton setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleTopMargin];
            [annotationView setRightCalloutAccessoryView:infoButton];
        }
        
        MerchantLocation *merchantLocation = (MerchantLocation *)annotation;
        switch (merchantLocation.merchant.locationType) {
            case BCMerchantLocationTypeBeverage:
                pinImage = [UIImage imageNamed:@"marker_cafe"];
                break;
            case BCMerchantLocationTypeBar:
                pinImage = [UIImage imageNamed:@"marker_drink"];
                break;
            case BCMerchantLocationTypeFood:
                pinImage = [UIImage imageNamed:@"marker_eat"];
                break;
            case BCMerchantLocationTypeBusiness:
                pinImage = [UIImage imageNamed:@"marker_spend"];
                break;
            case BCMerchantLocationTypeOther:
                pinImage = [UIImage imageNamed:@"marker_atm"];
                break;
            default:
                break;
        }
        
        annotationView.image = pinImage;
        
        return annotationView;
    }
    
    return nil;
}

- (void)mapView:(MKMapView *)map annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    if ([view.annotation isKindOfClass:[MerchantLocation class]]) {
        MerchantMapDetailViewController *merchantDetail = [[MerchantMapDetailViewController alloc] initWithNibName:@"MerchantDetailView" bundle:[NSBundle mainBundle]];
        MerchantLocation *merchantLocation = view.annotation;
        merchantDetail.merchant = merchantLocation.merchant;
        [self presentViewController:merchantDetail animated:YES completion:nil];
    }
}


@end
