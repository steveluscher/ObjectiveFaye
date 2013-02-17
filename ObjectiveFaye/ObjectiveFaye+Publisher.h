//
//  ObjectiveFaye+Publisher.h
//  ObjectiveFaye
//
//  Created by Steven Luscher on 2013-02-16.
//  Copyright (c) 2013 Steven Luscher. All rights reserved.
//

#import "ObjectiveFaye.h"

@interface ObjectiveFaye (Publisher)

- (int)countListeners:(NSString *)eventType;
- (void)bind:(NSString *)eventType withListener:(void(^)(id args, id context))listener inContext:(id)context;
- (void)unbind:(NSString *)eventType withListener:(void(^)(id args, id context))listener inContext:(id)context;
- (void)trigger:(NSString *)eventType withArgs:(id)args;

@end
