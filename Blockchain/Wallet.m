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
#import "NSString+NSString_EscapeQuotes.h"
#import "crypto_scrypt.h"
#import "NSData+Hex.h"
#import "TransactionsViewController.h"

@implementation transactionProgressListeners
@end

@implementation Key
@synthesize addr;
@synthesize priv;
@synthesize tag;
@synthesize label;

- (NSString *)description
{
    return [NSString stringWithFormat:@"<Key : addr %@, tag, %d>", addr, tag];
}

- (NSComparisonResult)compare:(Key *)otherObject
{
    return [self.addr compare:otherObject.addr];
}

@end

@implementation Wallet

@synthesize delegate;
@synthesize password;
@synthesize webView;
@synthesize sharedKey;
@synthesize guid;

- (id)init
{
    self = [super init];
    
    if (self) {
        _transactionProgressListeners = [NSMutableDictionary dictionary];
        webView = [[JSBridgeWebView alloc] initWithFrame:CGRectZero];
        webView.JSDelegate = self;
    }
    
    return self;
}

- (void)dealloc
{
    self.webView.JSDelegate = nil;
}

- (void)apiGetPINValue:(NSString*)key pin:(NSString*)pin withWalletDownload:(BOOL)withWalletDownload
{
    [self loadJS];
    
    [self.webView executeJS:@"MyWalletPhone.apiGetPINValue(\"%@\", \"%@\")", key, pin];
}

- (void)loadWalletWithGuid:(NSString*)_guid sharedKey:(NSString*)_sharedKey password:(NSString*)_password
{
    self.guid = _guid;
    // Shared Key can be empty
    self.sharedKey = _sharedKey;
    self.password = _password;
    
    // Load the JS. Proceed in the webViewDidFinishLoad callback
    [self loadJS];
}

- (void)loadBlankWallet
{
    [self loadWalletWithGuid:nil sharedKey:nil password:nil];
}

- (void)loadJS
{
    NSError *error = nil;
    NSString *walletHTML = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"wallet-ios" ofType:@"html"] encoding:NSUTF8StringEncoding error:&error];
    
    NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath]];
    
    [webView loadHTMLString:walletHTML baseURL:baseURL];
}

#pragma mark - WebView handlers

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    DLog(@"webViewDidStartLoad:");
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    DLog(@"WebView: didFailLoadWithError:");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    DLog(@"webViewDidFinishLoad:");
    
    if ([delegate respondsToSelector:@selector(walletJSReady)])
        [delegate walletJSReady];
    
    if ([delegate respondsToSelector:@selector(walletDidLoad)])
        [delegate walletDidLoad];
    
    if (self.guid && self.password) {
        DLog(@"Fetch Wallet");
        
        [self.webView executeJS:@"MyWalletPhone.fetchWalletJson(\"%@\", \"%@\", false, \"%@\")", [self.guid escapeStringForJS], [self.sharedKey escapeStringForJS], [self.password escapeStringForJS]];
    }
}

# pragma mark - Calls from Obj-C to JS

- (BOOL)isInitialized
{
    if ([self.webView isLoaded])
        return [[self.webView executeJSSynchronous:@"MyWallet.getIsInitialized()"] boolValue];
    else
        return FALSE;
}

- (BOOL)hasEncryptedWalletData
{
    if ([self.webView isLoaded])
        return [[self.webView executeJSSynchronous:@"MyWalletPhone.hasEncryptedWalletData()"] boolValue];
    else
        return NO;
}

- (BOOL)isDoubleEncrypted
{
    return [[self.webView executeJSSynchronous:@"MyWallet.getDoubleEncryption()"] boolValue];
}

- (void)pinServerPutKeyOnPinServerServer:(NSString*)key value:(NSString*)value pin:(NSString*)pin
{
    [self.webView executeJS:@"MyWalletPhone.pinServerPutKeyOnPinServerServer(\"%@\", \"%@\", \"%@\")", key, value, pin];
}

- (NSString*)encrypt:(NSString*)data password:(NSString*)_password pbkdf2_iterations:(int)pbkdf2_iterations
{
    return [self.webView executeJSSynchronous:@"MyWallet.encrypt(\"%@\", \"%@\", %d)", [data escapeStringForJS], [_password escapeStringForJS], pbkdf2_iterations];
}

