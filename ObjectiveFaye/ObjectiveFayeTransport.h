//
//  ObjectiveFayeTransport.h
//  ObjectiveFaye
//
//  Created by Steven Luscher on 2013-02-15.
//  Copyright (c) 2013 Steven Luscher. All rights reserved.
//

#import "ObjectiveFaye.h"
#import "ObjectiveFayeClient.h"

extern int const kObjectiveFayeMaxUrlLength;

@interface ObjectiveFayeTransport : ObjectiveFaye

@property (nonatomic) NSString *endpoint;
@property (nonatomic, readonly) NSString *connectionType;

+ (void)getForClient:(ObjectiveFayeClient *)client fromTransportTypes:(NSArray *)transportTypes withCallback:(void(^)(ObjectiveFayeTransport *callback, id context))callback inContext:(id)context;

- (void)receive:(NSArray *)responses;
- (void)close;

@end
