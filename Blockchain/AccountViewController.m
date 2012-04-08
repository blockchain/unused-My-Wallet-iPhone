//
//  AccountViewController.m
//  Blockchain
//
//  Created by Ben Reeves on 17/03/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "AccountViewController.h"
#import "AppDelegate.h"
@interface AccountViewController ()

@end

@implementation AccountViewController

-(void)dealloc {
    [activity release];
    [webView release];
    [super dealloc];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    NSLog(@"%@", [request URL]);
    
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [activity startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [activity stopAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if ([error code] != NSURLErrorCancelled) {
        [app standardNotify:[error localizedDescription]];
        
        [activity stopAnimating];
    }
}

-(void)viewWillAppear:(BOOL)animated {
        
        [webView stopLoading];
    
#ifdef CYDIA
        NSString * requestString = [NSString stringWithFormat:@"%@wallet/iphone-view?guid=%@&sharedKey=%@&device=iphone&cydia=true", WebROOT, [app guid], [app sharedKey]];
#else
        NSString * requestString = [NSString stringWithFormat:@"%@wallet/iphone-view?guid=%@&sharedKey=%@&device=iphone", WebROOT, [app guid], [app sharedKey]];
#endif
    
        [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:requestString]]];

}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    //Remove Shadow
    for(UIView *wview in [[[webView subviews] objectAtIndex:0] subviews]) { 
        if([wview isKindOfClass:[UIImageView class]]) { wview.hidden = YES; } 
    }   
}

@end
