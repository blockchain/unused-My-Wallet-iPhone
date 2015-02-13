//
//  BCLine.m
//  Blockchain
//
//  Created by Mark Pfluger on 2/13/15.
//  Copyright (c) 2015 Qkos Services Ltd. All rights reserved.
//

#import "BCLine.h"

@implementation BCLine

- (void)awakeFromNib
{
    float onePixelHeight = 1.0/[UIScreen mainScreen].scale;
    UIView *onePixelLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, onePixelHeight)];
    
    onePixelLine.userInteractionEnabled = NO;
    [onePixelLine setBackgroundColor:self.backgroundColor];
    [self addSubview:onePixelLine];
    
    self.backgroundColor = [UIColor clearColor];
    self.userInteractionEnabled = NO;
}

@end
