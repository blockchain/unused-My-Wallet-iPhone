//
//  Merchant.h
//  Blockchain
//
//  Created by User on 12/18/14.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

extern NSString *const kMerchantIdKey;
extern NSString *const kMerchantNameKey;
extern NSString *const kMerchantAdressKey;
extern NSString *const kMerchantCityKey;
extern NSString *const kMerchantPCodeKey;
extern NSString *const kMerchantTelphoneKey;
extern NSString *const kMerchantURLKey;
extern NSString *const kMerchantLatitudeKey;
extern NSString *const kMerchantLongitudeKey;
extern NSString *const kMerchantTypeKey;
extern NSString *const kMerchantDescriptionKey;
extern NSString *const kMerchantDistanceKey;

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, BCMerchantLocationType) {
    BCMerchantLocationTypeBeverage = 1,
    BCMerchantLocationTypeBar,
    BCMerchantLocationTypeFood,
    BCMerchantLocationTypeBusiness,
    BCMerchantLocationTypeOther
};

@interface Merchant : NSObject

@property (copy, nonatomic) NSString *merchantId;
@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSString *address;
@property (copy, nonatomic) NSString *city;
@property (copy, nonatomic) NSString *pcode;
@property (copy, nonatomic) NSString *telephone;
@property (copy, nonatomic) NSString *urlString;
@property (copy, nonatomic) NSString *latitude;
@property (copy, nonatomic) NSString *longitude;
@property (copy, nonatomic) NSString *merchantDescription;
@property (assign, nonatomic) CGFloat distance;

@property (readonly, nonatomic) BCMerchantLocationType locationType;

+ (Merchant *)merchantWithDict:(NSDictionary *)dict;


@end
