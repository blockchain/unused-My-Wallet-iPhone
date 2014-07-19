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
#import "Transaction.h"

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

@synthesize delegate;
@synthesize secondPassword;
@synthesize password;
@synthesize webView;
@synthesize sharedKey;
@synthesize guid;
@synthesize keys;


+(id)parseJSON:(NSString*)json {
    NSError * error = nil;
    
    id dict = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options: NSJSONReadingMutableContainers error: &error];
    
    if (error != NULL) {
        NSLog(@"Error Parsing JSON %@", error);
        return nil;
    }

    return dict;
}

+ (NSString *)generateUUID 
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return [(NSString *)string autorelease];
}

-(BOOL)isDoubleEncrypted {
    return [[self.webView executeJSSynchronous:@"MyWallet.getDoubleEncryption()"] isEqualToString:@"TRUE"];
}

-(void)getHistory {
    [self.webView executeJS:@"MyWallet.get_history()"];
}

-(void)cancelTxSigning {
    [webView stringByEvaluatingJavaScriptFromString:@"cancel();"];
}

-(void)sendPaymentTo:(NSString*)toAddress from:(NSString*)fromAddress value:(NSString*)value {
       [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"MyWallet.quickSend('%@', '%@', '%@', listener);", toAddress, fromAddress, value]];
}


// generateNewAddress
-(void)generateNewKey:(void (^)(Key * key))callback {
    [self.webView executeJSWithCallback:^(NSString * encoded_key) {
        NSArray *components = [[webView stringByEvaluatingJavaScriptFromString:encoded_key] componentsSeparatedByString:@"|"];
        
        if ([components count] == 2) {
            Key * key = [[[Key alloc] init] autorelease];
            
            key.addr = [components objectAtIndex:0];
            key.priv = [components objectAtIndex:1];
            
            callback(key);
        }
    } command:@"MyWalletPhone.generateNewKey()"];
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

    if (self.guid && self.sharedKey && self.password) {
        walletHTML = [walletHTML stringByReplacingOccurrencesOfString:@"<body>" withString:[NSString stringWithFormat:@"<body data-guid=\"%@\" data-sharedkey=\"%@\">", self.guid, self.sharedKey]];
    }
    
    // Break here to debug js
    
    [webView loadHTMLString:walletHTML baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath]]];
    
    for(UIView *wview in [[[webView subviews] objectAtIndex:0] subviews]) { 
        if([wview isKindOfClass:[UIImageView class]]) { wview.hidden = YES; } 
    }
            
    [webView setBackgroundColor:[UIColor colorWithRed:246.0f/255.0f green:246.0f/255.0f blue:246.0f/255.0f alpha:1.0f]];
}

- (void)didParsePairingCode:(NSDictionary *)dict
{
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [app setAccountData:dict[@"guid"] sharedKey:dict[@"sharedKey"] password:dict[@"password"]];
}

- (void)errorParsingPairingCode:(NSString *)message
{
    NSLog(@"error message: %@", message);
}


#pragma mark Init Methods

//Called When Reading QR Pairing
-(id)initWithEncryptedQRString:(NSString*)encryptedQRString {
    
    if ([super init]) {
        self.webView = [[[JSBridgeWebView alloc] initWithFrame:CGRectZero] autorelease];
        [webView setJSDelegate:self];
        
        [self loadJS];
        
        [self.webView executeJS:[NSString stringWithFormat:@"MyWallet.parsePairingCode('%@');", encryptedQRString]];
    }
    
    return  self;
}

//Called when entering guid manually
-(id)initWithGuid:(NSString *)_guid password:(NSString*)_sharedKey {
    if ([super init]) {
        self.webView = [[[JSBridgeWebView alloc] initWithFrame:CGRectZero] autorelease];
        
        [webView setJSDelegate:self];
        
        self.guid = _guid;
        self.sharedKey = _sharedKey;
      
        [self loadJS];
    }
    return  self;
}

