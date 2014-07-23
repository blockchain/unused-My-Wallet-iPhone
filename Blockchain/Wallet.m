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
#import "NSString+NSString_EscapeQuotes.h"
#import "MultiAddressResponse.h"
#import "UncaughtExceptionHandler.h"

@implementation transactionProgressListeners
@end

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
@synthesize password;
@synthesize webView;
@synthesize sharedKey;
@synthesize guid;

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

-(BOOL)isIntialized {
    if ([self.webView isLoaded])
        return [[self.webView executeJSSynchronous:@"MyWallet.getIsInitialized()"] boolValue];
    else
        return FALSE;
}

-(BOOL)isDoubleEncrypted {
    return [[self.webView executeJSSynchronous:@"MyWallet.getDoubleEncryption()"] boolValue];
}

-(void)getHistory {
    if ([self isIntialized])
        [self.webView executeJS:@"MyWallet.get_history()"];
}

-(void)cancelTxSigning {
    [self.webView executeJSSynchronous:@"MyWalletPhone.cancelTxSigning();"];
}

-(void)tx_on_success:(NSString*)txProgressID {
    transactionProgressListeners * listener = [self.transactionProgressListeners objectForKey:txProgressID];
    
    if (listener) {
        if (listener.on_success) {
            listener.on_success();
        }
    }
}

-(void)tx_on_start:(NSString*)txProgressID {
    transactionProgressListeners * listener = [self.transactionProgressListeners objectForKey:txProgressID];
    
    if (listener) {
        if (listener.on_start) {
            listener.on_start();
        }
    }
}

-(void)tx_on_error:(NSString*)txProgressID error:(NSString*)error {
    transactionProgressListeners * listener = [self.transactionProgressListeners objectForKey:txProgressID];
    
    if (listener) {
        if (listener.on_error) {
            listener.on_error(error);
        }
    }
}

-(void)tx_on_begin_signing:(NSString*)txProgressID {
    transactionProgressListeners * listener = [self.transactionProgressListeners objectForKey:txProgressID];
    
    if (listener) {
        if (listener.on_begin_signing) {
            listener.on_begin_signing();
        }
    }
}

-(void)tx_on_sign_progress:(NSString*)txProgressID input:(NSString*)input {
    transactionProgressListeners * listener = [self.transactionProgressListeners objectForKey:txProgressID];
    
    if (listener) {
        if (listener.on_sign_progress) {
            listener.on_sign_progress([input integerValue]);
        }
    }
}

-(void)tx_on_finish_signing:(NSString*)txProgressID {
    transactionProgressListeners * listener = [self.transactionProgressListeners objectForKey:txProgressID];
    
    if (listener) {
        if (listener.on_finish_signing) {
            listener.on_finish_signing();
        }
    }
}

-(void)sendPaymentTo:(NSString*)toAddress from:(NSString*)fromAddress satoshiValue:(NSString*)satoshiValue listener:(transactionProgressListeners*)listener {
    
    NSString * txProgressID = [self.webView executeJSSynchronous:@"MyWalletPhone.quickSend(\"%@\", \"%@\", \"%@\")", [fromAddress escapeDoubleQuotes], [toAddress escapeDoubleQuotes], [satoshiValue escapeDoubleQuotes]];
        
    [self.transactionProgressListeners setObject:listener forKey:txProgressID];
}

// generateNewAddress
-(void)generateNewKey {
    [self.webView executeJS:@"MyWalletPhone.generateNewKey()"];
}

-(void)loadJS {
    NSError * error = nil;
    NSString * walletHTML = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"wallet" ofType:@"html"] encoding:NSUTF8StringEncoding error:&error];

    
    NSURL * baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath]];
                       
    walletHTML = [walletHTML stringByReplacingOccurrencesOfString:@"${resource_url}" withString:[baseURL absoluteString]];
    
    if (self.guid && self.sharedKey) {
        walletHTML = [walletHTML stringByReplacingOccurrencesOfString:@"<body>" withString:[NSString stringWithFormat:@"<body data-guid=\"%@\" data-sharedkey=\"%@\">", self.guid, self.sharedKey]];
    } else if (self.guid) {
        walletHTML = [walletHTML stringByReplacingOccurrencesOfString:@"<body>" withString:[NSString stringWithFormat:@"<body data-guid=\"%@\">", self.guid]];
    }
    
    [webView loadHTMLString:walletHTML baseURL:baseURL];
}

-(void)parsePairingCode:(NSString*)code {
    [self.webView executeJS:[NSString stringWithFormat:@"MyWallet.parsePairingCode(\"%@\");", [code escapeDoubleQuotes]]];
}

