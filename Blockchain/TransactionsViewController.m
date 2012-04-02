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
#import "RemoteDataSource.h"
#import "AppDelegate.h"

@implementation TransactionsViewController

@synthesize data;

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [data.transactions count];
}

- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    Transaction * transaction = [data.transactions objectAtIndex:[indexPath row]];
    
	TransactionTableCell * cell = (TransactionTableCell*)[tableView dequeueReusableCellWithIdentifier:@"transaction"];

    cell.transaction = transaction;
    
    [cell seLatestBlock:data.latestBlock];
    
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

    if (transaction->result < 0) {
        NSArray * outputs = [transaction outputsNotToWallet:app.wallet];
        
        if ([outputs count] == 0)
            outputs = transaction.outputs;

        baseHeight += [outputs count] * 22;
    } else {
        
        NSArray * inputs = [transaction inputsNotFromWallet:app.wallet];
        
        if ([inputs count] == 0)
            inputs = transaction.inputs;
        
        baseHeight += [inputs count] * 22;
    }
    
    return baseHeight;
}

-(void)setData:(MulitAddressResponse *)_data {
    [data release];
    data = _data;
    [data retain];
    
    if ([data n_transactions] == 0) {
        [self.view addSubview:noTransactionsView];
    } else {
        [noTransactionsView removeFromSuperview];
    }
    
    [transactionCountLabel setText:[NSString stringWithFormat:@"%d Transactions", data.n_transactions]];
    
    [finalBalanceLabel setText:[app formatMoney:data.final_balance]];

    [tableView reloadData];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)viewDidLoad {
    NSLog(@"Did load");
    
    [tableView registerNib:[UINib nibWithNibName:@"TransactionTableView" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"transaction"];

    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

-(void)dealloc {
    [noTransactionsView release];
    [finalBalanceLabel release];
    [transactionCountLabel release];
    [tableView release];
    [data release];
    [super dealloc];
}

@end
