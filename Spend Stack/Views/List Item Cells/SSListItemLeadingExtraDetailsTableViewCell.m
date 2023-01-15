//
//  SSListItemLeadingExtraDetailsTableViewCell.m
//  Spend Stack
//
//  Created by Jordan Morgan on 1/28/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "SSListItemLeadingExtraDetailsTableViewCell.h"
#import "UITableViewCell+Common.h"
#import "SSConstants.h"
#import "TaxUtility.h"
#import "UITraitCollection+Utils.h"

@interface SSListItemLeadingExtraDetailsTableViewCell()

@property (strong, nonatomic, nonnull) UIImageView *firstImageView;
@property (strong, nonatomic, nonnull) UIImageView *secondImageView;
@property (strong, nonatomic, nonnull) UIImageView *thirdImageView;
@property (strong, nonatomic, nonnull) SSVerticalStackView *verticalStack;

@end

@implementation SSListItemLeadingExtraDetailsTableViewCell

#pragma mark - On The Fly Loads

- (UIImage *)notesImage
{
    return [[UIImage systemImageNamed:@"doc.text.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightMedium]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (UIImage *)mediaImage
{
    return [[[UIImage systemImageNamed:@"photo.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightMedium]] imageWithBaselineOffsetFromBottom:5.0f] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (UIImage *)linkImage
{
    return [[[UIImage systemImageNamed:@"link.circle.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightMedium]] imageWithBaselineOffsetFromBottom:4.5f] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

#pragma mark - Initializers

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self)
    {
        self.firstImageView = [UIImageView new];
        self.firstImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.firstImageView.tintColor = [UIColor ssSecondaryColor];
        self.firstImageView.image = [self notesImage];
        
        self.secondImageView = [UIImageView new];
        self.secondImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.secondImageView.tintColor = [UIColor ssSecondaryColor];
        self.secondImageView.image = [self mediaImage];
        
        self.thirdImageView = [UIImageView new];
        self.thirdImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.thirdImageView.tintColor = [UIColor ssSecondaryColor];
        self.thirdImageView.image = [self linkImage];
        
        [self.firstImageView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [self.secondImageView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [self.thirdImageView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        
        // Only used in accessibility font sizes
        self.verticalStack = [SSVerticalStackView new];
        self.verticalStack.horizontalAlignment = UIStackViewAlignmentLeading;
        self.verticalStack.verticalDistribution = UIStackViewDistributionEqualSpacing;
        self.verticalStack.spacing = SSSpacingBigMargin;
        self.verticalStack.hidden = NO;
        
        [self.contentView addSubviews:@[self.dividerView, self.verticalStack]];
        
        self.firstImageView.mas_key = @"firstImageView";
        self.secondImageView.mas_key = @"secondImageView";
        self.thirdImageView.mas_key = @"sthirdImageView";
        
        self.selectedBackgroundView = [self ssSelectionView];
        
        [self setConstraints];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didChangePreferredContentSize:)
                                                     name:UIContentSizeCategoryDidChangeNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didChangePreferredContentSize:)
                                                     name:SS_TRAIT_COLLECTION_CHANGED
                                                   object:nil];
    }
    
    return self;
}

#pragma mark - Constraint Handling

- (void)didChangePreferredContentSize:(NSNotification *)note
{
    [self setConstraints];
}

- (void)setConstraints
{
    [super setConstraints];
    
    if (self.firstImageView == nil )
    {
        // !!!: Hack. For some reason, super calls into here from its initializer which I think shouldn't happen.
        return;
    }
    
    CGFloat imageSize = ([SSCitizenship accessibilityFontsEnabled]) ? SSIconAccessibilitySize : 18.0f;
    [self toggleSubViewHierarchyForAccessibilityFonts];
    
    if ([SSCitizenship accessibilityFontsEnabled])
    {
        [self.firstImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.width.and.height.equalTo(@(imageSize));
        }];
        
        [self.secondImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.width.and.height.equalTo(@(imageSize));
        }];
        
        [self.thirdImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.width.and.height.equalTo(@(imageSize));
        }];
    }
    else
    {
        [self.firstImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.listItemNameLabel.mas_leading);
            make.width.and.height.equalTo(@(imageSize));
            make.top.equalTo(self.listItemNameLabel.mas_bottom).with.offset(SSTopElementMargin);
            make.bottom.equalTo(self.dividerView.mas_top).with.offset(SSBottomBigElementMargin).with.priorityHigh();
        }];
        
        [self.secondImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.firstImageView.mas_trailingMargin).with.offset(SSLeftBigElementMargin);
            make.baseline.equalTo(self.firstImageView.mas_baseline);
            make.width.and.height.equalTo(@(imageSize));
        }];
        
        [self.thirdImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.secondImageView.mas_trailingMargin).with.offset(SSLeftBigElementMargin);
            make.baseline.equalTo(self.secondImageView.mas_baseline);
            make.width.and.height.equalTo(@(imageSize));
        }];
        
        [self.listItemNameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView.mas_top).with.offset(SSTopBigElementMargin);
            make.left.equalTo(self.checkBoxView.checkbox.mas_right).with.offset(SSLeftElementMargin);
            make.width.lessThanOrEqualTo(self.dividerView.mas_width).multipliedBy(.60f);
        }];
    }
    
    [self.verticalStack mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView.mas_leftMargin);
        make.top.equalTo(self.contentView.mas_topMargin);
        make.right.equalTo(self.contentView.mas_rightMargin);
        make.bottom.equalTo(self.dividerView.mas_bottom).with.offset(SSBottomBigElementMargin);
    }];
}

