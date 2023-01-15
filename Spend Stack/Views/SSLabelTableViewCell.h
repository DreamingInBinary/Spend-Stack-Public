//
//  SSLabelTableViewCell.h
//  Spend Stack
//
//  Created by Jordan Morgan on 4/26/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString * const _Nonnull LABEL_CELL_ID = @"LabelCellID";

@interface SSLabelTableViewCell : UITableViewCell

@property (strong, nonatomic, nonnull, readonly) SSLabel *topLabel;
@property (strong, nonatomic, nonnull, readonly) SSLabel *bottomLabel;
@property (nonatomic, getter=shouldShowDivider) BOOL showDivider;
@property (nonatomic, getter=shouldShowDisclosureIndicator) BOOL showDisclosureIndicator; // Using the iOS disclosure indicator clips subviews beneath it, this avoids it
@property (nonatomic, getter=shouldHideBottomLabel) BOOL hideBottomLabel;

@end

