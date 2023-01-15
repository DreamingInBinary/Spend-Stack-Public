//
//  SSWeakObjectContainer.m
//  Spend Stack
//
//  Created by Jordan Morgan on 10/28/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "SSWeakObjectContainer.h"

@interface SSWeakObjectContainer()

@property (nonatomic, readonly, nullable, weak) id object;

@end

@implementation SSWeakObjectContainer

- (instancetype) initWithObject:(id)object
{
    if (!(self = [super init]))
        return nil;

    _object = object;

    return self;
}

@end
