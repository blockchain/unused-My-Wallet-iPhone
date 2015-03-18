//
//  BCEntropyChecker.h
//  entropy
//
//  Created by User on 3/17/15.
//  Copyright (c) 2015 com.blockchain. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BCEntropyChecker : NSObject

+ (instancetype)sharedInstance;

- (CGFloat)entropyStrengthForWord:(NSString *)word;

@end
