//
//  SSListItemTrailingExtraDetailsTableViewCell.m
//  Spend Stack
//
//  Created by Jordan Morgan on 1/28/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "SSListItemTrailingExtraDetailsTableViewCell.h"
#import "UITableViewCell+Common.h"
#import "SSConstants.h"
#import "TaxUtility.h"
#import "UITraitCollection+Utils.h"

@interface SSListItemTrailingExtraDetailsTableViewCell()

@property (strong, nonatomic, nonnull) SSLabel *listItemBaseAndTaxAmountLabel;
@property (strong, nonatomic, nonnull) SSVerticalStackView *verticalStack;

@end

@implementation SSListItemTrailingExtraDetailsTableViewCell

#pragma mark - Initializers

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self)
    {
        self.listItemBaseAndTaxAmountLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleCaption2];
        self.listItemBaseAndTaxAmountLabel.textColor = [UIColor ssSecondaryColor];
        
        // Only used in accessibility font sizes
        self.verticalStack = [SSVerticalStackView new];
        self.verticalStack.horizontalAlignment = UIStackViewAlignmentLeading;
        self.verticalStack.verticalDistribution = UIStackViewDistributionEqualSpacing;
        self.verticalStack.spacing = SSSpacingBigMargin;
        self.verticalStack.hidden = NO;
        
        [self.contentView addSubviews:@[self.dividerView, self.verticalStack]];
    
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
    
    if (self.listItemBaseAndTaxAmountLabel == nil)
    {
        // !!!: Hack. For some reason, super calls into here from its initializer which I think shouldn't happen.
        return;
    }
    
    // Set alignments based off of text size
    self.listItemBaseAndTaxAmountLabel.textAlignment = [SSCitizenship accessibilityFontsEnabled] ? NSTextAlignmentNatural : NSTextAlignmentRight;
    [self toggleSubViewHierarchyForAccessibilityFonts];
    
    if ([SSCitizenship accessibilityFontsEnabled])
    {
        
    }
    else
    {
        [self.listItemTotalPriceLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView.mas_top).with.offset(SSTopBigElementMargin);
            make.right.equalTo(self.contentView.mas_rightMargin);
            make.width.equalTo(self.listItemTotalPriceLabel.mas_width);
            make.height.equalTo(self.listItemTotalPriceLabel.mas_height);
        }];
        
        [self.listItemBaseAndTaxAmountLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.contentView.mas_rightMargin);
            make.width.equalTo(self.listItemBaseAndTaxAmountLabel.mas_width);
            make.top.equalTo(self.listItemTotalPriceLabel.mas_bottom).with.offset(SSTopElementMargin);
            make.bottom.equalTo(self.dividerView.mas_top).with.offset(SSBottomBigElementMargin).with.priorityHigh();
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
        [self.listItemBaseAndTaxAmountLabel removeFromSuperview];
        
        [self.verticalStack setArrangedSubviews:@[self.tagView,
                                                  self.checkBoxView,
                                                  self.listItemNameLabel,
                                                  self.listItemTotalPriceLabel,
                                                  self.listItemBaseAndTaxAmountLabel]];
    }
    else
    {
        [self.contentView addSubviews:@[self.tagView,
                                        self.checkBoxView,
                                        self.listItemNameLabel,
                                        self.listItemTotalPriceLabel,
                                        self.listItemBaseAndTaxAmountLabel]];
        
        [self.verticalStack removeArrangedSubviews];
    }
}

#pragma mark - Table View Cell Overrides

#pragma mark - Drag and Drop

#pragma mark - Public Methods

- (void)setData:(SSListItem *)item taxInfo:(SSTaxRateInfo *)taxInfo withList:(SSList *)list
{
    [super setData:item taxInfo:taxInfo withList:list];
    
    NSString *subtotalAmount = [self.taxUtil guranteedCurrencyString:[item calcSubtotalAmount].stringValue];
    NSString *taxAmount = [self.taxUtil guranteedCurrencyString:[item calcTaxedAmount:taxInfo taxUtil:list.taxUtil].stringValue];
    self.listItemBaseAndTaxAmountLabel.text = [NSString stringWithFormat:@"%@ • %@", subtotalAmount, taxAmount];
}

@end
