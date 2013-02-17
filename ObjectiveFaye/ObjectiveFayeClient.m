//
//  ObjectiveFayeClient.m
//  ObjectiveFaye
//
//  Created by Steven Luscher on 2013-02-14.
//  Copyright (c) 2013 Steven Luscher. All rights reserved.
//

#import "ObjectiveFayeClient.h"
#import "ObjectiveFayeChannel.h"
#import "ObjectiveFayeChannelSet.h"
#import "ObjectiveFayeTransportWebsocket.h"
#import "ObjectiveFayeSubscription.h"
#import "ObjectiveFaye+Deferrable.h"
#import "ObjectiveFaye+Publisher.h"

typedef enum {
    kUnconnected = 1,
    kConnecting = 2,
    kConnected = 3,
    kDisconnected = 4
} ObjectiveFayeClientConnectionStatus;

typedef void(^message_handler_t)(NSDictionary *);
typedef BOOL(^message_handler_with_bool_response_t)(NSDictionary *);

NSString * const kAdviceHandshake = @"handshake";
NSString * const kAdviceRetry = @"retry";
NSString * const kAdviceNone = @"none";

float const kConnectionTimeout = 60.0;
float const kDefaultRetry = 5.0;

NSString * const kDefaultEndpoint = @"/bayeux";
float const kInterval = 0.0;

@interface ObjectiveFayeClient()

@property (nonatomic) NSDictionary *_options;
@property (nonatomic) NSDictionary *_headers;
@property (nonatomic) NSMutableArray *_disabled;
@property (nonatomic) ObjectiveFayeClientConnectionStatus _state;
@property (nonatomic) ObjectiveFayeChannelSet *_channels;
@property (nonatomic) int _messageId;
@property (nonatomic) NSDictionary *_responseCallbacks;
@property (nonatomic) NSMutableDictionary *_advice;
@property (nonatomic) ObjectiveFayeTransport *_transport;
@property (nonatomic) BOOL _connectRequest;
@property (nonatomic) NSNumber *_transportUp;

@end

@implementation ObjectiveFayeClient

- (id)init
{
    if (self = [super init]) {
        self._options = @{};
        self.endpoint = kDefaultEndpoint;
        self.endpoints = @{};
        self.transports = @{};
        
        // TODO: self._cookies   = Faye.CookieJar && new Faye.CookieJar();
        self._headers = @{};
        self._disabled = [[NSMutableArray alloc] init];
        self.retry = kDefaultRetry;
        
        self._state = kDisconnected;
        self._channels = [[ObjectiveFayeChannelSet alloc] init];
        self._messageId = 0;
        
        self._responseCallbacks = @{};
        self._advice = [[NSMutableDictionary alloc]
                        initWithDictionary:@{
                        @"reconnect": kAdviceRetry,
                        @"interval": [NSNumber numberWithFloat:(1000.0 * kInterval)],
                        @"timeout": [NSNumber numberWithFloat:(1000.0 * kConnectionTimeout)]
                        }];
        
    }
    return self;
}

- (id)initWithEndpoint:(NSString *)endpoint andOptions:(NSDictionary *)options
{
    if (self = [self init]) {
        NSLog(@"New client created for %@", endpoint);
        
        if (options) self._options = options;
        if (endpoint) self.endpoint = endpoint;
        if (options[@"endpoints"]) self.endpoints = options[@"endpoints"];
        
        if (options[@"retry"]) self.retry = [options[@"retry"] floatValue];
        
        if (options[@"interval"]) {
            float value = [options[@"interval"] floatValue];
            NSNumber *milliseconds = [NSNumber numberWithFloat:(1000 * value)];
            [self._advice setObject:milliseconds forKey:@"interval"];
        }
        if (options[@"timeout"]) {
            float value = [options[@"timeout"] floatValue];
            NSNumber *milliseconds = [NSNumber numberWithFloat:(1000 * value)];
            [self._advice setObject:milliseconds forKey:@"timeout"];
        }
        
        /* TODO
         if (Faye.Event)
         Faye.Event.on(Faye.ENV, 'beforeunload', function() {
         if (Faye.indexOf(self._disabled, 'autodisconnect') < 0)
         self.disconnect();
         }, this);
         */
    }
    return self;
}

