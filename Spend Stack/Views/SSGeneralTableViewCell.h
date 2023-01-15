//
//  SSGeneralTableViewCell.h
//  Spend Stack
//
//  Created by Jordan Morgan on 11/20/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString * const _Nonnull GENERAL_CELL_ID = @"GeneralCellID";

@interface SSGeneralTableViewCell : UITableViewCell

@property (strong, nonatomic, nonnull, readonly) SSLabel *topLabel;
@property (strong, nonatomic, nonnull, readonly) SSLabel *bottomLabel;
@property (strong, nonatomic, nonnull, readonly) UIImageView *leftImageView;
@property (strong, nonatomic, nullable, readonly) UISwitch *rightSwitch;
@property (nonatomic, getter=shouldShowSwitch) BOOL showSwitch;
@property (nonatomic, getter=shouldShowDivider) BOOL showDivider;
@property (nonatomic, getter=shouldStyleBottomLabelAsButton) BOOL styleBottomLabelAsButton;
@property (nonatomic, getter=shouldShowDisclosureIndicator) BOOL showDisclosureIndicator; // Using the iOS disclosure indicator clips subviews beneath it, this avoids it
@property (nonatomic, getter=shouldHideAllAccessoryViews) BOOL hideAllAccessoryViews;
@property (nonatomic, getter=shouldHideBottomLabel) BOOL hideBottomLabel;
@property (copy) void (^ _Nullable onSwitchChanged)(BOOL isOn);
@property (copy) void (^ _Nullable onBottomLabelTapped)(void);
@property (strong, nonatomic, nullable) UIMenu *menu API_AVAILABLE(ios(14.0));
@property (strong, nonatomic, nullable, readonly) UIButton *menuButton;

// Helper function for settings like icons
- (void)setLeadingIconImage:(UIImage * _Nonnull)image backgroundColor:(UIColor * _Nonnull)backgroundColor;
- (void)setLeadingIconWithSystemImage:(UIImage * _Nonnull)image backgroundColor:(UIColor * _Nonnull)backgroundColor;
- (void)setPointerInteractionEnabled:(BOOL)enabled;

@end
