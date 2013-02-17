//
//  ObjectiveFayeChannelSet.h
//  ObjectiveFaye
//
//  Created by Steven Luscher on 2013-02-15.
//  Copyright (c) 2013 Steven Luscher. All rights reserved.
//

#import "ObjectiveFaye.h"

@interface ObjectiveFayeChannelSet : ObjectiveFaye

- (NSArray *)getKeys;
- (void)remove:(NSString *)name;
- (BOOL)hasSubscription:(NSString *)name;
- (void)subscribe:(NSArray *)names withCallback:(id)callback inContext:(id)context;
- (BOOL)unsubscribe:(NSString *)name withCallback:(id)callback inContext:(id)context;

@end
