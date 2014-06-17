//
//  Wallet.m
//  Blockchain
//
//  Created by Ben Reeves on 16/03/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "Wallet.h"
#import "JSONKit.h"
#import "AppDelegate.h"

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
@synthesize delegate;
@synthesize secondPassword;
@synthesize password;
@synthesize webView;
@synthesize document;

+ (NSString *)generateUUID 
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return [(NSString *)string autorelease];
}

-(void)cancelTxSigning {
    [webView stringByEvaluatingJavaScriptFromString:@"cancel();"];
}

-(void)setJSVars {
#warning fix all this stuff
    [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"double_encryption = %s;", [self doubleEncryption] ? "true" : "false"]];
    
    if (self.secondPassword)
        [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"dpassword = '%@';", self.secondPassword]];
    else
        [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"dpassword = null"]];

    [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"sharedKey = '%@'", [self sharedKey]]];

//    [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"parseWalletJSON('%@');", [self jsonString]]];
}

-(void)sendPaymentTo:(NSString*)toAddress from:(NSString*)fromAddress value:(NSString*)value {

    [self setJSVars];
   
    // to, from, value,
    [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"MyWallet.quickSend('%@', '%@', '%@', listener);", toAddress, fromAddress, value]];
}


// generateNewAddress
-(Key*)generateNewKey {
    [self setJSVars];
    
    // generateNewAddress is in wallet.html
    NSArray *components = [[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"generateNewAddress(%@);", [self sharedKey]]] componentsSeparatedByString:@"|"];
    
//    NSArray *components = [webView stringByEvaluatingJavaScriptFromString:NSString stringWithFormat:@"generateNewAddressAndKey();", [self sharedKey]];
    if ([components count] == 2) {
        
        Key * key = [[[Key alloc] init] autorelease];
        key.addr = [components objectAtIndex:0];
        key.priv = [components objectAtIndex:1];
        
        [self addKey:key];

        return key;
    }
    
    return nil;
}

-(NSString*)jsonString {    
    return [document JSONString];
}


-(void)loadJS {
    
    NSError * error = nil;
#warning clean this up -- load directly from js.
    NSString * bitcoinJS = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"bitcoinjs" ofType:@"js"] encoding:NSUTF8StringEncoding error:&error];
    NSString * blockchainJS = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"blockchainapi" ofType:@"js"] encoding:NSUTF8StringEncoding error:&error];
    NSString * bootstrapJS = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"bootstrap" ofType:@"min.js"] encoding:NSUTF8StringEncoding error:&error];
    NSString * jqueryJS = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"jquery" ofType:@"min.js"] encoding:NSUTF8StringEncoding error:&error];
    NSString * signerJS = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"signer" ofType:@"js"] encoding:NSUTF8StringEncoding error:&error];
    NSString * sharedJS = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"shared" ofType:@"js"] encoding:NSUTF8StringEncoding error:&error];
    NSString * walletJS = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"wallet" ofType:@"js"] encoding:NSUTF8StringEncoding error:&error];
    NSString * bridgeJS = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"bridge" ofType:@"js"] encoding:NSUTF8StringEncoding error:&error];
    NSString * walletHTML = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"wallet" ofType:@"html"] encoding:NSUTF8StringEncoding error:&error];
    
    walletHTML = [walletHTML stringByReplacingOccurrencesOfString:@"${bitcoinjs}" withString:bitcoinJS];
    walletHTML = [walletHTML stringByReplacingOccurrencesOfString:@"${blockchainapi}" withString:blockchainJS];
    walletHTML = [walletHTML stringByReplacingOccurrencesOfString:@"${bootstrap}" withString:bootstrapJS];
    walletHTML = [walletHTML stringByReplacingOccurrencesOfString:@"${jquery}" withString:jqueryJS];
    walletHTML = [walletHTML stringByReplacingOccurrencesOfString:@"${signer}" withString:signerJS];
    walletHTML = [walletHTML stringByReplacingOccurrencesOfString:@"${shared}" withString:sharedJS];
    walletHTML = [walletHTML stringByReplacingOccurrencesOfString:@"${wallet}" withString:walletJS];
    walletHTML = [walletHTML stringByReplacingOccurrencesOfString:@"${bridge}" withString:bridgeJS];

    // Break here to debug js
    
    [webView loadHTMLString:walletHTML baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath]]];
    
    for(UIView *wview in [[[webView subviews] objectAtIndex:0] subviews]) { 
        if([wview isKindOfClass:[UIImageView class]]) { wview.hidden = YES; } 
    }
            
    [webView setBackgroundColor:[UIColor colorWithRed:246.0f/255.0f green:246.0f/255.0f blue:246.0f/255.0f alpha:1.0f]];
}

