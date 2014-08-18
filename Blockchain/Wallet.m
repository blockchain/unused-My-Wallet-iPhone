//
//  Wallet.m
//  Blockchain
//
//  Created by Ben Reeves on 16/03/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "Wallet.h"
#import "AppDelegate.h"
#import "Transaction.h"
#import "NSString+NSString_EscapeQuotes.h"
#import "MultiAddressResponse.h"
#import "UncaughtExceptionHandler.h"
#import "NSString+JSONParser_NSString.h"
#import "crypto_scrypt.h"
#import "NSData+Hex.h"

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

+ (NSString *)generateUUID 
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return (__bridge NSString *)string;
}

-(BOOL)isInitialized {
    if ([self.webView isLoaded])
        return [[self.webView executeJSSynchronous:@"MyWallet.getIsInitialized()"] boolValue];
    else
        return FALSE;
}

-(BOOL)isDoubleEncrypted {
    return [[self.webView executeJSSynchronous:@"MyWallet.getDoubleEncryption()"] boolValue];
}

-(void)getHistory {
    if ([self isInitialized])
        [self.webView executeJS:@"MyWallet.get_history()"];
}

-(void)getWalletAndHistory {
    if ([self isInitialized])
        [self.webView executeJS:@"MyWalletPhone.get_wallet_and_history()"];
}

-(void)cancelTxSigning {
    if (![self.webView isLoaded]) {
        return;
    }
    
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
    
    NSString * txProgressID = [self.webView executeJSSynchronous:@"MyWalletPhone.quickSend(\"%@\", \"%@\", \"%@\")", [fromAddress escapeStringForJS], [toAddress escapeStringForJS], [satoshiValue escapeStringForJS]];
        
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
    [self.webView executeJS:@"MyWalletPhone.parsePairingCode(\"%@\");", [code escapeStringForJS]];
}


-(void)ask_for_private_key:(NSString*)address success:(void(^)(id))_success error:(void(^)(id))_error {
    DLog(@"ask_for_private_key:");
    
    if ([delegate respondsToSelector:@selector(askForPrivateKey:success:error:)])
        [delegate askForPrivateKey:address success:_success error:_error];
}

- (void)didParsePairingCode:(NSDictionary *)dict
{
    DLog(@"didParsePairingCode:");

    if ([delegate respondsToSelector:@selector(didParsePairingCode:)])
        [delegate didParsePairingCode:dict];
}

- (void)errorParsingPairingCode:(NSString *)message
{
    DLog(@"errorParsingPairingCode:");
    
    if ([delegate respondsToSelector:@selector(errorParsingPairingCode:)])
        [delegate errorParsingPairingCode:message];
}

#pragma mark Init Methods

//Called When Reading QR Pairing
-(id)init {
    if ([super init]) {
        self.transactionProgressListeners = [NSMutableDictionary dictionary];
        self.webView = [[JSBridgeWebView alloc] initWithFrame:CGRectZero];
        [webView setJSDelegate:self];
    }
    
    return self;
}

//Called when entering guid manually
-(void)loadGuid:(NSString *)_guid  {
    
    if (![self.guid isEqualToString:_guid]) {
        self.sharedKey = nil;
        self.password = nil;
    }
    
    self.guid = _guid;

    [self loadJS];
}

//Normal load with sharedKey to skip two factor
-(void)loadGuid:(NSString*)_guid sharedKey:(NSString*)_sharedKey {
    
    if (![self.guid isEqualToString:_guid]) {
        self.password = nil;
    }
    
    self.guid = _guid;
    self.sharedKey = _sharedKey;
    
    // Load the JS. Proceed in the webviewDidLoad callback
    [self loadJS];
}

//Load the blank wallet login page
-(void)loadBlankWallet {
    self.guid = nil;
    self.password = nil;
    self.sharedKey = nil;
    
    [self loadJS];
}

-(BOOL)validateSecondPassword:(NSString*)secondPassword {
    if (![self.webView isLoaded]) {
        return FALSE;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWallet.validateSecondPassword(\"%@\")", [secondPassword escapeStringForJS]] boolValue];
}

-(BOOL)isWatchOnlyAddress:(NSString*)address {
    if (![self.webView isLoaded]) {
        return FALSE;
    }
    
    return ![[self.webView executeJSSynchronous:@"MyWallet.isWatchOnly(\"%@\")", [address escapeStringForJS]] boolValue];
}


