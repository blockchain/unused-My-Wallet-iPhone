//
//  Input.h
//  Blockchain
//
//  Created by Ben Reeves on 10/01/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Output;

@interface Input : NSObject {}

@property(nonatomic, strong) Output * prev_out;

@end
