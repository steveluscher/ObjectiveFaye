//
//  ObjectiveFaye+Timeouts.m
//  ObjectiveFaye
//
//  Created by Steven Luscher on 2013-02-16.
//  Copyright (c) 2013 Steven Luscher. All rights reserved.
//

#import "ObjectiveFaye+Timeouts.h"

typedef void(^delay_handle_t)(void);

@implementation ObjectiveFaye (Timeouts)

- (void)addTimeout:(NSString *)name withDelay:(float)delay andCallback:(void(^)(void))callback inContext:(id)context
{
    /* TODO:
     if (!self.timeouts) self.timeouts = [[NSMutableDictionary alloc] init];
     
     if (self.timeouts[name]) return;
     
     self.timeouts[name] = Faye.ENV.setTimeout(function() {
     delete self._timeouts[name];
     callback.call(context);
     }, 1000 * delay);
     */
}


- (void)removeTimeout:(NSString *)name
{
    /* TODO:
     self._timeouts = self._timeouts || {};
     var timeout = self._timeouts[name];
     if (!timeout) return;
     clearTimeout(timeout);
     delete self._timeouts[name];
     */
}

# pragma mark – Faked instance variables

ASSOCIATED_STORAGE_PROPERTY_IMP(NSMutableDictionary *, setTimeouts, timeouts, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

@end
