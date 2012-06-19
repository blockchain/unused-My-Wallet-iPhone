//
//  WebSocket.m
//  AIM Addict
//
//  Created by Ben Reeves on 12/05/2011.
//  Copyright 2011 Rainy Day Apps. All rights reserved.
//

#import "WebSocketUIView.h"

const NSString * js = @"<html> <body> <script language='javascript' type='text/javascript'> var websocket; var messages = []; function getLastMessage() { var last_receive = window.last_receive; window.last_receive = null; return last_receive; } function close() { messages = []; if (websocket) { websocket.close(); websocket = null; } } var process = function() { if (messages.length > 0) { if (!window || window.last_receive) return; var msg = messages[0]; messages.splice(0); window.last_receive = msg[1]; window.location = msg[0]; } setTimeout(process, 250); }; setTimeout(process, 250); function connect(url) { if (websocket) close(); try { websocket = new WebSocket(url); websocket.onopen = function(evt) { messages.push(['onopen://', evt.data]); }; websocket.onclose = function(evt) { messages.push(['onclose://', evt.data]); }; websocket.onmessage = function(evt) { messages.push(['onreceive://', evt.data]); }; websocket.onerror = function(evt) { messages.push(['onerror://', evt.data]); }; } catch (e) { messages.push(['onerror://', e.toString()]); } }; </script> </body> </html>";

@implementation WebSocketUIView

@synthesize connect_url;

-(ReadyState)readyState {
    if (![NSThread isMainThread]) {
        @throw @"[websocket readyState] called on background thread";
    }
    
    NSString * readyStr = [webView stringByEvaluatingJavaScriptFromString:@"websocket.readyState"];
            
    return [readyStr intValue];
}

-(void)connect:(NSString*)url_string {
    if (![NSThread isMainThread]) {
        @throw @"[websocket connect:] called on background thread";
    }
    
    self.connect_url = url_string;
    
    if (isInitialized) {        
        [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"connect(\"%@\");", self.connect_url]];
    } else {
        NSLog(@"Connect not initalized");
    }
}

-(id)init {
    if ((self = [super init])) {
        
        isInitialized = false;
        
        webView = [[UIWebView alloc] initWithFrame:CGRectZero];
                
        webView.delegate = self;
        
        [webView loadHTMLString:(NSString*)js baseURL:nil];
    }
    return self; 
}

-(void)dealloc {
    [webView stopLoading];
    webView.delegate = nil;
    
    [delegate release];
    [webView release];
    [super dealloc];
}

-(void)disconnect {
    if (![NSThread isMainThread]) {
        @throw @"[websocket disconnect] called on background thread";
    }
    
    [webView stringByEvaluatingJavaScriptFromString:@"close();"];
}

-(void)send:(NSString*)message {
    if (![NSThread isMainThread]) {
        @throw @"[websocket send:] called on background thread";
    }
    
    message = [message stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    
    [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"websocket.send(\"%@\");", message]];
}

//This method must return quickly or it can cause the UIWebView to crash
- (BOOL)webView:(UIWebView *)fwebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    NSURL * url = [request URL];
    NSString * scheme = [url scheme];
    
    @try {
        if ([scheme isEqualToString:@"onopen"]) {
            dispatch_async(dispatch_get_main_queue(),^ {
                [delegate webSocketOnOpen:self];
            });
            return NO;
        } else if ([scheme isEqualToString:@"onclose"]) {
            dispatch_async(dispatch_get_main_queue(),^ {
                [delegate webSocketOnClose:self];
            });
            return NO;
        } else if ([scheme isEqualToString:@"onerror"]) {
            NSString * last_error = [webView stringByEvaluatingJavaScriptFromString:@"getLastMessage();"];

            dispatch_async(dispatch_get_main_queue(),^ {
                [delegate webSocket:self onError:[NSError errorWithDomain:last_error code:1 userInfo:nil]];
            });
            return NO;
        } else if ([scheme isEqualToString:@"onreceive"]) {                            
            NSString * last_receive = [webView stringByEvaluatingJavaScriptFromString:@"getLastMessage();"];
            
            dispatch_async(dispatch_get_main_queue(),^ {
                [delegate webSocket:self onReceive:[last_receive dataUsingEncoding:NSUTF8StringEncoding]];
            });
            
            return NO;
        }
    } @catch (NSException * e) {
        NSLog(@"%@", e);
    }
    
    return YES;
}

-(void)webViewDidFinishLoad:(UIWebView *)fwebView {
    isInitialized = true;
    
    if (self.connect_url)
        [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"connect(\"%@\");", self.connect_url]];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [delegate webSocket:self onError:error];
}


@end
