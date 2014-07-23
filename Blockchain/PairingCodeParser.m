//
//  PairingCodeDelegate.m
//  Blockchain
//
//  Created by Ben Reeves on 22/07/2014.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import "PairingCodeParser.h"
#import "AppDelegate.h"

@implementation PairingCodeParser

-(void)dealloc {
    self.readerView = nil;
    self.wallet = nil;
    self.success = nil;
    self.error = nil;
    
    [super dealloc];
}

- (void)errorParsingPairingCode:(NSString *)message {
    [app networkActivityStop];

    if (self.error) {
        self.error(message);
    }
    
    [self.wallet clearDelegates];
    self.wallet = nil;
}

-(void)didParsePairingCode:(NSDictionary *)dict {
    [app networkActivityStop];

    if (self.success) {
        self.success(dict);
    }
    
    [self.wallet clearDelegates];
    self.wallet = nil;
}

-(void)scanAndParse:(void (^)(NSDictionary*))__success error:(void (^)(NSString*))__error {
    self.success = __success;
    self.error = __error;
    
    self.readerView = [[ZBarReaderView new] autorelease];
    
    [app showModal:self.readerView isClosable:TRUE onDismiss:^() {
        [self.readerView stop];
        
        self.readerView = nil;
    }];
    
    [self.readerView start];
    
    [self.readerView setReaderDelegate:self];
}

- (void) readerView: (ZBarReaderView*) view didReadSymbols: (ZBarSymbolSet*) syms fromImage: (UIImage*) img {
    
    // do something uselful with results
    for(ZBarSymbol *sym in syms) {
        self.wallet = [[[Wallet alloc] init] autorelease];
        
        self.wallet.delegate = self;
        
        [self.wallet parsePairingCode:sym.data];
        
        app.loadingText = @"Parsing Pairing Code";
        
        [app networkActivityStart];
        
        break;
    }
    
    [app showWelcome];
    
    [self.readerView stop];
    
    self.readerView = nil;
}

@end
