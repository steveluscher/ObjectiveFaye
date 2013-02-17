//
//  ObjectiveFaye+Publisher.m
//  ObjectiveFaye
//
//  Created by Steven Luscher on 2013-02-16.
//  Copyright (c) 2013 Steven Luscher. All rights reserved.
//

#import "ObjectiveFaye+Publisher.h"

@implementation ObjectiveFaye (Publisher)

- (int)countListeners:(NSString *)eventType
{
    if (!self.subscribers || ![self.subscribers objectForKey:eventType]) return 0;
    return [[self.subscribers objectForKey:eventType] count];
}

- (void)bind:(NSString *)eventType withListener:(void(^)(id args, id context))listener inContext:(id)context
{
    if (!self.subscribers) self.subscribers = [[NSMutableDictionary alloc] init];

    NSMutableArray *list = [self.subscribers objectForKey:eventType];
    if (!list) list = [[NSMutableArray alloc] init];
    
    [list addObject:@[listener, context]];
}


- (void)unbind:(NSString *)eventType withListener:(void(^)(id args, id context))listener inContext:(id)context
{
    if (!self.subscribers || !self.subscribers[eventType]) return;
    
    if (!listener) {
        [self.subscribers removeObjectForKey:eventType];
        return;
    }
    NSMutableArray *list = self.subscribers[eventType];
    int i = [list count];
    
    while (i--) {
        if (listener != (void(^)(id args, id context))list[i][0]) continue;
        if (context && list[i][1] != context) continue;
        [list removeObjectAtIndex:i+1];
    }
}

- (void)trigger:(NSString *)eventType withArgs:(id)args
{
    if (!self.subscribers || !self.subscribers[eventType]) return;
    
    for (NSArray *listener in self.subscribers[eventType]) {
        ((id (^)(id, id))listener[0])(args, listener[1]);
    }
}

# pragma mark – Faked instance variables

ASSOCIATED_STORAGE_PROPERTY_IMP(NSMutableDictionary *, setSubscribers, subscribers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

@end
