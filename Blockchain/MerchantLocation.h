//
//  MerchantLocation.h
//  Blockchain
//
//  Created by User on 12/19/14.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class Merchant;

@interface MerchantLocation : NSObject <MKAnnotation>

@property (nonatomic, strong) Merchant *merchant;

// MKAnnotation

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *subtitle;

@end
