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
    [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"double_encryption = %s;", [self doubleEncryption] ? "true" : "false"]];
    
    if (self.secondPassword)
        [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"dpassword = '%@';", self.secondPassword]];
    else
        [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"dpassword = null"]];

    [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"sharedKey = '%@'", [self sharedKey]]];

    [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"parseWalletJSON('%@');", [self jsonString]]];
}

-(void)sendPaymentTo:(NSString*)toAddress from:(NSString*)fromAddress value:(NSString*)value {
    [self setJSVars];
   
    [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"sendTx('%@', '%@', '%@');", toAddress, fromAddress, value]];
}


-(Key*)generateNewKey {
    [self setJSVars];
    
//    NSArray *components = [[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"generateNewAddressAndKey();", [self sharedKey]]] componentsSeparatedByString:@"|"];
    NSArray *components = [[webView stringByEvaluatingJavaScriptFromString:@"generateNewAddressAndKey();"] componentsSeparatedByString:@"|"];

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
    NSString * walletHTML = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"wallet" ofType:@"html"] encoding:NSUTF8StringEncoding error:&error];
    
    NSLog(@"js path: %@", [[NSBundle mainBundle] pathForResource:@"bitcoinjs" ofType:@"js"]);
    NSLog(@"js path: %@", [[NSBundle mainBundle] pathForResource:@"blockchainapi" ofType:@"js"]);
    NSLog(@"js path: %@", [[NSBundle mainBundle] pathForResource:@"bootstrap" ofType:@"js"]);
    NSLog(@"js path: %@", [[NSBundle mainBundle] pathForResource:@"jquery" ofType:@"js"]);
    NSLog(@"js path: %@", [[NSBundle mainBundle] pathForResource:@"signer" ofType:@"js"]);
    NSLog(@"js path: %@", [[NSBundle mainBundle] pathForResource:@"shared" ofType:@"js"]);
    NSLog(@"js path: %@", [[NSBundle mainBundle] pathForResource:@"wallet" ofType:@"js"]);

    walletHTML = [walletHTML stringByReplacingOccurrencesOfString:@"${bitcoinjs.js}" withString:bitcoinJS];
    walletHTML = [walletHTML stringByReplacingOccurrencesOfString:@"${blockchainapi.min.js}" withString:blockchainJS];
    walletHTML = [walletHTML stringByReplacingOccurrencesOfString:@"${shared.min.js}" withString:sharedJS];
    walletHTML = [walletHTML stringByReplacingOccurrencesOfString:@"${jquery.min.js}" withString:jqueryJS];
    walletHTML = [walletHTML stringByReplacingOccurrencesOfString:@"${signer.js}" withString:signerJS];
    walletHTML = [walletHTML stringByReplacingOccurrencesOfString:@"${wallet.js}" withString:walletJS];
    walletHTML = [walletHTML stringByReplacingOccurrencesOfString:@"${bootstrap.min.js}" withString:bootstrapJS];
    
    [webView loadHTMLString:walletHTML baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath]]];
        
    for(UIView *wview in [[[webView subviews] objectAtIndex:0] subviews]) { 
        if([wview isKindOfClass:[UIImageView class]]) { wview.hidden = YES; } 
    }   
    
    [webView setBackgroundColor:[UIColor colorWithRed:246.0f/255.0f green:246.0f/255.0f blue:246.0f/255.0f alpha:1.0f]];
}

-(id)initWithPassword:(NSString*)fpassword {
    if ([super init]) {
        self.webView = [[[UIWebView alloc] initWithFrame:CGRectZero] autorelease];
                
        webView.delegate = self;
        
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
        self.webView = [[[UIWebView alloc] initWithFrame:CGRectZero] autorelease];
        
        webView.delegate = self;
        
        self.password = fpassword;
        self.encrypted_payload = payload;
        
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

- (BOOL)webView:(UIWebView *)webView2  shouldStartLoadWithRequest:(NSURLRequest *)request  navigationType:(UIWebViewNavigationType)navigationType {
    
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


- (void)webViewDidStartLoad:(UIWebView *)webView {
    NSLog(@"Start load");
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

-(void)decrypt {
    self.secondPassword = nil;

    if (self.encrypted_payload == nil) {
        NSLog(@"encrypted payload is nil");
        return;
    }

    NSString * payload = [[[NSString alloc] initWithData:self.encrypted_payload encoding:NSUTF8StringEncoding] autorelease];

    NSLog(@"payload: %@", payload);
    
    NSString * decryptFunction = [NSString stringWithFormat:@"decrypt('%@', '%@');", payload, self.password];

    // Evaluate
    NSString * walletJSON = [webView stringByEvaluatingJavaScriptFromString:decryptFunction];

    if (!walletJSON || [walletJSON length] == 0) {
        
        if ([delegate respondsToSelector:@selector(walletFailedToDecrypt:)])
            [delegate walletFailedToDecrypt:self];
        
        NSLog(@"Failed to decrypt wallet data");
            
        return;
    }

    JSONDecoder * json = [[[JSONDecoder alloc] init] autorelease];
    
    NSDictionary * immutable_document = [json objectWithUTF8String:(const unsigned char*)[walletJSON UTF8String] length:[walletJSON length]];
             
    if (immutable_document) {
        self.document = (NSMutableDictionary *)CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (CFDictionaryRef)immutable_document, kCFPropertyListMutableContainers);
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
    NSLog(@"Did fail %@", error);
}

-(void)dealloc {
    [webView stopLoading];
    webView.delegate = nil;

    [self.password release];
    [self.document release];
    
    webView = nil;
    
    [super dealloc];
}
@end
