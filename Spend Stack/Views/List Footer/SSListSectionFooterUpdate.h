//
//  SSListSectionFooterUpdate.h
//  Spend Stack
//
//  Created by Jordan Morgan on 9/20/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

static NSString * const RELOAD_TAG_FOOTER = @"reloadTagFooter";

@interface SSListSectionFooterUpdate : NSObject

@property (strong, nonatomic) NSString * tagdbID;
@property (strong, nonatomic) NSString * updatedTotal;
- (void)postNotificationWithTagID:(NSString * _Nullable)tagdbID;

@end

NS_ASSUME_NONNULL_END
