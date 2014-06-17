//
//  ReceiveCoinsViewControllerViewController.m
//  Blockchain
//
//  Created by Ben Reeves on 17/03/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "ReceiveCoinsViewController.h"
#import "AppDelegate.h"
#import "QREncoder.h"
#import "ReceiveTableCell.h"
#import "Address.h"

@implementation ReceiveCoinsViewController

@synthesize readerView;
@synthesize wallet;
@synthesize activeKeys;
@synthesize archivedKeys;
@synthesize otherKeys;

-(void)dealloc {
    
    [currencyConversionLabel release];
    [amountKeyoboardAccessoryView release];
    [optionsTitleLabel release];
    [archiveUnarchiveButton release];
    [optionsModalView release];
    [requestCoinsView release];
    [qrCodeImageView release];
    [otherKeys release];
    [optionsAddressLabel release];
    [activeKeys release];
    [archivedKeys release];
    [tableView release];
    [requestAmountTextField release];
    [firstSectionFooterView release];
    [super dealloc];
}


- (void) readerView: (ZBarReaderView*) view didReadSymbols: (ZBarSymbolSet*) syms fromImage: (UIImage*) img
{
    // do something useful with results
    for(ZBarSymbol *sym in syms) {
        NSString * privateKey = sym.data;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
            if ([app getSecondPasswordBlocking]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    Key * key =  [wallet parsePrivateKey:privateKey];
                    
                    if (key == nil) {
                        [app standardNotify:@"Error importing private key"];
                        return;
                    }
                    
                    [app.dataSource saveWallet:[wallet guid] sharedKey:[wallet sharedKey] payload:[wallet encryptedString] success:^ {
                        [self reload];
                        
                        [app standardNotify:[NSString stringWithFormat:@"Added bitcoin address %@", key.addr] title:@"Success" delegate:nil];
                        
                        [app.dataSource multiAddr:wallet.guid addresses:[wallet.keys allKeys]];
                        
                        [app subscribeWalletAndToKeys];
                    } error:^{ 
                        [wallet removeAddress:key.addr];
                        
                    }];
                });
            } else {
                [app standardNotify:@"Cannot Generate new address without the second password"];
            }
        });
    }
    
    [app closeModal];
    
    [readerView stop];
    
    self.readerView = nil;
}

-(IBAction)scanKeyClicked:(id)sender {
    [self initQRCodeView];
}

-(void)initQRCodeView {
    self.readerView = [[ZBarReaderView new] autorelease];
    
    [readerView start];
    
    [readerView setReaderDelegate:self];
    
    [app showModal:readerView];
    
    app.modalDelegate = self;
}

-(void)didDismissModal {    
    [readerView stop];
    
    self.readerView = nil;
    
    [wallet cancelTxSigning];
}

-(void)viewDidLoad {

    if (APP_IS_IPHONE5) {
        self.view.frame = CGRectMake(0, 0, 320, 450);
    }
    else {
        self.view.frame = CGRectMake(0, 0, 320, 361);
    }
}

-(void)reload {
    NSArray * keys = [[wallet keys] allValues];

    self.activeKeys  = nil;
    self.archivedKeys  = nil;
    self.otherKeys  = nil;

    if ([keys count] == 0) {
        [self.view addSubview:noaddressesView];
    } else {
        [noaddressesView removeFromSuperview];
        
        NSMutableArray * _activeKeys = [NSMutableArray arrayWithCapacity:[keys count]];
        NSMutableArray * _archivedKeys = [NSMutableArray arrayWithCapacity:[keys count]];
        NSMutableArray * _otherKeys = [NSMutableArray arrayWithCapacity:[keys count]];
        
        for (Key * key in keys) {
            if ([key tag] == 0)
                [_activeKeys addObject:key];
            else if ([key tag] == 2)
                [_archivedKeys addObject:key];
            else
                [_otherKeys addObject:key];
        }
        
        
        self.activeKeys = [_activeKeys sortedArrayUsingSelector:@selector(compare:)];
        self.archivedKeys = [_archivedKeys sortedArrayUsingSelector:@selector(compare:)];
        self.otherKeys = [_otherKeys sortedArrayUsingSelector:@selector(compare:)];
    }
    
    [tableView reloadData];
}

-(void)setWallet:(Wallet *)_wallet {
    [wallet release];
    wallet = _wallet;
    [wallet retain];
    
    [self reload];
}

