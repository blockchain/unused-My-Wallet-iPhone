//
//  WebSocket.h
//  AIM Addict
//
//  Created by Ben Reeves on 12/05/2011.
//  Copyright 2011 Rainy Day Apps. All rights reserved.
//

#import "WebSocket.h"

@implementation WebSocket

@synthesize delegate;

-(void)connect:(NSString*)url_string {}
-(void)disconnect {}
-(void)send:(NSString*)message {}
-(ReadyState)readyState { return ReadyStateClosed; }

@end