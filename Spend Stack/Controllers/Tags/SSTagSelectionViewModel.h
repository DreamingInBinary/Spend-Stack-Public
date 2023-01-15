//
//  SSTagSelectionViewModel.h
//  Spend Stack
//
//  Created by Jordan Morgan on 2/27/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SSTagType) {
    SSTagTypeUnset,
    SSTagTypeMasterTag,
    SSTagTypeListTag
};

// Represents either an SSTag or SSListTag for selection
@interface SSTagSelectionViewModel : SSObject <IGListDiffable>

@property (nonatomic, readonly) SSTagType type;
@property (strong, nonatomic, nonnull, readonly) NSString *color;
@property (strong, nonatomic, nonnull, readonly) NSString *name;
@property (strong, nonatomic, nonnull, readonly) NSNumber *orderingIndex;
@property (strong, nonatomic, nullable, readonly) SSTag *underlyingTag;
@property (strong, nonatomic, nullable, readonly) SSListTag *underlyingListTag;

+ (instancetype _Nonnull)new NS_UNAVAILABLE;
- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithMasterTag:(SSTag * _Nonnull)tag;
- (instancetype _Nonnull)initWithListTag:(SSListTag * _Nonnull)listTag;

+ (NSArray <SSTagSelectionViewModel *> * _Nonnull)tagViewModelArrayFromTags:(NSArray *_Nonnull)tags;
+ (SSTagSelectionViewModel * _Nullable)tagViewModelForMasterTag:(SSTag * _Nonnull)tag viewModels:(NSArray <SSTagSelectionViewModel *> *_Nonnull)viewModels;

@end
