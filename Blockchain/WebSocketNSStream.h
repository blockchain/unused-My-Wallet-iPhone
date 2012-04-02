//
//  WebSocketNSStream.h
//  AIM Addict
//
//  Created by Ben Reeves on 14/05/2011.
//  Copyright 2011 Rainy Day Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebSocket.h"

@interface WebSocketNSStream : WebSocket <NSStreamDelegate> {
    NSInputStream * inStream;
    NSOutputStream * outStream;
    BOOL hasWrittenRequest;
    BOOL receivedResponse;
    BOOL receivedUpgradeResponse;
    NSString * request;
   
    uint8_t * outputBuffer;
    int outputBufferTotalLength;
    int outputBufferLength;
    
    uint8_t * currentMessage;
    int currentMessageLen;
    uint8_t * currentMessagePtr;
}

-(void)connect:(NSString*)url_string;
-(void)disconnect; //TODO closing handshake

-(void)send:(NSString*)message;
-(void)send:(const uint8_t*)data length:(int)length;

//TODO send binary frame

@end
