//
//  ObjectiveFayeChannel.m
//  ObjectiveFaye
//
//  Created by Steven Luscher on 2013-02-15.
//  Copyright (c) 2013 Steven Luscher. All rights reserved.
//

#import "ObjectiveFayeChannel.h"

NSString * const kObjectiveFayeChannelHandshake = @"/meta/handshake";
NSString * const kObjectiveFayeChannelConnect = @"/meta/connect";
NSString * const kObjectiveFayeChannelSubscribe = @"/meta/subscribe";
NSString * const kObjectiveFayeChannelUnsubscribe = @"/meta/unsubscribe";
NSString * const kObjectiveFayeChannelDisconnect = @"/meta/disconnect";

@interface ObjectiveFayeChannel()

@property (nonatomic) NSString *id;
@property (nonatomic) NSString *name;

@end

@implementation ObjectiveFayeChannel

- (ObjectiveFayeChannel *)initWithName:(NSString *)name
{
    if (self = [self init]) {
        self.id = name;
        self.name = name;
    }
    return self;
}

- (void)push:(id)message
{
    // TODO: (From Publisher) [self trigger:@"message" withArgs:message];
}

- (BOOL)isUnused
{
    // TODO: (From Publisher) return [self countListeners:@"message"] == 0;
    return NO;
}

@end
