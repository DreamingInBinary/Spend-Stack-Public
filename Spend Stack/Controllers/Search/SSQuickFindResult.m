//
//  SSQuickFindResult.m
//  Spend Stack
//
//  Created by Jordan Morgan on 2/3/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "SSQuickFindResult.h"

@implementation SSQuickFindResult

#pragma mark - Search Parse

+ (NSArray <SSQuickFindResult *> *)resultsFromQuery:(FMResultSet *)res
{
    NSMutableArray <SSQuickFindResult *> *results = [NSMutableArray new];
    
    while ([res next])
    {
        SSQuickFindResult *result = [SSQuickFindResult new];
        result.objectID = [res stringForColumn:@"id"];
        result.matchedTerm = [res stringForColumn:@"searchTerm"];
        result.parentObjectID = [res stringForColumn:@"parentID"];
        result.type = [SSQuickFindResult typeFromStringColumn:[res stringForColumn:@"type"]];
        
        [results addObject:result];
    }
    
    return [results copy];
}

#pragma mark - Private

+ (SSQuickFindResultType)typeFromStringColumn:(NSString *)string
{
    NSString *str = string.lowercaseString;
    
    if ([str isEqualToString:@"list"])
    {
        return SSQuickFindResultList;
    }
    else if ([str isEqualToString:@"listitem"])
    {
        return SSQuickFindResultListItem;
    }
    else if ([str isEqualToString:@"note"])
    {
        return SSQuickFindResultNote;
    }
    else if ([str isEqualToString:@"tag"])
    {
        return SSQuickFindResultTag;
    }
    
    
    return SSQuickFindResultUnknown;
}

#pragma mark - Diffing

- (id<NSObject>)diffIdentifier
{
    return self.objectID;
}

- (BOOL)isEqualToDiffableObject:(id<IGListDiffable>)object
{
    return [self isEqual:object];
}

- (NSUInteger)hash
{
    return [self.objectID hash] ^ [self.matchedTerm hash] ^ [@(self.type) hash] ^ [self.parentObjectID hash];
}

- (BOOL)isEqual:(SSQuickFindResult *)otherResult
{
    if (self == otherResult)
    {
        return YES;
    }
    
    if (otherResult == nil || ![otherResult isKindOfClass:[SSQuickFindResult class]])
    {
        return NO;
    }
    
    return self.type == otherResult.type &&
    (self.objectID == otherResult.objectID || [self.objectID isEqualToString:otherResult.objectID]) &&
    (self.parentObjectID == otherResult.parentObjectID || [self.parentObjectID isEqualToString:otherResult.parentObjectID]) &&
    (self.matchedTerm == otherResult.matchedTerm || [self.matchedTerm isEqualToString:otherResult.matchedTerm]);
}

@end
