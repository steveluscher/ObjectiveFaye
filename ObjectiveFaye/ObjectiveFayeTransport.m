//
//  ObjectiveFayeTransport.m
//  ObjectiveFaye
//
//  Created by Steven Luscher on 2013-02-15.
//  Copyright (c) 2013 Steven Luscher. All rights reserved.
//

#import "ObjectiveFayeTransport.h"
#import "ObjectiveFayeTransportWebsocket.h"
#import "ObjectiveFayeChannel.h"
#import "ObjectiveFaye+Deferrable.h"
#import "ObjectiveFaye+Publisher.h"
#import "ObjectiveFaye+Timeouts.h"

float const kMaxDelay = 0.0;
int const kObjectiveFayeMaxUrlLength = 2048;
// TODO: static NSMutableArray *_transports;

@interface ObjectiveFayeTransport()

@property (nonatomic, readonly) BOOL batching;
@property (nonatomic) ObjectiveFayeClient *_client;
@property (nonatomic) NSMutableArray *_outbox;
@property (nonatomic) NSNumber *_timeout;
@property (nonatomic) NSDictionary *_connectMessage;

@end

@implementation ObjectiveFayeTransport

+ (void)initialize
{
    // TODO: _transports = [[NSMutableArray alloc] init];
}

- (id)init
{
    if (self = [super init]) {
        _batching = YES;
    }
    return self;
}

- (id)initWithClient:(ObjectiveFayeClient *)client andEndpoint:(NSString *)endpoint
{
    if (self = [super init]) {
        self._client = client;
        self.endpoint = endpoint;
        self._outbox = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)request:(id)messages withTimeout:(NSNumber *)timeout
{
    // Implement in subclass
}

- (void)close
{
    // Implement in subclass
}
    
- (void)sendMessage:(NSDictionary *)message withTimeout:(NSNumber *)timeout
{
    NSLog(@"Client %@ sending message to %@: %@", self._client._clientId, self.endpoint, message);
    
    if (!self.batching) return [self request:@[message] withTimeout:timeout];
    
    [self._outbox addObject:message];
    self._timeout = timeout;
    
    if (message[@"channel"] == kObjectiveFayeChannelHandshake) {
        [self addTimeout:@"publish" withDelay:0.01 andCallback:^{ [self flush]; } inContext:self];
        return;
    }
    
    if (message[@"channel"] == kObjectiveFayeChannelConnect)
        self._connectMessage = message;
    
    if ([self respondsToSelector:@selector(shouldFlush:)] && [self performSelector:@selector(shouldFlush:) withObject:self._outbox]) {
        [self flush];
        return;
    }

    [self addTimeout:@"publish" withDelay:kMaxDelay andCallback:^{ [self flush]; } inContext:self];
}
    
- (void)flush
{
    [self removeTimeout:@"publish"];
    
    if ([self._outbox count] > 1 && self._connectMessage) {
        NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary:self._connectMessage];
        [d setObject:@{@"timeout": @0} forKey:@"advice"];
        self._connectMessage = [NSDictionary dictionaryWithDictionary:d];
    }
    
    [self request:self._outbox withTimeout:self._timeout];
    
    self._connectMessage = nil;
    self._outbox = [[NSMutableArray alloc] init];
}
    
- (void)receive:(NSArray *)responses
{
    NSLog(@"Client %@ received from %@: %@", self._client._clientId, self.endpoint, responses);
    
    for (NSDictionary *response in responses) {
        [self._client receiveMessage:response];
    }
}
    
- (void(^)(void))retry:(NSDictionary *)message withTimeout:(NSNumber *)timeout
{
    __block BOOL called = NO;
    float retry = self._client.retry * 1000;
    // TODO: (Necessary?) self = this;
    
    return ^ {
        if (called) return;
        called = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, retry * NSEC_PER_SEC), dispatch_get_current_queue(), ^ { [self request:@[message] withTimeout:timeout]; });
    };
}

+ (void)getForClient:(ObjectiveFayeClient *)client fromTransportTypes:(NSArray *)transportTypes withCallback:(void(^)(ObjectiveFayeTransport *callback, id context))callback inContext:(id)context
{
    // TODO: Actually implement transport selection; for now we always pick the websocket transport
 
    NSString *connEndpoint = client.endpoint;
    if ([client.endpoints objectForKey:@"websocket"]) connEndpoint = [client.endpoints objectForKey:@"websocket"];
    
    ObjectiveFayeTransport *transport = [[ObjectiveFayeTransportWebsocket alloc] initWithClient:client andEndpoint:connEndpoint];
    callback(transport, context);
}


@end
