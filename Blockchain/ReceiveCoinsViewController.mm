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
#import "PrivateKeyReader.h"
#import "AddThis.h"

@implementation ReceiveCoinsViewController

@synthesize activeKeys;
@synthesize archivedKeys;

#pragma mark - Lifecycle

-(void)viewWillAppear:(BOOL)animated {
    if ([[app.wallet activeAddresses] count] == 0) {
        [noaddressesView setHidden:FALSE];
    } else {
        [noaddressesView setHidden:TRUE];
    }
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    if (APP_IS_IPHONE5) {
        self.view.frame = CGRectMake(0, 0, 320, 450);
    }
    else {
        self.view.frame = CGRectMake(0, 0, 320, 361);
    }

    [self reload];
}

-(void)reload {
    self.activeKeys = [app.wallet activeAddresses];
    self.archivedKeys = [app.wallet archivedAddresses];

    if ([activeKeys count] == 0) {
        [self.view addSubview:noaddressesView];
    } else {
        [noaddressesView removeFromSuperview];
    }
    
    if (app->symbolLocal && app.latestResponse.symbol_local && app.latestResponse.symbol_local.conversion > 0) {
        [btcCodeButton setTitle:app.latestResponse.symbol_local.code forState:UIControlStateNormal];
        displayingLocalSymbol = TRUE;
    } else if (app.latestResponse.symbol_btc) {
        [btcCodeButton setTitle:app.latestResponse.symbol_btc.symbol forState:UIControlStateNormal];
        displayingLocalSymbol = FALSE;
    }
    
    [tableView reloadData];
}

#pragma mark - Helpers

-(NSString *)getAddress:(NSIndexPath*)indexPath {
    
    NSString *addr = nil;
    
    if ([indexPath section] == 0)
        addr = [activeKeys objectAtIndex:[indexPath row]];
    else if ([indexPath section] == 1)
        addr = [archivedKeys objectAtIndex:[indexPath row]];
    
    
    return addr;
}

-(NSString*)uriURL {
    
    double amount = (double)[self getInputAmountInSatoshi] / SATOSHI;

    app.btcFormatter.usesGroupingSeparator = NO;
    NSString *amountString = [app.btcFormatter stringFromNumber:[NSNumber numberWithDouble:amount]];
    app.btcFormatter.usesGroupingSeparator = YES;

    amountString = [amountString stringByReplacingOccurrencesOfString:@"," withString:@"."];

    return [NSString stringWithFormat:@"bitcoin://%@?amount=%@", self.clickedAddress, amountString];
}

-(uint64_t)getInputAmountInSatoshi {
    NSString *requestedAmountString = [requestAmountTextField.text stringByReplacingOccurrencesOfString:@"," withString:@"."];

    if (displayingLocalSymbol) {
        return app.latestResponse.symbol_local.conversion * [requestedAmountString doubleValue];
    } else {
        return [app.wallet parseBitcoinValue:requestedAmountString];
    }
}

-(void)doCurrencyConversion {
    uint64_t amount = SATOSHI;
    
    if ([requestAmountTextField.text length] > 0) {
        amount = [self getInputAmountInSatoshi];
    } else if (displayingLocalSymbol) {
        amount = app.latestResponse.symbol_local.conversion;
    }
    
    if (displayingLocalSymbol) {
        currencyConversionLabel.text = [NSString stringWithFormat:@"%@ = %@", [app formatMoney:amount localCurrency:TRUE], [app formatMoney:amount localCurrency:FALSE]];
    } else {
        currencyConversionLabel.text = [NSString stringWithFormat:@"%@ = %@", [app formatMoney:amount localCurrency:FALSE], [app formatMoney:amount localCurrency:TRUE]];
    }
}


-(NSString *)getKey:(NSIndexPath*)indexPath {
    
    NSString * key =  NULL;
    
    if ([indexPath section] == 0)
        key = [activeKeys objectAtIndex:[indexPath row]];
    else
        key = [archivedKeys objectAtIndex:[indexPath row]];
    
    return key;
}

