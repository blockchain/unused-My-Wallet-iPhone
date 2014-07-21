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

-(void)dealloc {
    
    [currencyConversionLabel release];
    [amountKeyoboardAccessoryView release];
    [optionsTitleLabel release];
    [archiveUnarchiveButton release];
    [optionsModalView release];
    [requestCoinsView release];
    [qrCodeImageView release];
    [optionsAddressLabel release];
    [activeKeys release];
    [archivedKeys release];
    [tableView release];
    [requestAmountTextField release];
    [super dealloc];
}


- (void) readerView: (ZBarReaderView*) view didReadSymbols: (ZBarSymbolSet*) syms fromImage: (UIImage*) img
{
    // do something useful with results
    for(ZBarSymbol *sym in syms) {
        NSString * privateKey = sym.data;
        
//TODO
        /*
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
            if (!isDoubleEncrypted || [app getSecondPasswordBlocking]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if ([wallet addKey:privateKey]) {
                        [self reload];
                        
                        [app standardNotify:[NSString stringWithFormat:@"Added bitcoin address"] title:@"Success" delegate:nil];
                    } else {
                        [app standardNotify:@"Error importing private key"];
                    }
                });
            } else {
                [app standardNotify:@"Cannot Generate new address without the second password"];
            }
        });*/
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
    
    [app showModal:readerView onDismiss:^() {
        [readerView stop];
        
        self.readerView = nil;
        
        [wallet cancelTxSigning];
    }];
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
    self.activeKeys = [app.wallet activeAddresses];
    self.archivedKeys = [app.wallet archivedAddresses];

    if ([activeKeys count] == 0) {
        [self.view addSubview:noaddressesView];
    } else {
        [noaddressesView removeFromSuperview];
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
                   [wallet generateNewKey:^(Key* key) {
                    
                       [self reload];
                       
                       [app standardNotify:[NSString stringWithFormat:@"Generated new bitcoin address %@", key.addr] title:@"Success" delegate:nil];
                    }];
                });
        } else {
            [app standardNotify:@"Cannot Generate new address without the second password"];
        }
    });
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    int n = 0;
    
    if ([archivedKeys count]) ++n;
    if ([activeKeys count]) ++n;

    return n;
}

-(NSString *)getAddress:(NSIndexPath*)indexPath {
    
    NSString *addr = nil;
    
    if ([indexPath section] == 0)
        addr = [activeKeys objectAtIndex:[indexPath row]];
    else if ([indexPath section] == 1)
        addr = [archivedKeys objectAtIndex:[indexPath row]];

    
    return addr;
}