// This is only called when creating a new account,
-(id)initWithPassword:(NSString*)fpassword {
    if ([super init]) {
        self.webView = [[[JSBridgeWebView alloc] initWithFrame:CGRectZero] autorelease];
                
        [webView setJSDelegate:self];
        
        self.password = fpassword;        
        self.guid = [Wallet generateUUID];
        self.sharedKey = [Wallet generateUUID];
        
        [self loadJS];

        //Generate the first Address
        [self generateNewKey:nil];
    }
    return  self;
}

-(id)initWithGuid:(NSString*)_guid sharedKey:(NSString*)_sharedKey password:(NSString*)_password {
    
    if ([super init]) {
        self.webView = [[[JSBridgeWebView alloc] initWithFrame:CGRectZero] autorelease];
        
        [webView setJSDelegate:self];
        
        self.password = _password;
        self.guid = _guid;
        self.sharedKey = _sharedKey;
        
        // Load the JS. Proceed in the webviewDidLoad callback
        [self loadJS];
    }
    
    return self;
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


-(NSArray*)allAddresses {
    NSString * allAddressesJSON = [self.webView executeJSSynchronous:@"JSON.stringify(MyWallet.getAllAddresses())"];
    
    return [Wallet parseJSON:allAddressesJSON];
}


-(NSArray*)activeAddresses {
    NSString * activeAddressesJSON = [self.webView executeJSSynchronous:@"JSON.stringify(MyWallet.getActiveAddresses())"];
    
    return [Wallet parseJSON:activeAddressesJSON];
}


-(void)setLabel:(NSString*)label ForAddress:(NSString*)address {
    
    //TODO escape properly
    [self.webView executeJS:@"MyWallet.setLabel('%@', '%@')", address, label];
}

-(void)archiveAddress:(NSString*)address {
    [self.webView executeJS:@"MyWallet.archiveAddr()", address];
}

-(void)unArchiveAddress:(NSString*)address {
    [self.webView executeJS:@"MyWallet.unArchiveAddr()", address];
}

-(void)removeAddress:(NSString*)address {
    [self.webView executeJS:@"MyWallet.deleteAddress()", address];
}

-(uint64_t)getAddressBalance:(NSString*)address {
    return [[self.webView executeJSSynchronous:@"MyWallet.getAddressBalance('%@')", address] longLongValue];
}

-(BOOL)addKey:(NSString*)privateKeyString {
    
    //TODO escape properly
    NSString * returnVal = [self.webView executeJSSynchronous:@"MyWalletPhone.addPrivateKey('%@')", privateKeyString];
    
    if ([returnVal isEqualToString:@"TRUE"]) {
        return true;
    } else {
        return false;
    }
}

-(NSDictionary*)addressBook {
    NSString * addressBookJSON = [self.webView executeJSSynchronous:@"JSON.stringify(MyWallet.getAddressBook())"];
    
    return [Wallet parseJSON:addressBookJSON];
}

-(void)addToAddressBook:(NSString*)address label:(NSString*)label {
    [self.webView executeJS:@"MyWallet.addAddressBookEntry('%@', '%@')", address, label];
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
    
    if ([delegate respondsToSelector:@selector(walletDidLoad:)])
        [delegate walletDidLoad:self];
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

-(void)parseLatestBlockJSON:(NSString*)latestBlockJSON {
    
    NSDictionary * dict = [Wallet parseJSON:latestBlockJSON];
    
    LatestBlock * latestBlock = [[LatestBlock alloc] init];
    
    latestBlock.hash = [dict objectForKey:@"hash"];
    latestBlock.height = [[dict objectForKey:@"height"] intValue];
    latestBlock.time = [[dict objectForKey:@"time"] longLongValue];
    latestBlock.blockIndex = [[dict objectForKey:@"block_index"] intValue];
    
    [delegate didSetLatestBlock:latestBlock];
}

-(void)parseMultiAddrJSON:(NSString*)multiAddrJSON {
    
    if (multiAddrJSON == nil)
        return;
    
    NSDictionary * dict = [Wallet parseJSON:multiAddrJSON];
    
    MulitAddressResponse * response = [[MulitAddressResponse alloc] init];
    
    response.transactions = [NSMutableArray array];

    NSArray * transactionsArray = [dict objectForKey:@"transactions"];
    
    for (NSDictionary * dict in transactionsArray) {
        
        Transaction * tx = [Transaction fromJSONDict:dict];
        
        [response.transactions addObject:tx];
    }
    
    response.final_balance = [[dict objectForKey:@"final_balance"] longLongValue];
    response.total_received = [[dict objectForKey:@"total_received"] longLongValue];
    response.n_transactions = [[dict objectForKey:@"n_transactions"] longValue];
    response.total_sent = [[dict objectForKey:@"total_sent"] longLongValue];
    
    [delegate didGetMultiAddressResponse:response];
}

-(void)getFinalBalance {
    [self.webView executeJSWithCallback:^(NSString * final_balance) {
        self.final_balance = [final_balance longLongValue];
        
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLongLong:self.final_balance] forKey:@"final_balance"];
        
    } command:@"MyWallet.getFinalBalance()"];
}

