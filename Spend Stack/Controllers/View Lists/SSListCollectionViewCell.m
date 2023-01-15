//
//  SSListCollectionViewCell.m
//  Spend Stack
//
//  Created by Jordan Morgan on 7/9/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

#import "SSListCollectionViewCell.h"
#import "UICollectionViewCell+Common.h"
#import "UIView+Animations.h"
#import "UITraitCollection+Utils.h"
#import "Spend_Stack_2-Swift.h"

@interface SSListCollectionViewCell()

@property (strong, nonatomic, nonnull) SSLabel *listNameLabel;
@property (strong, nonatomic, nonnull) SSLabel *listAmountLabel;
@property (strong, nonatomic, nonnull) SSLabel *listItemCountLabel;
@property (strong, nonatomic, nonnull) UIImageView *firstImageView;
@property (strong, nonatomic, nonnull) UIImageView *secondImageView;
@property (strong, nonatomic, nonnull) UIView *dividerView;
@property (strong, nonatomic, nonnull) SSVerticalStackView *verticalStack;
@property (strong, nonatomic, nonnull) TaxUtility *taxUtil;

@end

@implementation SSListCollectionViewCell

#pragma mark - On The Fly Loads

- (UIImage *)padlockImage
{
    return [[UIImage systemImageNamed:@"lock.circle.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightMedium]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (UIImage *)sharedListImage
{
    return [[[UIImage systemImageNamed:@"person.2.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightMedium]] imageWithBaselineOffsetFromBottom:-0.5f] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

#pragma mark - Initializers

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.listNameLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleTitle3];
        self.listAmountLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleTitle3];
        self.listItemCountLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleBody];
        
        self.dividerView = [UIView new];
        self.dividerView.backgroundColor = [UIColor ssMutedColor];
        self.dividerView.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.listNameLabel.textColor = [UIColor ssMainFontColor];
        self.listAmountLabel.textColor = [UIColor ssMainFontColor];
        self.listItemCountLabel.textColor = [UIColor ssSecondaryColor];
        
        [self.listNameLabel configureFontWeight:UIFontWeightBold];
        [self.listAmountLabel configureFontWeight:UIFontWeightBold];
        
        [self.listNameLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
        [self.listAmountLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
        
        self.firstImageView = [UIImageView new];
        self.firstImageView.image = [self padlockImage];
        self.firstImageView.tintColor = [UIColor ssSecondaryColor];
        self.firstImageView.contentMode = UIViewContentModeScaleAspectFit;
        
        self.secondImageView = [UIImageView new];
        self.secondImageView.image = [self sharedListImage];
        self.secondImageView.tintColor = [UIColor ssSecondaryColor];
        self.secondImageView.contentMode = UIViewContentModeScaleAspectFit;
        
        // Only used in accessibility font sizes
        self.verticalStack = [SSVerticalStackView new];
        self.verticalStack.horizontalAlignment = UIStackViewAlignmentLeading;
        self.verticalStack.verticalDistribution = UIStackViewDistributionEqualSpacing;
        self.verticalStack.spacing = SSSpacingBigMargin;
        self.verticalStack.hidden = NO;
        
        [self.contentView addSubviews:@[self.dividerView, self.verticalStack]];
        
        self.backgroundView = [UIView new];
        self.backgroundView.backgroundColor = [UIColor redColor];
        
        self.selectedBackgroundView = [self ssSelectionView];
        self.accessibilityHint = ss_Localized(@"listItem.cell.hint");
        self.accessibilityTraits = UIAccessibilityTraitButton;
        
        for (UIView *subview in self.contentView.subviews)
        {
            subview.isAccessibilityElement = NO;
        }

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

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.selectedBackgroundView.layer.cornerRadius = SSSpacingMargin;
    self.selectedBackgroundView.frame = CGRectInset(self.contentView.frame, 6, 6);
}

- (void)updateColors:(BOOL)compact
{
    UIColor *countColor = [UIColor ssSecondaryColor];
    UIColor *dividerColor = [UIColor ssMutedColor];
    UIColor *selectionColor = [UIColor ssSelectedBackgroundColor];
    UIColor *fillColor = [UIColor colorMDVRegular];
    
    if (compact)
    {
        countColor = [UIColor secondaryLabelColor];
        dividerColor = [UIColor placeholderTextColor];
        selectionColor = [UIColor secondarySystemFillColor];
        fillColor = [UIColor colorMDVCompact];
    }
    
    self.backgroundColor = fillColor;
    self.backgroundView.backgroundColor = fillColor;
    self.listItemCountLabel.textColor = countColor;
    self.firstImageView.tintColor = countColor;
    self.secondImageView.tintColor = countColor;
    self.dividerView.backgroundColor = dividerColor;
    self.selectedBackgroundView.backgroundColor = selectionColor;
}

#pragma mark - Constraint Handling

- (void)didChangePreferredContentSize:(NSNotification *)note
{
    [self setConstraints];
}

- (void)setConstraints
{
    // Set alignments based off of text size
    self.listAmountLabel.textAlignment = [SSCitizenship accessibilityFontsEnabled] ? NSTextAlignmentNatural : NSTextAlignmentRight;
    
    CGFloat imageSize = 14.0f;
    
    if ([SSCitizenship accessibilityFontsEnabled]) imageSize = SSIconAccessibilitySize;
    
    [self toggleSubViewHierarchyForAccessibilityFonts];
    
    if ([SSCitizenship accessibilityFontsEnabled] || [[NSLocale currentLocale].countryCode isEqualToString:COUNTRY_CODE_INDONESIA])
    {
        self.listAmountLabel.textColor = [UIColor ssSectionHeaderColor];
        [self.firstImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.width.and.height.equalTo(@(imageSize));
        }];

        [self.secondImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.width.and.height.equalTo(@(imageSize));
        }];
    }
    else
    {
        self.listAmountLabel.textColor = [UIColor ssMainFontColor];
        [self.listNameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentView.mas_leadingMargin);
            make.top.equalTo(self.contentView.mas_top).with.offset(SSTopBigElementMargin);
            make.width.lessThanOrEqualTo(self.contentView.mas_width).multipliedBy(0.65f);
        }];

        [self.listAmountLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView.mas_top).with.offset(SSTopBigElementMargin);
            make.bottom.equalTo(self.dividerView.mas_top).with.offset(SSBottomBigElementMargin);
            make.width.lessThanOrEqualTo(self.dividerView.mas_width).multipliedBy(.38f);
            make.trailing.equalTo(self.contentView.mas_trailingMargin);
        }];
        
        [self.listItemCountLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.listNameLabel.mas_leading);
            make.top.equalTo(self.listNameLabel.mas_bottom).with.offset(SSTopElementMargin).with.priorityHigh();
            make.bottom.equalTo(self.dividerView.mas_bottom).with.offset(SSBottomBigElementMargin);
        }];
        
        [self.firstImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.listItemCountLabel.mas_trailingMargin).with.offset(SSLeftBigElementMargin);
            make.baseline.equalTo(self.listItemCountLabel.mas_baseline);
            make.width.and.height.equalTo(@(imageSize)).with.priorityHigh();
        }];
        
        [self.secondImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.firstImageView.mas_trailingMargin).with.offset(SSLeftBigElementMargin);
            make.baseline.equalTo(self.listItemCountLabel.mas_baseline);
            make.width.and.height.equalTo(@(imageSize)).with.priorityHigh();
        }];
    }
    
    [self.dividerView mas_remakeConstraints:[self constraintsForFullWidthDividerView:self.dividerView]];
    
    [self.verticalStack mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView.mas_leftMargin);
        make.top.equalTo(self.contentView.mas_topMargin);
        make.right.equalTo(self.contentView.mas_rightMargin);
        make.bottom.equalTo(self.dividerView.mas_bottom).with.offset(SSBottomBigElementMargin);
    }];
}

