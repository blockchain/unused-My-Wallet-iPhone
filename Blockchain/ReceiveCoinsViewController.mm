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

@synthesize wallet;
@synthesize activeKeys;
@synthesize archivedKeys;
@synthesize otherKeys;

-(void)dealloc {
    [depositButton release];
    [archiveUnarchiveButton release];
    [qrCodeModalView release];
    [qrCodeImageView release];
    [otherKeys release];
    [activeKeys release];
    [archivedKeys release];
    [tableView release];
    [super dealloc];
}

-(void)setWallet:(Wallet *)_wallet {
    [wallet release];
    wallet = _wallet;
    [wallet retain];
    
    if ([wallet.keys count] == 0) {
        [self.view addSubview:noaddressesView];
    } else {
        [noaddressesView removeFromSuperview];
    }
    
    NSMutableArray * _activeKeys = [NSMutableArray arrayWithCapacity:[wallet.keys count]];
    NSMutableArray * _archivedKeys = [NSMutableArray arrayWithCapacity:[wallet.keys count]];
    NSMutableArray * _otherKeys = [NSMutableArray arrayWithCapacity:[wallet.keys count]];

    for (Key * key in [[wallet keys] allValues]) {
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

    [tableView reloadData];
}


-(IBAction)generateNewAddressClicked:(id)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
        if ([app getSecondPasswordBlocking]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString * addr =  [wallet generateNewAddress];
                
                if (addr)
                    [app standardNotify:[NSString stringWithFormat:@"Generated new bitcoin address %@", addr] title:@"Success" delegate:nil];
                else
                    [app standardNotify:@"Error generating bitcoin address"];
                
                self.wallet = wallet;
                
                [app.dataSource saveWallet:[wallet guid] sharedKey:[wallet sharedKey] payload:[wallet encryptedString]];
                
                [app.dataSource multiAddr:wallet.guid addresses:[wallet.keys allKeys]];
                                
                [app subscribeWalletAndToKeys];
            });
        } else {
            [app standardNotify:@"Cannot Generate new address without the second password"];
        }
    });
}

-(void)depositClicked:(id)sender {
    for (Key * key in [wallet.keys allValues]) {
        
        //Only depsit to addresses with private keys and active
        if (key.priv && key.tag != 2) {
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://blockchain.info/deposit?address=%@", key.addr]];
        
            [[UIApplication sharedApplication] openURL:url];
            
            break;
        }
    }
}

-(void)viewDidLoad {
    
#ifndef CYDIA 
    [depositButton setHidden:TRUE];
#endif
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return 88.0f;
    }
    
    return 0.0f;

}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return tableFooterView;
    }
    
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    int n = 0;
    if ([otherKeys count]) ++n;
    if ([archivedKeys count]) ++n;
    if ([activeKeys count]) ++n;
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
    
    
    if ([labelTextField.text length] == 0 || [labelTextField.text length] > 255) {
        [app standardNotify:@"You must enter a label"];
        return;
    }
    
    key.label = labelTextField.text;
    
    [tableView reloadData];
    
    [app.dataSource saveWallet:[wallet guid] sharedKey:[wallet sharedKey] payload:[wallet encryptedString]];

    [app closeModal];
}

-(IBAction)qrCodeImageClicked:(id)sender {
    Key * key =  [self getKey:[tableView indexPathForSelectedRow]];
    
    [app standardNotify:[NSString stringWithFormat:@"%@ copied to clipboard", key.addr]  title:@"Success" delegate:nil];

    [UIPasteboard generalPasteboard].string = key.addr;
}

-(IBAction)labelAddressClicked:(id)sender {
    Key * key =  [self getKey:[tableView indexPathForSelectedRow]];

    labelAddressLabel.text = key.addr;

    [app showModal:labelAddressView];
    
    labelTextField.text = nil;
    
    [labelTextField becomeFirstResponder];
}

-(IBAction)archiveAddressClicked:(id)sender {

    Key * key =  [self getKey:[tableView indexPathForSelectedRow]];

    if (key.tag == 2)
        key.tag = 0;
    else
        key.tag = 2;
    
    self.wallet = wallet;
    
    [app.dataSource saveWallet:[wallet guid] sharedKey:[wallet sharedKey] payload:[wallet encryptedString]];
    
    [app closeModal];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Key * key =  [self getKey:indexPath];
    
    DataMatrix * data = [QREncoder encodeWithECLevel:1 version:1 string:[key addr]];
    
    UIImage * image = [QREncoder renderDataMatrix:data imageDimension:250];
    
    qrCodeImageView.image = image;
    
    if (key.tag == 2)
        [archiveUnarchiveButton setTitle:@"Unarchive" forState:UIControlStateNormal];
    else
        [archiveUnarchiveButton setTitle:@"Archive" forState:UIControlStateNormal];
    
    [app showModal:qrCodeModalView];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70.0f;
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
        cell = [[[NSBundle mainBundle] loadNibNamed:@"ReceiveTableCell" owner:nil options:nil] objectAtIndex:0];
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

    if (address) {
        cell.balanceLabel.text = [app formatMoney:address->final_balance];
    } else {
        cell.balanceLabel.text = nil;
    }
    
    return cell;
}

@end