- (void)didParsePairingCode:(NSDictionary *)dict
{
    NSLog(@"didParsePairingCode:");

    if ([delegate respondsToSelector:@selector(didParsePairingCode:)])
        [delegate didParsePairingCode:dict];
}

- (void)errorParsingPairingCode:(NSString *)message
{
    NSLog(@"errorParsingPairingCode:");
    
    if ([delegate respondsToSelector:@selector(errorParsingPairingCode:)])
        [delegate errorParsingPairingCode:message];
}


#pragma mark Init Methods

//Called When Reading QR Pairing
-(id)init {
    if ([super init]) {
        self.transactionProgressListeners = [NSMutableDictionary dictionary];
        self.webView = [[[JSBridgeWebView alloc] initWithFrame:CGRectZero] autorelease];
        [webView setJSDelegate:self];
        
        [self loadJS];
    }
    
    return self;
}

//Called when entering guid manually
-(id)initWithGuid:(NSString *)_guid password:(NSString*)_password {
    if ([super init]) {
        self.transactionProgressListeners = [NSMutableDictionary dictionary];
        self.webView = [[[JSBridgeWebView alloc] initWithFrame:CGRectZero] autorelease];
        
        [webView setJSDelegate:self];
        
        self.guid = _guid;
        self.password = _password;
      
        [self loadJS];
    }
    return  self;
}

// This is only called when creating a new account,
-(id)initWithPassword:(NSString*)fpassword {
    if ([super init]) {
        self.transactionProgressListeners = [NSMutableDictionary dictionary];
        self.webView = [[[JSBridgeWebView alloc] initWithFrame:CGRectZero] autorelease];
                
        [webView setJSDelegate:self];
        
        self.password = fpassword;        
        self.guid = [Wallet generateUUID];
        self.sharedKey = [Wallet generateUUID];
        
        [self loadJS];

        //Generate the first Address
        [self generateNewKey];
    }
    return  self;
}