-(NSString*)labelForAddress:(NSString*)address {
    if (![self.webView isLoaded]) {
        return nil;
    }
    
    return [self.webView executeJSSynchronous:@"MyWallet.getAddressLabel(\"%@\")", [address escapeStringForJS]];
}

-(NSInteger)tagForAddress:(NSString*)address {
    if (![self.webView isLoaded]) {
        return 0;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWallet.getAddressTag(\"%@\")", [address escapeStringForJS]] intValue];
}

-(BOOL)isValidAddress:(NSString*)string {
    if (![self.webView isLoaded]) {
        return FALSE;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWalletPhone.isValidAddress(\"%@\");", [string escapeStringForJS]] boolValue];
}

-(NSArray*)allAddresses {
    if (![self.webView isLoaded]) {
        return nil;
    }
    
    NSString * allAddressesJSON = [self.webView executeJSSynchronous:@"JSON.stringify(MyWallet.getAllAddresses())"];
    
    return [allAddressesJSON getJSONObject];        
}

-(NSArray*)activeAddresses {
    if (![self.webView isLoaded]) {
        return nil;
    }
    
    NSString * activeAddressesJSON = [self.webView executeJSSynchronous:@"JSON.stringify(MyWallet.getActiveAddresses())"];
    
    return [activeAddressesJSON getJSONObject];
}

-(NSArray*)archivedAddresses {
    if (![self.webView isLoaded]) {
        return nil;
    }
    
    NSString * activeAddressesJSON = [self.webView executeJSSynchronous:@"JSON.stringify(MyWallet.getArchivedAddresses())"];
    
    return [activeAddressesJSON getJSONObject];
}



-(void)setLabel:(NSString*)label ForAddress:(NSString*)address {
    [self.webView executeJS:@"MyWallet.setLabel(\"%@\", \"%@\")", [address escapeStringForJS], [label escapeStringForJS]];
}

-(void)archiveAddress:(NSString*)address {
    [self.webView executeJS:@"MyWallet.archiveAddr(\"%@\")", [address escapeStringForJS]];
}

-(void)unArchiveAddress:(NSString*)address {
    [self.webView executeJS:@"MyWallet.unArchiveAddr(\"%@\")", [address escapeStringForJS]];
}

-(void)removeAddress:(NSString*)address {
    [self.webView executeJS:@"MyWallet.deleteAddress(\"%@\")", [address escapeStringForJS]];
}

-(uint64_t)getAddressBalance:(NSString*)address {
    if (![self.webView isLoaded]) {
        return 0;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWallet.getAddressBalance(\"%@\")", [address escapeStringForJS]] longLongValue];
}

-(BOOL)addKey:(NSString*)privateKeyString {
    if (![self.webView isLoaded]) {
        return 0;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWalletPhone.addPrivateKey(\"%@\")", [privateKeyString escapeStringForJS]] boolValue];
}

-(NSDictionary*)addressBook {
    NSString * addressBookJSON = [self.webView executeJSSynchronous:@"JSON.stringify(MyWallet.getAddressBook())"];
    
    return [addressBookJSON getJSONObject];
}

-(void)addToAddressBook:(NSString*)address label:(NSString*)label {
    [self.webView executeJS:@"MyWalletPhone.addAddressBookEntry(\"%@\", \"%@\")", [address escapeStringForJS], [label escapeStringForJS]];
}

-(void)clearLocalStorage {
    [self.webView executeJS:@"localStorage.clear();"];
}

-(NSString*)detectPrivateKeyFormat:(NSString*)privateKeyString {
    if (![self.webView isLoaded]) {
        return nil;
    }
    
   return [self.webView executeJSSynchronous:@"MyWalletPhone.detectPrivateKeyFormat(\"%@\")", [privateKeyString escapeStringForJS]];
}

// Calls from JS

-(void)log:(NSString*)message {
    DLog(@"console.log: %@", [message description]);
}


-(void)parseLatestBlockJSON:(NSString*)latestBlockJSON {
    
    NSDictionary * dict = [latestBlockJSON getJSONObject];
    
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
    
    NSDictionary * dict = [multiAddrJSON getJSONObject];
    
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
    DLog(@"on_tx");

    [app playBeepSound];
    
    [self getHistory];
}

