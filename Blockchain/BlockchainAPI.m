//
//  BlockchainAPI.m
//  Blockchain
//
//  Created by Ben Reeves on 19/07/2014.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import "BlockchainAPI.h"

@implementation BlockchainAPI
+(NSDictionary*)resolveAlias:(NSString*)alias {
    
    NSMutableString * string = [NSMutableString stringWithFormat:@"%@wallet/%@?format=json", WebROOT, [alias urlencode]];
    
    NSURL * url = [NSURL URLWithString:string];
    
    NSHTTPURLResponse * response = NULL;
    NSError * error = NULL;
    
    NSData * data = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:url] returningResponse:&response error:&error];
    
    if (data == NULL || [data length] == 0) {
        [app standardNotify:@"Error Resolving Alias"];
        return nil;
    }
    
    NSString * responseString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    
    if ([response statusCode] == 500) {
        [app standardNotify:responseString];
        return nil;
    }
    
    if (error != NULL || [response statusCode] != 200) {
        [app standardNotify:[error localizedDescription]];
        return nil;
    }
    
    JSONDecoder * json = [[[JSONDecoder alloc] init] autorelease];
    
    return [json objectWithData:data];
}
@end