- (void)disableFeature:(NSString *)feature
{
    [self._disabled addObject:feature];
}

/* TODO:
 setHeader: function(name, value) {
 self._headers[name] = value;
 },
 */

- (NSString *)getClientId
{
    return self._clientId;
}

- (NSString *)getState
{
    NSString *result = nil;
    
    switch(self._state) {
        case kUnconnected:
            result = @"UNCONNECTED";
            break;
        case kConnecting:
            result = @"CONNECTING";
            break;
        case kConnected:
            result = @"CONNECTED";
            break;
        case kDisconnected:
            result = @"DISCONNECTED";
            break;
        default:
            [NSException raise:NSGenericException format:@"Unexpected state."];
    }
    
    return result;
}

// Request
// MUST include:  * channel
//                * version
//                * supportedConnectionTypes
// MAY include:   * minimumVersion
//                * ext
//                * id
//
// Success Response                             Failed Response
// MUST include:  * channel                     MUST include:  * channel
//                * version                                    * successful
//                * supportedConnectionTypes                   * error
//                * clientId                    MAY include:   * supportedConnectionTypes
//                * successful                                 * advice
// MAY include:   * minimumVersion                             * version
//                * advice                                     * minimumVersion
//                * ext                                        * ext
//                * id                                         * id
//                * authSuccessful
- (void)handshakeWithCallback:(void(^)(id context))callback inContext:(id)context
{
    if (self._advice[@"reconnect"] == kAdviceNone) return;
    if (self._state != kUnconnected) return;
    
    self._state = kConnecting;
    // TODO: var self = this;
    
    NSLog(@"Initiating handshake with %@", self.endpoint);
    [self selectTransport:kObjectiveFayeMandatoryConnectionTypes];
    
    NSDictionary *message = @{
                              @"channel": kObjectiveFayeChannelHandshake,
                              @"version": kObjectiveFayeBayeuxVersion,
                              @"supportedConnectionTypes": self._transport.connectionType
                              };
    message_handler_t onResponse = ^ (NSDictionary *response) {
        if (response[@"successful"]) {
            self._state = kConnected;
            self._clientId = response[@"clientId"];
            
            [self selectTransport:response[@"supportedConnectionTypes"]];
            
            NSLog(@"Handshake successful: %@", self._clientId);
            
            [self subscribeToChannel:[self._channels getKeys] withCallback:(id)kCFBooleanTrue inContext:nil];
            if (callback) callback(context);
        } else {
            NSLog(@"Handshake unsuccessful");
            // TODO: Faye.ENV.setTimeout(function() { self.handshake(callback, context) }, self._advice.interval);
            self._state = kUnconnected;
        }
    };
    
    [self sendMessage:message withCallback:onResponse inContext:self];
}


 // Request                              Response
 // MUST include:  * channel             MUST include:  * channel
 //                * clientId                           * successful
 //                * connectionType                     * clientId
 // MAY include:   * ext                 MAY include:   * error
 //                * id                                 * advice
 //                                                     * ext
 //                                                     * id
 //                                                     * timestamp
- (void)connectWithCallback:(id)callback inContext:(id)context
{
    if (self._advice[@"reconnect"] == kAdviceNone) return;
    if (self._state == kDisconnected) return;
 
    if (self._state == kUnconnected) {
        void(^onSuccess)(void) = ^{ [self connectWithCallback:callback inContext:context]; };

        return [self handshakeWithCallback:(id)onSuccess inContext:self];
    }
 
    // TODO: (From Deferrable) self.callback(callback, context);
    
    if (self._state != kConnected) return;
 
    /* TODO:
     NSLog(@"Calling deferred actions for %@", self._clientId);
     self.setDeferredStatus('succeeded');
     self.setDeferredStatus('deferred');
     */
 
    if (self._connectRequest) return;
    self._connectRequest = YES;
 
    NSLog(@"Initiating connection for %@", self._clientId);
 
    NSDictionary *message = @{
                              @"channel": kObjectiveFayeChannelConnect,
                              @"clientId": self._clientId,
                              @"connectionType": self._transport.connectionType
                              };

    [self sendMessage:message withCallback:(id)^{ [self cycleConnection]; } inContext:self];
}

