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


- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    //DLog(@"%@", [request URL]);
    
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

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // reload wallet
    [app.wallet getWalletAndHistory];
}

-(void)viewWillAppear:(BOOL)animated
{
    [webView stopLoading];

    if ([app guid] && [app sharedKey])
    {
        NSString *requestString = [NSString stringWithFormat:@"%@wallet/iphone-view?guid=%@&sharedKey=%@&device=iphone", WebROOT, [app guid], [app sharedKey]];
        [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:requestString]]];
    }
}

// Called after user logs out
- (void)emptyWebView
{
    [webView loadHTMLString:@"Logged out" baseURL:nil];
}

-(void)viewDidLoad {
    [super viewDidLoad];
	
    if (APP_IS_IPHONE5) {
        self.view.frame = CGRectMake(0, 0, 320, 450);
    }
    else {
        self.view.frame = CGRectMake(0, 0, 320, 361);
    }

    // Remove Shadow
    for(UIView *wview in [[[webView subviews] objectAtIndex:0] subviews]) {
        if([wview isKindOfClass:[UIImageView class]]) { wview.hidden = YES; }
    }
}

@end
