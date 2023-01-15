//
//  SSLabelTableViewCell.m
//  Spend Stack
//
//  Created by Jordan Morgan on 4/26/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "SSLabelTableViewCell.h"
#import "UITableViewCell+Common.h"

@interface SSLabelTableViewCell()

@property (strong, nonatomic, nonnull, readwrite) SSLabel *topLabel;
@property (strong, nonatomic, nonnull, readwrite) SSLabel *bottomLabel;
@property (strong, nonatomic, nonnull) UIImageView *disclosureImage;
@property (strong, nonatomic, nonnull) UIView *dividerView;

@end

@implementation SSLabelTableViewCell


#pragma mark - Custom Setters

- (void)setShowDivider:(BOOL)showDivider
{
    _showDivider = showDivider;
    _dividerView.alpha = showDivider ? 1.0f : 0.0f;
}

- (void)setShowDisclosureIndicator:(BOOL)showDisclosureIndicator
{
    _showDisclosureIndicator = showDisclosureIndicator;
    _disclosureImage.hidden = !showDisclosureIndicator;
}

- (void)setHideBottomLabel:(BOOL)hideBottomLabel
{
    _hideBottomLabel = hideBottomLabel;
    self.bottomLabel.hidden = _hideBottomLabel;
    
    if (_hideBottomLabel)
    {
        // Basic early out. Can make this a bit smarter later.
        // If we've already moved over the bottom label, we've done the update of the constraints already.
        // So, skip doing it again since this is likely set in cellForRowAtIndexPath:.
        if (self.bottomLabel.ss_x != 0 || [SSCitizenship accessibilityFontsEnabled]) return;

        [self.topLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView.mas_topMargin);
            make.left.equalTo(self.contentView.mas_leftMargin);
            make.right.equalTo(self.disclosureImage.mas_left).with.offset(SSRightElementMargin);
            make.bottom.equalTo(self.dividerView.mas_top).with.offset(SSBottomBigElementMargin);
        }];
        
        [self.bottomLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.topLabel);
        }];
    }
    else
    {
        [self setConstraints];
    }
}

#pragma mark - Initializers

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self)
    {
        self.showDisclosureIndicator = YES;
        self.backgroundColor = [UIColor systemBackgroundColor];
        self.contentView.clipsToBounds = NO;
        self.clipsToBounds = NO;
        
        self.topLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleBody];
        [self.topLabel configureFontWeight:UIFontWeightMedium];
        [self.topLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        
        [self.bottomLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        self.bottomLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleSubheadline];
        self.bottomLabel.textColor = [UIColor ssTextPlaceholderColor];
        
        self.disclosureImage = [self ssDisclosureImageView];
        self.disclosureImage.isAccessibilityElement = NO;
        
        self.dividerView = [UIView new];
        self.dividerView.backgroundColor = [UIColor ssMutedColor];
        
        [self.contentView addSubviews:@[self.topLabel,
                                        self.bottomLabel,
                                        self.disclosureImage,
                                        self.dividerView]];
        
        self.dividerView.alpha = 0.0f;
        self.selectedBackgroundView = [self ssSelectionView];
        
        [self setConstraints];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.selectedBackgroundView.layer.cornerRadius = SSSpacingMargin;
    self.selectedBackgroundView.frame = CGRectInset(self.contentView.frame, 6, 6);
}

#pragma mark - Constraint Handling

- (void)didChangePreferredContentSize:(NSNotification *)note
{
    [self setConstraints];
}

- (void)setConstraints
{
    [self.topLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView.mas_top).with.offset(SSTopElementMargin);
        make.left.equalTo(self.contentView.mas_leftMargin);
        make.right.equalTo(self.disclosureImage.mas_left).with.offset(SSRightElementMargin);
        make.bottom.equalTo(self.bottomLabel.mas_top).with.offset(-4);
    }];
    
    [self.bottomLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView.mas_leftMargin);
        make.bottom.equalTo(self.dividerView.mas_top).with.offset(SSBottomElementMargin);
        make.right.equalTo(self.disclosureImage.mas_left).with.offset(SSRightElementMargin);
    }];
    
    [self.disclosureImage mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView.mas_centerY);
        make.right.equalTo(self.contentView.mas_rightMargin).with.offset(SSSpacingMargin); // Because the image itself has padding
        make.height.and.width.equalTo(self.showDisclosureIndicator ? @28 : @0);
    }];
    
    [self.dividerView mas_remakeConstraints:[self constraintsForDividerView:self.dividerView]];
}

#pragma mark - Table View Cell Overrides

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.showDisclosureIndicator = NO;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    
    if (highlighted)
    {
        self.dividerView.backgroundColor = [UIColor systemBackgroundColor];
    }
    else
    {
        self.dividerView.backgroundColor = [UIColor ssMutedColor];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    self.dividerView.backgroundColor = [UIColor ssMutedColor];
}

@end
