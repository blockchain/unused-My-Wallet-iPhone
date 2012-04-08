//
//  Wallet.m
//  Blockchain
//
//  Created by Ben Reeves on 16/03/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "Wallet.h"
#import "JSONKit.h"

@implementation Key
@synthesize addr;
@synthesize priv;
@synthesize tag;
@synthesize label;

- (NSString *)description {
    return [NSString stringWithFormat:@"<Key : addr %@, tag, %d>", addr, tag];
}


- (NSComparisonResult)compare:(Key *)otherObject {
    return [self.addr compare:otherObject.addr];
}

@end

@implementation Wallet

@synthesize guid;
@synthesize sharedKey;
@synthesize doubleEncryption;
@synthesize keys;
@synthesize delegate;
@synthesize dPasswordHash;
@synthesize addressBook;
@synthesize secondPassword;

+ (NSString *)generateUUID 
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return [(NSString *)string autorelease];
}

-(void)cancelTxSigning {
    [_webView stringByEvaluatingJavaScriptFromString:@"txCancelled = true;"];
}

-(void)setJSVars {
    [_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"double_encryption = %s;", doubleEncryption ? "true" : "false"]];
    
    if (self.secondPassword)
        [_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"dpassword = '%@';", self.secondPassword]];
    else
        [_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"dpassword = null"]];

    [_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"sharedKey = '%@'", sharedKey]];

    [_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"parseWalletJSON('%@');", [self jsonString]]];
}

-(void)sendPaymentTo:(NSString*)toAddress from:(NSString*)fromAddress value:(double)value {
    [self setJSVars];
   
    [_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"sendTx('%@', '%@', '%f');", toAddress, fromAddress, value]];
}

-(NSString*)generateNewAddress {
    [self setJSVars];
    
    NSArray * components = [[_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"generateNewAddressAndKey();", sharedKey]] componentsSeparatedByString:@"|"];

    if ([components count] == 2) {
        
        Key * key = [[[Key alloc] init] autorelease];
        key.addr = [components objectAtIndex:0];
        key.priv = [components objectAtIndex:1];
        
        [self.keys setObject:key forKey:key.addr];

        return key.addr;
    }
    
    return nil;
}


-(NSString*)jsonString {
    NSMutableDictionary * root = [NSMutableDictionary dictionary];
    
    [root setObject:guid forKey:@"guid"];
    [root setObject:sharedKey forKey:@"sharedKey"];
    
    if (dPasswordHash)
        [root setObject:dPasswordHash forKey:@"dpasswordhash"];
    
    if (doubleEncryption)
        [root setObject:[NSNumber numberWithBool:doubleEncryption] forKey:@"double_encryption"];

    NSMutableArray * addressBookArray = [NSMutableArray array];
    for (NSString * addr in [addressBook allKeys]) {
        [addressBookArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:addr, @"addr", [addressBook objectForKey:addr], @"label", nil]];
    }
    
    [root setObject:addressBookArray forKey:@"address_book"];
    
    NSMutableArray * keysArray = [NSMutableArray array];
    for (Key * key in [keys allValues]) {
        
        NSMutableDictionary * keydict = [NSMutableDictionary dictionary];
        [keydict setObject:key.addr forKey:@"addr"];
        
        if (key.priv)
            [keydict setObject:key.priv forKey:@"priv"];

        if (key.tag > 0)
            [keydict setObject:[NSNumber numberWithInt:key.tag] forKey:@"tag"];

        if (key.label)
            [keydict setObject:key.label forKey:@"label"];

        [keysArray addObject:keydict];
    }
    
    [root setObject:keysArray forKey:@"keys"];

    return [root JSONString];
}


-(void)loadJS {
    NSString * path = [[NSBundle mainBundle] pathForResource:@"wallet" ofType:@"html"];
    
    NSError * error = nil;
    
    NSString* htmlString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    
    [_webView loadHTMLString:htmlString baseURL:[[NSBundle mainBundle] resourceURL]];
    
    for(UIView *wview in [[[_webView subviews] objectAtIndex:0] subviews]) { 
        if([wview isKindOfClass:[UIImageView class]]) { wview.hidden = YES; } 
    }   
    
    [_webView setBackgroundColor:[UIColor colorWithRed:246.0f/255.0f green:246.0f/255.0f blue:246.0f/255.0f alpha:1.0f]];
}

-(id)initWithPassword:(NSString*)password {
    if ([super init]) {
        _webView = [[UIWebView alloc] init];
        
        [_webView.scrollView setScrollEnabled:FALSE];
        
        _webView.delegate = self;
        
        _password = [password retain];
        
        self.guid = [Wallet generateUUID];
        self.sharedKey = [Wallet generateUUID];
        self.keys = [NSMutableDictionary dictionary];
        self.addressBook = [NSMutableDictionary dictionary];
        
        //Generate the fist Address
        [self generateNewAddress];
        
        [self loadJS];
    }
    return  self;
}