-(void)did_multiaddr {
    DLog(@"did_multiaddr");
    
    [self getFinalBalance];
    
    [self.webView executeJSWithCallback:^(NSString * multiAddrJSON) {
        [self parseMultiAddrJSON:multiAddrJSON];
    } command:@"JSON.stringify(MyWalletPhone.getMultiAddrResponse())"];
}


-(void)on_block {
    DLog(@"on_block");
}

-(void)did_set_latest_block {
    
    DLog(@"did_set_latest_block");
    
    [self.webView executeJSWithCallback:^(NSString* latestBlockJSON) {
        
        [[NSUserDefaults standardUserDefaults] setObject:latestBlockJSON forKey:@"transactions"];

        [self parseLatestBlockJSON:latestBlockJSON];
        
    } command:@"JSON.stringify(MyWallet.getLatestBlock())"];
}

-(void)getPassword:(NSString*)selector success:(void(^)(id))_success {
    [self getPassword:selector success:_success error:nil];
}

-(void)getPassword:(NSString*)selector success:(void(^)(id))_success error:(void(^)(id))_error {
    if ([selector isEqualToString:@"#second-password-modal"]) {
        [app getSecondPassword:^(NSString * _secondPassword) {
            _success(_secondPassword);
        } error:_error];
    } else if ([selector isEqualToString:@"#import-private-key-password"]) {
        [app getPrivateKeyPassword:^(NSString * _secondPassword) {
            _success(_secondPassword);
        } error:_error];
    } else {
        @throw [NSException exceptionWithName:@"Unknown Modal" reason:[NSString stringWithFormat:@"Unknown Modal Selector %@", selector] userInfo:nil];
    }
}


-(void)setLoadingText:(NSString*)message {    
    [[NSNotificationCenter defaultCenter] postNotificationName:LOADING_TEXT_NOTIFICAITON_KEY object:message];
}

-(uint64_t)parseBitcoinValue:(NSString*)input {
    if (![self.webView isLoaded]) {
        return 0;
    }
    
    return [[self.webView executeJSSynchronous:@"precisionToSatoshiBN(\"%@\").toString()", input] longLongValue];
}

-(void)on_generate_key:(NSString*)address {
    DLog(@"on_generate_key");
    
    [delegate didGenerateNewAddress:address];
}

-(void)error_restoring_wallet {
    DLog(@"error_restoring_wallet");
    if ([delegate respondsToSelector:@selector(walletFailedToDecrypt)])
        [delegate walletFailedToDecrypt];
}

-(void)did_decrypt {
    DLog(@"did_decrypt");
    
    self.sharedKey = [self.webView executeJSSynchronous:@"MyWallet.getSharedKey()"];
    self.guid = [self.webView executeJSSynchronous:@"MyWallet.getGuid()"];

    if ([delegate respondsToSelector:@selector(walletDidDecrypt)])
        [delegate walletDidDecrypt];
}


-(void)on_create_new_account:(NSString*)_guid sharedKey:(NSString*)_sharedKey password:(NSString*)_password {
    DLog(@"on_create_new_account:");
    
    if ([delegate respondsToSelector:@selector(didCreateNewAccount:sharedKey:password:)])
        [delegate didCreateNewAccount:_guid sharedKey:_sharedKey password:_password];
}

-(void)on_error_creating_new_account:(NSString*)message {
    DLog(@"on_error_creating_new_account:");
    
    if ([delegate respondsToSelector:@selector(errorCreatingNewAccount:)])
        [delegate errorCreatingNewAccount:message];
}


-(void)on_error_pin_code_put_error:(NSString*)message {
    DLog(@"on_error_pin_code_put_error:");
    
    if ([delegate respondsToSelector:@selector(didFailPutPin:)])
        [delegate didFailPutPin:message];
}

-(void)on_pin_code_put_response:(NSDictionary*)responseObject {
    DLog(@"on_pin_code_put_response: %@", responseObject);
    
    if ([delegate respondsToSelector:@selector(didPutPinSuccess:)])
        [delegate didPutPinSuccess:responseObject];
}

-(void)on_error_pin_code_get_error:(NSString*)message {
    DLog(@"on_error_pin_code_get_error:");
    
    if ([delegate respondsToSelector:@selector(didFailGetPin:)])
        [delegate didFailGetPin:message];
}

-(void)on_pin_code_get_response:(NSDictionary*)responseObject {
    DLog(@"on_pin_code_get_response:");
    
    if ([delegate respondsToSelector:@selector(didGetPinSuccess:)])
        [delegate didGetPinSuccess:responseObject];
}


