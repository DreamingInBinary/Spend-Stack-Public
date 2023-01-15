//
//  UICollectionView+Utils.m
//  Spend Stack
//
//  Created by Jordan Morgan on 3/14/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "UICollectionView+Utils.h"

@implementation UICollectionView (Utils)

- (NSArray <NSIndexPath *> *)indexPathsForElementsInRect:(CGRect)rect
{
    NSArray <UICollectionViewLayoutAttributes *> *allLayoutAttributes = [self.collectionViewLayout layoutAttributesForElementsInRect:rect];
    
    NSMutableArray <NSIndexPath *> *idps = [NSMutableArray new];
    for (UICollectionViewLayoutAttributes *attr in allLayoutAttributes)
    {
        [idps addObject:attr.indexPath];
    }
    
    return [idps copy];
}

@end
