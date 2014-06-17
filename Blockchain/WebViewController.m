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
    [app startTask:TaskLoadExternalURL];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [app finishTask];
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

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [app finishTask];

    [app standardNotify:[error localizedDescription]];
}

-(void)loadURL:(NSString*)url {
    
    NSLog(@"%@", webView);
    
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    [self addCookiesToRequest:request];

    [webView loadRequest:request];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    for(UIView *wview in [[[webView subviews] objectAtIndex:0] subviews]) { 
        if([wview isKindOfClass:[UIImageView class]]) { wview.hidden = YES; }
    }
    
    if (APP_IS_IPHONE5)
    {
        self.view.frame = CGRectMake(0, 0, 320, 450);
    }
    else {
        self.view.frame = CGRectMake(0, 0, 320, 361);
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


-(void)dealloc {
    [webView release];
    [super dealloc];
}

@end