-(void)on_wallet_decrypt_start {
    DLog(@"on_wallet_decrypt_start");
    
    if ([delegate respondsToSelector:@selector(didWalletDecryptStart)])
        [delegate didWalletDecryptStart];
}

-(void)on_wallet_decrypt_finish {
    DLog(@"on_wallet_decrypt_finish");
    
    if ([delegate respondsToSelector:@selector(didWalletDecryptFinish)])
        [delegate didWalletDecryptFinish];
}

-(void)on_backup_wallet_error {
    DLog(@"on_backup_wallet_error");
    
    if ([delegate respondsToSelector:@selector(didFailBackupWallet)])
        [delegate didFailBackupWallet];
}

-(void)on_backup_wallet_success {
    DLog(@"on_backup_wallet_success");
    
    if ([delegate respondsToSelector:@selector(didBackupWallet)])
        [delegate didBackupWallet];

}

-(void)did_fail_set_guid {
    DLog(@"did_fail_set_guid");
    
    if ([delegate respondsToSelector:@selector(walletFailedToLoad)])
        [delegate walletFailedToLoad];
}

-(void)did_set_guid {
    DLog(@"did_set_guid");
    
    if (self.password) {
        DLog(@"Setting Password");
        
        [self.webView executeJS:@"MyWalletPhone.setPassword(\"%@\")", [self.password escapeStringForJS]];
    }
    
    if ([delegate respondsToSelector:@selector(walletDidLoad)])
        [delegate walletDidLoad];
}

-(BOOL)hasEncryptedWalletData {
    if ([self.webView isLoaded])
        return [[self.webView executeJSSynchronous:@"MyWalletPhone.hasEncryptedWalletData()"] boolValue];
    else
        return NO;
}

-(void)setPassword:(NSString *)pw {
    password = pw;
    
    if (password) {
        DLog(@"Setting Password");
        
        [self.webView executeJS:@"MyWalletPhone.setPassword(\"%@\")", [self.password escapeStringForJS]];
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    DLog(@"Start load");
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    DLog(@"did fail");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    DLog(@"webViewDidFinishLoad:");
    
    if ([delegate respondsToSelector:@selector(walletJSReady)])
        [delegate walletJSReady];
}

-(void)dealloc {
    self.webView.JSDelegate = nil;
    
}

//Callbacks from javascript localstorage
-(void)getKey:(NSString*)key success:(void (^)(NSString*))success {
    id value = [[NSUserDefaults standardUserDefaults] valueForKey:key];
    
    DLog(@"getKey:%@", key);
    
    success(value);
}

-(void)saveKey:(NSString*)key value:(NSString*)value {
    DLog(@"saveKey:%@", key);

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
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
        [UncaughtExceptionHandler logException:exception walletIsLoaded:[self.webView isLoaded] walletIsInitialized:[self isInitialized]];
    });
    
    [app standardNotify:decription];
}

-(CurrencySymbol*)getLocalSymbol {
    if (![self.webView isLoaded]) {
        return nil;
    }
    
    return [CurrencySymbol symbolFromDict:[[webView executeJSSynchronous:@"JSON.stringify(symbol_local)"] getJSONObject]];
}

-(CurrencySymbol*)getBTCSymbol {
    if (![self.webView isLoaded]) {
        return nil;
    }
    
    return [CurrencySymbol symbolFromDict:[[webView executeJSSynchronous:@"JSON.stringify(symbol_btc)"] getJSONObject]];
}

-(void)on_add_private_key:(NSString*)address {
    [app standardNotify:[NSString stringWithFormat:@"Imported Private Key %@", address] title:@"Success" delegate:nil];
}

-(void)on_error_adding_private_key:(NSString*)error {
    [app standardNotify:error];
}

-(void)ajaxStart {
    DLog(@"ajaxStart");
    
    if ([delegate respondsToSelector:@selector(networkActivityStart)])
        [delegate networkActivityStart];
}
-(void)ajaxStop {
    DLog(@"ajaxStop");

    if ([delegate respondsToSelector:@selector(networkActivityStop)])
        [delegate networkActivityStop];
}

-(NSInteger)getWebsocketReadyState {
    if ([self.webView isLoaded])
        return [[self.webView executeJSSynchronous:@"MyWalletPhone.getWsReadyState()"] integerValue];
    else
        return -1;
}

