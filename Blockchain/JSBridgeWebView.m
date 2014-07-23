/*
 Copyright (c) 2010, Dante Torres All rights reserved.
 
 Redistribution and use in source and binary forms, with or without 
 modification, are permitted provided that the following conditions 
 are met:
 
 * Redistributions of source code must retain the above copyright 
 notice, this list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright 
 notice, this list of conditions and the following disclaimer in the 
 documentation and/or other materials provided with the distribution.
 
 * Neither the name of the author nor the names of its 
 contributors may be used to endorse or promote products derived from 
 this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
 POSSIBILITY OF SUCH DAMAGE.
 */

#import "JSBridgeWebView.h"
#import "JSONKit.h"
#import "NSString+NSString_EscapeQuotes.h"

@interface JSCommandObject : NSObject
@property(nonatomic, strong) NSString * command;
@property(nonatomic, strong) void (^callback)(NSString * result);
@end

@implementation JSCommandObject

@end

/*
	Those are some auxiliar procedures that are used internally.
 */
@interface JSBridgeWebView (Private)

// Verifies if a request URL is a JS notification.
-(NSArray*) getJSNotificationIds:(NSURL*) p_Url;

// Decodes a raw JSON dictionary.
-(NSDictionary*) translateDictionary:(NSDictionary*) dictionary;

// Returns the object that is stored in the objDic dictionary.
-(NSObject*) translateObject:(NSDictionary*) objDic;

@end

@implementation JSBridgeWebView

-(void)dealloc {
    [self stopLoading];
    self.delegate = nil;
    self.JSDelegate = nil;
    [self.pending_commands release];
    [super dealloc];
}

-(void)executeJSWithCallback:(void (^)(NSString * result))callback command:(NSString*)formatString,  ...
{
    va_list args;
    va_start(args, formatString);
    NSString * contents = [[NSString alloc] initWithFormat:formatString arguments:args];
    va_end(args);
    
    if (self.isLoaded) {
        NSString * result = [self stringByEvaluatingJavaScriptFromString:contents];
        
        if (callback != NULL)
            callback(result);
    } else {
        JSCommandObject * object = [[JSCommandObject alloc] init];
        
        object.command = contents;
        object.callback = callback;
        
        [self.pending_commands addObject:object];
    }
}


-(NSString*)executeJSSynchronous:(NSString*)formatString,  ... {
    
    va_list args;
    va_start(args, formatString);
    NSString * contents = [[NSString alloc] initWithFormat:formatString arguments:args];
    va_end(args);
    
    if (!self.isLoaded) {
        @throw [NSException exceptionWithName:@"JSBridgeWebView Exception" reason:[NSString stringWithFormat:@"Cannot Call Synchronous Method With Webview not fully loaded %@", formatString] userInfo:nil];
    }
    
    return [self stringByEvaluatingJavaScriptFromString:contents];
}

-(void)executeJS:(NSString*)formatString,  ...
{
    va_list args;
    va_start(args, formatString);
    NSString * contents = [[NSString alloc] initWithFormat:formatString arguments:args];
    va_end(args);
    
    if (self.isLoaded) {
        [self stringByEvaluatingJavaScriptFromString:contents];
    } else {
        
        JSCommandObject * object = [[JSCommandObject alloc] init];
        
        object.command = contents;
        object.callback = nil;
        
        [self.pending_commands addObject:object];
    }
}

/*
	Init the JSBridgeWebView object. It sets the regular UIWebview delegate to self,
	since the object will be listening to JS notifications.
*/
-(id) initWithFrame:(CGRect)frame
{
	if ([super initWithFrame:frame])
	{
        self.pending_commands = [NSMutableArray array];
        [self setDelegate:self];
        usedIDs = [[NSMutableSet alloc] init];
	}
	
	return self;
}

- (void)awakeFromNib
{
    self.pending_commands = [NSMutableArray array];
    [self setDelegate:self];
    usedIDs = [[NSMutableSet alloc] init];
}

/*
	Init the JSBridgeWebView object. It sets the regular UIWebview delegate to self,
	since the object will be listening to JS notifications.
 */
-(id) init
{
	if ([super init]) 
	{
        self.pending_commands = [NSMutableArray array];
        [self setDelegate:self];
        usedIDs = [NSMutableSet set];
	}
	
	return self;
}

-(void)reset {
    usedIDs = [NSMutableSet set];
}


/*
	Verifies if the JS is trying to communicate. This verification is done
	by analysing the URL that the JS is trying to load.
 */
