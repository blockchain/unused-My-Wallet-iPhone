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

@synthesize encrypted_payload;
@synthesize guid;
@synthesize sharedKey;
@synthesize doubleEncryption;
@synthesize keys;
@synthesize delegate;
@synthesize dPasswordHash;
@synthesize addressBook;
@synthesize secondPassword;
@synthesize password;

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

-(void)removeAddress:(NSString*)address {
    [self.keys removeObjectForKey:address];
}

-(Key*)generateNewKey {
    [self setJSVars];
    
    NSArray * components = [[_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"generateNewAddressAndKey();", sharedKey]] componentsSeparatedByString:@"|"];

    if ([components count] == 2) {
        
        Key * key = [[[Key alloc] init] autorelease];
        key.addr = [components objectAtIndex:0];
        key.priv = [components objectAtIndex:1];
        
        [self.keys setObject:key forKey:key.addr];

        return key;
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

-(id)initWithPassword:(NSString*)fpassword {
    if ([super init]) {
        _webView = [[UIWebView alloc] init];
                
        _webView.delegate = self;
        
        self.password = fpassword;        
        self.guid = [Wallet generateUUID];
        self.sharedKey = [Wallet generateUUID];
        self.keys = [NSMutableDictionary dictionary];
        self.addressBook = [NSMutableDictionary dictionary];
        
        //Generate the fist Address
        [self generateNewKey];
        
        [self loadJS];
    }
    return  self;
}

-(id)initWithData:(NSData*)payload password:(NSString*)fpassword {
    
    if ([super init]) {
        _webView = [[UIWebView alloc] init];
        
        _webView.delegate = self;
        
        self.password = fpassword;
        self.encrypted_payload = payload;
        
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

-(void)addToAddressBook:(NSString*)address label:(NSString*)label {
    [addressBook setObject:label forKey:address];
}

-(BOOL)isValidAddress:(NSString*)string {
    NSString * result = [_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"parseAddress('%@');", string]];
    
    return ([result length] > 0);
}

-(NSString*)encryptedString {
    NSString * encryptedFunction = [NSString stringWithFormat:@"encrypt('%@', '%@');", [self jsonString], self.password];

   return  [_webView stringByEvaluatingJavaScriptFromString:encryptedFunction];
}

-(void)decrypt {
        self.secondPassword = nil;
    
        if (self.encrypted_payload == nil) {
            NSLog(@"encrypted payload is nil");
            return;
        }
    
        NSString * payload = [[[NSString alloc] initWithData:self.encrypted_payload encoding:NSUTF8StringEncoding] autorelease];
    
        NSString * decryptFunction = [NSString stringWithFormat:@"decrypt('%@', '%@');", payload, self.password];
    
        NSString * walletJSON = [_webView stringByEvaluatingJavaScriptFromString:decryptFunction];
        
        if (walletJSON == NULL || [walletJSON length] == 0) {
            
            if ([delegate respondsToSelector:@selector(walletFailedToDecrypt:)])
                [delegate walletFailedToDecrypt:self];
            
            NSLog(@"Wallet data is null");
                
            return;
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
-(void)loadData:(NSData*)payload password:(NSString*)fpassword {
    self.encrypted_payload = payload;
    self.password = fpassword;
 
    [self decrypt];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {    
    if (self.encrypted_payload) {
        [self decrypt];
        
        self.encrypted_payload = nil;
    }
    
    if ([delegate respondsToSelector:@selector(walletJSReady)])
        [delegate walletJSReady];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"Did fail");
}

-(void)dealloc {
    [_webView stopLoading];
    _webView.delegate = nil;
    
    [encrypted_payload release];
    [secondPassword release];
    [dPasswordHash release];
    [_encrypted_payload release];
    [_password release];
    [_webView release];
    
    _webView = nil;
    
    [super dealloc];
}
@end
