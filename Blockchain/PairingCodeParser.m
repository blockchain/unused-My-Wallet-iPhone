//
//  PairingCodeDelegate.m
//  Blockchain
//
//  Created by Ben Reeves on 22/07/2014.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import "PairingCodeParser.h"
#import "AppDelegate.h"
#import "BCModalView.h"

@implementation PairingCodeParser

- (void)errorParsingPairingCode:(NSString *)message
{
    [app networkActivityStop];

    if (self.error) {
        self.error(message);
    }
}

-(void)didParsePairingCode:(NSDictionary *)dict
{
    [app networkActivityStop];

    if (self.success) {
        self.success(dict);
    }
}

-(void)scanAndParse:(void (^)(NSDictionary*))__success error:(void (^)(NSString*))__error
{
    self.success = __success;
    self.error = __error;
    
    self.readerView = [[ZBarReaderView alloc] init];
    
    [app showModalWithContent:self.readerView closeType:ModalCloseTypeBack onDismiss:^() {
        [self.readerView stop];
        
        self.readerView = nil;
    } onResume:nil];
    
    [self.readerView start];
    
    [self.readerView setReaderDelegate:self];
}

- (void) readerView: (ZBarReaderView*) view didReadSymbols: (ZBarSymbolSet*) syms fromImage: (UIImage*) img
{
    
    // do something uselful with results
    for(ZBarSymbol *sym in syms) {
        
        [app.wallet loadBlankWallet];
        
        app.wallet.delegate = self;
        
        [app.wallet parsePairingCode:sym.data];
        
        app.loadingText = BC_STRING_PARSING_PAIRING_CODE;
        
        [app networkActivityStart];
        
        break;
    }
    
    [app closeModalWithTransition:kCATransitionFade];
}

@end