-(NSString*)blockchainUriURL {
    NSString* address = [self getKey:[tableView indexPathForSelectedRow]];
    double amount = [requestAmountTextField.text doubleValue];
    return [NSString stringWithFormat:@"https://blockchain.info/uri?uri=bitcoin://%@?amount=%.8f", address, amount];
}

-(void)setQR {
    DataMatrix * data = [QREncoder encodeWithECLevel:1 version:1 string:[self uriURL]];
    
    UIImage * image = [QREncoder renderDataMatrix:data imageDimension:250];
    
    qrCodeImageView.image = image;
    
    [self doCurrencyConversion];
}

#pragma mark - Actions

-(IBAction)generateNewAddressClicked:(id)sender {
    [app.wallet generateNewKey];
}

-(IBAction)btcCodeClicked:(id)sender {
    [app toggleSymbol];
    [self setQR];
}

-(IBAction)scanKeyClicked:(id)sender {
    
    PrivateKeyReader * reader = [[PrivateKeyReader alloc] init];
    
    [reader readPrivateKey:^(NSString* privateKeyString) {
        [app.wallet addKey:privateKeyString];
    } error:nil];
}

-(IBAction)labelSaveClicked:(id)sender {
    labelTextField.text = [labelTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([labelTextField.text length] == 0 || [labelTextField.text length] > 255) {
        [app standardNotify:BC_STRING_YOU_MUST_ENTER_A_LABEL];
        return;
    }
        
    NSString * addr = self.clickedAddress;

    [app.wallet setLabel:labelTextField.text ForAddress:addr];
        
    [self reload];
    
    [app closeModal];
}

-(IBAction)copyAddressClicked:(id)sender {
    NSString * addr = self.clickedAddress;

    [app standardNotify:[NSString stringWithFormat:BC_STRING_COPIED_TO_CLIPBOARD, addr]  title:BC_STRING_SUCCESS delegate:nil];

    [UIPasteboard generalPasteboard].string = addr;
}

-(IBAction)shareByTwitter:(id)sender {
    [AddThisSDK shareURL:[self blockchainUriURL] withService:@"twitter" title:@"My Bitcoin Address" description:@"Pay me with bitcoin"];
}

-(IBAction)shareByFacebook:(id)sender {
    [AddThisSDK shareURL:[self blockchainUriURL] withService:@"facebook" title:@"My Bitcoin Address" description:@"Pay me with bitcoin"];
}
-(IBAction)shareByGooglePlus:(id)sender {
    [AddThisSDK shareURL:[self blockchainUriURL] withService:@"google" title:@"My Bitcoin Address" description:@"Pay me with bitcoin"];
}

-(IBAction)shareByEmailClicked:(id)sender {
    [AddThisSDK shareURL:[self uriURL] withService:@"mailto" title:@"Payment Request" description:@"Please send payment to bitcoin address (<a href=\"https://blockchain.info/wallet/faq\">help?</a>)"];
}

-(IBAction)requestPaymentClicked:(id)sender {
    [self setQR];
    
    requestAmountTextField.inputAccessoryView = amountKeyoboardAccessoryView;
    amountKeyoboardAccessoryView.layer.borderWidth = 1.0f / [UIScreen mainScreen].scale;
    amountKeyoboardAccessoryView.layer.borderColor = [[UIColor colorWithRed:181.0f/255.0f green:185.0f/255.0f blue:189.0f/255.0f alpha:1.0f] CGColor];
    
    //configure addthis -- (this step is optional)
	[AddThisSDK setNavigationBarColor:[UIColor lightGrayColor]];
	[AddThisSDK setToolBarColor:[UIColor lightGrayColor]];
	[AddThisSDK setSearchBarColor:[UIColor lightGrayColor]];
    
    [AddThisSDK setAddThisPubId:@"ra-4f841fb17ecdac5e"];
    [AddThisSDK setAddThisApplicationId:@"4f841fed1608c356"];
    
	//Facebook connect settings
	[AddThisSDK setFacebookAPIKey:@"289188934490223"];
	[AddThisSDK setFacebookAuthenticationMode:ATFacebookAuthenticationTypeFBConnect];
	
	[AddThisSDK setTwitterConsumerKey:@"o7MGZkxywxYgUnZFyBcecQ"];
	[AddThisSDK setTwitterConsumerSecret:@"oDkfGTdj8gKqqwxae6TgulvvIeQ96Qo3ilc9CdFBU"];
	[AddThisSDK setTwitterCallBackURL:@"http://blockchain.info/twitter_callback"];

    
    
    [app showModal:requestCoinsView isClosable:TRUE onDismiss:^() {
        self.clickedAddress = nil;
    } onResume:nil];
    [requestAmountTextField becomeFirstResponder];
}

-(IBAction)closeKeyboardClicked:(id)sender
{
    [requestAmountTextField resignFirstResponder];
}

-(IBAction)labelAddressClicked:(id)sender {
    NSString * addr =  self.clickedAddress;
    NSString * label =  [app.wallet labelForAddress:addr];

    if (label && ![label isEqualToString:@""])
        labelAddressLabel.text = label;
    else
        labelAddressLabel.text = addr;

    [app showModal:labelAddressView isClosable:TRUE onDismiss:^() {
        self.clickedAddress = nil;
    } onResume:nil];
    
    labelTextField.text = nil;
    
    [labelTextField becomeFirstResponder];
}

-(IBAction)archiveAddressClicked:(id)sender {

    NSString * addr = self.clickedAddress;
    NSInteger tag =  [app.wallet tagForAddress:addr];

    if (tag == 2)
        [app.wallet unArchiveAddress:addr];
    else
        [app.wallet archiveAddress:addr];
    
    [self reload];
    
    [app closeModal];
}


-(void)dismissKeyboard {
    //[requestAmountTextField resignFirstResponder];
    [requestAmountTextField endEditing:YES];
    [app.modalView removeGestureRecognizer:self.tapGesture];
    self.tapGesture = nil;
}

# pragma mark - UITextField delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	[app.tabViewController responderMayHaveChanged];
    self.tapGesture = [[UITapGestureRecognizer alloc]
                       initWithTarget:self
                       action:@selector(dismissKeyboard)];
    [app.modalView addGestureRecognizer:self.tapGesture];
}

