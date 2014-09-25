//
//  BCWebViewController.h
//  Blockchain
//
//  Created by Mark Pfluger on 9/25/14.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BCWebViewController : UIViewController <UIWebViewDelegate> {
    UIWebView * webView;
}

-(void)loadURL:(NSString*)url;

@end