/*
 // Request                              Response
 // MUST include:  * channel             MUST include:  * channel
 //                * clientId                           * successful
 // MAY include:   * ext                                * clientId
 //                * id                  MAY include:   * error
 //                                                     * ext
 //                                                     * id
 disconnect: function() {
 if (self._state !== self.CONNECTED) return;
 self._state = self.DISCONNECTED;
 
 NSLog(@"Disconnecting %@", self._clientId);
 
 self._send({
 channel:    Faye.Channel.DISCONNECT,
 clientId:   self._clientId
 
 }, function(response) {
 if (response.successful) self._transport.close();
 }, this);
 
 NSLog(@"Clearing channel listeners for %@", self._clientId);
 self._channels = new Faye.Channel.Set();
 },
 */
// Request                              Response
// MUST include:  * channel             MUST include:  * channel
//                * clientId                           * successful
//                * subscription                       * clientId
// MAY include:   * ext                                * subscription
//                * id                  MAY include:   * error
//                                                     * advice
//                                                     * ext
//                                                     * id
//                                                     * timestamp
- (ObjectiveFayeSubscription *)subscribeToChannel:(id)channel withCallback:(id)callback inContext:(id)context
{
    if ([channel isKindOfClass:[NSArray class]]) {
        [NSException raise:NSGenericException format:@"subscribeToChannel:withCallback:inContext: Array channel arguments not implemented."];
        return nil;
        /* TODO
        return Faye.map(channel, function(c) {
            return self.subscribe(c, callback, context);
        }, this);
         */
    }
    
    ObjectiveFayeSubscription *subscription = [[ObjectiveFayeSubscription alloc] initWithClient:self
                                                                                    forChannels:channel
                                                                                   withCallback:callback
                                                                                      inContext:context];
    BOOL force = [callback isEqual:(id)kCFBooleanTrue];
    BOOL hasSubscribe = [self._channels hasSubscription:channel];
     
    if (hasSubscribe && !force) {
        [self._channels subscribe:@[channel] withCallback:callback inContext:context];
        // TODO: [subscription setDeferredStatus:@"succeeded"];
        return subscription;
    }

    [self connectWithCallback:^{
        NSLog(@"Client %@ attempting to subscribe to %@", self._clientId, channel);
        if (!force) [self._channels subscribe:@[channel] withCallback:callback inContext:context];
        
        NSDictionary *message = @{
                                  @"channel": kObjectiveFayeChannelSubscribe,
                                  @"clientId": self._clientId,
                                  @"subscription": channel
                                  };
        message_handler_t onResponse = ^ (NSDictionary *response) {
            if (!response[@"successful"]) {
                // TODO: [subscription setDeferredStatus:@"failed" withArgs:[FayeError parse:response[@"error"]]];
                [self._channels unsubscribe:channel
                               withCallback:callback
                                  inContext:context];
                return;
            }
            
            NSArray *channels = @[response[@"subscription"]];
            NSLog(@"Subscription acknowledged for %@ to %@", self._clientId, channels);
            // TODO: [subscription setDeferredStatus:@"succeeded"];
        };
        
        [self sendMessage:message withCallback:onResponse inContext:self];
    } inContext:self];
     
    return subscription;
}