- (BOOL)textFieldShouldReturn:(UITextField*)aTextField
{
    [aTextField resignFirstResponder];
    return YES;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    NSArray  *points = [newString componentsSeparatedByString:@"."];
    NSArray  *commas = [newString componentsSeparatedByString:@","];
    
    if ([points count] > 2 || [commas count] > 2)
        return NO;
    
    [self performSelector:@selector(setQR) withObject:nil afterDelay:0.1f];
    
    return YES;
}

#pragma mark - UITableview Delegates

- (void)tableView:(UITableView *)_tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    NSString * addr =  [self getAddress:[_tableView indexPathForSelectedRow]];
    NSInteger tag =  [app.wallet tagForAddress:addr];
    NSString *label =  [app.wallet labelForAddress:addr];
    
    self.clickedAddress = addr;
    
    if (tag == 2)
        [archiveUnarchiveButton setTitle:BC_STRING_UNARCHIVE forState:UIControlStateNormal];
    else
        [archiveUnarchiveButton setTitle:BC_STRING_ARCHIVE forState:UIControlStateNormal];
    
    [app showModal:optionsModalView isClosable:TRUE];
    
    if (label)
        optionsTitleLabel.text = label;
    else
        optionsTitleLabel.text = BC_STRING_BITCOIN_ADDRESS;
    
    optionsAddressLabel.text = addr;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40.0f;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0)
        return BC_STRING_ACTIVE;
    else if (section == 1)
        return BC_STRING_ARCHIVED;
    else
        @throw @"Unknown Secion";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0)
        return [activeKeys count];
    else
        return [archivedKeys count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    int n = 0;
    
    if ([archivedKeys count]) ++n;
    if ([activeKeys count]) ++n;
    
    return n;
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
        cell.labelLabel.text = BC_STRING_NO_LABEL;
    
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
