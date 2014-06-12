//
//  API.m
//  Blockchain
//
//  Created by Ben Reeves on 10/01/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "RemoteDataSource.h"
#import "JSONKit.h"
#import "AppDelegate.h"
#import "Address.h"
#import "Transaction.h"
#import "Input.h"
#import "Output.h"
#import "Wallet.h"
#import "NSString+SHA256.h"
#import "NSString+URLEncode.h"
#import "APIDefines.h"

@implementation CurrencySymbol
@synthesize code;
@synthesize symbol;
@synthesize name;
@synthesize conversion;
@synthesize symbolappearsAfter;

-(void)dealloc {
    [code release];
    [symbol release];
    [name release];
    [super dealloc];
}
@end

@implementation LatestBlock
@synthesize hash;
@synthesize blockIndex;
@synthesize height;
@synthesize time;

-(void)dealloc {
    [hash release];
    [super dealloc];
}

@end

@implementation MulitAddressResponse

@synthesize transactions;
@synthesize addresses;
@synthesize total_received;
@synthesize total_sent;
@synthesize final_balance;
@synthesize n_transactions;
@synthesize latestBlock;
@synthesize symbol;

-(void)dealloc {
    [symbol release];
    [transactions release];
    [addresses release];
    [latestBlock release];
    [super dealloc];
}

@end

@implementation RemoteDataSource

@synthesize delegate;
@synthesize lastWalletSync;

-(BOOL)insertWallet:(NSString*)walletIdentifier sharedKey:(NSString*)sharedKey payload:(NSString*)payload catpcha:(NSString*)captcha {    
    if (!walletIdentifier || !sharedKey || !payload)
        return FALSE;
    
    lastWalletSync = time(NULL);

    NSURL * url = [NSURL URLWithString:[WebROOT stringByAppendingFormat:@"wallet"]];
    
    NSHTTPURLResponse * repsonse = NULL;
    NSError * error = NULL;
    
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url];

    [request setHTTPBody:[[NSString stringWithFormat:@"guid=%@&sharedKey=%@&payload=%@&method=insert&length=%d&checksum=%@&api_code=%@",
                           [walletIdentifier urlencode],
                           [sharedKey urlencode],
                           [payload urlencode],
                           [payload length],
                           [payload SHA256],
                           API_CODE
                           ] dataUsingEncoding:NSUTF8StringEncoding]];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
    [request setHTTPMethod:@"POST"];

//    NSLog(@"URL %@", [url absoluteString]);
//    NSLog(@"Payload %@", payload);
//    NSString *body = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
//    NSLog(@"HTTP Body %@", body);

    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&repsonse error:&error];
    
    if (data == NULL || [data length] == 0) {
        [app standardNotify:@"Error saving new wallet on server."];
        return FALSE;
    }
    
    NSString * responseString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    
    // getting this because captcha is wrong
    if ([repsonse statusCode] == 500) {
        [app standardNotify:responseString];
        return FALSE;
    }
    
    if (error != NULL || [repsonse statusCode] != 200) {
        [app standardNotify:[error localizedDescription]];
        return FALSE;
    }
    
    return  TRUE;
}



-(void)saveWallet:(NSString*)walletIdentifier sharedKey:(NSString*)sharedKey payload:(NSString*)payload {
    [self saveWallet:walletIdentifier sharedKey:sharedKey payload:payload success:NULL error:NULL];
}

-(void)saveWallet:(NSString*)walletIdentifier sharedKey:(NSString*)sharedKey payload:(NSString*)payload success:(void(^)() )success error:(void(^)() )_error {    
    if (!walletIdentifier || !sharedKey || !payload || [payload length] == 0) {
        [app standardNotify:@"Error saving new wallet on server."];
        return;
    }
    
    [app startTask:TaskSaveWallet];

    lastWalletSync = time(NULL);

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
        
        @try {
            NSURL * url = [NSURL URLWithString:[WebROOT stringByAppendingFormat:@"wallet"]];
            
            NSHTTPURLResponse * repsonse = NULL;
            NSError * error = NULL;
            
            NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url];
            
            [request setHTTPBody:[[NSString stringWithFormat:@"guid=%@&sharedKey=%@&payload=%@&method=update&length=%d&checksum=%@", 
                                   [walletIdentifier urlencode],
                                   [sharedKey urlencode],
                                   [payload urlencode],
                                   [payload length],
                                   [payload SHA256]
                                   ] dataUsingEncoding:NSUTF8StringEncoding]];
            
            [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
            
            [request setHTTPMethod:@"POST"];
            
            NSData * data = [NSURLConnection sendSynchronousRequest:request returningResponse:&repsonse error:&error];
            
            if (data == NULL || [data length] == 0) {
                [app standardNotify:@"Error saving wallet to server. Please check your internet connection."];
                
                if (_error)
                dispatch_async(dispatch_get_main_queue(), ^{
                    _error();
                });
                
                return;
            }
            
            NSString * responseString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
            
            if ([repsonse statusCode] == 500) {
                [app standardNotify:responseString];

                if (_error)
                dispatch_async(dispatch_get_main_queue(), ^{
                    _error();
                });

                return;
            }
            
            if (error != NULL || [repsonse statusCode] != 200) {
                [app standardNotify:[error localizedDescription]];
                
                if (_error)
                dispatch_async(dispatch_get_main_queue(), ^{
                    _error();
                });
                
                return;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (success)
                    success();
                
                //Save Cached copy
                [app writeWalletCacheToDisk:payload];
            });  

         } @finally {
             [app finishTask];
         }
    });
}

