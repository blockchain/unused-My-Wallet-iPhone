//
//  BlockchainAPI.h
//  Blockchain
//
//  Created by Ben Reeves on 19/07/2014.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BlockchainAPI : NSObject

+(NSDictionary*)resolveAlias:(NSString*)alias;

@end
