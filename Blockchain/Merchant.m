//
//  Merchant.m
//  Blockchain
//
//  Created by User on 12/18/14.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import "Merchant.h"

#import "Foundation-Utility.h"

NSString *const kMerchantIdKey = @"id";
NSString *const kMerchantNameKey = @"name";
NSString *const kMerchantAdressKey = @"address";
NSString *const kMerchantCityKey = @"city";
NSString *const kMerchantPCodeKey = @"pcode";
NSString *const kMerchantTelphoneKey = @"tel";
NSString *const kMerchantURLKey = @"web";
NSString *const kMerchantLatitudeKey = @"lat";
NSString *const kMerchantLongitudeKey = @"lon";
NSString *const kMerchantTypeKey = @"hc";
NSString *const kMerchantDescriptionKey = @"desc";
NSString *const kMerchantDistanceKey = @"distance";

@interface Merchant ()

@property (assign, nonatomic) BCMerchantLocationType locationType;

@end

@implementation Merchant

+ (Merchant *)merchantWithDict:(NSDictionary *)dict
{
    Merchant *merchant = [[Merchant alloc] init];

    merchant.merchantId = [dict safeObjectForKey:kMerchantIdKey];
    merchant.name = [dict safeObjectForKey:kMerchantNameKey];
    merchant.address = [dict safeObjectForKey:kMerchantAdressKey];
    merchant.city = [dict safeObjectForKey:kMerchantCityKey];
    merchant.pcode = [dict safeObjectForKey:kMerchantPCodeKey];
    merchant.telephone = [dict safeObjectForKey:kMerchantTelphoneKey];
    merchant.urlString = [dict safeObjectForKey:kMerchantURLKey];
    merchant.latitude = [dict safeObjectForKey:kMerchantLatitudeKey];
    merchant.longitude = [dict safeObjectForKey:kMerchantLongitudeKey];
    merchant.longitude = [dict safeObjectForKey:kMerchantLongitudeKey];
    
    NSString *merchantType = [dict safeObjectForKey:kMerchantTypeKey];
    BCMerchantLocationType locationType = BCMerchantLocationTypeOther;
    if ([merchantType isEqualToString:@"1"]) {
        locationType = BCMerchantLocationTypeBeverage;
    } else if ([merchantType isEqualToString:@"2"]) {
        locationType = BCMerchantLocationTypeBar;
    } else if ([merchantType isEqualToString:@"3"]) {
        locationType = BCMerchantLocationTypeFood;
    } else if ([merchantType isEqualToString:@"4"]) {
        locationType = BCMerchantLocationTypeBusiness;
    } else if ([merchantType isEqualToString:@"5"]) {
        locationType = BCMerchantLocationTypeOther;
    }
    merchant.locationType = locationType;
    
    merchant.merchantDescription = [dict safeObjectForKey:kMerchantDescriptionKey];
    
    NSNumber *distance = [dict safeObjectForKey:kMerchantDistanceKey];
    merchant.distance = [distance floatValue];

    return merchant;
}

- (NSString *)latLongQueryString
{
    NSString *queryString = @"";
    
    if ([self.latitude length] > 0) {
        queryString = [queryString stringByAppendingString:self.latitude];
    }
    
    if ([self.longitude length] > 0) {
        if ([queryString length] > 0) {
            queryString = [queryString stringByAppendingString:@","];
        }
        queryString = [queryString stringByAppendingString:self.longitude];
    }
    
    return queryString;
}

- (NSString *)addressQueryString
{
    NSString *addressString = @"";
    
    if ([self.address length] > 0) {
        addressString = self.address;
    }
    
    if ([self.city length] > 0) {
        if ([addressString length] > 0) {
            addressString = [addressString stringByAppendingString:@" "];
        }
        addressString = [addressString stringByAppendingString:self.city];
    }
    
    return addressString;
}

@end