- (void)toggleSubViewHierarchyForAccessibilityFonts
{
    if ([SSCitizenship accessibilityFontsEnabled] || [[NSLocale currentLocale].countryCode isEqualToString:COUNTRY_CODE_INDONESIA])
    {
        [self.listNameLabel removeFromSuperview];
        [self.listAmountLabel removeFromSuperview];
        [self.listItemCountLabel removeFromSuperview];
        [self.firstImageView removeFromSuperview];
        [self.secondImageView removeFromSuperview];
        
        [self.verticalStack setArrangedSubviews:@[self.listNameLabel,
                                                  self.listAmountLabel,
                                                  self.listItemCountLabel,
                                                  self.firstImageView,
                                                  self.secondImageView]];
    }
    else
    {
        [self.contentView addSubviews:@[self.listNameLabel,
                                        self.listAmountLabel,
                                        self.listItemCountLabel,
                                        self.firstImageView,
                                        self.secondImageView]];
        
        [self.verticalStack removeArrangedSubviews];
    }
}

#pragma mark - Drag and Drop

- (UIDragPreview *)dragPreviewRepresentation
{
    CGRect contentRect = CGRectInset(self.contentView.bounds, 2, 2);
    UIDragPreviewParameters *params = [UIDragPreviewParameters new];
    params.visiblePath = [UIBezierPath bezierPathWithRoundedRect:contentRect cornerRadius:SSSpacingMargin];
    return [[UIDragPreview alloc] initWithView:self.contentView parameters:params];
}

