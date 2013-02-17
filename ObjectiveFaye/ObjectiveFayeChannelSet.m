//
//  ObjectiveFayeChannelSet.m
//  ObjectiveFaye
//
//  Created by Steven Luscher on 2013-02-15.
//  Copyright (c) 2013 Steven Luscher. All rights reserved.
//

#import "ObjectiveFayeChannelSet.h"
#import "ObjectiveFayeChannel.h"
#import "ObjectiveFaye+Publisher.h"

@interface ObjectiveFayeChannelSet()

@property (nonatomic) NSMutableDictionary *_channels;

@end

@implementation ObjectiveFayeChannelSet

- (id)init
{
    if (self = [super init]) {
        self._channels = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (NSArray *)getKeys
{
    return [self._channels allKeys];
}

- (void)remove:(NSString *)name
{
    [self._channels removeObjectForKey:name];
}
 
- (BOOL)hasSubscription:(NSString *)name
{
    return !![self._channels objectForKey:name];
}
 
- (void)subscribe:(NSArray *)names withCallback:(id)callback inContext:(id)context
{
    if (!callback) return;
 
    for (NSString *name in names) {
        ObjectiveFayeChannel *channel = [self._channels objectForKey:name];
        if (!channel) {
            channel = [[ObjectiveFayeChannel alloc] initWithName:name];
            [self._channels setObject:channel forKey:name];
        }
        [channel bind:@"message" withListener:callback inContext:context];
    }
}

- (BOOL)unsubscribe:(NSString *)name withCallback:(id)callback inContext:(id)context
{
    ObjectiveFayeChannel *channel = [self._channels objectForKey:name];
    if (!channel) return NO;
 
    [channel unbind:@"message" withListener:callback inContext:context];
 
    if ([channel isUnused]) {
        [self remove:name];
        return YES;
    } else {
        return NO;
    }
}

/* TODO
 distributeMessage: function(message) {
 var channels = Faye.Channel.expand(message.channel);
 
 for (var i = 0, n = channels.length; i < n; i++) {
 var channel = this._channels[channels[i]];
 if (channel) channel.trigger('message', message.data);
 }
 }
 })
 */
@end
