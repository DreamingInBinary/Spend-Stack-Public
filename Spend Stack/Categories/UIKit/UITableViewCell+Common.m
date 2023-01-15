//
//  UITableViewCell+Common.m
//  Spend Stack
//
//  Created by Jordan Morgan on 1/1/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "UITableViewCell+Common.h"

@implementation UITableViewCell (Common)

- (UIView *)ssSelectionView
{
    UIView *selectionView = [UIView new];
    selectionView.backgroundColor = [UIColor ssSelectedBackgroundColor];
    
    return selectionView;
}

- (UIImageView *)ssDisclosureImageView
{
    UIImageView *disclosureImage = [UIImageView new];
    disclosureImage.tintColor = [UIColor ssMutedColor];
    disclosureImage.clipsToBounds = YES;
    disclosureImage.contentMode = UIViewContentModeCenter;
    UIImage *disclosureIcon = [[UIImage systemImageNamed:@"chevron.right"]  imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    disclosureImage.image = disclosureIcon;
    
    return disclosureImage;
}

+ (CGFloat)preferredDividerHeight
{
    return [SSCitizenship accessibilityFontsEnabled] || [SSCitizenship prefersBoldText] ? 2.0 : (1.0/[UIScreen mainScreen].scale);
}

- (void (^ _Nonnull)(MASConstraintMaker *))constraintsForDividerView:(UIView * _Nonnull)dividerView
{
    CGFloat dividerHeight = [UITableViewCell preferredDividerHeight];
    return ^(MASConstraintMaker *make) {
        make.height.equalTo(@(dividerHeight));
        // Recreate the indented look
        make.left.equalTo(self.contentView.mas_leftMargin);
        make.right.equalTo(self.contentView.mas_safeAreaLayoutGuideRight);
        make.bottom.equalTo(self.contentView.mas_bottom);
    };
}

- (void (^ _Nonnull)(MASConstraintMaker *))constraintsForFullWidthDividerView:(UIView *)dividerView
{
    CGFloat dividerHeight = [UITableViewCell preferredDividerHeight];
    return ^(MASConstraintMaker *make) {
        make.height.equalTo(@(dividerHeight));
        make.left.equalTo(self.contentView.mas_safeAreaLayoutGuideLeft);
        make.right.equalTo(self.contentView.mas_safeAreaLayoutGuideRight);
        make.bottom.equalTo(self.contentView.mas_bottom);
    };
}

- (void (^ _Nonnull)(MASConstraintMaker *))constraintsForReadableWidthDividerView:(UIView *)dividerView
{
    CGFloat dividerHeight = [UITableViewCell preferredDividerHeight];
    return ^(MASConstraintMaker *make) {
        make.height.equalTo(@(dividerHeight));
        make.left.equalTo(self.contentView.mas_readableContentGuideLeft);
        make.right.equalTo(self.contentView.mas_readableContentGuideRight);
        make.bottom.equalTo(self.contentView.mas_bottom);
    };
}

- (void)animateHighlightCallout
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self setHighlighted:YES animated:YES];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self setHighlighted:NO animated:YES];
        });
    });
}

@end

@implementation UITableViewCell (UIPointerUtil)

- (void)addShadowInteraction API_AVAILABLE(ios(13.4))
{
    if ([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad) return;
    UIPointerInteraction *hoverInteraction = [[UIPointerInteraction alloc] initWithDelegate:self];
    [self.contentView addInteraction:hoverInteraction];
}

#pragma mark - Pointer Interaction Delegate

- (nullable UIPointerStyle *)pointerInteraction:(UIPointerInteraction *)interaction styleForRegion:(UIPointerRegion *)region API_AVAILABLE(ios(13.4))
{
    if (interaction.view == nil) return nil;
    UITargetedPreview *targetedPreview = [[UITargetedPreview alloc] initWithView:self.contentView];
    UIPointerHoverEffect *hover = [UIPointerHoverEffect effectWithPreview:targetedPreview];
    hover.prefersScaledContent = NO;
    UIPointerStyle *pointerStyle = [UIPointerStyle styleWithEffect:hover
                                                             shape:nil];
    return pointerStyle;
}

@end
