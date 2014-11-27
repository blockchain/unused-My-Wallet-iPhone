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
#define ROW_HEIGHT_ACCOUNT 44

@implementation AddressBookView

@synthesize legacyAddresses;
@synthesize legacyAddressLabels;
@synthesize accounts;
@synthesize accountLabels;
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
        
        legacyAddresses = [NSMutableArray array];
        legacyAddressLabels = [NSMutableArray array];
        
        accounts = [NSMutableArray array];
        accountLabels = [NSMutableArray array];
        
        // Select from address
        if (_showFromAddresses) {
            // First show the HD accounts with positive balance
            for (int i = 0; i < app.wallet.getAccountsCount; i++) {
                if ([app.wallet getBalanceForAccount:i] > 0) {
                    [accounts addObject:[NSNumber numberWithInt:i]];
                    [accountLabels addObject:[_wallet getLabelForAccount:i]];
                }
            }
            
            // Then show the HD accounts with a zero balance
            for (int i = 0; i < app.wallet.getAccountsCount; i++) {
                if (![app.wallet getBalanceForAccount:i] > 0) {
                    [accounts addObject:[NSNumber numberWithInt:i]];
                    [accountLabels addObject:[_wallet getLabelForAccount:i]];
                }
            }
            
            // Then show user's active legacy addresses with a positive balance
            for (NSString * addr in _wallet.activeLegacyAddresses) {
                if ([_wallet getLegacyAddressBalance:addr] > 0) {
                    [legacyAddresses addObject:addr];
                    [legacyAddressLabels addObject:[_wallet labelForLegacyAddress:addr]];
                }
            }
            
            // Then show the active legacy addresses with a zero balance
            for (NSString * addr in _wallet.activeLegacyAddresses) {
                if (![_wallet getLegacyAddressBalance:addr] > 0) {
                    [legacyAddresses addObject:addr];
                    [legacyAddressLabels addObject:[_wallet labelForLegacyAddress:addr]];
                }
            }
            
            numMyAddresses = legacyAddresses.count;
            numAddressBookAddresses = legacyAddresses.count;
        }
        // Select to address
        else {
            // Show the address book
            for (NSString * addr in [_wallet.addressBook allKeys]) {
                [legacyAddresses addObject:addr];
                [legacyAddressLabels addObject:[app.sendViewController labelForLegacyAddress:addr]];
            }
            
            numAddressBookAddresses = legacyAddresses.count;
            
            // Then show the HD accounts
            for (int i = 0; i < app.wallet.getAccountsCount; i++) {
                [accounts addObject:[NSNumber numberWithInt:i]];
                [accountLabels addObject:[_wallet getLabelForAccount:i]];
            }
            
            // Finally show all the user's active legacy addresses
            for (NSString * addr in _wallet.activeLegacyAddresses) {
                [legacyAddresses addObject:addr];
                [legacyAddressLabels addObject:[_wallet labelForLegacyAddress:addr]];
            }
            
            numMyAddresses = legacyAddresses.count - numAddressBookAddresses;
        }
        
        [self addSubview:view];
        
        view.frame = CGRectMake(0, 0, app.window.frame.size.width, app.window.frame.size.height);
        
        // Hacky way to make sure the table view doesn't show empty entries (with divider lines)
        float tableHeight = ROW_HEIGHT * (self.legacyAddresses.count + self.accounts.count);
        float tableSpace = view.frame.size.height - DEFAULT_HEADER_HEIGHT - 49;
        
        if (tableHeight < tableSpace) {
            CGRect frame = tableView.frame;
            frame.size.height = tableHeight + 55 + 48 + (showFromAddresses ? 0 : 48);
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
        if (indexPath.section == 0) {
            [delegate didSelectFromAccount:indexPath.row];
        }
        else {
            [delegate didSelectFromAddress:[legacyAddresses objectAtIndex:[indexPath row]]];
        }
    }
    else {
        if (indexPath.section == 0) {
            [delegate didSelectToAddress:[legacyAddresses objectAtIndex:[indexPath row]]];
        }
        else if (indexPath.section == 1) {
            [delegate didSelectToAccount:indexPath.row];
        }
        else {
            [delegate didSelectToAddress:[legacyAddresses objectAtIndex:[indexPath row] + numAddressBookAddresses]];
        }
    }
    
    [app closeModalWithTransition:kCATransitionFromLeft];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (showFromAddresses) {
        return  1 + (self.legacyAddresses.count > 0 ? 1 : 0);
    }
    return 2 + (self.legacyAddresses.count > 0 ? 1 : 0);
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (showFromAddresses) {
        if (section == 0) {
            // TODO i18n
            return @"Accounts";
        }
    }
    else {
        if (section == 0) {
            // TODO i18n
            return @"Address Book";
        }
        else if (section == 1) {
            // TODO i18n
            return @"Accounts";
        }
    }
    
    // TODO i18n
    return @"Imported Addresses";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (showFromAddresses) {
        if (section == 0) {
            return self.accounts.count;
        }
    }
    else {
        if (section == 0) {
            return numAddressBookAddresses;
        }
        else if (section == 1) {
            return self.accounts.count;
        }
    }
    
    return numMyAddresses;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ((showFromAddresses && indexPath.section == 0) ||
        (!showFromAddresses && indexPath.section == 1)) {
        return ROW_HEIGHT_ACCOUNT;
    }
    
    return ROW_HEIGHT;
}

- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int row = indexPath.row;
    
    if (!showFromAddresses && indexPath.section == 2) {
        row = indexPath.row + numAddressBookAddresses;
    }
    NSString *addr = [legacyAddresses objectAtIndex:row];
    
    ReceiveTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"receive"];
    
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"ReceiveCell" owner:nil options:nil] objectAtIndex:0];
        
        // Don't show the watch only tag and resize the label and balance labels to use up the freed up space
        cell.labelLabel.frame = CGRectMake(20, 11, 185, 21);
        cell.balanceLabel.frame = CGRectMake(217, 11, 120, 21);
        
        [cell.watchLabel setHidden:TRUE];
    }
    
    NSString *label;
    if ((showFromAddresses && indexPath.section == 0) ||
        (!showFromAddresses && indexPath.section == 1)) {
        label = accountLabels[indexPath.row];
        cell.addressLabel.text = @"";
    }
    else {
        label = [legacyAddressLabels objectAtIndex:row];
        cell.addressLabel.text = addr;
    }
    
    if (label)
        cell.labelLabel.text = label;
    else
        cell.labelLabel.text = BC_STRING_NO_LABEL;
    
    if (showFromAddresses) {
        uint64_t balance;
        if (indexPath.section == 0) {
            balance = [app.wallet getBalanceForAccount:indexPath.row];
        }
        else {
            balance = [app.wallet getLegacyAddressBalance:addr];
        }
        cell.balanceLabel.text = [app formatMoney:balance];
        
        // Cells with empty balance can't be clicked and are dimmed
        if (balance == 0) {
            cell.userInteractionEnabled = NO;
            cell.balanceLabel.enabled = NO;
            cell.labelLabel.alpha = 0.5;
            cell.addressLabel.alpha = 0.5;
        }
        else {
            cell.userInteractionEnabled = YES;
            cell.balanceLabel.enabled = YES;
            cell.labelLabel.alpha = 1.0;
            cell.addressLabel.alpha = 1.0;
        }
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
