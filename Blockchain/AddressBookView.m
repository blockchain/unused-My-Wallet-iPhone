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

@implementation AddressBookView

@synthesize addresses;
@synthesize wallet;
@synthesize delegate;

-(id)initWithWallet:(Wallet*)_wallet {
    if ([super initWithFrame:CGRectZero]) {
        
        self.wallet = _wallet;
        self.addresses = [NSMutableArray array];
        for (NSString * addr in [_wallet.addressBook allKeys]) {
            [addresses addObject:addr]; 
        }
        
        [[NSBundle mainBundle] loadNibNamed:@"AddressBookView" owner:self options:nil];
        
        [self addSubview:view];
        
        view.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        
    }
    return self;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [delegate didSelectAddress:[addresses objectAtIndex:[indexPath row]]];
    
    [app closeModal];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [addresses count];
}

- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"cell"];
    }
    
    NSString * addr =  [addresses objectAtIndex:[indexPath row]];
    
    // User-given Label
    cell.textLabel.text = [wallet.addressBook objectForKey:addr];
    cell.textLabel.textAlignment = NSTextAlignmentLeft;

    // Actual Bitcoin Address
    cell.detailTextLabel.font = [UIFont systemFontOfSize:12.0f];
    cell.detailTextLabel.text = addr;
                            
    return cell;
}

@end