-(IBAction)labelSaveClicked:(id)sender {
    labelTextField.text = [labelTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([labelTextField.text length] == 0 || [labelTextField.text length] > 255) {
        [app standardNotify:@"You must enter a label"];
        return;
    }
    
    NSString * addr =  [self getAddress:[tableView indexPathForSelectedRow]];
    [wallet setLabel:labelTextField.text ForAddress:addr];
        
    [self reload];
    
    [app closeModal];
}

-(IBAction)copyAddressClicked:(id)sender {
    NSString * addr =  [self getAddress:[tableView indexPathForSelectedRow]];

    [app standardNotify:[NSString stringWithFormat:@"%@ copied to clipboard", addr]  title:@"Success" delegate:nil];

    [UIPasteboard generalPasteboard].string = addr;
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
    
    NSString * addr =  [self getAddress:[tableView indexPathForSelectedRow]];

    double amount = [requestAmountTextField.text doubleValue];
    
    return [NSString stringWithFormat:@"bitcoin://%@?amount=%.8f", addr, amount];
}

-(NSString*)blockchainUriURL {
    
    NSString * addr =  [self getAddress:[tableView indexPathForSelectedRow]];

    double amount = [requestAmountTextField.text doubleValue];
    
    return [NSString stringWithFormat:@"https://blockchain.info/uri?uri=bitcoin://%@?amount=%.8f", addr, amount];
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
//
//-(IBAction)shareByTwitter:(id)sender {
//#warning reimplement this
////    [AddThisSDK shareURL:[self blockchainUriURL] withService:@"twitter" title:@"My Bitcoin Address" description:@"Pay me with bitcoin"];
//}
//
//-(IBAction)shareByFacebook:(id)sender {
//#warning reimplement this
////    [AddThisSDK shareURL:[self blockchainUriURL] withService:@"facebook" title:@"My Bitcoin Address" description:@"Pay me with bitcoin"];
//}
//-(IBAction)shareByGooglePlus:(id)sender {
//#warning reimplement this
////    [AddThisSDK shareURL:[self blockchainUriURL] withService:@"google" title:@"My Bitcoin Address" description:@"Pay me with bitcoin"];
//}
//
//-(IBAction)shareByEmailClicked:(id)sender {
//#warning reimplement this
////  [AddThisSDK shareURL:[self uriURL] withService:@"mailto" title:@"Payment Request" description:@"Please send payment to bitcoin address (<a href=\"https://blockchain.info/wallet/faq\">help?</a>)"];
//}

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
    
    [app showModal:requestCoinsView onDismiss:nil];
}

-(IBAction)labelAddressClicked:(id)sender {
    NSString * addr =  [self getAddress:[tableView indexPathForSelectedRow]];
    NSString * label =  [app.wallet labelForAddress:addr];

    if (label)
        labelAddressLabel.text = label;
    else
        labelAddressLabel.text = addr;

    [app showModal:labelAddressView onDismiss:nil];
    
    labelTextField.text = nil;
    
    [labelTextField becomeFirstResponder];
}

-(IBAction)archiveAddressClicked:(id)sender {

    NSString * addr =  [self getAddress:[tableView indexPathForSelectedRow]];
    NSInteger tag =  [app.wallet tagForAddress:addr];

    if (tag == 2)
        [wallet unArchiveAddress:addr];
    else
        [wallet archiveAddress:addr];
    
    self.wallet = wallet;
        
    [app closeModal];
}

- (void)tableView:(UITableView *)_tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString * addr =  [self getAddress:[_tableView indexPathForSelectedRow]];
    NSInteger tag =  [app.wallet tagForAddress:addr];
    NSString *label =  [app.wallet labelForAddress:addr];

    if (tag == 2)
        [archiveUnarchiveButton setTitle:@"Unarchive" forState:UIControlStateNormal];
    else
        [archiveUnarchiveButton setTitle:@"Archive" forState:UIControlStateNormal];
    
    [app showModal:optionsModalView onDismiss:nil];
    
    if (label)
        optionsTitleLabel.text = label;
    else
        optionsTitleLabel.text = @"Bitcoin Address";
        
    optionsAddressLabel.text = addr;
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
        @throw @"Unknown Secion";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0)
        return [activeKeys count];
    else
        return [archivedKeys count];
}

-(void)viewWillAppear:(BOOL)animated {
    if ([[self.wallet activeAddresses] count] == 0) {
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

    NSString * addr =  [self getAddress:indexPath];
    NSString * label =  [app.wallet labelForAddress:addr];
    
    if (label)
        cell.labelLabel.text = label;
    else 
        cell.labelLabel.text = @"No Label";
    
    cell.addressLabel.text = addr;
    
    if ([app.wallet isWatchOnlyAddress:addr])
        [cell.watchLabel setHidden:TRUE];
    else
        [cell.watchLabel setHidden:FALSE];
    
    uint64_t balance = [app.wallet getAddressBalance:addr];
    
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0,0,cell.frame.size.width,cell.frame.size.height)];
    [v setBackgroundColor:COLOR_BLOCKCHAIN_BLUE];
    [cell setSelectedBackgroundView:v];
    
    cell.balanceLabel.text = [app formatMoney:balance];
 
    return cell;
}

@end
