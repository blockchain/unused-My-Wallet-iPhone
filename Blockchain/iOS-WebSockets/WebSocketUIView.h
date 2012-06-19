//
//  WebSocket.h
//  AIM Addict
//
//  Created by Ben Reeves on 12/05/2011.
//  Copyright 2011 Rainy Day Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "WebSocket.h"

@interface WebSocketUIView : WebSocket <UIWebViewDelegate> {
    UIWebView * webView;
    bool isInitialized;
}

@property(nonatomic, strong) NSString * connect_url;

-(void)connect:(NSString*)url_string;
-(void)disconnect;
-(void)send:(NSString*)message;
-(ReadyState)readyState;

@end
