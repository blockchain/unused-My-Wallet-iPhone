//
//  WebViewController.m
//  Blockchain
//
//  Created by Ben Reeves on 17/03/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "WebViewController.h"
#import "AppDelegate.h"
@interface WebViewController ()

@end

@implementation WebViewController


- (BOOL)webView:(UIWebView *)_webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
                
    if (navigationType != UIWebViewNavigationTypeOther) {
        if ([[[request URL] host] rangeOfString:@"blockchain.info"].location != NSNotFound) {
           
            NSMutableURLRequest * mutable = [NSMutableURLRequest requestWithURL:[request URL]];
            
            [self addCookiesToRequest:mutable];
            
            [webView loadRequest:mutable];
            
        } else {
            [[UIApplication sharedApplication] openURL:[request URL]];
        }
        
        return FALSE;
    }
    
    return TRUE;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    app.loadingText = BC_LOADING_EXTERNAL_PAGE;
    
    [app networkActivityStart];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [app networkActivityStop];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [app standardNotify:[error localizedDescription]];
    
    [app networkActivityStop];
}

-(void)addCookiesToRequest:(NSMutableURLRequest*)request {
    
    NSHTTPCookie *no_header_cookie = [NSHTTPCookie cookieWithProperties:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                         @"blockchain.info", NSHTTPCookieDomain,
                                                                         @"\\", NSHTTPCookiePath,  // IMPORTANT!
                                                                         @"no_header", NSHTTPCookieName,
                                                                         @"true", NSHTTPCookieValue,
                                                                         nil]];
    
    
    NSHTTPCookie *no_footer_cookie = [NSHTTPCookie cookieWithProperties:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                         @"blockchain.info", NSHTTPCookieDomain,
                                                                         @"\\", NSHTTPCookiePath,  // IMPORTANT!
                                                                         @"no_footer", NSHTTPCookieName,
                                                                         @"true", NSHTTPCookieValue,
                                                                         nil]];
    
    NSArray* cookies = [NSArray arrayWithObjects: no_header_cookie, no_footer_cookie, nil];
    
    NSDictionary * headers = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
    
    [request setAllHTTPHeaderFields:headers];
}

-(void)loadURL:(NSString*)url {
    
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    [self addCookiesToRequest:request];
   
    [webView loadRequest:request];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    
    webView.delegate = self;
    
	[self.view addSubview:webView];
    
    // Hide the imageViews?
    for(UIView *wview in [[[webView subviews] objectAtIndex:0] subviews]) { 
        if([wview isKindOfClass:[UIImageView class]]) { wview.hidden = YES; }
    }
    
    if (APP_IS_IPHONE5) {
        self.view.frame = CGRectMake(0, 0, 320, 450);
    }
    else {
        self.view.frame = CGRectMake(0, 0, 320, 361);
    }
}


@end