-(void)getWallet:(NSString*)walletIdentifier sharedKey:(NSString*)apiKey checksum:(NSString*)checksum {
    
    if (!walletIdentifier || !apiKey)
        return;
    
    NSLog(@"getWallet");
    
    lastWalletSync = time(NULL);
    
    [app startTask:TaskGetWallet];
    
    if (!checksum) {
        checksum = @"";
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
        
        @try {
            NSURL * url = [NSURL URLWithString:[WebROOT stringByAppendingFormat:@"wallet/wallet.aes.json?guid=%@&sharedKey=%@&checksum=%@", walletIdentifier, apiKey, checksum]];
            
            NSHTTPURLResponse * repsonse = NULL;
            NSError * error = NULL;

            NSData * data = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:url] returningResponse:&repsonse error:&error];
            
            if (data == NULL || [data length] == 0) {
                [app standardNotify:@"Error downloading wallet from server. Please check your internet connection."];
                return;
            }
            
            NSString * responseString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
            
            if ([responseString isEqualToString:@"Not modified"]) {
                NSLog(@"Not Modified");
                [delegate walletDataNotModified];
                return;
            }

            if ([repsonse statusCode] == 500) {
                [app standardNotify:responseString];
                return;
            }
            
            if (error != NULL || [repsonse statusCode] != 200) {
                [app standardNotify:[error localizedDescription]];
                return;
            }
        
            dispatch_async(dispatch_get_main_queue(), ^{
                
                //Save Cached copy
                [app writeWalletCacheToDisk:responseString];
                
                [delegate didGetWalletData:data];
            });   
            
        } @finally {
            [app finishTask];
        }
    });
}

-(MulitAddressResponse*)parseMultiAddr:(NSData*)data {
    JSONDecoder * json = [[[JSONDecoder alloc] init] autorelease];
    
    NSDictionary * top = [json objectWithData:data];
    
    MulitAddressResponse * res = [[[MulitAddressResponse alloc] init] autorelease];
    
    res.addresses = [NSMutableDictionary dictionary];
    res.transactions = [NSMutableArray array];
    
    NSArray * addressesDictArray = [top objectForKey:@"addresses"];
    
    for (NSDictionary * addressDict in addressesDictArray) {
        Address * address = [[[Address alloc] init] autorelease];
        address->total_received = [[addressDict objectForKey:@"total_received"] longLongValue];
        address->final_balance = [[addressDict objectForKey:@"final_balance"] longLongValue];
        address->total_sent = [[addressDict objectForKey:@"total_sent"] longLongValue];
        address->n_transactions = [[addressDict objectForKey:@"n_transactions"] longLongValue];
        address->address = [[addressDict objectForKey:@"address"] retain];
        
        [res.addresses setObject:address forKey:address->address];
    }
    
    NSArray * transactionsJSON = [top objectForKey:@"txs"];
    
    for (NSDictionary * transactionDict in transactionsJSON) {
        [res.transactions addObject:[Transaction fromJSONDict:transactionDict]];
    }
    
    NSDictionary * wallet = [top objectForKey:@"wallet"];
    
    NSString * n_tx = [wallet objectForKey:@"n_tx"];
    if (n_tx)
        res.n_transactions = [n_tx intValue];
    else
        res.n_transactions = [res.transactions count];

    res.total_sent = [[wallet objectForKey:@"total_sent"] longLongValue];
    res.total_received = [[wallet objectForKey:@"total_received"] longLongValue];
    
    NSString * final_balance = [wallet objectForKey:@"final_balance"];
    if (final_balance) {
        res.final_balance = [[wallet objectForKey:@"final_balance"] longLongValue];
    } else {
        for (Transaction * tx in res.transactions) {
            res.final_balance += tx->result;
        }
    }
    
    NSDictionary * infoDict = [top objectForKey:@"info"];
    NSDictionary * blockDict = [infoDict objectForKey:@"latest_block"];
    
    res.latestBlock = [[[LatestBlock alloc] init] autorelease];
    res.latestBlock.hash = [blockDict objectForKey:@"hash"];
    res.latestBlock.height = [[blockDict objectForKey:@"height"] unsignedIntValue];
    res.latestBlock.blockIndex = [[blockDict objectForKey:@"block_index"] unsignedIntValue];
    res.latestBlock.time = [[blockDict objectForKey:@"time"] longLongValue];
    
    NSDictionary * symbolDict = [infoDict objectForKey:@"symbol_local"];

    res.symbol = [[[CurrencySymbol alloc] init] autorelease];
    res.symbol.code = [symbolDict objectForKey:@"code"];
    res.symbol.symbol = [symbolDict objectForKey:@"symbol"];
    res.symbol.name = [symbolDict objectForKey:@"name"];
    res.symbol.conversion = [[symbolDict objectForKey:@"conversion"] longLongValue];
    res.symbol.symbolappearsAfter = [[symbolDict objectForKey:@"symbolAppearsAfter"] boolValue];

    return res;
}



