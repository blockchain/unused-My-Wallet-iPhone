//
//  BCAddressSelectionView.m
//  Blockchain
//
//  Created by Ben Reeves on 17/03/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "BCAddressSelectionView.h"
#import "Wallet.h"
#import "AppDelegate.h"
#import "ReceiveTableCell.h"
#import "SendViewController.h"

#define ROW_HEIGHT 68
#define ROW_HEIGHT_ACCOUNT 44

@implementation BCAddressSelectionView

@synthesize addressBookAddresses;
@synthesize addressBookAddressLabels;

@synthesize legacyAddresses;
@synthesize legacyAddressLabels;

@synthesize accounts;
@synthesize accountLabels;

@synthesize wallet;
@synthesize delegate;

bool showFromAddresses;

int addressBookSectionNumber;
int accountsSectionNumber;
int legacyAddressesSectionNumber;

- (id)initWithWallet:(Wallet*)_wallet showOwnAddresses:(BOOL)_showFromAddresses
{
    if ([super initWithFrame:CGRectZero]) {
        [[NSBundle mainBundle] loadNibNamed:@"BCAddressSelectionView" owner:self options:nil];
        
        self.wallet = _wallet;
        // The From Address View shows accounts and legacy addresses with their balance. Entries with 0 balance are not selectable.
        // The To Address View shows address book entries, account and legacy addresses without a balance.
        showFromAddresses = _showFromAddresses;
        
        addressBookAddresses = [NSMutableArray array];
        addressBookAddressLabels = [NSMutableArray array];
        
        accounts = [NSMutableArray array];
        accountLabels = [NSMutableArray array];
        
        legacyAddresses = [NSMutableArray array];
        legacyAddressLabels = [NSMutableArray array];
        
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
            
            addressBookSectionNumber = -1;
            accountsSectionNumber = 0;
            legacyAddressesSectionNumber = (legacyAddresses.count > 0) ? 1 : -1;
        }
        // Select to address
        else {
            // Show the address book
            for (NSString * addr in [_wallet.addressBook allKeys]) {
                [addressBookAddresses addObject:addr];
                [addressBookAddressLabels addObject:[app.sendViewController labelForLegacyAddress:addr]];
            }
            
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
            
            addressBookSectionNumber = (addressBookAddresses.count > 0) ? 0 : -1;
            accountsSectionNumber = addressBookSectionNumber + 1;
            legacyAddressesSectionNumber = (legacyAddresses.count > 0) ? accountsSectionNumber + 1 : -1;
        }
        
        [self addSubview:view];
        
        view.frame = CGRectMake(0, 0, app.window.frame.size.width, app.window.frame.size.height);
        
        [tableView layoutIfNeeded];
        float tableHeight = [tableView contentSize].height;
        float tableSpace = view.frame.size.height - DEFAULT_HEADER_HEIGHT;
        
        CGRect frame = tableView.frame;
        frame.size.height = tableSpace;
        tableView.frame = frame;
        
        // Disable scrolling if table content fits on screen
        if (tableHeight < tableSpace) {
            tableView.scrollEnabled = NO;
        }
        else {
            tableView.scrollEnabled = YES;
        }
        
        tableView.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (showFromAddresses) {
        if (indexPath.section == accountsSectionNumber) {
            [delegate didSelectFromAccount:[[accounts objectAtIndex:indexPath.row] intValue]];
        }
        else if (indexPath.section == legacyAddressesSectionNumber) {
            [delegate didSelectFromAddress:[legacyAddresses objectAtIndex:[indexPath row]]];
        }
    }
    else {
        if (indexPath.section == addressBookSectionNumber) {
            [delegate didSelectToAddress:[addressBookAddresses objectAtIndex:[indexPath row]]];
        }
        else if (indexPath.section == accountsSectionNumber) {
            [delegate didSelectToAccount:(int)indexPath.row];
        }
        else if (indexPath.section == legacyAddressesSectionNumber) {
            [delegate didSelectToAddress:[legacyAddresses objectAtIndex:[indexPath row]]];
        }
    }
    
    [app closeModalWithTransition:kCATransitionFromLeft];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (showFromAddresses) {
        return  1 + (legacyAddresses.count > 0 ? 1 : 0);
    }
    return (addressBookAddresses.count > 0 ? 1 : 0) + 1 + (legacyAddresses.count > 0 ? 1 : 0);
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (showFromAddresses) {
        if (section == accountsSectionNumber) {
            return BC_STRING_MY_ACCOUNTS;
        }
        else if (section == legacyAddressesSectionNumber) {
            return BC_STRING_IMPORTED_ADDRESSES;
        }
    }
    else {
        if (section == addressBookSectionNumber) {
            return BC_STRING_ADDRESS_BOOK;
        }
        else if (section == accountsSectionNumber) {
            return BC_STRING_MY_ACCOUNTS;
        }
        else if (section == legacyAddressesSectionNumber) {
            return BC_STRING_IMPORTED_ADDRESSES;
        }
    }
    
    assert(false); // Should never get here
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (showFromAddresses) {
        if (section == accountsSectionNumber) {
            return accounts.count;
        }
        else if (section == legacyAddressesSectionNumber) {
            return legacyAddresses.count;
        }
    }
    else {
        if (section == addressBookSectionNumber) {
            return addressBookAddresses.count;
        }
        else if (section == accountsSectionNumber) {
            return accounts.count;
        }
        else if (section == legacyAddressesSectionNumber) {
            return legacyAddresses.count;
        }
    }
    
    assert(false); // Should never get here
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == accountsSectionNumber) {
        return ROW_HEIGHT_ACCOUNT;
    }
    
    return ROW_HEIGHT;
}

- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int section = (int) indexPath.section;
    int row = (int) indexPath.row;
    
    ReceiveTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"receive"];
    
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"ReceiveCell" owner:nil options:nil] objectAtIndex:0];
        cell.backgroundColor = COLOR_BACKGROUND_GRAY;
        
        // Don't show the watch only tag and resize the label and balance labels to use up the freed up space
        cell.labelLabel.frame = CGRectMake(20, 11, 185, 21);
        cell.balanceLabel.frame = CGRectMake(217, 11, 120, 21);
        
        [cell.watchLabel setHidden:TRUE];
    }
    
    NSString *label;
    if (section == addressBookSectionNumber) {
        label = [addressBookAddressLabels objectAtIndex:row];
        cell.addressLabel.text = [addressBookAddresses objectAtIndex:row];
    }
    else if (section == accountsSectionNumber) {
        label = accountLabels[indexPath.row];
        cell.addressLabel.text = nil;
    }
    else if (section == legacyAddressesSectionNumber) {
        label = [legacyAddressLabels objectAtIndex:row];
        cell.addressLabel.text = [legacyAddresses objectAtIndex:row];
    }
    
    if (label)
        cell.labelLabel.text = label;
    else
        cell.labelLabel.text = BC_STRING_NO_LABEL;
    
    if (showFromAddresses) {
        uint64_t balance = 0;
        if (section == addressBookSectionNumber) {
            balance = [app.wallet getLegacyAddressBalance:[addressBookAddresses objectAtIndex:row]];
        }
        else if (section == accountsSectionNumber) {
            balance = [app.wallet getBalanceForAccount:[[accounts objectAtIndex:indexPath.row] intValue]];
        }
        else if (section == legacyAddressesSectionNumber) {
            balance = [app.wallet getLegacyAddressBalance:[legacyAddresses objectAtIndex:row]];
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
