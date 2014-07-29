//
//  TransactionsViewController.m
//  Blockchain
//
//  Created by Ben Reeves on 10/01/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "TransactionsViewController.h"
#import "Transaction.h"
#import "TransactionTableCell.h"
#import "MultiAddressResponse.h"
#import "AppDelegate.h"

@implementation TransactionsViewController

@synthesize data;
@synthesize latestBlock;

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [data.transactions count];
}

- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    Transaction * transaction = [data.transactions objectAtIndex:[indexPath row]];
    
	TransactionTableCell * cell = (TransactionTableCell*)[tableView dequeueReusableCellWithIdentifier:@"transaction"];

    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"TransactionCell" owner:nil options:nil] objectAtIndex:0];
    }
    
    cell.transaction = transaction;
    
    [cell seLatestBlock:self.latestBlock];
    
    [cell reload];

    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	[app.tabViewController responderMayHaveChanged];
}

-(void)drawRect:(CGRect)rect
{
	//Setup
	CGContextRef context = UIGraphicsGetCurrentContext();	
	CGContextSetShouldAntialias(context, YES);
	
    CGContextSetFillColorWithColor(context, [UIColor lightGrayColor].CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, 320, 15));
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    float baseHeight = 85.0f;
    
    Transaction * transaction = [data.transactions objectAtIndex:[indexPath row]];

    if (transaction.result < 0) {
        NSArray * outputs = [transaction outputsNotToAddresses:data.addresses];
        
        if ([outputs count] == 0)
            outputs = transaction.outputs;

        baseHeight += [outputs count] * 22;
    } else {
        
        NSArray * inputs = [transaction inputsNotFromAddresses:data.addresses];
        
        if ([inputs count] == 0)
            inputs = transaction.inputs;
        
        baseHeight += [inputs count] * 22;
    }
    
    if (!isfinite(baseHeight)) {        
        return 85.0f;
    }
    
    return baseHeight;
}

-(UITableView*)tableView {
    return tableView;
}

-(void)setText {
    if ([data.transactions count] == 0) {
        [self.view addSubview:noTransactionsView];
    } else {
        [noTransactionsView removeFromSuperview];
    }
    
    NSString * finalBalanceString = [app formatMoney:data.final_balance];
    
    //If the balance label is likely to overfla the transaction count hide it
    [transactionCountLabel setHidden:[finalBalanceString length] > 16];
    
    [transactionCountLabel setText:[NSString stringWithFormat:@"%d Transactions", data.n_transactions]];
    
    [finalBalanceLabel setText:finalBalanceString];
}

-(void)setLatestBlock:(LatestBlock *)_latestBlock {
    latestBlock = _latestBlock;
    
    if (latestBlock && latestBlock.blockIndex != _latestBlock.blockIndex) {
        [tableView reloadData];
    }
}

-(void)reload {
    [self setText];
    
    [tableView reloadData];
}

#pragma mark - View lifecycle

-(void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor whiteColor];
    [finalBalanceLabel setMinimumScaleFactor:.5f];
    [finalBalanceLabel setAdjustsFontSizeToFitWidth:YES];
    
    if (APP_IS_IPHONE5) {
        self.view.frame = CGRectMake(0, 0, 320, 450);
    } else {
        self.view.frame = CGRectMake(0, 0, 320, 361);
    }
    
    [self reload];
}


@end
