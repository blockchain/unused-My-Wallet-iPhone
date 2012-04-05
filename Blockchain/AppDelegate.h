/*
 * 
 * Copyright (c) 2012, Ben Reeves. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301  USA
 */

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

#import "Wallet.h"
#import "RemoteDataSource.h"
#import "WebSocket.h"
#import "Reachability.h"
#import "TabViewController.h"
#import "ZBarSDK.h"

#define SATOSHI 100000000
#define MultiaddrCacheFile @"multiaddr.cache"
#define WalletCachefile @"wallet.aes.json"
#define WebSocketURL @"ws://api.blockchain.info:8335/inv"
#define WebROOT @"https://blockchain.info/"
#define MULTI_ADDR_TIME 60.0f //1 Minute

//Some features disabled to pass review process
#define CYDIA

@class TransactionsViewController, RemoteDataSource, Wallet, UIFadeView, ReceiveCoinsViewController, AccountViewController, SendViewController, WebViewController, NewAccountView, MulitAddressResponse;

typedef enum {
    TaskGetMultiAddr,
    TaskGetWallet,
    TaskSaveWallet,
    TaskGeneratingWallet,
    TaskLoadExternalURL
} Task;

@interface AppDelegate : UIResponder <UIApplicationDelegate, RemoteDataSourceDelagate, WalletDelegate, WebSocketDelegate, ZBarReaderViewDelegate> {
    RemoteDataSource * dataSource;
    Wallet * wallet;
    WebSocket * webSocket;
    Reachability * reachability;
    
    SystemSoundID alertSoundID;
    SystemSoundID beepSoundID;
    SystemSoundID dingSoundID;

    BOOL symbolLocal;
    
    NSNumberFormatter * btcFromatter;
    
    int _tempLastKeyCount;
    
    IBOutlet UIActivityIndicatorView * activity;
    IBOutlet UIFadeView * busyView;
    IBOutlet UILabel * busyLabel;
    IBOutlet UIButton * powerButton;
    
    IBOutlet TabViewcontroller * tabViewController;
    
    IBOutlet TransactionsViewController * transactionsViewController;
    IBOutlet ReceiveCoinsViewController * receiveViewController;
    IBOutlet SendViewController * sendViewController;
    IBOutlet AccountViewController * accountViewController;
    
    IBOutlet UIView * welcomeView;
    IBOutlet NewAccountView * newAccountView;
    IBOutlet UIView * pairingInstructionsView;
    IBOutlet UIButton * pairLogoutButton;
    IBOutlet UIView * secondPasswordView;
    IBOutlet UITextField * secondPasswordTextField;
    
    WebViewController * webViewController;
    
    int webScoketFailures;
        
    int tasks;
}

@property (strong, nonatomic) IBOutlet UIWindow *window;
@property (retain, nonatomic) Wallet * wallet;
@property (retain, strong) MulitAddressResponse * latestResponse;

@property (retain, nonatomic) WebSocket * webSocket;
@property (retain, nonatomic) Reachability * reachability;
@property(nonatomic, strong) ZBarReaderView * readerView;

@property (retain, strong) IBOutlet UIView * modalView;
@property (retain, strong) IBOutlet UIView * modalContentView;
@property (retain, strong) id modalDelegate;

-(void)didGenerateNewWallet:(Wallet*)wallet password:(NSString*)password;

-(void)playBeepSound;
-(void)playDingSound;
-(void)playAlertSound;

-(TabViewcontroller*)tabViewController;
-(void)walletDidLoad:(Wallet *)wallet;
-(void)didGetMultiAddr:(MulitAddressResponse *)response;
-(void)didGetWalletData:(NSData *)data;

-(void)forgetWallet;
-(void)showWelcome;

-(NSString*)guid;
-(NSString*)sharedKey;
-(NSString*)password;

//Simple Modal UIVIew
-(void)showModal:(UIView*)contentView;
-(void)closeModal;
-(IBAction)closeModalClicked:(id)sender;

-(NSString*)checksumCache;

-(void)writeWalletCacheToDisk:(NSString*)payload;

-(NSDictionary*)parseURI:(NSString*)string;

-(void)startTask:(Task)task;
-(void)finishTask;
-(void)subscribeWalletAndToKeys;

//Wesocket Delegate
-(void)webSocketOnOpen:(WebSocket*)webSocket;
-(void)webSocketOnClose:(WebSocket*)webSocket;
-(void)webSocket:(WebSocket*)webSocket onError:(NSError*)error;
-(void)webSocket:(WebSocket*)webSocket onReceive:(NSData*)data; //Data is only until this function returns (You cannot retain it!)

//Status timer
-(void)checkStatus;

//Display a message
- (void)standardNotify:(NSString*)message;
- (void)standardNotify:(NSString*)message delegate:(id)fdelegate;
- (void)standardNotify:(NSString*)message title:(NSString*)title delegate:(id)fdelegate;

//Write and read from file
-(BOOL)writeToFile:(NSData *)data fileName:(NSString *)fileName;
-(NSData*)readFromFileName:(NSString *)fileName;

-(NSString*)formatMoney:(uint64_t)value;

-(BOOL)getSecondPasswordBlocking;
  
-(RemoteDataSource*)dataSource;

-(void)toggleSymbol;
  
-(void)pushWebViewController:(NSString*)url;

-(void)showSendCoins;

-(void)didSubmitTransaction;

-(IBAction)receiveCoinClicked:(UIButton *)sender;
-(IBAction)transactionsClicked:(UIButton *)sender;
-(IBAction)sendCoinsClicked:(UIButton *)sender;
-(IBAction)infoClicked:(UIButton *)sender;
-(IBAction)logoutClicked:(id)sender;
-(IBAction)signupClicked:(id)sender;
-(IBAction)loginClicked:(id)sender; 
-(IBAction)scanAccountQRCodeclicked:(id)sender;
-(IBAction)secondPasswordClicked:(id)sender;

@end

extern AppDelegate * app;