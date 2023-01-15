//
//  SSQuickFindTableViewCell.m
//  Spend Stack
//
//  Created by Jordan Morgan on 2/5/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "SSQuickFindTableViewCell.h"
#import "SSQuickFindTypeView.h"
#import "SSQuickFindResult.h"
#import "UITraitCollection+Utils.h"
#import "UITableViewCell+Common.h"

@interface SSQuickFindTableViewCell()

@property (strong, nonatomic, nonnull) SSLabel *topLabel;
@property (strong, nonatomic, nonnull) SSQuickFindTypeView *typeView;
@property (strong, nonatomic, readwrite, nonnull) UIView *dividerView;
@property (strong, nonatomic, nonnull) UIImageView *disclosureImage;

@end

@implementation SSQuickFindTableViewCell

#pragma mark - Initializers

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self)
    {
        self.selectedBackgroundView = [self ssSelectionView];
        
        self.disclosureImage = [self ssDisclosureImageView];
        self.dividerView = [UIView new];
        self.dividerView.backgroundColor = [UIColor ssMutedColor];
        
        self.topLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleTitle2];
        [self.topLabel configureFontWeight:UIFontWeightSemibold];
        [self.topLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        self.typeView = [[SSQuickFindTypeView alloc] initWithFrame:self.bounds];
        
        [self.contentView addSubviews:@[self.dividerView, self.topLabel, self.typeView, self.disclosureImage]];
        
        [self setConstraints];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didChangePreferredContentSize:)
                                                     name:SS_TRAIT_COLLECTION_CHANGED
                                                   object:nil];
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
    BOOL isRegularEnv = self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular;
    
    [self.topLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView.mas_leftMargin);
        make.right.equalTo(self.disclosureImage.mas_left).with.offset(SSRightElementMargin);
        make.top.equalTo(self.contentView.mas_top).with.offset(SSTopBigElementMargin);
        make.bottom.equalTo(self.typeView.mas_top).with.offset(SSBottomElementMargin);
    }];
    
    [self.typeView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView.mas_leftMargin);
        make.bottom.equalTo(self.dividerView.mas_top).with.offset(SSBottomBigElementMargin);
    }];
    
    [self.disclosureImage mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView.mas_centerY);
        make.right.equalTo(self.contentView.mas_rightMargin).with.offset(SSSpacingMargin); // Because the image itself has padding
        make.height.and.width.equalTo(@28);
    }];
    
    if (isRegularEnv)
    {
        [self.dividerView mas_remakeConstraints:[self constraintsForReadableWidthDividerView:self.dividerView]];
    }
    else
    {
        [self.dividerView mas_remakeConstraints:[self constraintsForDividerView:self.dividerView]];
    }
}

#pragma mark - Table View Cell Overrides

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

#pragma mark - Public Methods

- (void)setData:(SSQuickFindResult *)result
{
    self.topLabel.text = result.matchedTerm;
    [self.typeView setData:result];
}

@end