- (NSString*)decrypt:(NSString*)data password:(NSString*)_password pbkdf2_iterations:(int)pbkdf2_iterations
{
    return [self.webView executeJSSynchronous:@"MyWallet.decryptPasswordWithProcessedPin(\"%@\", \"%@\", %d)", [data escapeStringForJS], [_password escapeStringForJS], pbkdf2_iterations];
}

- (void)getHistory
{
    if ([self isInitialized])
        [self.webView executeJS:@"MyWallet.get_history()"];
}

- (void)getWalletAndHistory
{
    if ([self isInitialized])
        [self.webView executeJS:@"MyWalletPhone.get_wallet_and_history()"];
}

- (CurrencySymbol*)getLocalSymbol
{
    if (![self.webView isLoaded]) {
        return nil;
    }
    
    return [CurrencySymbol symbolFromDict:[[webView executeJSSynchronous:@"JSON.stringify(symbol_local)"] getJSONObject]];
}

- (CurrencySymbol*)getBTCSymbol
{
    if (![self.webView isLoaded]) {
        return nil;
    }
    
    return [CurrencySymbol symbolFromDict:[[webView executeJSSynchronous:@"JSON.stringify(symbol_btc)"] getJSONObject]];
}

- (void)cancelTxSigning
{
    if (![self.webView isLoaded]) {
        return;
    }
    
    [self.webView executeJSSynchronous:@"MyWalletPhone.cancelTxSigning();"];
}

- (void)sendPaymentFromAddress:(NSString*)fromAddress toAddress:(NSString*)toAddress satoshiValue:(NSString *)satoshiValue listener:(transactionProgressListeners*)listener
{
    NSString * txProgressID = [self.webView executeJSSynchronous:@"MyWalletPhone.quickSendFromAddressToAddress(\"%@\", \"%@\", \"%@\")", [fromAddress escapeStringForJS], [toAddress escapeStringForJS], [satoshiValue escapeStringForJS]];
        
    [self.transactionProgressListeners setObject:listener forKey:txProgressID];
}

- (void)sendPaymentFromAddress:(NSString*)fromAddress toAccount:(int)toAccount satoshiValue:(NSString *)satoshiValue listener:(transactionProgressListeners*)listener
{
    NSString * txProgressID = [self.webView executeJSSynchronous:@"MyWalletPhone.quickSendFromAddressToAccount(\"%@\", %d, \"%@\")", [fromAddress escapeStringForJS], toAccount, [satoshiValue escapeStringForJS]];
    
    [self.transactionProgressListeners setObject:listener forKey:txProgressID];
}

- (void)sendPaymentFromAccount:(int)fromAccount toAddress:(NSString*)toAddress satoshiValue:(NSString *)satoshiValue listener:(transactionProgressListeners*)listener
{
    NSString * txProgressID = [self.webView executeJSSynchronous:@"MyWalletPhone.quickSendFromAccountToAddress(%d, \"%@\", \"%@\")", fromAccount, [toAddress escapeStringForJS], satoshiValue];
    
    [self.transactionProgressListeners setObject:listener forKey:txProgressID];
}

- (void)sendPaymentFromAccount:(int)fromAccount toAccount:(int)toAccount satoshiValue:(NSString *)satoshiValue listener:(transactionProgressListeners*)listener
{
    NSString * txProgressID = [self.webView executeJSSynchronous:@"MyWalletPhone.quickSendFromAccountToAccount(%d, %d, \"%@\")", fromAccount, toAccount, satoshiValue];
    
    [self.transactionProgressListeners setObject:listener forKey:txProgressID];
}

- (uint64_t)parseBitcoinValue:(NSString*)input
{
    if (![self.webView isLoaded]) {
        return 0;
    }
    
    return [[self.webView executeJSSynchronous:@"precisionToSatoshiBN(\"%@\").toString()", input] longLongValue];
}

// Make a request to blockchain.info to get the session id SID in a cookie. This cookie is around for new instances of UIWebView and will be used to let the server know the user is trying to gain access from a new device. The device is recognized based on the SID.
- (void)loadWalletLogin
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@wallet/login", WebROOT]];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    [webView loadRequest:requestObj];
}

- (void)parsePairingCode:(NSString*)code
{
    [self.webView executeJS:@"MyWalletPhone.parsePairingCode(\"%@\");", [code escapeStringForJS]];
}

