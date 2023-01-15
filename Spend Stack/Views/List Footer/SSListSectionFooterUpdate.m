//
//  SSListSectionFooterUpdate.m
//  Spend Stack
//
//  Created by Jordan Morgan on 9/20/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "SSListSectionFooterUpdate.h"

@implementation SSListSectionFooterUpdate

- (void)postNotificationWithTagID:(NSString *)tagdbID
{
    [[NSNotificationCenter defaultCenter] postNotificationName:RELOAD_TAG_FOOTER object:self];
}

@end
