//
//  Output.h
//  Blockchain
//
//  Created by Ben Reeves on 10/01/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Output : NSObject {

}

@property(nonatomic, strong) NSString * addr;
@property(nonatomic, assign) uint64_t value;


@end