-(id)initWithEncryptedQRString:(NSString*)encryptedQRString {

    if ([super init]) {
        self.webView = [[[JSBridgeWebView alloc] initWithFrame:CGRectZero] autorelease];
        [webView setJSDelegate:self];
        
        self.document = [NSMutableDictionary dictionary];
        [self loadJS];

        [self.webView executeJS:[NSString stringWithFormat:@"MyWallet.parsePairingCode('%@');", encryptedQRString]];
    }

    return  self;
}

- (void)didParsePairingCode:(NSDictionary *)dict
{
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [app setAccountData:dict[@"guid"] sharedKey:dict[@"sharedKey"] password:dict[@"password"]];
    [app.dataSource getWallet:dict[@"guid"] sharedKey:dict[@"sharedKey"] checksum:nil];
}

- (void)errorParsingPairingCode:(NSString *)message
{
    NSLog(@"error message: %@", message);
}

// This is only called when creating a new account,
-(id)initWithPassword:(NSString*)fpassword {
    if ([super init]) {
        self.webView = [[[JSBridgeWebView alloc] initWithFrame:CGRectZero] autorelease];
                
        [webView setJSDelegate:self];
        
        self.password = fpassword;        
        self.document = [NSMutableDictionary dictionary];
        self.guid = [Wallet generateUUID];
        self.sharedKey = [Wallet generateUUID];
        
        //Generate the fist Address
        [self generateNewKey];
        
        [self loadJS];
    }
    return  self;
}

-(id)initWithData:(NSData*)payload password:(NSString*)fpassword {
    
    if ([super init]) {
        self.webView = [[[JSBridgeWebView alloc] initWithFrame:CGRectZero] autorelease];
        
        [webView setJSDelegate:self];
        
        self.password = fpassword;
        self.encrypted_payload = payload;
        
        // Load the JS. Proceed in the webviewDidLoad callback
        [self loadJS];
    }
    
    return self;
}

-(Key*)parsePrivateKey:(NSString*)key {
    [self setJSVars];
    
    NSArray * components = [[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"parsePrivateKey('%@');", key]] componentsSeparatedByString:@"|"];
    
    if ([components count] == 2) {
        
        Key * key = [[[Key alloc] init] autorelease];
        key.addr = [components objectAtIndex:0];
        key.priv = [components objectAtIndex:1];
        
        [self addKey:key];
                
        return key;
    }
    
    return nil;
}



-(NSString*)labelForAddress:(NSString*)address {
    NSString * addressbookLabel = [[self addressBook] objectForKey:address];

    if (addressbookLabel) {
        return addressbookLabel;
    }
    
    Key * key = [[self keys] objectForKey:address];
    if (key && [key label]) {
        return [key label];
    }
    return address;
}



-(BOOL)isValidAddress:(NSString*)string {
    NSString * result = [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"parseAddress('%@');", string]];
    
    return ([result length] > 0);
}

-(NSString*)encryptedString {    
    NSString * _json = [self jsonString];
    NSString * _password = [self password];
    
    if ([_json length] == 0 || [_password length] == 0)
        return nil;

    NSString * encryptedFunction = [NSString stringWithFormat:@"encrypt('%@', '%@');", _json, _password];

   return  [webView stringByEvaluatingJavaScriptFromString:encryptedFunction];
}

-(NSString*)guid {
    return [document objectForKey:@"guid"];
}

-(void)setGuid:(NSString *)guid {
    [document setValue:guid forKey:@"guid"];
}

-(NSString*)sharedKey {
    return [document objectForKey:@"sharedKey"];
}

-(void)setSharedKey:(NSString *)sharedKey {
    [document setValue:sharedKey forKey:@"sharedKey"];
}

-(BOOL)doubleEncryption {
    return [[document objectForKey:@"double_encryption"] boolValue];
}

-(void)setDoubleEncryption:(BOOL)value {
    [document setValue:[NSNumber numberWithBool:value] forKey:@"double_encryption"];
}

-(NSString*)dPasswordHash {
    return [document objectForKey:@"dpasswordhash"];
}

-(void)setdPasswordHash:(NSString*)dpasswordhash {
    [document setValue:dpasswordhash forKey:@"dpasswordhash"];
}