- (void)toggleSubViewHierarchyForAccessibilityFonts
{
    if ([SSCitizenship accessibilityFontsEnabled])
    {
        [self.tagView removeFromSuperview];
        [self.checkBoxView removeFromSuperview];
        [self.listItemNameLabel removeFromSuperview];
        [self.listItemTotalPriceLabel removeFromSuperview];
        [self.firstImageView removeFromSuperview];
        [self.secondImageView removeFromSuperview];
        [self.thirdImageView removeFromSuperview];
        
        [self.verticalStack setArrangedSubviews:@[self.tagView,
                                                  self.checkBoxView,
                                                  self.listItemNameLabel,
                                                  self.listItemTotalPriceLabel,
                                                  self.firstImageView,
                                                  self.secondImageView,
                                                  self.thirdImageView]];
    }
    else
    {
        [self.contentView addSubviews:@[self.tagView,
                                        self.checkBoxView,
                                        self.listItemNameLabel,
                                        self.listItemTotalPriceLabel,
                                        self.firstImageView,
                                        self.secondImageView,
                                        self.thirdImageView]];
        
        [self.verticalStack removeArrangedSubviews];
    }
}

#pragma mark - Table View Cell Overrides

#pragma mark - Drag and Drop

#pragma mark - Public Methods

- (void)setData:(SSListItem *)item taxInfo:(SSTaxRateInfo *)taxInfo withList:(SSList *)list
{
    [super setData:item taxInfo:taxInfo withList:list];
    
    self.firstImageView.hidden = (item.notes == nil || [item.notes isEqualToString:@""]);
    self.secondImageView.hidden = (item.mediaAssetData == nil);
    self.thirdImageView.highlighted = (item.linkAttachment == nil || [item.linkAttachment isEqualToString:@""]);
    
    NSUInteger activeGlyphs = 0;
    
    BOOL hasNotes = item.notes != nil && [item.notes isEqualToString:@""] == NO;
    if (hasNotes) activeGlyphs++;
    
    BOOL hasImage = item.mediaAssetData != nil;
    if (hasImage) activeGlyphs++;
    
    BOOL hasLink = item.linkAttachment != nil && [item.linkAttachment isEqualToString:@""] == NO;
    if (hasLink) activeGlyphs++;
    
    // If it has notes or just an image then show first image view and hide the other.
    // If all are active, show notes first, then the image and link
    if (activeGlyphs == 3)
    {
        self.firstImageView.hidden = NO;
        self.firstImageView.image = [self notesImage];
        self.secondImageView.hidden = NO;
        self.secondImageView.image = [self mediaImage];
        self.thirdImageView.hidden = NO;
        self.thirdImageView.image = [self linkImage];
    }
    else if (activeGlyphs == 2)
    {
        self.firstImageView.hidden = NO;
        self.firstImageView.image = hasNotes ? [self notesImage] : [self mediaImage];
        self.secondImageView.hidden = NO;
        self.secondImageView.image = hasLink ? [self linkImage] : [self mediaImage];
        
        self.thirdImageView.hidden = YES;
    }
    else if (activeGlyphs == 1)
    {
        self.firstImageView.hidden = NO;
        
        if (hasNotes)
        {
            self.firstImageView.image = [self notesImage];
        }
        else if (hasImage)
        {
            self.firstImageView.image = [self mediaImage];
        }
        else if (hasLink)
        {
            self.firstImageView.image = [self linkImage];
        }
        else
        {
            NSAssert(NO, @"Spend Stack - Showing a leading details cell with no leading details.");
        }
        
        self.secondImageView.hidden = YES;
        self.thirdImageView.hidden = YES;
    }
    else
    {
        NSAssert(NO, @"Spend Stack - Showing a leading details cell with no leading details.");
        self.firstImageView.hidden = YES;
        self.secondImageView.hidden = YES;
        self.thirdImageView.hidden = YES;
    }
}

@end
