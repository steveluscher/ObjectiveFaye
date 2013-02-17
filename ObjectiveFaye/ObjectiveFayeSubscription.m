//
//  ObjectiveFayeSubscription.m
//  ObjectiveFaye
//
//  Created by Steven Luscher on 2013-02-15.
//  Copyright (c) 2013 Steven Luscher. All rights reserved.
//

#import "ObjectiveFayeSubscription.h"
#import "ObjectiveFayeClient.h"

@interface ObjectiveFayeSubscription()

@property (nonatomic) ObjectiveFayeClient *_client;
@property (nonatomic) NSArray *_channels;
@property (nonatomic) id _callback;
@property (nonatomic) id _context;
@property (nonatomic) BOOL _cancelled;

@end

@implementation ObjectiveFayeSubscription

- (id)initWithClient:(ObjectiveFayeClient *)client forChannels:(NSArray *)channels withCallback:(id)callback inContext:(id)context
{
    if (self = [self init]) {
        self._client = client;
        self._channels = channels;
        self._callback = callback;
        self._context = context;
        self._cancelled = NO;
    }
    return self;
}

- (void)cancel
{
    if (self._cancelled == YES) return;
    [self._client unsubscribeFromChannel:self._channels withCallback:self._callback inContext:self._context];
    self._cancelled = YES;
}

- (void)unsubscribe
{
    [self cancel];
}

@end