-(void)getTotalSent {
    [self.webView executeJSWithCallback:^(NSString * total_sent) {
        self.total_sent = [total_sent longLongValue];
        
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLongLong:self.total_sent] forKey:@"total_sent"];
    } command:@"MyWallet.getTotalSent()"];
}


-(void)did_multiaddr {
    NSLog(@"Did MultiAddr");
    
    [self getFinalBalance];
    
    [self.webView executeJSWithCallback:^(NSString * multiAddrJSON) {
        
        [self parseMultiAddrJSON:multiAddrJSON];
    
        [[NSUserDefaults standardUserDefaults] setObject:multiAddrJSON forKey:@"multiaddr"];
    } command:@"JSON.stringify(MyWalletPhone.getMultiAddrResponse())"];
}

-(void)did_set_latest_block {
    [self.webView executeJSWithCallback:^(NSString* latestBlockJSON) {
        
        [[NSUserDefaults standardUserDefaults] setObject:latestBlockJSON forKey:@"transactions"];

        [self parseLatestBlockJSON:latestBlockJSON];
        
    } command:@"JSON.stringify(MyWallet.getLatestBlock())"];
}

-(void)did_decrypt {
    NSLog(@"Did Decrypt");
}

-(void)error_restoring_wallet {
    NSLog(@"Error Restoring Wallet");
}

-(void)did_set_guid {
    NSLog(@"Did Set GUID");
    
    [self.webView executeJS:[NSString stringWithFormat:@"setPassword(\"%@\")", self.password]];
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
    if ([delegate respondsToSelector:@selector(walletJSReady)])
        [delegate walletJSReady];
}

-(void)dealloc {
    [self.password release];
    
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


//Callbacks from javascript localstorage

-(id)getKey:(NSString*)dictionary {
    NSString * key = [dictionary valueForKey:@"key"];
    
    //NSLog(@"GET %@", key);
    
    return [[NSUserDefaults standardUserDefaults] valueForKey:key];
}

-(id)saveKey:(NSString*)dictionary {
    NSString * key = [dictionary valueForKey:@"key"];
    NSString * value = [dictionary valueForKey:@"value"];
    
    [[NSUserDefaults standardUserDefaults] setValue:value forKey:key];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    return nil;
}

-(id)removeKey:(NSString*)dictionary {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[dictionary valueForKey:@"key"]];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    return nil;
}

-(id)clearKeys:(NSString*)dictionary {
    NSString * appDomain = [[NSBundle mainBundle] bundleIdentifier];
    
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    return nil;
}


@end
