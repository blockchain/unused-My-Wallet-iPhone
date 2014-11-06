//
//  AddressBookView.m
//  Blockchain
//
//  Created by Ben Reeves on 17/03/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "AddressBookView.h"
#import "Wallet.h"
#import "AppDelegate.h"
#import "ReceiveTableCell.h"
#import "SendViewController.h"

#define ROW_HEIGHT 68

@implementation AddressBookView

@synthesize addresses;
@synthesize labels;
@synthesize wallet;
@synthesize delegate;

bool showFromAddresses;
int numAddressBookAddresses;
int numMyAddresses;

- (id)initWithWallet:(Wallet*)_wallet showOwnAddresses:(BOOL)_showFromAddresses
{
    if ([super initWithFrame:CGRectZero]) {
        [[NSBundle mainBundle] loadNibNamed:@"AddressBookView" owner:self options:nil];
        
        self.wallet = _wallet;
        showFromAddresses = _showFromAddresses;
        
        addresses = [NSMutableArray array];
        labels = [NSMutableArray array];
        
        // Select from address
        if (_showFromAddresses) {
            // Only show user's active addresses with a positive balance
            for (NSString * addr in _wallet.activeAddresses) {
                if ([_wallet getAddressBalance:addr] > 0) {
                    [addresses addObject:addr];
                    [labels addObject:[_wallet labelForAddress:addr]];
                }
            }
            
            numMyAddresses = addresses.count;
            numAddressBookAddresses = addresses.count;
        }
        // Select to address
        else {
            // Show the address book and all the user's active addresses
            for (NSString * addr in [_wallet.addressBook allKeys]) {
                [addresses addObject:addr];
                [labels addObject:[app.sendViewController labelForAddress:addr]];
            }
            
            numAddressBookAddresses = addresses.count;
            
            for (NSString * addr in _wallet.activeAddresses) {
                [addresses addObject:addr];
                [labels addObject:[_wallet labelForAddress:addr]];
            }
            
            numMyAddresses = addresses.count - numAddressBookAddresses;
        }
        
        [self addSubview:view];
        
        view.frame = CGRectMake(0, 0, app.window.frame.size.width, app.window.frame.size.height);
        
        // Hacky way to make sure the table view doesn't show empty entries (with divider lines)
        float tableHeight = ROW_HEIGHT * self.addresses.count;
        float tableSpace = view.frame.size.height - DEFAULT_HEADER_HEIGHT - 49;
        
        if (tableHeight < tableSpace) {
            CGRect frame = tableView.frame;
            frame.size.height = ROW_HEIGHT * self.addresses.count + 55 + (showFromAddresses ? 0 : 48);
            tableView.frame = frame;
            
            tableView.scrollEnabled = NO;
        }
        else {
            CGRect frame = tableView.frame;
            frame.size.height = tableSpace;
            tableView.frame = frame;
        }
    }
    return self;
}

- (void)setHeader:(NSString *)headerText
{
    headerLabel.text = headerText;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (showFromAddresses) {
        [delegate didSelectFromAddress:[addresses objectAtIndex:[indexPath row]]];
    }
    else {
        if (indexPath.section == 1) {
            [delegate didSelectToAddress:[addresses objectAtIndex:[indexPath row] + numAddressBookAddresses]];
        }
        else {
            [delegate didSelectToAddress:[addresses objectAtIndex:[indexPath row]]];
        }
    }
    
    [app closeModalWithTransition:kCATransitionFromLeft];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (showFromAddresses) {
        return  1;
    }
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0 && !showFromAddresses) {
        return @"Address Book";
    }
    
    return @"My Addresses";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return numAddressBookAddresses;
    }
    
    return numMyAddresses;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ROW_HEIGHT;
}

- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int row = indexPath.row;
    if (!showFromAddresses && indexPath.section == 1) {
        row = indexPath.row + numAddressBookAddresses;
    }
    NSString *addr = [addresses objectAtIndex:row];
    
    ReceiveTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"receive"];
    
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"ReceiveCell" owner:nil options:nil] objectAtIndex:0];
        
        // Don't show the watch only tag and resize the label and balance labels to use up the freed up space
        cell.labelLabel.frame = CGRectMake(20, 11, 185, 21);
        cell.balanceLabel.frame = CGRectMake(217, 11, 120, 21);
        
        [cell.watchLabel setHidden:TRUE];
    }
    
    NSString *label = [labels objectAtIndex:row];
    
    if (label)
        cell.labelLabel.text = label;
    else
        cell.labelLabel.text = BC_STRING_NO_LABEL;
    
    cell.addressLabel.text = addr;
    
    if (showFromAddresses) {
        uint64_t balance = [app.wallet getAddressBalance:addr];
        cell.balanceLabel.text = [app formatMoney:balance];
    }
    else {
        cell.balanceLabel.text = nil;
    }
    
    // Selected cell color
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0,0,cell.frame.size.width,cell.frame.size.height)];
    [v setBackgroundColor:COLOR_BLOCKCHAIN_BLUE];
    [cell setSelectedBackgroundView:v];
    
    return cell;
}

@end
