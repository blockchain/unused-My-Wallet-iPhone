//
//  BCEntropyChecker.m
//  entropy
//
//  Created by User on 3/17/15.
//  Copyright (c) 2015 com.blockchain. All rights reserved.
//

#import "BCEntropyChecker.h"

#import "RegExCategories.h"

@implementation BCEntropyChecker

+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });

    return sharedInstance;
}

- (CGFloat)entropyStrengthForWord:(NSString *)word
{
    CGFloat score = [self scoreWord:word];
    
    return score;
}

- (CGFloat)scoreWord:(NSString *)word
{
    CGFloat score = [self weightedEntropyForWord:word];
    
    if (score > 100) {
        score = 100;
    }
    
    return score;
}

- (CGFloat)weightedEntropyForWord:(NSString *)word
{
    CGFloat entropy = [self entropy:word];
    CGFloat quality = [self qualityForWord:word];
    CGFloat weightedEntropy = entropy * quality;
    
    return weightedEntropy;
}

- (CGFloat)entropy:(NSString *)string
{
    return log2(pow([self baseEntropyValueForWord:string], string.length));
}

- (NSUInteger)baseEntropyValueForWord:(NSString *)word
{
    NSUInteger base = 0;
    
    if ([RX(@"[0-9]") isMatch:word]) {
        base += 10;
    }

    if ([RX(@"[a-z]") isMatch:word]) {
        base += 26;
    }
    
    if ([RX(@"[A-Z]") isMatch:word]) {
        base += 26;
    }
    
    if ([RX(@"[-!$%^&*()_+|~=`{}\\[\\]:\";'<>?@,.\\/]") isMatch:word]) {
        base += 31;
    }
    
    if (!base) {
        base = 1;
    }
    
    return base;
}

- (CGFloat)qualityForWord:(NSString *)word
{
    CGFloat quality = CGFLOAT_MAX;
    
    Rx *allDigits = RX(@"^[\\d]+$");
    quality = [allDigits isMatch:word] ? MIN(quality, 0.25f) : quality;

    Rx *allLowerEndWithOneDigit = RX(@"^[a-z\\s]+\\d$");
    quality = [allLowerEndWithOneDigit isMatch:word] ? MIN(quality, 0.25f) : quality;

    Rx *allUpperEndWithOneDigit = RX(@"^[A-Z\\s]+\\d$");
    quality = [allUpperEndWithOneDigit isMatch:word] ? MIN(quality, 0.25f) : quality;

    Rx *allLettersWithOneDigit = RX(@"^[a-zA-Z\\s]+\\d$");
    quality = [allLettersWithOneDigit isMatch:word] ? MIN(quality, 0.5f) : quality;

    Rx *allLowerThanDigits = RX(@"^[a-z\\s]+\\d+$");
    quality = [allLowerThanDigits isMatch:word] ? MIN(quality, 0.5f) : quality;

    Rx *allLower = RX(@"^[a-z\\s]+$");
    quality = [allLower isMatch:word] ? MIN(quality, 0.25f) : quality;

    Rx *allUpper = RX(@"^[A-Z\\s]+$");
    quality = [allUpper isMatch:word] ? MIN(quality, 0.25f) : quality;

    Rx *oneUpperAllLower = RX(@"^[A-Z][\\s]+$");
    quality = [oneUpperAllLower isMatch:word] ? MIN(quality, 0.25f) : quality;

    Rx *oneUpperOneLowerOneDigit = RX(@"^[A-Z][a-z\\s]+\\d$");
    quality = [oneUpperOneLowerOneDigit isMatch:word] ? MIN(quality, 0.25f) : quality;

    Rx *oneUpperOneLowerDigits = RX(@"^[A-Z][a-z\\s]+\\d+$");
    quality = [oneUpperOneLowerDigits isMatch:word] ? MIN(quality, 0.5f) : quality;

    Rx *allLowerOneSpecial = RX(@"^[a-z\\s]+[._!\\- @*#]$");
    quality = [allLowerOneSpecial isMatch:word] ? MIN(quality, 0.25f) : quality;

    Rx *allUpperOneSpecial = RX(@"^[A-Z\\s]+[._!\\- @*#]$");
    quality = [allUpperOneSpecial isMatch:word] ? MIN(quality, 0.25) : quality;

    Rx *allLettersOneSpecial = RX(@"^[a-zA-Z\\s]+[._!\\- @*#]$");
    quality = [allLettersOneSpecial isMatch:word] ? MIN(quality, 0.5f) : quality;

    Rx *email = RX(@"^[a-zA-Z0-9._%+-]+@[a-zA-z0-9.-]+\\.[a-zA-z]+$");
    quality = [email isMatch:word] ? MIN(quality, 0.25f) : quality;
    
    Rx *anything = RX(@"^.*$");
    quality = [anything isMatch:word] ? MIN(quality, 1.0f) : quality;
    
    if (quality == CGFLOAT_MAX) {
        quality = 0.0f;
    }
    
    return quality;
}

@end
