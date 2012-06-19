//
//  WebSocketNSStream.m
//  AIM Addict
//
//  Created by Ben Reeves on 14/05/2011.
//  Copyright 2011 Rainy Day Apps. All rights reserved.
//

#import "WebSocketNSStream.h"

#define BUFFER_LEN 2024

@implementation WebSocketNSStream

-(void)releaseStreams {
    
    if (inStream) {
        [inStream setDelegate:nil];
        [inStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [inStream close];
        [inStream release];
    }
    
    if (outStream) {
        [outStream setDelegate:nil];
        [outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [outStream close];
        [outStream release];
    }
    
    outStream = nil; 
    inStream = nil;
    
    currentMessagePtr = currentMessage;       
    outputBufferLength = 0;
}

-(ReadyState)readyState {
     
    switch ([inStream streamStatus]) {
        case NSStreamStatusClosed:
        case NSStreamStatusError:
        case NSStreamStatusNotOpen:
            return ReadyStateClosed;
            break;
        case NSStreamStatusOpening:
            return ReadyStateConnecting;
            break;
        case NSStreamStatusAtEnd:
            return ReadyStateClosing;
            break; 
        default:
            return ReadyStateOpen;
            break;
    }
}

-(void)dealloc {
    if (currentMessage) free(currentMessage);
    if (outputBuffer) free(outputBuffer);
    
    [request release];
    [super dealloc];
}

-(void)disconnect {
    [self releaseStreams];
}

-(void)connect:(NSString*)urlString {
    
    [self releaseStreams];
    
    hasWrittenRequest = NO;
    receivedResponse = NO;
    receivedUpgradeResponse = NO;
    
    NSURL * url = [NSURL URLWithString:urlString];
        
    uint16_t port = [[url port] shortValue];
    if (port == 0)
        port = 80;
        
    CFStreamCreatePairWithSocketToHost (kCFAllocatorSystemDefault,
                                        (CFStringRef)[url host],
                                        port,
                                        (CFReadStreamRef*)&inStream,
                                        (CFWriteStreamRef*)&outStream
                                        );
    inStream.delegate = self;
    outStream.delegate = self;
    
    [request release];
    request = [[NSString alloc] initWithFormat:
                          @"GET %@ HTTP/1.1\r\n"
                          "Upgrade: WebSocket\r\n"
                          "Connection: Upgrade\r\n"
                          "Host: %@\r\n"
                          "Origin: %@\r\n"
                          "\r\n",
                          [url path], [url host], [url absoluteURL]];
        
    NSLog(@"%@", request);
    
    [inStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                       forMode:NSDefaultRunLoopMode];
    [outStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                       forMode:NSDefaultRunLoopMode];
    
    [inStream open];
    
    [outStream open];
}

-(void)pumpOutputBuffer {
    int written = [outStream write:outputBuffer maxLength:outputBufferLength];   
    
    if (written == -1) {
        [self releaseStreams];
        [delegate webSocket:self onError:[outStream streamError]];
        [delegate webSocketOnClose:self];
    } else if (written != outputBufferLength) {        
        memmove(outputBuffer, outputBuffer+written, outputBufferLength-written);
        outputBufferLength -= written;
    } else {
        outputBufferLength = 0;
    }
}

-(void)send:(const uint8_t*)data length:(int)length {
    
    if (!receivedUpgradeResponse)
        return;
    
    length += 2;
    
    if (outputBufferTotalLength <= outputBufferLength+length) {
        outputBuffer = realloc(outputBuffer, outputBufferLength+length);
        outputBufferTotalLength += length;
    }
    
    *(outputBuffer+outputBufferLength) = 0x00;
    memcpy(outputBuffer+outputBufferLength+1, data, length-2);
    *(outputBuffer+outputBufferLength+length-1) = 0xFF;
    
    outputBufferLength += length;
    
    if ([outStream hasSpaceAvailable]) {
        [self pumpOutputBuffer];
    }
}

- (void)send:(NSString*)message {
    [self send:(const uint8_t*)[message cStringUsingEncoding:NSUTF8StringEncoding] length:[message lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
            break;
        case NSStreamEventErrorOccurred:
            [delegate webSocket:self onError:[aStream streamError]];
        case NSStreamEventEndEncountered:
            [delegate webSocketOnClose:self];
            [self releaseStreams];
            break;
        case NSStreamEventHasBytesAvailable:
        {
            if (receivedUpgradeResponse) {
                while ([inStream hasBytesAvailable])
                {
                    int lengthUsed = currentMessagePtr - currentMessage;

                    if (lengthUsed == currentMessageLen) {
                        currentMessageLen += BUFFER_LEN;                                             
                        currentMessage = realloc(currentMessage, currentMessageLen);
                        currentMessagePtr = currentMessage + lengthUsed;
                    }

                    int lengthLeft = currentMessageLen - (currentMessagePtr - currentMessage);
                    
                    int read = [inStream read:currentMessagePtr maxLength:lengthLeft];
                           
                    for (int ii = 0; ii < read; ++ii) {
                                                                                    
                       if (*currentMessagePtr == 0x00) {                                                        
                           memmove(currentMessage, currentMessagePtr, read-ii);
                           currentMessagePtr = currentMessage;
                       } else if (*currentMessagePtr == 0xFF) {                                                        
                           [delegate webSocket:self onReceive:[NSData dataWithBytesNoCopy:currentMessage+1 length:(currentMessagePtr-currentMessage-1) freeWhenDone:NO]];
                       } 
                        
                        ++currentMessagePtr;
                    }
                }
                
            } else {
                //read data
                uint8_t buffer[BUFFER_LEN];
                int len;
                while ([inStream hasBytesAvailable])
                {
                                        
                    len = [inStream read:buffer maxLength:BUFFER_LEN];
                    if (len > 0)  {
                        printf("%s\n", buffer);
                        
                        if (!receivedResponse && strstr((const char*)buffer,  "HTTP/1.1 101 Web Socket Protocol Handshake")) {
                            receivedUpgradeResponse = YES;
                          
                            [delegate webSocketOnOpen:self];

                            if (outputBufferLength > 0) {
                                [self pumpOutputBuffer];
                            }

                        }
                        receivedResponse = YES;
                    }
                }
            }
            break;
        }
        case NSStreamEventHasSpaceAvailable:
        {
            if (!hasWrittenRequest) {
                [outStream write:(const uint8_t*)[request cStringUsingEncoding:NSASCIIStringEncoding] maxLength:[request length]];
                hasWrittenRequest = YES;
            } else if (outputBufferLength > 0 && receivedUpgradeResponse) {
                [self pumpOutputBuffer];
            }
        }
            break;
        default:
            break;
    }
}


@end