-(NSArray*) getJSNotificationIds:(NSURL*) p_Url
{
	NSString* strUrl = [p_Url absoluteString];
	NSArray* array = nil;
	
	// Checks if the URL means a JS notification.
	if ([strUrl hasPrefix:@"JSBridge://ReadNotificationWithId="]) {
		
		NSRange range = [strUrl rangeOfString:@"="];
		
		NSUInteger index = range.location + range.length;
		
		NSString*  result = [strUrl substringFromIndex:index];
        
       array = [result componentsSeparatedByString:@","];
	}
	
	return array;
}

/*
	Translates a raw JSON dictionary into a new dictionary with Objective-C
	objects. The input dictionary contains only string objects, which represent the
	object types and values.
 */
-(NSDictionary*) translateDictionary:(NSDictionary*) dictionary
{
	NSMutableDictionary* result = [NSMutableDictionary dictionaryWithCapacity:0];
	for (NSString* key in dictionary) {
		NSDictionary* tempDic = [dictionary objectForKey:key];
		
		NSObject* obj = [self translateObject:tempDic];
		
        if (obj != nil)
            [result setObject:obj forKey:key];
	}
	
	return result;
}

/*
	Translates a dictionary containing two objects with keys 'type' and 'value'
	into an actual Objective-C object. The objects may be NSString, NSNumber,
	UIImage and NSArray.
 */
-(NSObject*) translateObject:(NSDictionary*) objDic
{
	NSString* type = [objDic objectForKey:@"type"];
	NSObject* value = [objDic objectForKey:@"value"];
	NSObject* result = nil;
	
	if ([type compare:@"string"] == NSOrderedSame) {
		
		result = value;
	} else if ([type compare:@"number"] == NSOrderedSame) {
		
		result = [NSNumber numberWithDouble:[((NSString*)value) doubleValue]];
	} else if ([type compare:@"boolean"] == NSOrderedSame) {
		
		result = [NSNumber numberWithBool:[((NSString*)value) boolValue]];
	} else if ([type compare:@"array"] == NSOrderedSame) {
		
		NSDictionary* arrayData = (NSDictionary*) value;
		NSUInteger count = [arrayData count];
		NSMutableArray* array = [NSMutableArray arrayWithCapacity:count];
		
		for (int i = 0; i < count; i++) {
			[array addObject:[self translateObject:[arrayData objectForKey:[NSString stringWithFormat:@"obj%d", i]]]];
		}
		result = array;
	} else if ([type compare:@"object"] == NSOrderedSame) {
		
		result = [NSDictionary dictionaryWithDictionary:(NSDictionary*)value];
	}
	
	return result;
}


- (void)webView:(UIWebView*) webview didReceiveJSNotificationWithDictionary:(NSDictionary*) dictionary success:(void (^)(id))success error:(void (^)(id))error
{
    //NSLog(@"didReceiveJSNotificationWithDictionary: %@", dictionary);
    
    NSString * function = (NSString*)[dictionary objectForKey:@"function"];
        
    BOOL successArg = [[dictionary objectForKey:@"success"] isEqualToString:@"TRUE"];
    BOOL errorArg = [[dictionary objectForKey:@"error"] isEqualToString:@"TRUE"];
    
    int componentsCount = [[function componentsSeparatedByString:@":"] count]-1;

    __block int retain = 0;

    if (success || errorArg) {
        [webview retain];
        [self.JSDelegate retain];
        ++retain;
    }
    
    void (^_success)(id) = ^(id object) {
        success(object);
        
        if (retain > 0) {
            [webview release];
            [self.JSDelegate release];
        }
    };
    
    void (^_error)(id) = ^(id object) {
        error(object);
        
        if (retain > 0) {
            [webview release];
            [self.JSDelegate release];
        }
    };
    
    if (successArg) {
        function = [function stringByAppendingString:@"success:"];
    }
    
    if (errorArg) {
        function = [function stringByAppendingString:@"error:"];
    }
    
    if (function != nil) {
        SEL selector = NSSelectorFromString(function);
        if ([self.JSDelegate respondsToSelector:selector]) {
            
            NSMethodSignature * sig = [self.JSDelegate methodSignatureForSelector:selector];
            
            if (sig) {
                NSInvocation* invo = [NSInvocation invocationWithMethodSignature:sig];
                
                [invo setTarget:self.JSDelegate];
                [invo setSelector:selector];
                
                int index = 2;
                
                if ([sig numberOfArguments] > index && componentsCount >= 1) {
                    id arg1 = [dictionary objectForKey:@"arg1"];
                    [invo setArgument:&arg1 atIndex:index];
                    ++index;
                }
                
                if ([sig numberOfArguments] > index && componentsCount >= 2) {
                    id arg2 = [dictionary objectForKey:@"arg2"];
                    [invo setArgument:&arg2 atIndex:index];
                    ++index;
                }
                
                if ([sig numberOfArguments] > index && componentsCount >= 3) {
                    id arg3 = [dictionary objectForKey:@"arg3"];
                    [invo setArgument:&arg3 atIndex:index];
                    ++index;
                }
                
                if ([sig numberOfArguments] > index && componentsCount >= 3) {
                    id arg4 = [dictionary objectForKey:@"arg4"];
                    [invo setArgument:&arg4 atIndex:index];
                    ++index;
                }
                
                if (successArg) {
                    [invo setArgument:&_success atIndex:index];
                    ++index;
                }
                
                if (errorArg) {
                    [invo setArgument:&_error atIndex:index];
                    ++index;
                }
                                
                [invo invoke];
            }
        } else {
            NSLog(@"!!! JSdelegate does not respond to selector %@", function);
        }
    }
    
    if (!successArg && !errorArg) {
        success(nil);
    }
}