/*
 
 // Request                              Response
 // MUST include:  * channel             MUST include:  * channel
 //                * clientId                           * successful
 //                * subscription                       * clientId
 // MAY include:   * ext                                * subscription
 //                * id                  MAY include:   * error
 //                                                     * advice
 //                                                     * ext
 //                                                     * id
 //                                                     * timestamp
 unsubscribe: function(channel, callback, context) {
 if (channel instanceof Array)
 return Faye.map(channel, function(c) {
 return self.unsubscribe(c, callback, context);
 }, this);
 
 var dead = self._channels.unsubscribe(channel, callback, context);
 if (!dead) return;
 
 self.connect(function() {
 NSLog(@"Client %@ attempting to unsubscribe from %@", self._clientId, channel);
 
 self._send({
 channel:      Faye.Channel.UNSUBSCRIBE,
 clientId:     self._clientId,
 subscription: channel
 
 }, function(response) {
 if (!response.successful) return;
 
 var channels = [].concat(response.subscription);
 NSLog(@"Unsubscription acknowledged for %@ from %@", self._clientId, channels);
 }, this);
 }, this);
 },
 
 // Request                              Response
 // MUST include:  * channel             MUST include:  * channel
 //                * data                               * successful
 // MAY include:   * clientId            MAY include:   * id
 //                * id                                 * error
 //                * ext                                * ext
 publish: function(channel, data) {
 var publication = new Faye.Publication();
 
 self.connect(function() {
 NSLog(@"Client %@ queueing published message to %@: ?", self._clientId, channel, data);
 
 self._send({
 channel:      channel,
 data:         data,
 clientId:     self._clientId
 }, function(response) {
 if (response.successful)
 publication.setDeferredStatus('succeeded');
 else
 publication.setDeferredStatus('failed', Faye.Error.parse(response.error));
 }, this);
 }, this);
 
 return publication;
 },
 
 receiveMessage: function(message) {
 self.pipeThroughExtensions('incoming', message, function(message) {
 if (!message) return;
 
 if (message.advice) self._handleAdvice(message.advice);
 self._deliverMessage(message);
 
 if (message.successful === undefined) return;
 
 var callback = self._responseCallbacks[message.id];
 if (!callback) return;
 
 delete self._responseCallbacks[message.id];
 callback[0].call(callback[1], message);
 }, this);
 },
 */

- (void)selectTransport:(NSArray *)transportTypes
{
    [ObjectiveFayeTransport getForClient:self fromTransportTypes:transportTypes withCallback:^(ObjectiveFayeTransport *transport, id context) {
        
        NSLog(@"Selected %@ transport for %@", transport.connectionType, transport.endpoint);
         
         if (transport == self._transport) return;
         if (self._transport) [self._transport close];
         
         self._transport = transport;
         // TODO: self._transport.cookies = self._cookies;
         // TODO: self._transport.headers = self._headers;
        
        [transport bind:@"down" withListener:^(id args, id context){
            if (self._transportUp && ![self._transportUp boolValue]) return;
            self._transportUp = [NSNumber numberWithBool:NO];
            [self trigger:@"transport:down" withArgs:nil];
        } inContext:self];
         
        [transport bind:@"up" withListener:^(id args, id context){
            if (self._transportUp && [self._transportUp boolValue]) return;
            self._transportUp = [NSNumber numberWithBool:YES];
            [self trigger:@"transport:up" withArgs:nil];
        } inContext:self];
        
    } inContext:self];
}

- (void)sendMessage:(NSDictionary *)message withCallback:(message_handler_t)callback inContext:(id)context
{
    /* TODO:
     message.id = self._generateMessageId();
     if (callback) self._responseCallbacks[message.id] = [callback, context];
     
     self.pipeThroughExtensions('outgoing', message, function(message) {
     if (!message) return;
     self._transport.send(message, self._advice.timeout / 1000);
     }, this);
     */
}

/*
 _generateMessageId: function() {
 self._messageId += 1;
 if (self._messageId >= Math.pow(2,32)) self._messageId = 0;
 return self._messageId.toString(36);
 },
 
 _handleAdvice: function(advice) {
 Faye.extend(self._advice, advice);
 
 if (self._advice.reconnect === self.HANDSHAKE && self._state !== self.DISCONNECTED) {
 self._state    = self.UNCONNECTED;
 self._clientId = null;
 self._cycleConnection();
 }
 },
 
 _deliverMessage: function(message) {
 if (!message.channel || message.data === undefined) return;
 NSLog(@"Client %@ calling listeners for %@ with %@", self._clientId, message.channel, message.data);
 self._channels.distributeMessage(message);
 },
 
 _teardownConnection: function() {
 if (!self._connectRequest) return;
 self._connectRequest = null;
 NSLog(@"Closed connection for %@", self._clientId);
 },
 
*/
- (void)cycleConnection
{
 /* TODO
  self._teardownConnection();
  var self = this;
  Faye.ENV.setTimeout(function() { self.connect() }, self._advice.interval);
  }
  */
}

@end