-(id)initWithGuid:(NSString*)_guid sharedKey:(NSString*)_sharedKey password:(NSString*)_password {
    
    if ([super init]) {
        self.transactionProgressListeners = [NSMutableDictionary dictionary];
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

-(BOOL)validateSecondPassword:(NSString*)secondPassword {
    return [[self.webView executeJSSynchronous:@"MyWallet.validateSecondPassword(\"%@\")", [secondPassword escapeDoubleQuotes]] boolValue];
}

-(BOOL)isWatchOnlyAddress:(NSString*)address {
    return ![[self.webView executeJSSynchronous:@"MyWallet.isWatchOnly(\"%@\")", [address escapeDoubleQuotes]] boolValue];
}


-(NSString*)labelForAddress:(NSString*)address {
    return [self.webView executeJSSynchronous:@"MyWallet.getAddressLabel(\"%@\")", [address escapeDoubleQuotes]];
}

-(NSInteger)tagForAddress:(NSString*)address {
    return [[self.webView executeJSSynchronous:@"MyWallet.getAddressTag(\"%@\")", [address escapeDoubleQuotes]] intValue];
}

-(BOOL)isValidAddress:(NSString*)string {
    return [[self.webView executeJSSynchronous:@"MyWalletPhone.isValidAddress(\"%@\");", [string escapeDoubleQuotes]] boolValue];
}

-(NSArray*)allAddresses {
    NSString * allAddressesJSON = [self.webView executeJSSynchronous:@"JSON.stringify(MyWallet.getAllAddresses())"];
    
    return [Wallet parseJSON:allAddressesJSON];
}


-(NSArray*)activeAddresses {
    NSString * activeAddressesJSON = [self.webView executeJSSynchronous:@"JSON.stringify(MyWallet.getActiveAddresses())"];
    
    return [Wallet parseJSON:activeAddressesJSON];
}

-(NSArray*)archivedAddresses {
    NSString * activeAddressesJSON = [self.webView executeJSSynchronous:@"JSON.stringify(MyWallet.getArchivedAddresses())"];
    
    return [Wallet parseJSON:activeAddressesJSON];
}



-(void)setLabel:(NSString*)label ForAddress:(NSString*)address {
    [self.webView executeJS:@"MyWallet.setLabel(\"%@\", \"%@\")", [address escapeDoubleQuotes], [label escapeDoubleQuotes]];
}

-(void)archiveAddress:(NSString*)address {
    [self.webView executeJS:@"MyWallet.archiveAddr(\"%@\")", [address escapeDoubleQuotes]];
}

-(void)unArchiveAddress:(NSString*)address {
    [self.webView executeJS:@"MyWallet.unArchiveAddr(\"%@\")", [address escapeDoubleQuotes]];
}

-(void)removeAddress:(NSString*)address {
    [self.webView executeJS:@"MyWallet.deleteAddress(\"%@\")", [address escapeDoubleQuotes]];
}

-(uint64_t)getAddressBalance:(NSString*)address {
    return [[self.webView executeJSSynchronous:@"MyWallet.getAddressBalance(\"%@\")", [address escapeDoubleQuotes]] longLongValue];
}

-(BOOL)addKey:(NSString*)privateKeyString {
    return [[self.webView executeJSSynchronous:@"MyWalletPhone.addPrivateKey(\"%@\")", [privateKeyString escapeDoubleQuotes]] boolValue];
}

-(NSDictionary*)addressBook {
    NSString * addressBookJSON = [self.webView executeJSSynchronous:@"JSON.stringify(MyWallet.getAddressBook())"];
    
    return [Wallet parseJSON:addressBookJSON];
}

-(void)addToAddressBook:(NSString*)address label:(NSString*)label {
    [self.webView executeJS:@"MyWallet.addAddressBookEntry(\"%@\", \"%@\")", [address escapeDoubleQuotes], [label escapeDoubleQuotes]];
}

// Calls from JS

-(void)log:(NSString*)message {
    NSLog(@"console.log: %@", message);
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
    
    MulitAddressResponse * response = [[[MulitAddressResponse alloc] init] autorelease];
    
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
    response.addresses = [dict objectForKey:@"addresses"];
    
    {
        NSDictionary * symbolLocalDict = [dict objectForKey:@"symbol_local"] ;
        if (symbolLocalDict) {
            response.symbol_local = [CurrencySymbol symbolFromDict:symbolLocalDict];
        }
    }
    
    {
        NSDictionary * symbolBTCDict = [dict objectForKey:@"symbol_btc"] ;
        if (symbolBTCDict) {
            response.symbol_btc = [CurrencySymbol symbolFromDict:symbolBTCDict];
        }
    }
    
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

-(void)on_tx {
    NSLog(@"on_tx");

    [app playBeepSound];
    
    [self getHistory];
}

-(void)did_multiaddr {
    NSLog(@"did_multiaddr");
    
    [self getFinalBalance];
    
    [self.webView executeJSWithCallback:^(NSString * multiAddrJSON) {
        [self parseMultiAddrJSON:multiAddrJSON];
    } command:@"JSON.stringify(MyWalletPhone.getMultiAddrResponse())"];
}


-(void)on_block {
    NSLog(@"on_block");
}

-(void)did_set_latest_block {
    
    NSLog(@"did_set_latest_block");
    
    [self.webView executeJSWithCallback:^(NSString* latestBlockJSON) {
        
        [[NSUserDefaults standardUserDefaults] setObject:latestBlockJSON forKey:@"transactions"];

        [self parseLatestBlockJSON:latestBlockJSON];
        
    } command:@"JSON.stringify(MyWallet.getLatestBlock())"];
}

-(void)getPassword:(NSString*)selector success:(void(^)(id))_success {
    if ([selector isEqualToString:@"#second-password-modal"]) {
        [app getSecondPassword:^(NSString * _secondPassword) {
            _success(_secondPassword);
        } error:nil];
    } else if ([selector isEqualToString:@"#import-private-key-password"]) {
        [app getPrivateKeyPassword:^(NSString * _secondPassword) {
            _success(_secondPassword);
        } error:nil];
    } else {
        @throw [NSException exceptionWithName:@"Unknown Modal" reason:[NSString stringWithFormat:@"Unknown Modal Selector %@", selector] userInfo:nil];
    }
}

-(void)getPassword:(NSString*)title success:(void(^)(id))_success error:(void(^)(id))_error {
    [app getSecondPassword:^(NSString * _secondPassword) {
        
        NSLog(@"getPassword: Success");
        
        _success(_secondPassword);
    } error:^(NSString * errorMessage) {
        NSLog(@"getPassword error %@", errorMessage);

        _error(errorMessage);
    }];
}


-(void)setLoadingText:(NSString*)message {    
    [[NSNotificationCenter defaultCenter] postNotificationName:LOADING_TEXT_NOTIFICAITON_KEY object:message];
}

-(uint64_t)parseBitcoinValue:(NSString*)input {
    return [[self.webView executeJSSynchronous:@"precisionToSatoshiBN(\"%@\").toString()", input] longLongValue];
}

-(void)on_generate_key:(NSString*)address {
    NSLog(@"on_generate_key");
    
    [delegate didGenerateNewAddress:address];
}

-(void)error_restoring_wallet {
    NSLog(@"error_restoring_wallet");
    if ([delegate respondsToSelector:@selector(walletFailedToDecrypt:)])
        [delegate walletFailedToDecrypt:self];
}

-(void)did_decrypt {
    NSLog(@"did_decrypt");
    
    self.sharedKey = [self.webView executeJSSynchronous:@"MyWallet.getSharedKey()"];
    self.guid = [self.webView executeJSSynchronous:@"MyWallet.getGuid()"];

    if ([delegate respondsToSelector:@selector(walletDidLoad:)])
        [delegate walletDidLoad:self];
}

-(void)on_backup_wallet_error {
    NSLog(@"on_backup_wallet_error");
 
    if ([delegate respondsToSelector:@selector(didFailBackupWallet:)])
        [delegate didFailBackupWallet:self];
}

-(void)on_backup_wallet_success {
    NSLog(@"on_backup_wallet_success");
    
    if ([delegate respondsToSelector:@selector(didBackupWallet:)])
        [delegate didBackupWallet:self];

}

-(void)did_fail_set_guid {
    NSLog(@"did_fail_set_guid");
}

-(void)did_set_guid {
    NSLog(@"did_set_guid");
    
    if (self.password) {
        [self.webView executeJS:[NSString stringWithFormat:@"setPassword(\"%@\")", self.password]];
    }
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
    NSLog(@"webViewDidFinishLoad:");
    
    if ([delegate respondsToSelector:@selector(walletJSReady)])
        [delegate walletJSReady];
}

-(void)dealloc {
    self.guid = nil;
    self.sharedKey = nil;
    self.password = nil;
    self.delegate = nil;
    self.webView = nil;
    self.transactionProgressListeners = nil;
    
    [super dealloc];
}

//Callbacks from javascript localstorage
-(void)getKey:(NSString*)key success:(void (^)(NSString*))success {
    id value = [[NSUserDefaults standardUserDefaults] valueForKey:key];
    
    NSLog(@"getKey:%@", key);
    
    success(value);
}

-(void)saveKey:(NSString*)key value:(NSString*)value {
    NSLog(@"saveKey:%@", key);

    [[NSUserDefaults standardUserDefaults] setValue:value forKey:key];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)removeKey:(NSString*)key {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)clearKeys {
    NSString * appDomain = [[NSBundle mainBundle] bundleIdentifier];
    
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)makeNotice:(NSString*)type id:(NSString*)_id message:(NSString*)message {
    if ([type isEqualToString:@"error"]) {
        [app standardNotify:message title:@"Error" delegate:nil];
    } else if ([type isEqualToString:@"info"]) {
        [app standardNotify:message title:@"Information" delegate:nil];
    }
}

-(void)jsUncaughtException:(NSString*)message url:(NSString*)url lineNumber:(NSNumber*)lineNumber {
    
    NSString * decription = [NSString stringWithFormat:@"Javscript Exception: %@ File: %@ lineNumber: %@", message, url, lineNumber];
    
    NSException * exception = [[NSException alloc] initWithName:@"Uncaught Exception" reason:decription userInfo:nil];
    
    [UncaughtExceptionHandler logException:exception];
    
    [exception release];
    
    [app standardNotify:decription];
}

-(CurrencySymbol*)getLocalSymbol {
    return [CurrencySymbol symbolFromDict:[Wallet parseJSON:[webView executeJSSynchronous:@"JSON.stringify(symbol_local)"]]];
}

-(CurrencySymbol*)getBTCSymbol {
    return [CurrencySymbol symbolFromDict:[Wallet parseJSON:[webView executeJSSynchronous:@"JSON.stringify(symbol_btc)"]]];
}

-(void)on_add_private_key:(NSString*)address {
    [app standardNotify:[NSString stringWithFormat:@"Imported Private Key %@", address] title:@"Success" delegate:nil];
}

-(void)on_error_adding_private_key:(NSString*)error {
    [app standardNotify:error];
}

-(void)ajaxStart {
    NSLog(@"ajaxStart");
    
    if ([delegate respondsToSelector:@selector(networkActivityStart)])
        [delegate networkActivityStart];
}
-(void)ajaxStop {
    NSLog(@"ajaxStop");

    if ([delegate respondsToSelector:@selector(networkActivityStop)])
        [delegate networkActivityStop];
}

-(void)clearDelegates {
    self.webView.JSDelegate = nil;
    self.webView.delegate = nil;
    [self.webView stopLoading];
    self.webView = nil;
    self.delegate = nil;
}

-(NSInteger)getWebsocketReadyState {
    return [[self.webView executeJSSynchronous:@"MyWalletPhone.getWsReadyState()"] integerValue];
}

-(void)ws_on_close {
    NSLog(@"ws_on_close");

    [app setStatus];
}

-(void)ws_on_open {
    NSLog(@"ws_on_open");
    
    [app setStatus];
}

@end