// Pairing code JS callbacks
- (void)ask_for_private_key:(NSString*)address success:(void(^)(id))_success error:(void(^)(id))_error
{
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

- (void)newAccount:(NSString*)__password email:(NSString *)__email
{
    [self.webView executeJS:@"MyWalletPhone.newAccount(\"%@\", \"%@\")", [__password escapeStringForJS], [__email escapeStringForJS]];
}

- (BOOL)validateSecondPassword:(NSString*)secondPassword
{
    if (![self.webView isLoaded]) {
        return FALSE;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWallet.validateSecondPassword(\"%@\")", [secondPassword escapeStringForJS]] boolValue];
}

- (void)getFinalBalance
{
    [self.webView executeJSWithCallback:^(NSString * final_balance) {
        self.final_balance = [final_balance longLongValue];
        
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLongLong:self.final_balance] forKey:@"final_balance"];
        
    } command:@"MyWallet.getFinalBalance()"];
}

- (void)getTotalSent
{
    [self.webView executeJSWithCallback:^(NSString * total_sent) {
        self.total_sent = [total_sent longLongValue];
        
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLongLong:self.total_sent] forKey:@"total_sent"];
    } command:@"MyWallet.getTotalSent()"];
}

- (BOOL)isWatchOnlyLegacyAddress:(NSString*)address
{
    if (![self.webView isLoaded]) {
        return FALSE;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWallet.isWatchOnlyLegacyAddress(\"%@\")", [address escapeStringForJS]] boolValue];
}

- (NSString*)labelForLegacyAddress:(NSString*)address
{
    if (![self.webView isLoaded]) {
        return nil;
    }
    
    return [self.webView executeJSSynchronous:@"MyWallet.getLegacyAddressLabel(\"%@\")", [address escapeStringForJS]];
}

- (NSInteger)tagForLegacyAddress:(NSString*)address
{
    if (![self.webView isLoaded]) {
        return 0;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWallet.getLegacyAddressTag(\"%@\")", [address escapeStringForJS]] intValue];
}

- (BOOL)isValidAddress:(NSString*)string
{
    if (![self.webView isLoaded]) {
        return FALSE;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWallet.isValidAddress(\"%@\");", [string escapeStringForJS]] boolValue];
}

- (NSArray*)allLegacyAddresses
{
    if (![self.webView isLoaded]) {
        return nil;
    }
    
    NSString * allAddressesJSON = [self.webView executeJSSynchronous:@"JSON.stringify(MyWallet.getAllLegacyAddresses())"];
    
    return [allAddressesJSON getJSONObject];        
}

- (NSArray*)activeLegacyAddresses
{
    if (![self.webView isLoaded]) {
        return nil;
    }
    
    NSString *activeAddressesJSON = [self.webView executeJSSynchronous:@"JSON.stringify(MyWallet.getLegacyActiveAddresses())"];
    
    return [activeAddressesJSON getJSONObject];
}

- (NSArray*)archivedLegacyAddresses
{
    if (![self.webView isLoaded]) {
        return nil;
    }
    
    NSString *activeAddressesJSON = [self.webView executeJSSynchronous:@"JSON.stringify(MyWallet.getLegacyArchivedAddresses())"];
    
    return [activeAddressesJSON getJSONObject];
}

- (void)setLabel:(NSString*)label forLegacyAddress:(NSString*)address
{
    [self.webView executeJS:@"MyWallet.setLegacyAddressLabel(\"%@\", \"%@\")", [address escapeStringForJS], [label escapeStringForJS]];
}

- (void)archiveLegacyAddress:(NSString*)address
{
    [self.webView executeJS:@"MyWallet.archiveLegacyAddr(\"%@\")", [address escapeStringForJS]];
}

- (void)unArchiveLegacyAddress:(NSString*)address
{
    [self.webView executeJS:@"MyWallet.unArchiveLegacyAddr(\"%@\")", [address escapeStringForJS]];
}

- (void)removeLegacyAddress:(NSString*)address
{
    [self.webView executeJS:@"MyWallet.deleteLegacyAddress(\"%@\")", [address escapeStringForJS]];
}

