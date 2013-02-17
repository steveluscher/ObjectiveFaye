//
//  ObjectiveFaye+Timeouts.h
//  ObjectiveFaye
//
//  Created by Steven Luscher on 2013-02-16.
//  Copyright (c) 2013 Steven Luscher. All rights reserved.
//

#import "ObjectiveFaye.h"

@interface ObjectiveFaye (Timeouts)

- (void)addTimeout:(NSString *)name withDelay:(float)delay andCallback:(void(^)(void))callback inContext:(id)context;
- (void)removeTimeout:(NSString *)name;

@end