-(IBAction)generateNewAddressClicked:(id)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
        if ([app getSecondPasswordBlocking]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                Key * key =  [wallet generateNewKey];
                
                if (key == nil) {
                    [app standardNotify:@"Error generating bitcoin address"];
                    return;
                }
                
                [app.dataSource saveWallet:[wallet guid] sharedKey:[wallet sharedKey] payload:[wallet encryptedString] success:^ {
                    [self reload];
                    
                    [app standardNotify:[NSString stringWithFormat:@"Generated new bitcoin address %@", key.addr] title:@"Success" delegate:nil];
                        
                    [app.dataSource multiAddr:wallet.guid addresses:[wallet activeAddresses]];
                    
                    [app subscribeWalletAndToKeys];
                } error:^{ 
                    [wallet removeAddress:key.addr];

                }];
            });
        } else {
            [app standardNotify:@"Cannot Generate new address without the second password"];
        }
    });
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {

    if (section == 0)
    {
        return firstSectionFooterView;
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    int n = 0;
    if ([otherKeys count]) ++n;
    if ([archivedKeys count]) ++n;
    if ([activeKeys count]) ++n;
    
    NSLog(@"n: %d", n);
    return n;
}

-(Key *)getKey:(NSIndexPath*)indexPath {
    
    Key * key =  NULL;
    
    if ([indexPath section] == 0)
        key = [activeKeys objectAtIndex:[indexPath row]];
    else if ([indexPath section] == 1)
        key = [archivedKeys objectAtIndex:[indexPath row]];
    else
        key = [otherKeys objectAtIndex:[indexPath row]];

    
    return key;
}

-(IBAction)labelSaveClicked:(id)sender {
    Key * key =  [self getKey:[tableView indexPathForSelectedRow]];
    
    labelTextField.text = [labelTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([labelTextField.text length] == 0 || [labelTextField.text length] > 255) {
        [app standardNotify:@"You must enter a label"];
        return;
    }
    
    [wallet setLabel: labelTextField.text ForAddress:key.addr];
        
    [self reload];
    
    [app.dataSource saveWallet:[wallet guid] sharedKey:[wallet sharedKey] payload:[wallet encryptedString]];

    [app closeModal];
}

-(IBAction)copyAddressClicked:(id)sender {
    Key * key =  [self getKey:[tableView indexPathForSelectedRow]];
    
    [app standardNotify:[NSString stringWithFormat:@"%@ copied to clipboard", key.addr]  title:@"Success" delegate:nil];

    [UIPasteboard generalPasteboard].string = key.addr;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	[app.tabViewController responderMayHaveChanged];
}

- (BOOL)textFieldShouldReturn:(UITextField*)aTextField
{
    [aTextField resignFirstResponder];
    return YES;
}


-(NSString*)uriURL {
    
    Key * key =  [self getKey:[tableView indexPathForSelectedRow]];
    
    double amount = [requestAmountTextField.text doubleValue];
    
    return [NSString stringWithFormat:@"bitcoin://%@?amount=%.8f", key.addr, amount];
}

-(NSString*)blockchainUriURL {
    
    Key * key =  [self getKey:[tableView indexPathForSelectedRow]];
    
    double amount = [requestAmountTextField.text doubleValue];
    
    return [NSString stringWithFormat:@"https://blockchain.info/uri?uri=bitcoin://%@?amount=%.8f", key.addr, amount];
}

-(void)setQR {
    DataMatrix * data = [QREncoder encodeWithECLevel:1 version:1 string:[self uriURL]];
    
    UIImage * image = [QREncoder renderDataMatrix:data imageDimension:250];
    
    qrCodeImageView.image = image;

    uint64_t amount = SATOSHI;
    if ([requestAmountTextField.text length] > 0)
        amount = [requestAmountTextField.text doubleValue] * SATOSHI;
    
    currencyConversionLabel.text = [NSString stringWithFormat:@"%@ = %@", [app formatMoney:amount localCurrency:FALSE], [app formatMoney:amount localCurrency:TRUE]];
    
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    [self performSelector:@selector(setQR) withObject:nil afterDelay:0.1f];
    
    return TRUE;
}

-(IBAction)shareByTwitter:(id)sender {
#warning reimplement this
//    [AddThisSDK shareURL:[self blockchainUriURL] withService:@"twitter" title:@"My Bitcoin Address" description:@"Pay me with bitcoin"];
}

-(IBAction)shareByFacebook:(id)sender {
#warning reimplement this
//    [AddThisSDK shareURL:[self blockchainUriURL] withService:@"facebook" title:@"My Bitcoin Address" description:@"Pay me with bitcoin"];
}
-(IBAction)shareByGooglePlus:(id)sender {
#warning reimplement this
//    [AddThisSDK shareURL:[self blockchainUriURL] withService:@"google" title:@"My Bitcoin Address" description:@"Pay me with bitcoin"];
}

-(IBAction)shareByEmailClicked:(id)sender {
#warning reimplement this
//  [AddThisSDK shareURL:[self uriURL] withService:@"mailto" title:@"Payment Request" description:@"Please send payment to bitcoin address (<a href=\"https://blockchain.info/wallet/faq\">help?</a>)"];
}

-(IBAction)requestPaymentClicked:(id)sender {
    [self setQR];
    
    requestAmountTextField.inputAccessoryView = amountKeyoboardAccessoryView;
    
    //configure addthis -- (this step is optional)
#warning re-implement sharing
//	[AddThisSDK setNavigationBarColor:[UIColor lightGrayColor]];
//	[AddThisSDK setToolBarColor:[UIColor lightGrayColor]];
//	[AddThisSDK setSearchBarColor:[UIColor lightGrayColor]];
    
//    [AddThisSDK setAddThisPubId:@"ra-4f841fb17ecdac5e"];
//    [AddThisSDK setAddThisApplicationId:@"4f841fed1608c356"];
    
	//Facebook connect settings
//	[AddThisSDK setFacebookAPIKey:@"289188934490223"];
//	[AddThisSDK setFacebookAuthenticationMode:ATFacebookAuthenticationTypeFBConnect];
//	
//	[AddThisSDK setTwitterConsumerKey:@"o7MGZkxywxYgUnZFyBcecQ"];
//	[AddThisSDK setTwitterConsumerSecret:@"oDkfGTdj8gKqqwxae6TgulvvIeQ96Qo3ilc9CdFBU"];
//	[AddThisSDK setTwitterCallBackURL:@"http://blockchain.info/twitter_callback"];
    
    [app showModal:requestCoinsView];
}

-(IBAction)labelAddressClicked:(id)sender {
    Key * key =  [self getKey:[tableView indexPathForSelectedRow]];

    if (key.label)
        labelAddressLabel.text = key.label;
    else
        labelAddressLabel.text = key.addr;

    [app showModal:labelAddressView];
    
    labelTextField.text = nil;
    
    [labelTextField becomeFirstResponder];
}

-(IBAction)archiveAddressClicked:(id)sender {

    Key * key =  [self getKey:[tableView indexPathForSelectedRow]];

    if (key.tag == 2)
        [wallet unArchiveAddress:key.addr];
    else
        [wallet archiveAddress:key.addr];
    
    self.wallet = wallet;
    
    [app.dataSource saveWallet:[wallet guid] sharedKey:[wallet sharedKey] payload:[wallet encryptedString]];
    
    [app closeModal];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Key * key =  [self getKey:indexPath];
    
    if (key.tag == 2)
        [archiveUnarchiveButton setTitle:@"Unarchive" forState:UIControlStateNormal];
    else
        [archiveUnarchiveButton setTitle:@"Archive" forState:UIControlStateNormal];
    
    [app showModal:optionsModalView];
    
    if (key.label)
        optionsTitleLabel.text = key.label;
    else
        optionsTitleLabel.text = @"Bitcoin Address";
        
    optionsAddressLabel.text = key.addr;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30.0f;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0)
        return @"Active";
    else if (section == 1)
        return @"Archived";
    else
        return @"Other";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0)
        return [activeKeys count];
    else if (section == 1)
        return [archivedKeys count];
    else
        return [otherKeys count];
}

-(void)viewWillAppear:(BOOL)animated {
    if ([[wallet.keys allKeys] count] == 0) {
        [noaddressesView setHidden:FALSE];
    } else {
        [noaddressesView setHidden:TRUE];
    }
}

- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ReceiveTableCell * cell = [tableView dequeueReusableCellWithIdentifier:@"receive"];
    
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"ReceiveCell" owner:nil options:nil] objectAtIndex:0];
    }
    
    Key * key =  [self getKey:indexPath];
    
    if ([key label])
        cell.labelLabel.text = [key label];
    else 
        cell.labelLabel.text = @"No Label";
    
    cell.addressLabel.text = [key addr];
    
    if ([key priv])
        [cell.watchLabel setHidden:TRUE];
    else
        [cell.watchLabel setHidden:FALSE];
    
    Address * address = [app.latestResponse.addresses objectForKey:key.addr];

    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0,0,cell.frame.size.width,cell.frame.size.height)];
    [v setBackgroundColor:COLOR_BLOCKCHAIN_BLUE];
    [cell setSelectedBackgroundView:v];
    
    if (address) {
        cell.balanceLabel.text = [app formatMoney:address->final_balance];
    } else {
        cell.balanceLabel.text = nil;
    }
    
    return cell;
}

@end
