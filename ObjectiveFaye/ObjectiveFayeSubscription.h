//
//  ObjectiveFayeSubscription.h
//  ObjectiveFaye
//
//  Created by Steven Luscher on 2013-02-15.
//  Copyright (c) 2013 Steven Luscher. All rights reserved.
//

#import "ObjectiveFaye.h"
#import "ObjectiveFayeClient.h"

@class ObjectiveFayeClient;

@interface ObjectiveFayeSubscription : ObjectiveFaye

- (id)initWithClient:(ObjectiveFayeClient *)client forChannels:(NSArray *)channels withCallback:(id)callback inContext:(id)context;

@end
