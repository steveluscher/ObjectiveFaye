//
//  ObjectiveFayeTransportWebsocket.m
//  ObjectiveFaye
//
//  Created by Steven Luscher on 2013-02-15.
//  Copyright (c) 2013 Steven Luscher. All rights reserved.
//

#import "ObjectiveFayeTransportWebsocket.h"
#import "ObjectiveFaye+Deferrable.h"
#import "ObjectiveFaye+Publisher.h"

#import <SocketRocket/SRWebSocket.h>

typedef enum {
    kUnconnected = 1,
    kConnecting = 2,
    kConnected = 3
} ObjectiveFayeWebsocketConnectionStatus;

@interface ObjectiveFayeTransportWebsocket() <SRWebSocketDelegate>

@property (nonatomic) ObjectiveFayeClient *_client;
@property (nonatomic, readonly) BOOL batching;
@property (nonatomic) NSMutableDictionary *_messages;
@property (nonatomic) BOOL _closed;
@property (nonatomic) SRWebSocket *_socket;
@property (nonatomic) ObjectiveFayeWebsocketConnectionStatus _state;
@property (nonatomic) BOOL _everConnected;

@end

@implementation ObjectiveFayeTransportWebsocket

- (id)init
{
    if (self = [super init]) {
        _batching = NO;
    }
    return self;
}

- (void)request:(NSArray *)messages withTimeout:(NSNumber *)timeout
{
    if ([messages count] == 0) return;
    if (!self._messages) self._messages = [[NSMutableDictionary alloc] init];
    
    for (NSDictionary *message in messages) {
        [self._messages setObject:message forKey:message[@"id"]];
    }
    [self callback:^(id socket, id context){ [socket send:messages]; } withContext:nil];
    [self connect];
}

- (void)close
{
    if (self._closed) return;
    self._closed = YES;
    if (self._socket) [self._socket close];
}

- (void)connect
{
    // TODO: if (Faye.Transport.WebSocket._unloaded) return;
    if (self._closed) return;
    
    if (!self._state) self._state = kUnconnected;
    if (self._state != kUnconnected) return;
    
    self._state = kConnecting;
    
    self._socket = [[SRWebSocket alloc] initWithURL:[ObjectiveFayeTransportWebsocket getSocketUrl:self.endpoint]];
    
    self._socket.delegate = self;
    [self._socket open];
}


- (void)resend
{
    if (!self._messages) return;
    NSArray *messages = [self._messages allValues];
    [self request:messages withTimeout:nil];
}


+ (NSURL *)getSocketUrl:(NSString *)endpoint
{
    endpoint = [[[NSURL alloc] initWithString:endpoint] absoluteString];
    
    NSError *error = nil;
    NSRegularExpression *re = [[NSRegularExpression alloc] initWithPattern:@"^http(s?):" options:0 error:&error];
    endpoint = [re stringByReplacingMatchesInString:endpoint options:0 range:NSRangeFromString(endpoint) withTemplate:@"ws$1:"];
    
    return [NSURL URLWithString:endpoint];
}

#pragma mark - SRWebSocketDelegate methods

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    // message will either be an NSString if the server is using text
    // or NSData if the server is using binary
    NSError *readError = nil;
    id messages = [NSJSONSerialization JSONObjectWithData:message options:0 error:&readError];
    
    if (![messages isKindOfClass:[NSArray class]]) {
        messages = @[messages];
    }
    
    for (NSDictionary *message in messages) {
        [self._messages removeObjectForKey:message[@"id"]];
    }
    [self receive:messages];
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    self._state = kConnected;
    self._everConnected = YES;
    [self setDeferredStatus:@"succeeded" withArgs:self._socket];
    [self trigger:@"up" withArgs:nil];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    BOOL wasConnected = (self._state == kConnected);
    [self setDeferredStatus:@"deferred"];
    self._state = kUnconnected;
    self._socket.delegate = nil;
    self._socket = nil;
    
    if (wasConnected) return [self resend];
    if (!self._everConnected) return [self setDeferredStatus:@"failed"];
    
    float retry = self._client.retry * 1000;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, retry * NSEC_PER_SEC), dispatch_get_current_queue(), ^ { [self connect]; });
    [self trigger:@"down" withArgs:nil];
}


@end
