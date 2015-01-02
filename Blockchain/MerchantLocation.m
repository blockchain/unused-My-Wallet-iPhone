//
//  MerchantLocation.m
//  Blockchain
//
//  Created by User on 12/19/14.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import "MerchantLocation.h"

#import "Merchant.h"

@interface MerchantLocation ()

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

@property (nonatomic, copy) NSString *title;

@end

@implementation MerchantLocation

@synthesize merchant = _merchant;

- (void)setMerchant:(Merchant *)merchant
{
    _merchant = merchant;

    self.coordinate = CLLocationCoordinate2DMake([merchant.latitude floatValue], [merchant.longitude floatValue]);
    self.title = merchant.name;
}

@end
