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

BOOL animateNextCell;

UIRefreshControl *refreshControl;
int lastNumberTransactions = INT_MAX;

#define MAX_ADDRESS_ROWS_PER_CELL 5

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [data.transactions count];
}

- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Transaction * transaction = [data.transactions objectAtIndex:[indexPath row]];
    
	TransactionTableCell * cell = (TransactionTableCell*)[tableView dequeueReusableCellWithIdentifier:@"transaction"];

    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"TransactionCell" owner:nil options:nil] objectAtIndex:0];
    }
    
    cell.transaction = transaction;
    
    [cell seLatestBlock:self.latestBlock];
    
    [cell reload];
    
    // Selected cell color
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0,0,cell.frame.size.width,cell.frame.size.height)];
    [v setBackgroundColor:COLOR_BLOCKCHAIN_BLUE];
    [cell setSelectedBackgroundView:v];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TransactionTableCell *cell = (TransactionTableCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell transactionClicked:nil];
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	[app.tabViewController responderMayHaveChanged];
}

- (void)drawRect:(CGRect)rect
{
	//Setup
	CGContextRef context = UIGraphicsGetCurrentContext();	
	CGContextSetShouldAntialias(context, YES);
	
    CGContextSetFillColorWithColor(context, [UIColor lightGrayColor].CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, 320, 15));
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    float baseHeight = 75.0f;
    
    Transaction * transaction = [data.transactions objectAtIndex:[indexPath row]];

    if (transaction.result < 0) {
        
        NSArray * outputs = [transaction outputsNotToAddresses:data.addresses];
        
        if ([outputs count] == 0)
            outputs = transaction.outputs;
        
        if ([outputs count] >= MAX_ADDRESS_ROWS_PER_CELL)
            baseHeight += (MAX_ADDRESS_ROWS_PER_CELL + 1) * 22;
        else
            baseHeight += [outputs count] * 22;
    } else if (transaction.result > 0){
        
        NSArray * inputs = [transaction inputsNotFromAddresses:data.addresses];
        
        if ([inputs count] == 0)
            inputs = transaction.inputs;
        
        if ([inputs count] >= MAX_ADDRESS_ROWS_PER_CELL)
            baseHeight += (MAX_ADDRESS_ROWS_PER_CELL + 1) * 22;
        else
            baseHeight += [inputs count] * 22;
    }
    
    if (!isfinite(baseHeight)) {        
        return 75.0f;
    }
    
    return baseHeight;
}

- (UITableView*)tableView
{
    return tableView;
}

- (void)setText
{
    // Data not loaded yet
    if (!self.data) {
        [noTransactionsView removeFromSuperview];
        
        [headerLabel setHidden:YES];
        [headerSeparator setHidden:YES];
        
        [balanceBigButton setTitle:@"" forState:UIControlStateNormal];
        [balanceSmallButton setTitle:@"" forState:UIControlStateNormal];
    }
    // Data loaded, but no Balance yet
    else if (!latestBlock) {
        [self.view addSubview:noTransactionsView];
        
        [headerLabel setHidden:NO];
        [headerSeparator setHidden:NO];
        
        [balanceBigButton setTitle:@"" forState:UIControlStateNormal];
        [balanceSmallButton setTitle:@"" forState:UIControlStateNormal];
    }
    // Data loaded and we have a balance - display the balance and transactions
    else {
        [noTransactionsView removeFromSuperview];
        
        [headerLabel setHidden:NO];
        [headerSeparator setHidden:NO];
        
        // Balance
        [balanceBigButton setTitle:[app formatMoney:data.final_balance localCurrency:app->symbolLocal] forState:UIControlStateNormal];
        [balanceSmallButton setTitle:[app formatMoney:data.final_balance localCurrency:!app->symbolLocal] forState:UIControlStateNormal];
    }
}

- (void)setLatestBlock:(LatestBlock *)_latestBlock
{
    latestBlock = _latestBlock;
    
    if (latestBlock && latestBlock.blockIndex != _latestBlock.blockIndex) {
        [tableView reloadData];
    }
}

- (void)animateNextCellAfterReload
{
    animateNextCell = YES;
}

- (void)reload
{
    [self setText];
    
    [tableView reloadData];
    
    if (data.n_transactions > lastNumberTransactions) {
        int numNewTransactions = data.n_transactions - lastNumberTransactions;
        // Max number displayed
        if (numNewTransactions > data.transactions.count) {
            numNewTransactions = data.transactions.count;
        }
        // We only do this for the last five transactions at most
        if (numNewTransactions > 5) {
            numNewTransactions = 5;
        }
        
        NSMutableArray *rows = [[NSMutableArray alloc] initWithCapacity:numNewTransactions];
        for (int i = 0; i < numNewTransactions; i++) {
            [rows addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        
        [tableView reloadRowsAtIndexPaths:rows withRowAnimation:UITableViewRowAnimationLeft];
    }
    
    // Animate the first cell
    if (data.transactions.count > 0 && animateNextCell) {
        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
        animateNextCell = NO;
    }
    
    // If all the data is available, set the lastNumberTransactions - reload gets called once when wallet is loaded and once when latest block is loaded
    if (app.latestResponse) {
        lastNumberTransactions = data.n_transactions;
    }
}

- (void)loadTransactions
{
    lastNumberTransactions = data.n_transactions;
    
    [app.wallet getHistory];
    
    // This should be done when request has finished but there is no callback
    if (refreshControl && refreshControl.isRefreshing) {
        [refreshControl endRefreshing];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.frame = CGRectMake(0, 0, app.window.frame.size.width,
                                 app.window.frame.size.height - DEFAULT_HEADER_HEIGHT - DEFAULT_FOOTER_HEIGHT);
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor whiteColor];
    
    [balanceBigButton.titleLabel setMinimumScaleFactor:.5f];
    [balanceBigButton.titleLabel setAdjustsFontSizeToFitWidth:YES];
    
    [balanceSmallButton.titleLabel setMinimumScaleFactor:.5f];
    [balanceSmallButton.titleLabel setAdjustsFontSizeToFitWidth:YES];
    
    [balanceBigButton addTarget:app action:@selector(toggleSymbol) forControlEvents:UIControlEventTouchUpInside];
    [balanceSmallButton addTarget:app action:@selector(toggleSymbol) forControlEvents:UIControlEventTouchUpInside];
    
    // Tricky way to get the refreshController to work on a UIViewController - @see http://stackoverflow.com/a/12502450/2076094
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tableView;
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self
                       action:@selector(loadTransactions)
             forControlEvents:UIControlEventValueChanged];
    tableViewController.refreshControl = refreshControl;
    
    [self reload];
}

@end