/*
	Listen to any try of page loading. This method checks, by the URL to be loaded, if
	it is a JS notification.
 */
- (BOOL)webView:(UIWebView *)p_WebView  shouldStartLoadWithRequest:(NSURLRequest *)request  navigationType:(UIWebViewNavigationType)navigationType {
{
   NSLog(@"JSBridgeView shouldStartLoadWithRequest:%@", [request mainDocumentURL]);
    
	// Checks if it is a JS notification. It returns the ID ob the JSON object in the JS code. Returns nil if it is not.
	NSArray * IDArray = [self getJSNotificationIds:[request URL]];
    
	if([IDArray count] > 0)
	{
            for (NSString * jsNotId in IDArray) {
                if (![usedIDs containsObject:jsNotId]) {
                    [usedIDs addObject:jsNotId];
                    
                    // Reads the JSON object to be communicated.
                    NSString* jsonStr = [p_WebView stringByEvaluatingJavaScriptFromString:[NSString  stringWithFormat:@"JSBridge_getJsonStringForObjectWithId(%@)", jsNotId]];
                    
                    JSONDecoder * json = [[[JSONDecoder alloc] init] autorelease];
                    
                    NSDictionary * jsonDic = [json objectWithUTF8String:(const unsigned char*)[jsonStr UTF8String] length:[jsonStr length]];
                    
                    NSDictionary* dicTranslated = [self translateDictionary:jsonDic];
                    
                    // Calls the delegate method with the notified object.
                    if(self.JSDelegate)
                    {
                        [self webView:p_WebView didReceiveJSNotificationWithDictionary: dicTranslated success:^(id success) {
                            //On success
                            if (success != nil) {
                                NSString * function = [NSString stringWithFormat:@"JSBridge_setResponseWithId(%@, \"%@\", true);", jsNotId, [success escapeDoubleQuotes]];
                                
                                [p_WebView stringByEvaluatingJavaScriptFromString:function];
                            } else {
                                [p_WebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"JSBridge_setResponseWithId(%@, null, true);", jsNotId]];
                            }
                        } error:^(id error) {
                            //On Error
                            if (error != nil) {
                                NSString * function = [NSString stringWithFormat:@"JSBridge_setResponseWithId(%@, \"%@\", false);", jsNotId, [error escapeDoubleQuotes]];
                                
                                [p_WebView stringByEvaluatingJavaScriptFromString:function];
                                
                            } else {
                                [p_WebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"JSBridge_setResponseWithId(%@, null, false);", jsNotId]];

                            }
                        }];
                    }
                }
            }
        
            return FALSE;
        } else {
            [usedIDs removeAllObjects];
            
            // If it is not a JS notification, pass it to the delegate.
            return TRUE;
        }
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSLog(@"JSBridgeWebView Did Load");

    for (JSCommandObject * command in self.pending_commands) {
        
        NSString * result = [self stringByEvaluatingJavaScriptFromString:command.command];
        
        if (command.callback != NULL)
            command.callback(result);
    }
    
    [self.pending_commands removeAllObjects];
    
    self.isLoaded = true;
    
    if ([self.JSDelegate respondsToSelector:@selector(webViewDidFinishLoad:)])
        [self.JSDelegate webViewDidFinishLoad:webView];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"JSBridgeWebView Did fail %@", error);
    
    if ([self.JSDelegate respondsToSelector:@selector(webView:didFailLoadWithError:)])
        [self.JSDelegate webView:webView didFailLoadWithError:error];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    if ([self.JSDelegate respondsToSelector:@selector(webViewDidStartLoad:)])
        [self.JSDelegate webViewDidStartLoad:webView];
}
@end
