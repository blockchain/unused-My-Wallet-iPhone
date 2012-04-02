//
//  WebSocket.h
//  AIM Addict
//
//  Created by Ben Reeves on 12/05/2011.
//  Copyright 2011 Rainy Day Apps. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    ReadyStateConnecting = 0,
    ReadyStateOpen = 1,
    ReadyStateClosing = 3,
    ReadyStateClosed = 2,
} ReadyState;

@class WebSocket;

@protocol WebSocketDelegate
@required
-(void)webSocketOnOpen:(WebSocket*)webSocket;
-(void)webSocketOnClose:(WebSocket*)webSocket;
-(void)webSocket:(WebSocket*)webSocket onError:(NSError*)error;
-(void)webSocket:(WebSocket*)webSocket onReceive:(NSData*)data; //Data is only until this function returns (You cannot retain it!)
@end

@interface WebSocket : NSObject {
    NSObject<WebSocketDelegate> * delegate;
}

@property(nonatomic, retain) NSObject<WebSocketDelegate> * delegate;

-(void)connect:(NSString*)url_string;
-(void)disconnect;
-(void)send:(NSString*)message;
-(ReadyState)readyState;

@end
