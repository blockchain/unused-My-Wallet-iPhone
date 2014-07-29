//
//  MerchantViewController.h
//  Blockchain
//
//  Created by Ben Reeves on 29/07/2014.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MerchantViewController : UIViewController <UIWebViewDelegate> {
    IBOutlet UIWebView * webView;
}
-(void)loadURL:(NSString*)url;
@end