- (uint64_t)getLegacyAddressBalance:(NSString*)address
{
    if (![self.webView isLoaded]) {
        return 0;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWallet.getLegacyAddressBalance(\"%@\")", [address escapeStringForJS]] longLongValue];
}

- (BOOL)addKey:(NSString*)privateKeyString
{
    if (![self.webView isLoaded]) {
        return 0;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWalletPhone.addPrivateKey(\"%@\")", [privateKeyString escapeStringForJS]] boolValue];
}

- (NSDictionary*)addressBook
{
    if (![self.webView isLoaded]) {
        return [[NSDictionary alloc] init];
    }
    
    NSString * addressBookJSON = [self.webView executeJSSynchronous:@"JSON.stringify(MyWallet.getAddressBook())"];
    
    return [addressBookJSON getJSONObject];
}

- (void)addToAddressBook:(NSString*)address label:(NSString*)label
{
    [self.webView executeJS:@"MyWalletPhone.addAddressBookEntry(\"%@\", \"%@\")", [address escapeStringForJS], [label escapeStringForJS]];
}

- (void)clearLocalStorage
{
    [self.webView executeJS:@"localStorage.clear();"];
}

- (NSString*)detectPrivateKeyFormat:(NSString*)privateKeyString
{
    if (![self.webView isLoaded]) {
        return nil;
    }
    
   return [self.webView executeJSSynchronous:@"MyWalletPhone.detectPrivateKeyFormat(\"%@\")", [privateKeyString escapeStringForJS]];
}

# pragma mark - Transaction handlers

- (void)tx_on_success:(NSString*)txProgressID
{
    transactionProgressListeners * listener = [self.transactionProgressListeners objectForKey:txProgressID];
    
    if (listener) {
        if (listener.on_success) {
            listener.on_success();
        }
    }
}

- (void)tx_on_start:(NSString*)txProgressID
{
    transactionProgressListeners * listener = [self.transactionProgressListeners objectForKey:txProgressID];
    
    if (listener) {
        if (listener.on_start) {
            listener.on_start();
        }
    }
}

- (void)tx_on_error:(NSString*)txProgressID error:(NSString*)error
{
    transactionProgressListeners * listener = [self.transactionProgressListeners objectForKey:txProgressID];
    
    if (listener) {
        if (listener.on_error) {
            listener.on_error(error);
        }
    }
}

- (void)tx_on_begin_signing:(NSString*)txProgressID
{
    transactionProgressListeners * listener = [self.transactionProgressListeners objectForKey:txProgressID];
    
    if (listener) {
        if (listener.on_begin_signing) {
            listener.on_begin_signing();
        }
    }
}

- (void)tx_on_sign_progress:(NSString*)txProgressID input:(NSString*)input
{
    transactionProgressListeners * listener = [self.transactionProgressListeners objectForKey:txProgressID];
    
    if (listener) {
        if (listener.on_sign_progress) {
            listener.on_sign_progress([input integerValue]);
        }
    }
}

- (void)tx_on_finish_signing:(NSString*)txProgressID
{
    transactionProgressListeners * listener = [self.transactionProgressListeners objectForKey:txProgressID];
    
    if (listener) {
        if (listener.on_finish_signing) {
            listener.on_finish_signing();
        }
    }
}

#pragma mark - Callbacks from JS to Obj-C

- (void)log:(NSString*)message
{
    DLog(@"console.log: %@", [message description]);
}

- (void)ajaxStart
{
    DLog(@"ajaxStart");
    
    if ([delegate respondsToSelector:@selector(networkActivityStart)])
        [delegate networkActivityStart];
}

- (void)ajaxStop
{
    DLog(@"ajaxStop");
    
    if ([delegate respondsToSelector:@selector(networkActivityStop)])
        [delegate networkActivityStop];
}

- (void)ws_on_open
{
    DLog(@"ws_on_open");
}

- (void)ws_on_close
{
    DLog(@"ws_on_close");
}

- (void)on_block
{
    DLog(@"on_block");
}

- (void)did_set_latest_block
{
    DLog(@"did_set_latest_block");
    
    [self.webView executeJSWithCallback:^(NSString* latestBlockJSON) {
        
        [[NSUserDefaults standardUserDefaults] setObject:latestBlockJSON forKey:@"transactions"];
        
        [self parseLatestBlockJSON:latestBlockJSON];
        
    } command:@"JSON.stringify(MyWallet.getLatestBlock())"];
}

