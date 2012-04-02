//
//  Output.h
//  Blockchain
//
//  Created by Ben Reeves on 10/01/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Output : NSObject {

@public
    uint64_t value;
    NSString * addr;
}

-(NSString*)addr;
-(uint64_t)value;

@end
