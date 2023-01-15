//
//  SSMediaCollectionViewCell.h
//  Spend Stack
//
//  Created by Jordan Morgan on 3/14/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString * _Nonnull const SS_MEDIA_CELL_ID = @"SSMediaCollectionViewCell";

@interface SSMediaCollectionViewCell : UICollectionViewCell

@property (strong, nonatomic, nullable) UIImage *image;
@property (strong, nonatomic, nullable) NSString *assetID;

@end
