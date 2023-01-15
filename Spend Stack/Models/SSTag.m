//
//  SSTag.m
//  Spend Stack
//
//  Created by Jordan Morgan on 5/29/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "SSTag.h"
#import "FMResultSet.h"

@interface SSTag()

@end

@implementation SSTag

#pragma mark - Initializers

- (instancetype)initWithColor:(NSString *)color name:(NSString *)name order:(NSNumber *)order
{
    self = [super init];
    
    if (self)
    {
        self.color = color;
        self.name = name;
        self.orderingIndex = order;
        NSAssert([self suppliedNameIsAppleColor], @"Sent in a color that's not supported. Supplying a default color.");
        if ([self suppliedNameIsAppleColor] == NO) self.color = AppleRed;
    }
    
    return self;
}

- (instancetype)initWithResultSet:(FMResultSet *)result
{
    self = [super initWithResultSet:result];
    
    if (self)
    {
        self.color = [result stringForColumn:@"color"];
        self.name = [result stringForColumn:@"name"];
        self.orderingIndex = @([result intForColumn:@"tagOrderingIndex"]);        
        NSAssert(self.objCKRecord != nil, @"Spend Stack - Query resulted in no record ID for a tag.");
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
    {
        self.color = [aDecoder decodeObjectForKey:@"color"];
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.orderingIndex = [aDecoder decodeObjectForKey:@"tagOrderingIndex"];
        if ([self suppliedNameIsAppleColor] == NO) self.color = AppleRed;
    }
    
    return self;
}

#pragma mark - NSCoding

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.color forKey:@"color"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.orderingIndex forKey:@"tagOrderingIndex"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    SSTag *newTag = [super copyWithZone:zone];
    
    if (newTag)
    {
        newTag.color = [_color copyWithZone:zone];
        newTag.name = [_name copyWithZone:zone];
        newTag.orderingIndex = [_orderingIndex copyWithZone:zone];
    }
    
    return newTag;
}

#pragma mark - Private Methods

- (BOOL)suppliedNameIsAppleColor
{
    return ([self.color isEqualToString:AppleRed] ||
            [self.color isEqualToString:AppleOrange] ||
            [self.color isEqualToString:AppleYellow] ||
            [self.color isEqualToString:AppleGreen] ||
            [self.color isEqualToString:AppleTealBlue] ||
            [self.color isEqualToString:AppleBlue] ||
            [self.color isEqualToString:ApplePurple] ||
            [self.color isEqualToString:ApplePink] ||
            [self.color isEqualToString:AppleNavy] ||
            [self.color isEqualToString:AppleDarkOrange] ||
            [self.color isEqualToString:AppleDarkGreen] ||
            [self.color isEqualToString:AppleDarkPurple] ||
            [self.color isEqualToString:AppleClear]);
}

#pragma mark - Overrides

- (NSDictionary *)dictionaryRepresentation
{
    NSDictionary *guranteedData = @{@"color":self.color,
                                    @"name":self.name,
                                    @"tagOrderingIndex":self.orderingIndex};
    NSMutableDictionary *data = [[super dictionaryRepresentation] mutableCopy];
    [data addEntriesFromDictionary:guranteedData];
    
    return guranteedData;
}

#pragma mark - Public Methods

// These two class methods, tagColors and tagColorStrings, must return the colors in the same order or it could break some tag initializers.
+ (NSArray <UIColor *> *)tagColors
{
    return @[[UIColor appleRed],
             [UIColor appleOrange],
             [UIColor appleYellow],
             [UIColor appleGreen],
             [UIColor appleTealBlue],
             [UIColor appleBlue],
             [UIColor applePurple],
             [UIColor applePink],
             [UIColor appleNavy],
             [UIColor appleDarkOrange],
             [UIColor appleDarkGreen],
             [UIColor appleDarkPurple]];
}

+ (NSArray <NSString *> *)tagColorStrings
{
    return @[AppleRed,
             AppleOrange,
             AppleYellow,
             AppleGreen,
             AppleTealBlue,
             AppleBlue,
             ApplePurple,
             ApplePink,
             AppleNavy,
             AppleDarkOrange,
             AppleDarkGreen,
             AppleDarkPurple];
}

+ (UIColor *)miscTagDisplayColor
{
    return [UIColor lightGrayColor];
}

#pragma mark - Diffing

- (id<NSObject>)diffIdentifier
{
    return self.dbID;
}

- (BOOL)isEqualToDiffableObject:(id<IGListDiffable>)object
{
    return [self isEqual:object];
}

- (NSUInteger)hash
{
    return [self.dbID hash];
}

- (BOOL)isEqual:(SSTag *)otherTag
{
    if (self == otherTag)
    {
        return YES;
    }
    
    if (otherTag == nil || ![otherTag isKindOfClass:[SSTag class]])
    {
        return NO;
    }
    
    return self.orderingIndex.integerValue == otherTag.orderingIndex.integerValue &&
           (self.dbID == otherTag.dbID || [self.dbID isEqualToString:otherTag.dbID]) &&
           (self.name == otherTag.name || [self.name isEqualToString:otherTag.name]) &&
           (self.color == otherTag.color || [self.color isEqualToString:otherTag.color]);
}

@end
