//
//  ObjectiveFaye+Deferrable.h
//  ObjectiveFaye
//
//  Created by Steven Luscher on 2013-02-15.
//  Copyright (c) 2013 Steven Luscher. All rights reserved.
//

#import "ObjectiveFaye.h"

@interface ObjectiveFaye (Deferrable)

@property NSString *deferredStatus;
@property NSArray *deferredArgs;
@property NSMutableArray *callbacks;

- (void)callback:(void(^)(id args, id context))callback withContext:(id)context;
- (void)timeout:(float)seconds withMessage:(id)message;
- (void)errback:(void(^)(id args, id context))callback inContext:context;
- (void)setDeferredStatus:(NSString *)status withArgs:(id)args;

@end