-(void)ws_on_close {
    DLog(@"ws_on_close");

    [app setStatus];
}

-(void)ws_on_open {
    DLog(@"ws_on_open");
    
    [app setStatus];
}

-(void)newAccount:(NSString*)__password email:(NSString *)__email {
    [self.webView executeJS:@"MyWalletPhone.newAccount(\"%@\", \"%@\")", [__password escapeStringForJS], [__email escapeStringForJS]];
}

-(NSData*)_internal_crypto_scrypt:(id)_password salt:(id)_salt n:(uint64_t)N
                   r:(uint32_t)r p:(uint32_t)p dkLen:(uint32_t)derivedKeyLen {
    
    uint8_t * _passwordBuff = NULL;
    int _passwordBuffLen = 0;
    if ([_password isKindOfClass:[NSArray class]]) {
        _passwordBuff = alloca([_password count]);
        _passwordBuffLen = [_password count];
        
        {
            int ii = 0;
            for (NSNumber * number in _password) {
                _passwordBuff[ii] = [number shortValue];
                ++ii;
            }
        }
    } else if ([_password isKindOfClass:[NSString class]]) {
         _passwordBuff = (uint8_t*)[_password UTF8String];
        _passwordBuffLen = [_password length];
    } else {
        DLog(@"Scrypt password unsupported type");
        return nil;
    }
    
    uint8_t * _saltBuff = NULL;
    int _saltBuffLen = 0;

    if ([_salt isKindOfClass:[NSArray class]]) {
        _saltBuff = alloca([_salt count]);
        _saltBuffLen = [_salt count];

        {
            int ii = 0;
            for (NSNumber * number in _salt) {
                _saltBuff[ii] = [number shortValue];
                ++ii;
            }
        }
    } else if ([_salt isKindOfClass:[NSString class]]) {
        _saltBuff = (uint8_t*)[_password UTF8String];
        _saltBuffLen = [_password length];
    } else {
        DLog(@"Scrypt salt unsupported type");
        return nil;
    }
    
    uint8_t * derivedBytes = malloc(derivedKeyLen);
    
    if (crypto_scrypt((uint8_t*)_passwordBuff, _passwordBuffLen, (uint8_t*)_saltBuff, _saltBuffLen, N, r, p, derivedBytes, derivedKeyLen) == -1) {
        return nil;
    }

    return [NSData dataWithBytesNoCopy:derivedBytes length:derivedKeyLen];
}


-(void)crypto_scrypt:(id)_password salt:(id)salt n:(NSNumber*)N
                   r:(NSNumber*)r p:(NSNumber*)p dkLen:(NSNumber*)derivedKeyLen success:(void(^)(id))_success error:(void(^)(id))_error {
        
    [app setLoadingText:@"Decrypting Private Key"];
    
    [app networkActivityStart];
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData * data = [self _internal_crypto_scrypt:_password salt:salt n:[N unsignedLongLongValue] r:[r unsignedIntegerValue] p:[p unsignedIntegerValue] dkLen:[derivedKeyLen unsignedIntegerValue]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [app networkActivityStop];

            if (data) {
                _success([data hexadecimalString]);
            } else {
                _error(@"Scrypt Error");
            }
        });
    });
}

-(void)pinServerPutKeyOnPinServerServer:(NSString*)key value:(NSString*)value pin:(NSString*)pin {
    [self.webView executeJS:@"MyWalletPhone.pinServerPutKeyOnPinServerServer(\"%@\", \"%@\", \"%@\")", key, value, pin];
}

-(void)apiGetPINValue:(NSString*)key pin:(NSString*)pin {
    [self.webView executeJS:@"MyWalletPhone.apiGetPINValue(\"%@\", \"%@\")", key, pin];
}

-(NSString*)encrypt:(NSString*)data password:(NSString*)_password pbkdf2_iterations:(int)pbkdf2_iterations {
    return [self.webView executeJSSynchronous:@"MyWallet.encrypt(\"%@\", \"%@\", %d)", data, _password, pbkdf2_iterations];
}

-(NSString*)decrypt:(NSString*)data password:(NSString*)_password pbkdf2_iterations:(int)pbkdf2_iterations {
    return [self.webView executeJSSynchronous:@"MyWalletPhone.decrypt(\"%@\", \"%@\", %d)", data, _password, pbkdf2_iterations];
}

@end