-(NSDictionary*)resolveAlias:(NSString*)alias {    

        NSMutableString * string = [NSMutableString stringWithFormat:@"%@wallet/%@?format=json", WebROOT, [alias urlencode]];
        
        NSURL * url = [NSURL URLWithString:string];
        
        NSHTTPURLResponse * response = NULL;
        NSError * error = NULL;
        
        NSData * data = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:url] returningResponse:&response error:&error];
        
        if (data == NULL || [data length] == 0) {
            [app standardNotify:@"Error Resolving Alias"];
            return nil;
        }
        
        NSString * responseString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
        
        if ([response statusCode] == 500) {
            [app standardNotify:responseString];
            return nil;
        }
        
        if (error != NULL || [response statusCode] != 200) {
            [app standardNotify:[error localizedDescription]];
            return nil;
        }
    
    JSONDecoder * json = [[[JSONDecoder alloc] init] autorelease];
        
    return [json objectWithData:data];
}


-(void)getUnconfirmedTransactions {
    
    [app startTask:TaskLoadUnconfirmed];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
        @try {
            NSMutableString * string = [NSMutableString stringWithFormat:@"%@unconfirmed-transactions?format=json", WebROOT];
          
            NSURL * url = [NSURL URLWithString:string];
            
            NSHTTPURLResponse * repsonse = NULL;
            NSError * error = NULL;
            
            NSData * data = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:url] returningResponse:&repsonse error:&error];
            
            if (data == NULL || [data length] == 0) {
                [app standardNotify:@"Error getting pending trasactions from server"];
                return;
            }
            
            NSString * responseString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
            
            if ([repsonse statusCode] == 500) {
                [app standardNotify:responseString];
                return;
            }
            
            if (error != NULL || [repsonse statusCode] != 200) {
                [app standardNotify:[error localizedDescription]];
                return;
            }
                    
            MulitAddressResponse * res = [self parseMultiAddr:data];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate didGetUnconfirmedTransactions:res];
            });    
        } @finally {
            [app finishTask];
        }
    });

}


-(void)multiAddr:(NSString*)walletIdentifier addresses:(NSArray*)addresses {
    
    NSLog(@"Do multi address");
    
    if ([addresses count] == 0)
        return;
    
    [app startTask:TaskGetMultiAddr];
        
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
        @try {
            NSMutableString * string = [NSMutableString stringWithFormat:@"%@multiaddr?", WebROOT];
            
            for (NSString * addr in addresses) {
                [string appendFormat:@"&addr[]=%@", addr];
            }
            
            NSURL * url = [NSURL URLWithString:string];
            
            NSHTTPURLResponse * repsonse = NULL;
            NSError * error = NULL;
            
            NSData * data = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:url] returningResponse:&repsonse error:&error];
            
            if (data == NULL || [data length] == 0) {
                [app standardNotify:@"Error getting trasactions from server"];
                return;
            }
                        
            NSString * responseString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
            
            if ([repsonse statusCode] == 500) {
                [app standardNotify:responseString];
                return;
            }
            
            if (error != NULL || [repsonse statusCode] != 200) {
                [app standardNotify:[error localizedDescription]];
                return;
            }
            
            //Write Cached copy
            [app writeToFile:data fileName:MultiaddrCacheFile];
            
            MulitAddressResponse * res = [self parseMultiAddr:data];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate didGetMultiAddr:res];
            });    
        } @finally {
            [app finishTask];
        }
    });
}

@end
