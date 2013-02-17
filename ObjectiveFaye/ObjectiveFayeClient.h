//
//  ObjectiveFayeClient.h
//  ObjectiveFaye
//
//  Created by Steven Luscher on 2013-02-14.
//  Copyright (c) 2013 Steven Luscher. All rights reserved.
//

#import "ObjectiveFaye.h"
#import "ObjectiveFayeSubscription.h"

@class ObjectiveFayeSubscription;

@interface ObjectiveFayeClient : ObjectiveFaye

@property (nonatomic) NSString *endpoint;
@property (nonatomic) NSDictionary *endpoints;
@property (nonatomic) NSDictionary *transports;
@property (nonatomic) float retry;
@property (nonatomic) NSString *_clientId;

- (ObjectiveFayeClient *)initWithEndpoint:(NSString *)endpoint andOptions:(NSDictionary *)options;
- (void)disableFeature:(NSString *)feature;
- (NSString *)getState;

- (void)receiveMessage:(NSDictionary *)message;

- (ObjectiveFayeSubscription *)subscribeToChannel:(id)channel withCallback:(id)callback inContext:(id)context;
- (void)unsubscribeFromChannel:(id)channels withCallback:(id)callback inContext:(id)context;

@end