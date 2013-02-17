//
//  ObjectiveFaye.m
//  ObjectiveFaye
//
//  Created by Steven Luscher on 2013-02-14.
//  Copyright (c) 2013 Steven Luscher. All rights reserved.
//

#import "ObjectiveFaye.h"

NSString * const kObjectiveFayeBayeuxVersion = @"1.0";
NSArray * kObjectiveFayeMandatoryConnectionTypes;

@implementation ObjectiveFaye

+ (void)initialize
{
    kObjectiveFayeMandatoryConnectionTypes = @[@"long-polling", @"callback-polling", @"in-process"];
}

@end
