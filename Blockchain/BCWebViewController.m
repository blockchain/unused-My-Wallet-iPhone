//
//  BCWebViewController.m
//  Blockchain
//
//  Created by Mark Pfluger on 9/25/14.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import "BCWebViewController.h"
#import "AppDelegate.h"
#import "LocalizationConstants.h"

#define TOP_BAR_HEIGHT 66

@interface BCWebViewController ()

@end

@implementation BCWebViewController

-(id)init {
    self = [super init];
    if (self) {
        webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, TOP_BAR_HEIGHT, self.view.frame.size.width, self.view.frame.size.height - TOP_BAR_HEIGHT)];
        
        webView.delegate = self;
        
        [self.view addSubview:webView];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (APP_IS_IPHONE5) {
        self.view.frame = CGRectMake(0, 0, 320, 449);
    }
    else {
        self.view.frame = CGRectMake(0, 0, 320, 360);
    }
    
    UIView *topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, TOP_BAR_HEIGHT)];
    topBar.backgroundColor = COLOR_BLOCKCHAIN_BLUE;
    [self.view addSubview:topBar];
    
    UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"top_menu_logo.png"]];
    logo.frame = CGRectMake(88, 22, 143, 40);
    [topBar addSubview:logo];
    
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 70, 15, 80, 51)];
    [closeButton setTitle:BC_STRING_CLOSE forState:UIControlStateNormal];
    closeButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [closeButton addTarget:self action:@selector(closeButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:closeButton];
}

- (void)closeButtonClicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [app networkActivityStart];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [app networkActivityStop];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [app standardNotify:[error localizedDescription]];
    
    [app networkActivityStop];
}

- (void)loadURL:(NSString*)url {
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    [webView loadRequest:request];
}

@end
