//
//  ObjectiveFaye+Deferrable.m
//  ObjectiveFaye
//
//  Created by Steven Luscher on 2013-02-15.
//  Copyright (c) 2013 Steven Luscher. All rights reserved.
//

#import "ObjectiveFaye+Deferrable.h"

typedef void(^delay_handle_t)(void);

@implementation ObjectiveFaye (Deferrable)

- (void)callback:(void(^)(id args, id context))callback withContext:(id)context
{
    if (!callback) return;
    
    if ([self.deferredStatus isEqualToString:@"succeeded"]) {
        callback(self.deferredArgs, context);
        return;
    }

    if (!self.callbacks) {
        self.callbacks = [[NSMutableArray alloc] init];
    }
    [self.callbacks addObject:@[callback, context]];
}


- (void)timeout:(float)seconds withMessage:(id)message
{
    delay_handle_t delayHandle = ^{
        [self setDeferredStatus:@"failed" withArgs:message];
    };
    [self.timers addObject:delayHandle];
    int timerIndex = [self.timers count] - 1;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, seconds * 1000 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{ if(self.timers[timerIndex]) ((delay_handle_t)self.timers[timerIndex])(); });
}

- (void)errback:(void(^)(id args, id context))callback inContext:context
{
    if (!callback) return;
    
    if ([self.deferredStatus isEqualToString:@"failed"]) {
        callback(self.deferredArgs, context);
        return;
    }
    
    if (!self.errbacks) {
        self.errbacks = [[NSMutableArray alloc] init];
    }
    [self.errbacks addObject:@[callback, context]];
}

- (void)setDeferredStatus:(NSString *)status withArgs:(id)args
{
    if([self.timers count] > 0)
        [self.timers replaceObjectAtIndex:[self.timers count]-1 withObject:nil]; // Cancel the timer
    
    self.deferredStatus = status;
    self.deferredArgs = args;
    
    NSArray *callbacks = nil;
    
    if ([status isEqualToString:@"succeeded"])
        callbacks = self.callbacks;
    else if ([status isEqualToString:@"failed"])
        callbacks = self.errbacks;
    
    if (!callbacks) return;
    
    while ([callbacks count] > 0) {
        NSArray *callbackDescriptor = [callbacks objectAtIndex:0];
        id(^callback)(id args, id context) = callbackDescriptor[0];
        id context = callbackDescriptor[1];
        
        callback(self.deferredArgs, context);
        
        callbacks = [callbacks subarrayWithRange:NSMakeRange(1, [callbacks count] - 1)];
    }
}

# pragma mark – Faked instance variables

ASSOCIATED_STORAGE_PROPERTY_IMP(NSString *, setDeferredStatus, deferredStatus, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
ASSOCIATED_STORAGE_PROPERTY_IMP(id, setDeferredArgs, deferredArgs, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
ASSOCIATED_STORAGE_PROPERTY_IMP(NSMutableArray *, setCallbacks, callbacks, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
ASSOCIATED_STORAGE_PROPERTY_IMP(NSMutableArray *, setErrbacks, errbacks, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
ASSOCIATED_STORAGE_PROPERTY_IMP(NSMutableArray *, setTimers, timers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

@end
