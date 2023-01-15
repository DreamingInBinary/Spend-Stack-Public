//
//  SSBaseListItemEditingTableViewCell.m
//  Spend Stack
//
//  Created by Jordan Morgan on 2/17/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSBaseListItemEditingTableViewCell.h"
#import "SSConstants.h"
#import "UITableViewCell+Common.h"

@interface SSBaseListItemEditingTableViewCell()

@property (strong, nonatomic, nonnull, readwrite) UIView *dividerView;

@end

@implementation SSBaseListItemEditingTableViewCell

#pragma mark - Custom Setters

- (void)setCurrencyID:(NSString *)currencyID
{
    _currencyID = currencyID;
    if (!_taxUtil || [_taxUtil.localeID isEqualToString:_currencyID] == NO)
    {
        _taxUtil = [[TaxUtility alloc] initWithLocaleID:_currencyID];
    }
}

#pragma mark - Initializers

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self)
    {
        self.contentView.clipsToBounds = NO;
        self.clipsToBounds = NO;
        self.contentView.backgroundColor = [UIColor systemBackgroundColor];
        
        self.dividerView = [UIView new];
        self.dividerView.backgroundColor = [UIColor ssMutedColor];
        
        [self.contentView addSubviews:@[self.dividerView]];
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
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
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular)
    {
        [self.dividerView mas_remakeConstraints:[self constraintsForReadableWidthDividerView:self.dividerView]];
    }
    else
    {
        [self.dividerView mas_remakeConstraints:[self constraintsForDividerView:self.dividerView]];
    }
}

#pragma mark - Public Methods

- (UITableView *)containingTableView
{
    // Haha object oriented whaaaaa?
    UIView *parentTableView = self.superview;
    
    if ([parentTableView isKindOfClass:[UITableView class]])
    {
        return (UITableView *)parentTableView;
    }
    
    return nil;
}

- (void)setData:(SSListItem *)item list:(SSList * _Nonnull)list
{
    // This should be overriden
    self.listItem = item;
    self.taxRateInfo = list.taxInfo;
    self.taxUtil = list.taxUtil;
    self.list = list;
}

@end