- (void)parseLatestBlockJSON:(NSString*)latestBlockJSON
{
    NSDictionary *dict = [latestBlockJSON getJSONObject];
    
    LatestBlock *latestBlock = [[LatestBlock alloc] init];
    
    latestBlock.height = [[dict objectForKey:@"height"] intValue];
    latestBlock.time = [[dict objectForKey:@"time"] longLongValue];
    latestBlock.blockIndex = [[dict objectForKey:@"block_index"] intValue];
    
    [delegate didSetLatestBlock:latestBlock];
}

- (void)did_multiaddr
{
    DLog(@"did_multiaddr");
    
    [self getFinalBalance];
    
    [self.webView executeJSWithCallback:^(NSString * multiAddrJSON) {
        [self parseMultiAddrJSON:multiAddrJSON];
    } command:@"JSON.stringify(MyWalletPhone.getMultiAddrResponse())"];
}

- (void)parseMultiAddrJSON:(NSString*)multiAddrJSON
{
    if (multiAddrJSON == nil)
        return;
    
    NSDictionary *dict = [multiAddrJSON getJSONObject];
    
    MulitAddressResponse *response = [[MulitAddressResponse alloc] init];
    
    response.transactions = [NSMutableArray array];

    NSArray * transactionsArray = [dict objectForKey:@"transactions"];
    
    for (NSDictionary *dict in transactionsArray) {
        Transaction *tx = [Transaction fromJSONDict:dict];
        
        [response.transactions addObject:tx];
    }
        
    response.final_balance = [[dict objectForKey:@"final_balance"] longLongValue];
    response.total_received = [[dict objectForKey:@"total_received"] longLongValue];
    response.n_transactions = [[dict objectForKey:@"n_transactions"] longValue];
    response.total_sent = [[dict objectForKey:@"total_sent"] longLongValue];
    response.addresses = [dict objectForKey:@"addresses"];
    
    {
        NSDictionary *symbolLocalDict = [dict objectForKey:@"symbol_local"] ;
        if (symbolLocalDict) {
            response.symbol_local = [CurrencySymbol symbolFromDict:symbolLocalDict];
        }
    }
    
    {
        NSDictionary *symbolBTCDict = [dict objectForKey:@"symbol_btc"] ;
        if (symbolBTCDict) {
            response.symbol_btc = [CurrencySymbol symbolFromDict:symbolBTCDict];
        }
    }
    
    [delegate didGetMultiAddressResponse:response];
}

- (void)on_tx
{
    DLog(@"on_tx");

    [app playBeepSound];
    
    [app.transactionsViewController animateNextCellAfterReload];
    
    [self getHistory];
}

- (void)getPassword:(NSString*)selector success:(void(^)(id))_success
{
    [self getPassword:selector success:_success error:nil];
}