#pragma mark - Public Methods

- (void)setData:(SSList *)data
{
    self.listNameLabel.text = data.name;
    
    if (!self.taxUtil || [self.taxUtil.localeID isEqualToString:data.currencyIdentifier] == NO)
    {
        self.taxUtil = [[TaxUtility alloc] initWithLocaleID:data.currencyIdentifier];
    }
    
    self.listAmountLabel.text = [self.taxUtil guranteedCurrencyString:[data totalCost].stringValue];
    
    switch (data.itemCount)
    {
        case 0:
        {
            self.listItemCountLabel.text = ss_Localized(@"listItem.cell.zero");
            break;
        }
        case 1:
        {
            self.listItemCountLabel.text = ss_Localized(@"listItem.cell.one");
            break;
        }
        default:
        {
            self.listItemCountLabel.text = [NSString stringWithFormat:ss_Localized(@"listItem.cell.plural"), (long)data.itemCount];
            break;
        }
    }
    
    self.accessibilityLabel = [NSString stringWithFormat:@"%@, %@, %@", self.listNameLabel.text, self.listItemCountLabel.text, self.listAmountLabel.text];
    
    // If locked or just shared populate first image view and hide the other.
    // If both are active, show share first then lock
    if (data.isLocked && data.objCKRecord.share != nil)
    {
        self.firstImageView.hidden = NO;
        self.firstImageView.image = [self sharedListImage];
        self.secondImageView.hidden = NO;
        self.secondImageView.image = [self padlockImage];
        
        self.accessibilityLabel = [self.accessibilityLabel stringByAppendingString:[NSString stringWithFormat:@"%@ %@", ss_Localized(@"listItem.cell.locked"), ss_Localized(@"listItem.cell.shared")]];
    }
    else if (data.isLocked)
    {
        self.firstImageView.hidden = NO;
        self.firstImageView.image = [self padlockImage];
        self.secondImageView.hidden = YES;
        
        self.accessibilityLabel = [self.accessibilityLabel stringByAppendingString:ss_Localized(@"listItem.cell.locked")];
    }
    else if (data.objCKRecord.share != nil)
    {
        self.firstImageView.hidden = NO;
        self.firstImageView.image = [self sharedListImage];
        self.secondImageView.hidden = YES;
        
         self.accessibilityLabel = [self.accessibilityLabel stringByAppendingString:ss_Localized(@"listItem.cell.shared")];
    }
    else
    {
        self.firstImageView.hidden = YES;
        self.secondImageView.hidden = YES;
    }
    
    self.accessibilityUserInputLabels = @[self.listNameLabel.text];
}

@end
