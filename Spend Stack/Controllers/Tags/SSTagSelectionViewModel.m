//
//  SSTagSelectionViewModel.m
//  Spend Stack
//
//  Created by Jordan Morgan on 2/27/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "SSTagSelectionViewModel.h"

@interface SSTagSelectionViewModel()

@property (nonatomic, readwrite) SSTagType type;
@property (strong, nonatomic, nonnull, readwrite) NSString *color;
@property (strong, nonatomic, nonnull, readwrite) NSString *name;
@property (strong, nonatomic, nonnull, readwrite) NSNumber *orderingIndex;
@property (strong, nonatomic, nullable, readwrite) SSTag *underlyingTag;
@property (strong, nonatomic, nullable, readwrite) SSListTag *underlyingListTag;

@end

@implementation SSTagSelectionViewModel

#pragma mark - Initializer

- (instancetype)initWithMasterTag:(SSTag *)tag
{
    self = [super init];
    
    if (self)
    {
        self.type = SSTagTypeMasterTag;
        self.color = tag.color;
        self.name = tag.name;
        self.orderingIndex = tag.orderingIndex;
        self.underlyingTag = tag;
        [self setObjectForNoPersistencyOrSync];
    }
    
    return self;
}

- (instancetype)initWithListTag:(SSListTag *)listTag
{
    self = [super init];
    
    if (self)
    {
        self.type = SSTagTypeListTag;
        self.color = listTag.color;
        self.name = listTag.name;
        self.orderingIndex = listTag.orderingIndex;
        self.underlyingListTag = listTag;
        [self setObjectForNoPersistencyOrSync];
    }
    
    return self;
}

#pragma mark - Diffing

- (id<NSObject>)diffIdentifier
{
    return self.type == SSTagTypeMasterTag ? self.underlyingTag.dbID : self.underlyingListTag.dbID;
}

- (BOOL)isEqualToDiffableObject:(id<IGListDiffable>)object
{
    return [self isEqual:object];
}

- (NSUInteger)hash
{
    return self.type == SSTagTypeMasterTag ? [self.underlyingTag hash] : [self.underlyingListTag hash];
}

- (BOOL)isEqual:(SSTagSelectionViewModel *)otherTag
{
    if (self == otherTag)
    {
        return YES;
    }
    
    if (otherTag == nil || ![otherTag isKindOfClass:[SSTagSelectionViewModel class]])
    {
        return NO;
    }
    
    if (self.type == SSTagTypeMasterTag)
    {
        return [self.underlyingTag isEqual:otherTag.underlyingTag];
    }
    else
    {
        return [self.underlyingListTag isEqual:otherTag.underlyingListTag];
    }
}

#pragma mark - Class Methods

+ (NSArray <SSTagSelectionViewModel *> *)tagViewModelArrayFromTags:(NSArray *)tags
{
    NSMutableArray <SSTagSelectionViewModel *> *tagVMs = [NSMutableArray new];
    
    for (id tagType in tags)
    {
        SSTagSelectionViewModel *vm;
        
        if ([tagType isKindOfClass:[SSTag class]])
        {
            vm = [[SSTagSelectionViewModel alloc] initWithMasterTag:tagType];
        }
        else if ([tagType isKindOfClass:[SSListTag class]])
        {
            vm = [[SSTagSelectionViewModel alloc] initWithListTag:tagType];
        }
        else
        {
            NSAssert(NO, @"Spend Stack - Supplied a tag model to transform into a view model that wasn't an SSTag or SSListTag.");
        }
        
        [tagVMs addObject:vm];
    }
    
    return [tagVMs copy];
}

+ (SSTagSelectionViewModel *)tagViewModelForMasterTag:(SSTag *)tag viewModels:(NSArray<SSTagSelectionViewModel *> *)viewModels
{
    NSPredicate *masterTagPred = [NSPredicate predicateWithFormat:@"SELF.type == 1"];
    for (SSTagSelectionViewModel *vm in [viewModels filteredArrayUsingPredicate:masterTagPred])
    {
        if ([vm.underlyingTag.dbID isEqualToString:tag.dbID])
        {
            return vm;
        }
    }
    
    return nil;
}

@end