- (void)getPassword:(NSString*)selector success:(void(^)(id))_success error:(void(^)(id))_error
{
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

- (void)setLoadingText:(NSString*)message
{
    [[NSNotificationCenter defaultCenter] postNotificationName:LOADING_TEXT_NOTIFICATION_KEY object:message];
}

- (void)makeNotice:(NSString*)type id:(NSString*)_id message:(NSString*)message
{
    // This is kind of ugly. When the wallet fails to load, usually because of a connection problem, wallet.js throws two errors in the setGUID function and we only want to show one. This filters out the one we don't want to show.
    if ([message isEqualToString:@"Error changing wallet identifier"]) {
        return;
    }
    
    if ([type isEqualToString:@"error"]) {
        [app standardNotify:message title:BC_STRING_ERROR delegate:nil];
    } else if ([type isEqualToString:@"info"]) {
        [app standardNotify:message title:BC_STRING_INFORMATION delegate:nil];
    }
}

- (void)error_restoring_wallet
{
    DLog(@"error_restoring_wallet");
    if ([delegate respondsToSelector:@selector(walletFailedToDecrypt)])
        [delegate walletFailedToDecrypt];
}

- (void)did_decrypt
{
    DLog(@"did_decrypt");
    
    self.sharedKey = [self.webView executeJSSynchronous:@"MyWallet.getSharedKey()"];
    self.guid = [self.webView executeJSSynchronous:@"MyWallet.getGuid()"];

    if ([delegate respondsToSelector:@selector(walletDidDecrypt)])
        [delegate walletDidDecrypt];
}

- (void)on_create_new_account:(NSString*)_guid sharedKey:(NSString*)_sharedKey password:(NSString*)_password
{
    DLog(@"on_create_new_account:");
    
    if ([delegate respondsToSelector:@selector(didCreateNewAccount:sharedKey:password:)])
        [delegate didCreateNewAccount:_guid sharedKey:_sharedKey password:_password];
}

- (void)on_add_private_key:(NSString*)address
{
    [app standardNotify:[NSString stringWithFormat:BC_STRING_IMPORTED_PRIVATE_KEY, address] title:BC_STRING_SUCCESS delegate:nil];
}

- (void)on_error_adding_private_key:(NSString*)error
{
    [app standardNotify:error];
}

- (void)on_error_creating_new_account:(NSString*)message
{
    DLog(@"on_error_creating_new_account:");
    
    if ([delegate respondsToSelector:@selector(errorCreatingNewAccount:)])
        [delegate errorCreatingNewAccount:message];
}

- (void)on_error_pin_code_put_error:(NSString*)message
{
    DLog(@"on_error_pin_code_put_error:");
    
    if ([delegate respondsToSelector:@selector(didFailPutPin:)])
        [delegate didFailPutPin:message];
}

- (void)on_pin_code_put_response:(NSDictionary*)responseObject
{
    DLog(@"on_pin_code_put_response: %@", responseObject);
    
    if ([delegate respondsToSelector:@selector(didPutPinSuccess:)])
        [delegate didPutPinSuccess:responseObject];
}

- (void)on_error_pin_code_get_error:(NSString*)message
{
    DLog(@"on_error_pin_code_get_error:");
    
    if ([delegate respondsToSelector:@selector(didFailGetPin:)])
        [delegate didFailGetPin:message];
}

- (void)on_error_pin_code_get_timeout
{
    DLog(@"on_error_pin_code_get_timeout");
    
    if ([delegate respondsToSelector:@selector(didFailGetPinTimeout)])
    [delegate didFailGetPinTimeout];
}

- (void)on_error_pin_code_get_empty_response
{
    DLog(@"on_error_pin_code_get_empty_response");
    
    if ([delegate respondsToSelector:@selector(didFailGetPinNoResponse)])
    [delegate didFailGetPinNoResponse];
}

- (void)on_error_pin_code_get_invalid_response
{
    DLog(@"on_error_pin_code_get_invalid_response");
    
    if ([delegate respondsToSelector:@selector(didFailGetPinInvalidResponse)])
    [delegate didFailGetPinInvalidResponse];
}

- (void)on_pin_code_get_response:(NSDictionary*)responseObject
{
    DLog(@"on_pin_code_get_response:");
    
    if ([delegate respondsToSelector:@selector(didGetPinSuccess:)])
        [delegate didGetPinSuccess:responseObject];
}

- (void)on_wallet_decrypt_start
{
    DLog(@"on_wallet_decrypt_start");
    
    if ([delegate respondsToSelector:@selector(didWalletDecryptStart)])
        [delegate didWalletDecryptStart];
}

- (void)on_wallet_decrypt_finish
{
    DLog(@"on_wallet_decrypt_finish");
    
    if ([delegate respondsToSelector:@selector(didWalletDecryptFinish)])
        [delegate didWalletDecryptFinish];
}

- (void)on_backup_wallet_error
{
    DLog(@"on_backup_wallet_error");
    
    if ([delegate respondsToSelector:@selector(didFailBackupWallet)])
        [delegate didFailBackupWallet];
}

- (void)on_backup_wallet_success
{
    DLog(@"on_backup_wallet_success");
    
    if ([delegate respondsToSelector:@selector(didBackupWallet)])
        [delegate didBackupWallet];
}

- (void)did_fail_set_guid
{
    DLog(@"did_fail_set_guid");
    
    if ([delegate respondsToSelector:@selector(walletFailedToLoad)])
        [delegate walletFailedToLoad];
}

# pragma mark - Calls from Obj-C to JS for HD wallet

- (int)getAccountsCount
{
    if (![self isInitialized]) {
        return 0;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWallet.getAccountsCount()"] intValue];
}

- (int)getDefaultAccountIndex
{
    if (![self isInitialized]) {
        return 0;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWallet.getDefaultAccountIndex()"] intValue];
}

- (BOOL)hasLegacyAddresses
{
    if (![self isInitialized]) {
        return false;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWallet.hasLegacyAddresses()"] boolValue];
}

- (uint64_t)getTotalBalanceForActiveLegacyAddresses
{
    if (![self isInitialized]) {
        return 0;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWallet.getTotalBalanceForActiveLegacyAddresses()"] longLongValue];
}

- (uint64_t)getBalanceForAccount:(int)account
{
    if (![self isInitialized]) {
        return 0;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWallet.getBalanceForAccount(%d)", account] longLongValue];
}

- (NSString *)getLabelForAccount:(int)account
{
    if (![self isInitialized]) {
        return nil;
    }
    
    return [self.webView executeJSSynchronous:@"MyWallet.getLabelForAccount(%d)", account];
}

- (void)setLabelForAccount:(int)account label:(NSString *)label
{
    if ([self isInitialized]) {
        [self.webView executeJSSynchronous:@"MyWallet.setLabelForAccount(%d, \"%@\")", account, label];
    }
}

- (void)createAccountWithLabel:(NSString *)label
{
    if ([self isInitialized]) {
        [self.webView executeJSSynchronous:@"MyWallet.createAccount(\"%@\")", label];
    }
}

- (NSString *)getEmptyPaymentRequestAddressForAccount:(int)account
{
    if (![self isInitialized]) {
        return nil;
    }
    
    return [self.webView executeJSSynchronous:@"MyWalletPhone.getEmptyPaymentRequestAddressForAccount(%d)", account];
}

#pragma mark - Callbacks from JS to Obj-C for HD wallet

- (void)hd_wallets_does_not_exist
{
    DLog(@"hd_wallets_does_not_exist");
    
    DLog(@"Creating new HD Wallet");
    [self.webView executeJS:@"MyWallet.initializeHDWallet(MyWallet.generateHDWalletPassphrase())"];
}

- (void)hw_wallet_balance_updated
{
    DLog(@"hw_wallet_balance_updated");
    
    [app reload];
}

- (void)logging_out
{
    DLog(@"logging_out");
    
    // TODO implement this
}

#pragma mark - Callbacks from javascript localstorage

- (void)getKey:(NSString*)key success:(void (^)(NSString*))success 
{
    id value = [[NSUserDefaults standardUserDefaults] valueForKey:key];
    
    DLog(@"getKey:%@", key);
    
    success(value);
}

- (void)saveKey:(NSString*)key value:(NSString*)value 
{
    DLog(@"saveKey:%@", key);

    [[NSUserDefaults standardUserDefaults] setValue:value forKey:key];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)removeKey:(NSString*)key 
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)clearKeys 
{
    NSString * appDomain = [[NSBundle mainBundle] bundleIdentifier];
    
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

# pragma mark - Cyrpto helpers, called from JS

- (void)crypto_scrypt:(id)_password salt:(id)salt n:(NSNumber*)N r:(NSNumber*)r p:(NSNumber*)p dkLen:(NSNumber*)derivedKeyLen success:(void(^)(id))_success error:(void(^)(id))_error
{
    [app setLoadingText:BC_STRING_DECRYPTING_PRIVATE_KEY];
    
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

- (NSData*)_internal_crypto_scrypt:(id)_password salt:(id)_salt n:(uint64_t)N r:(uint32_t)r p:(uint32_t)p dkLen:(uint32_t)derivedKeyLen
{    
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

#pragma mark - JS Exception handler

- (void)jsUncaughtException:(NSString*)message url:(NSString*)url lineNumber:(NSNumber*)lineNumber
{
    
    NSString * decription = [NSString stringWithFormat:@"Javscript Exception: %@ File: %@ lineNumber: %@", message, url, lineNumber];
    
#ifndef DEBUG
    NSException * exception = [[NSException alloc] initWithName:@"Uncaught Exception" reason:decription userInfo:nil];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
        [UncaughtExceptionHandler logException:exception walletIsLoaded:[self.webView isLoaded] walletIsInitialized:[self isInitialized]];
    });
#endif
    
    [app standardNotify:decription];
}

@end
