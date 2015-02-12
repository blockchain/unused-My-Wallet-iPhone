//
//  BCWebViewController.h
//  Blockchain
//
//  Created by Mark Pfluger on 10/9/14.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BCWebViewController : UIViewController <UIWebViewDelegate> {
    UIWebView * webView;
}

- (id)initWithTitle:(NSString *)title;

- (void)loadSettings;
- (void)loadURL:(NSString*)url;

@end
