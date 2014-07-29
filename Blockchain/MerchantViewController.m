//
//  MerchantViewController.m
//  Blockchain
//
//  Created by Ben Reeves on 29/07/2014.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import "MerchantViewController.h"
#import "AppDelegate.h"

@interface MerchantViewController ()

@end

@implementation MerchantViewController


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
    app.loadingText = @"Loading External Page";
    
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSError * error = nil;
    NSString * merchantHTML = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"merchant" ofType:@"html"] encoding:NSUTF8StringEncoding error:&error];
    
    
    NSURL * baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath]];
    
    [webView loadHTMLString:merchantHTML baseURL:baseURL];
    
    if (APP_IS_IPHONE5) {
        self.view.frame = CGRectMake(0, 0, 320, 450);
    }
    else {
        self.view.frame = CGRectMake(0, 0, 320, 361);
    }
}



@end
