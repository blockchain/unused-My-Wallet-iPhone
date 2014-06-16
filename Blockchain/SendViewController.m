//
//  SendViewController.m
//  Blockchain
//
//  Created by Ben Reeves on 17/03/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "SendViewController.h"
#import "Wallet.h"
#import "MultiValueField.h"
#import "AppDelegate.h"
#import "ZBarSDK.h"
#import "AddressBookView.h"
#import "TabViewController.h"
#import "UncaughtExceptionHandler.h"

@implementation SendViewController

@synthesize wallet;
@synthesize fromAddress;
@synthesize readerView;

-(void)dealloc {
    [amountKeyoboardAccessoryView release];
    [currencyConversionLabel release];
    [readerView release];
    [toField release];
    [wallet release];
    [fromField release];
    [labelAddressView release];
    [labelAddressLabel release];
    [labelAddressTextField release];
    [super dealloc];
}

-(void)setWallet:(Wallet*)_wallet {
    
    [[wallet webView] removeFromSuperview];
    
    [wallet release];
    wallet = _wallet;
    [wallet retain];
    
    self.fromAddress = [NSMutableArray array];
    
    for (Key * key in [wallet.keys allValues]) {
        if (key.tag == 0) {
            [fromAddress addObject:key];
        }
    }
    
    NSLog(@"Set Wallet");
    
    [fromField reload];
    
    [fromField setIndex:0];
}


-(IBAction)labelAddressClicked:(id)sender {
    NSString * to = toField.text;
    
    [wallet addToAddressBook:to label:labelAddressTextField.text];
    
    [app closeModal];
    
    [app.dataSource saveWallet:[wallet guid] sharedKey:[wallet sharedKey] payload:[wallet encryptedString]];
    
    [self reallyDoPayment];
}

-(void)reallyDoPayment {
    NSString * to = toField.text;
    NSString * from = @"";
    if ([fromField index] > 0) {
        from = [[fromAddress objectAtIndex:[fromField index]-1] addr];
    }
    
    NSString * value = amountField.text;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
        @try {
            if ([app getSecondPasswordBlocking]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    @try {
                        [wallet sendPaymentTo:to from:from value:value];
                        
                        [app showModal:[wallet webView]];
                        
                        app.modalDelegate = self;
                    } @catch (NSException * e) {
                        [UncaughtExceptionHandler logException:e];
                    }
                });
            } else {
                [app standardNotify:@"Cannot send payment without the second password"];
            }
        } @catch (NSException * e) {
            [UncaughtExceptionHandler logException:e];
        }
    });
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {    
    NSString * to = toField.text;

    if (buttonIndex == 0) {
        [self reallyDoPayment];
    } else if (buttonIndex == 1) {
        labelAddressLabel.text = to;
        
        [app showModal:labelAddressView];
        
        [labelAddressTextField becomeFirstResponder];
    }
}

-(IBAction)reviewPaymentClicked:(id)sender {
    NSString * to = toField.text;
    
    if ([to length] == 0) {
        [app standardNotify:@"You must enter a destination address"];
        return;
    }
    
    if (![wallet isValidAddress:to]) {
        [app standardNotify:@"Invalid to bitcoin address"];
        return;
    }
            
    double value = [amountField.text doubleValue];
    if (value <= 0) {
        [app standardNotify:@"You must enter a value greter than zero"];
        return;
    }
    
    int countPriv = [[wallet activeAddresses] count];
    
    if (countPriv == 0) {
        [app standardNotify:@"You have no active bitcoin addresses available for sending"];
        return;
    }
    
    if ([[wallet.addressBook objectForKey:to] length] == 0 && [[wallet keys] objectForKey:to] == nil) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Add to Address book?" 
                                                        message:[NSString stringWithFormat:@"Would you like to add the bitcoin address %@ to your address book?", to]
                                                       delegate:nil 
                                              cancelButtonTitle:@"No" 
                                              otherButtonTitles:@"Yes", nil];
        alert.delegate = self;
        
        [alert show];
        [alert release];
    } else {
        [self reallyDoPayment];
    }
}

-(void)doCurrencyConversion {
    uint64_t amount = SATOSHI;
    if ([amountField.text length] > 0)
        amount = [amountField.text doubleValue] * SATOSHI;
    
    currencyConversionLabel.text = [NSString stringWithFormat:@"%@ = %@", [app formatMoney:amount localCurrency:FALSE], [app formatMoney:amount localCurrency:TRUE]];

}
-(void)setToAddress:(NSString*)string {
    toField.text = string;
}

-(void)setAmount:(NSString*)amount {
    amountField.text = amount;
    
    [self doCurrencyConversion];
}

- (void) readerView: (ZBarReaderView*) view didReadSymbols: (ZBarSymbolSet*) syms fromImage: (UIImage*) img
{
    // do something useful with results
    for(ZBarSymbol *sym in syms) {
        
        NSDictionary * dict = [app parseURI:sym.data];
        toField.text = [dict objectForKey:@"address"];
        amountField.text = [dict objectForKey:@"amount"];
        
        [view stop];
        
        [app closeModal];

        break;
    }
    
    self.readerView = nil;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self doCurrencyConversion];
    
	[app.tabViewController responderMayHaveChanged];
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    [self performSelector:@selector(doCurrencyConversion) withObject:nil afterDelay:0.1f];
    
    return TRUE;
}

- (BOOL)textFieldShouldReturn:(UITextField*)aTextField
{
    [aTextField resignFirstResponder];
    return YES;
}

-(void)initQRCodeView {
    self.readerView = [[ZBarReaderView new] autorelease];
    
    [readerView start];
    
    [readerView setReaderDelegate:self];
    
    [app showModal:readerView];
    
    app.modalDelegate = self;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    fromField.valueFont = [UIFont systemFontOfSize:14];
    
    amountField.inputAccessoryView = amountKeyoboardAccessoryView;

    // Hack for screensize
    UIWindow *w = [[[UIApplication sharedApplication] windows] objectAtIndex:0];
    self.view.frame = CGRectMake(0, 0, 320, w.bounds.size.height - 70);
}

-(NSUInteger)countForValueField:(MultiValueField*)valueField {
    if (valueField == fromField) {
        return [fromAddress count]+1;
    }
    return 0;
}

-(void)didDismissModal {    
    [readerView stop];

    self.readerView = nil;

    [wallet cancelTxSigning];
}

-(void)didSelectAddress:(NSString *)address {
    toField.text = address;
}

-(NSString*)titleForValueField:(MultiValueField*)valueField atIndex:(NSUInteger)index {
    if (valueField == fromField) {
        if (index == 0) {
            return @"Any Address";
        }
        
        return [wallet labelForAddress:[[fromAddress objectAtIndex:index-1] addr]];
    }
    
    return @"";
}
-(IBAction)addressBookClicked:(id)sender {
    AddressBookView * view = [[AddressBookView alloc] initWithWallet:app.wallet];
    
    view.delegate = self;
    
    [app showModal:view];
    
    [view release];
}

-(IBAction)QRCodebuttonClicked:(id)sender {
    [self initQRCodeView];
}

@end
