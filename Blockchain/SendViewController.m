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

@implementation SendViewController

@synthesize wallet;
@synthesize fromAddress;
@synthesize readerView;

-(void)dealloc {
    [readerView release];
    [toField release];
    [wallet release];
    [fromField release];
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

-(IBAction)reviewPaymentClicked:(id)sender {
    
    NSString * to = toField.text;
    
    if ([to length] == 0) {
        [app standardNotify:@"You must enter a destination address"];
        return;
    }

    NSString * from = @"";
    if ([fromField index] > 0) {
        from = [[fromAddress objectAtIndex:[fromField index]-1] addr];
    }
    
    double value = [amountField.text doubleValue];
    if (value <= 0) {
        [app standardNotify:@"You must enter a value greter than zero"];
        return;
    }
    
    int countPriv = 0;
    for (Key * key in [wallet.keys allKeys]) {
        ++countPriv;
    }
    
    if (countPriv == 0) {
        [app standardNotify:@"You have no bitcoin addresses available for sending"];
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
        if ([app getSecondPasswordBlocking]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [wallet sendPaymentTo:to from:from value:value];
                
                [app showModal:[wallet webView]];
                
                app.modalDelegate = self;
            });
        } else {
            [app standardNotify:@"Cannot send payment without the second password"];
        }
    });
    
}

-(void)setToAddress:(NSString*)string {
    toField.text = string;
}

-(void)setAmount:(NSString*)amount {
    amountField.text = amount;
}

- (void) readerView: (ZBarReaderView*) view didReadSymbols: (ZBarSymbolSet*) syms fromImage: (UIImage*) img
{
    // do something useful with results
    for(ZBarSymbol *sym in syms) {
        toField.text = sym.data;
        
        [view stop];
        
        [app closeModal];

        break;
    }
    
    self.readerView = nil;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	[app.tabViewController responderMayHaveChanged];
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
    fromField.valueFont = [UIFont systemFontOfSize:14];
}

-(NSUInteger)countForValueField:(MultiValueField*)valueField {
    if (valueField == fromField) {
        return [fromAddress count]+1;
    }
    return 0;
}

-(void)didDismissModal {
    self.readerView = nil;
    
    [readerView stop];
    
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
