//
//  SSTagCollectionViewCell.h
//  Spend Stack
//
//  Created by Jordan Morgan on 2/25/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SSTagSelectionViewModel.h"

static NSString * _Nonnull const SS_TAG_CELL_ID = @"SSTagCell";

@interface SSTagCollectionViewCell : UICollectionViewCell

- (void)setData:(SSTagSelectionViewModel * _Nonnull)tag;

@end
