//
//  ObjectiveFayeChannel.h
//  ObjectiveFaye
//
//  Created by Steven Luscher on 2013-02-15.
//  Copyright (c) 2013 Steven Luscher. All rights reserved.
//

#import "ObjectiveFaye.h"

extern NSString * const kObjectiveFayeChannelHandshake;
extern NSString * const kObjectiveFayeChannelConnect;
extern NSString * const kObjectiveFayeChannelSubscribe;
extern NSString * const kObjectiveFayeChannelUnsubscribe;
extern NSString * const kObjectiveFayeChannelDisconnect;

@interface ObjectiveFayeChannel : ObjectiveFaye

- (ObjectiveFayeChannel *)initWithName:(NSString *)name;
- (BOOL)isUnused;

@end