-(NSArray*)activeAddresses {
    NSMutableArray * active = [NSMutableArray array];
    NSArray * keysArray = [document objectForKey:@"keys"];

    for (NSDictionary * keyDict in keysArray) {
        int tag = [[keyDict objectForKey:@"tag"] intValue];

        if (tag == 2)
            continue;
        
        [active addObject:[keyDict objectForKey:@"addr"]];
    }
    
    return active;
}

-(NSDictionary*)keys {
    NSArray * keysArray = [document objectForKey:@"keys"];
    NSMutableDictionary * keys = [NSMutableDictionary dictionaryWithCapacity:[keysArray count]];
    
    for (NSDictionary * keyDict in keysArray) {
        
        Key * key = [[[Key alloc] init] autorelease];
        key.addr = [keyDict objectForKey:@"addr"];
        key.priv = [keyDict objectForKey:@"priv"];
        key.tag = [[keyDict objectForKey:@"tag"] intValue];
        key.label = [keyDict objectForKey:@"label"];
        
        [keys setObject:key forKey:key.addr];
    }
    
    return keys;
}

-(NSDictionary*)keyDictForAddress:(NSString*)address {
    NSMutableArray * keysArray = [document objectForKey:@"keys"];
    
    for (int ii = 0; ii < [keysArray count]; ++ii) {
        NSDictionary * keyDict = [keysArray objectAtIndex:ii];
                
        if ([[keyDict objectForKey:@"addr"] isEqualToString:address]) {
            return keyDict;
        }
    }
    return nil;
}

-(void)setLabel:(NSString*)label ForAddress:(NSString*)address {
    NSDictionary * keyDict = [self keyDictForAddress:address];
    
    if (keyDict) {
        [keyDict setValue:label forKey:@"label"];
    }
}

-(void)archiveAddress:(NSString*)address {
    NSDictionary * keyDict = [self keyDictForAddress:address];

    if (keyDict) {
        [keyDict setValue:[NSNumber numberWithInt:2] forKey:@"tag"];
    }
}

-(void)unArchiveAddress:(NSString*)address {
    NSDictionary * keyDict = [self keyDictForAddress:address];
    
    if (keyDict) {
        [keyDict setValue:[NSNumber numberWithInt:0] forKey:@"tag"];
    }
}

-(void)removeAddress:(NSString*)address {

    NSDictionary * keyDict = [self keyDictForAddress:address];
    
    if (keyDict) {
        NSMutableArray * keysArray = [document objectForKey:@"keys"];

        [keysArray removeObject:keyDict];
        
        [document setValue:keysArray forKey:@"keys"];
    }
}

-(void)addKey:(Key*)key {
    
    NSMutableArray * keysArray = [document objectForKey:@"keys"];

    if (keysArray == nil) {
        keysArray = [NSMutableArray array];
        [document setValue:keysArray forKey:@"keys"]; 
    }
    
    NSMutableDictionary * keydict = [NSMutableDictionary dictionary];
    
    [keydict setObject:key.addr forKey:@"addr"];
    
    if (key.priv)
        [keydict setObject:key.priv forKey:@"priv"];
    
    if (key.tag > 0)
        [keydict setObject:[NSNumber numberWithInt:key.tag] forKey:@"tag"];
    
    if (key.label)
        [keydict setObject:key.label forKey:@"label"];
    
    [keysArray addObject:keydict];
        
    [document setValue:keysArray forKey:@"keys"];
}

-(NSDictionary*)addressBook {
    NSMutableDictionary * addressBook = [NSMutableDictionary dictionary];
    NSArray * addressBookDict = [document objectForKey:@"address_book"];
    for (NSDictionary * addrDict in addressBookDict) {
        [addressBook setObject:[addrDict objectForKey:@"label"] forKey:[addrDict objectForKey:@"addr"]];
    }
    return addressBook;
}

-(void)addToAddressBook:(NSString*)address label:(NSString*)label {
    
    //Check if it already existing
    if ([[self addressBook] objectForKey:address])
        return;
    
    NSMutableArray * addressBookArray = [document objectForKey:@"address_book"];

    if (addressBookArray == nil) {
        addressBookArray = [NSMutableArray array];
        [document setValue:addressBookArray forKey:@"address_book"]; 
    }
    
    NSMutableDictionary * addrDict = [NSMutableDictionary dictionary];
    [addrDict setValue:label forKey:@"label"];
    [addrDict setValue:address forKey:@"addr"];
    
    [addressBookArray addObject:addrDict];
    
    [document setValue:addressBookArray forKey:@"address_book"];
}