-(id)initWithData:(NSData*)payload password:(NSString*)password {
    
    if ([super init]) {
        _webView = [[UIWebView alloc] init];
        
        //[_webView.scrollView setScrollEnabled:FALSE];
        
        _webView.delegate = self;
        
        _password = [password retain];
        _encrypted_payload = [payload retain];
        
        [self loadJS];
    }
    
    return self;
}


- (BOOL)webView:(UIWebView *)webView2  shouldStartLoadWithRequest:(NSURLRequest *)request  navigationType:(UIWebViewNavigationType)navigationType {
    
    NSString *requestString = [[[request URL] absoluteString] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
    
    if ([requestString hasPrefix:@"ios-log:"]) {
        NSString* logString = [[requestString componentsSeparatedByString:@":#iOS#"] objectAtIndex:1];
        
        if ([logString isEqualToString:@"did-submit-tx"]) {
            if ([delegate respondsToSelector:@selector(didSubmitTransaction)])
                [delegate didSubmitTransaction];
        }
        
        NSLog(@"UIWebView console: %@", logString);
        return NO;
    }
    
    return YES;
}

-(UIWebView*)webView {
    return _webView;
}

-(NSString*)labelForAddress:(NSString*)address {
    NSString * addressbookLabel = [addressBook objectForKey:address];

    if (addressbookLabel) {
        return addressbookLabel;
    }
    
    Key * key = [keys objectForKey:address];
    if (key && [key label]) {
        return [key label];
    }
    return address;
}


- (void)webViewDidStartLoad:(UIWebView *)webView {
    NSLog(@"Start load");
}


-(NSString*)encryptedString {
    NSString * encryptedFunction = [NSString stringWithFormat:@"encrypt('%@', '%@');", [self jsonString], _password];

   return  [_webView stringByEvaluatingJavaScriptFromString:encryptedFunction];
}

-(void)decrypt {
        self.secondPassword = nil;
    
        if (_encrypted_payload == nil) {
            NSLog(@"encrypted payload is nil");
        }
    
        NSString * decryptFunction = [NSString stringWithFormat:@"decrypt('%@', '%@');", [[[NSString alloc] initWithData:_encrypted_payload encoding:NSUTF8StringEncoding] autorelease], _password];
        
        NSString * walletJSON = [_webView stringByEvaluatingJavaScriptFromString:decryptFunction];
        
        if (walletJSON == NULL || [walletJSON length] == 0) {
            NSLog(@"Wallet data is null");
        }
        
        JSONDecoder * json = [[[JSONDecoder alloc] init] autorelease];
        
        NSDictionary * document = [json objectWithUTF8String:(const unsigned char*)[walletJSON UTF8String] length:[walletJSON length]];
        
        self.guid = [document objectForKey:@"guid"];
        self.sharedKey = [document objectForKey:@"sharedKey"];
        self.doubleEncryption = [[document objectForKey:@"double_encryption"] boolValue];
        self.dPasswordHash = [document objectForKey:@"dpasswordhash"];
        
        NSArray * keysDict = [document objectForKey:@"keys"];
        
        self.keys = [NSMutableDictionary dictionaryWithCapacity:[keysDict count]];
        
        for (NSDictionary * keyDict in keysDict) {
            
            Key * key = [[[Key alloc] init] autorelease];
            key.addr = [keyDict objectForKey:@"addr"];
            key.priv = [keyDict objectForKey:@"priv"];
            key.tag = [[keyDict objectForKey:@"tag"] intValue];
            key.label = [keyDict objectForKey:@"label"];
            
            [self.keys setObject:key forKey:key.addr];
        }
        
        self.addressBook = [NSMutableDictionary dictionary];
        NSArray * addressBookDict = [document objectForKey:@"address_book"];
        for (NSDictionary * addrDict in addressBookDict) {
            [addressBook setObject:[addrDict objectForKey:@"label"] forKey:[addrDict objectForKey:@"addr"]];
        }
    
    if ([delegate respondsToSelector:@selector(walletDidLoad:)])
        [delegate walletDidLoad:self];

}
-(void)loadData:(NSData*)payload password:(NSString*)password {
    [_encrypted_payload release];
    _encrypted_payload = [payload retain];
    
    [_password release];
    _password = [password retain];
 
    [self decrypt];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {    
    if (_encrypted_payload) {
        [self decrypt];
        
        [_encrypted_payload release];
        _encrypted_payload = nil;
    }
    
    if ([delegate respondsToSelector:@selector(walletJSReady)])
        [delegate walletJSReady];
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"Did fail");
}

-(void)dealloc {
    [secondPassword release];
    [dPasswordHash release];
    [_encrypted_payload release];
    [_password release];
    [_webView release];
    [super dealloc];
}
@end