// Calls from JS

-(void)log:(NSString*)message {
    NSLog(@"console.log: %@", message);
}

-(void)didFailToDecryptWallet:(NSString*)message {
    
    NSLog(@"Failed To Decrypt Wallet: %@", message);
    
    if ([delegate respondsToSelector:@selector(walletFailedToDecrypt:)])
        [delegate walletFailedToDecrypt:self];
    
}

-(void)didDecryptWallet:(NSString*)walletJSON {
    NSLog(@"didDecryptWallet:");

    if (walletJSON) {
        self.document = (NSMutableDictionary *)CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (CFDictionaryRef)walletJSON, kCFPropertyListMutableContainers);
    }
    
    if ([delegate respondsToSelector:@selector(walletDidLoad:)])
        [delegate walletDidLoad:self];
}

-(void)decrypt {
    self.secondPassword = nil;

    if (self.encrypted_payload == nil) {
        NSLog(@"encrypted payload is nil");
        return;
    }

    NSString * payload = [[[NSString alloc] initWithData:self.encrypted_payload encoding:NSUTF8StringEncoding] autorelease];
    
    NSString * decryptFunction = [NSString stringWithFormat:@"decrypt('%@', '%@');", payload, self.password];

    // Evaluate
   [webView stringByEvaluatingJavaScriptFromString:decryptFunction];
}

-(void)loadData:(NSData*)payload password:(NSString*)fpassword {
    self.encrypted_payload = payload;
    self.password = fpassword;
 
    [self decrypt];
}


#pragma mark WebView Delegate Methods
- (BOOL)webView:(UIWebView *)webView2 shouldStartLoadWithRequest:(NSURLRequest *)request  navigationType:(UIWebViewNavigationType)navigationType {
    
    NSString *requestString = [[[request URL] absoluteString] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
    
    NSLog(@"Request URL %@", [request URL]);
    
    if ([requestString hasPrefix:@"log://"]) {
        NSLog(@"UIWebView console: %@", [webView2 stringByEvaluatingJavaScriptFromString:@"getMsg();"]);
        return NO;
    } else if ([requestString hasPrefix:@"did-submit-tx://"]) {
        if ([delegate respondsToSelector:@selector(didSubmitTransaction)])
        [delegate didSubmitTransaction];
    }
    
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    NSLog(@"Start load");
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"did fail");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (self.encrypted_payload) {
        [self decrypt];
        
        self.encrypted_payload = nil;
    }
    
    if ([delegate respondsToSelector:@selector(walletJSReady)])
        [delegate walletJSReady];
}

-(void)dealloc {
    [self.password release];
    [self.document release];
    
    self.webView = nil;
    
    [super dealloc];
}

- (NSString*)webView:(UIWebView*) webview didReceiveJSNotificationWithDictionary:(NSDictionary*) dictionary
{
    NSString * function = (NSString*)[dictionary objectForKey:@"function"];
    
    if (function != nil) {
        SEL selector = NSSelectorFromString(function);
        if ([self respondsToSelector:selector]) {
            
            NSMethodSignature *sig = [self methodSignatureForSelector:selector];
            if (!sig)
                return nil;
            
            NSInvocation* invo = [NSInvocation invocationWithMethodSignature:sig];
            [invo setTarget:self];
            [invo setSelector:selector];
            
            
            if ([sig numberOfArguments] > 2) {
                id arg1 = [dictionary objectForKey:@"arg1"];
                if (arg1 != nil)
                    [invo setArgument:&arg1 atIndex:2];
            }
            
            if ([sig numberOfArguments] > 3) {
                id arg2 = [dictionary objectForKey:@"arg2"];
                if (arg2 != nil)
                    [invo setArgument:&arg2 atIndex:3];
            }
            
            if ([sig numberOfArguments] > 4) {
                id arg3 = [dictionary objectForKey:@"arg3"];
                if (arg3 != nil)
                    [invo setArgument:&arg3 atIndex:4];
            }
            
            if ([sig numberOfArguments] > 5) {
                id arg4 = [dictionary objectForKey:@"arg4"];
                if (arg4 != nil)
                    [invo setArgument:&arg4 atIndex:5];
            }
            
            [invo invoke];
            if (sig.methodReturnLength) {
                id anObject;
                [invo getReturnValue:&anObject];
                return anObject;
            }
            
            return nil;
        } else {
            return nil;
        }
    }
    
    return nil;
}
@end
