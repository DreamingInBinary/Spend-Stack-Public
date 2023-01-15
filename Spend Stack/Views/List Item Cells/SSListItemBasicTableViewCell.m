//
//  SSListItemBasicTableViewCell.m
//  Spend Stack
//
//  Created by Jordan Morgan on 7/13/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSListItemBasicTableViewCell.h"
#import "SSListItemExtraDetailsTableViewCell.h"
#import "UITableViewCell+Common.h"
#import "SSConstants.h"
#import "TaxUtility.h"
#import "UITraitCollection+Utils.h"
#import "UISplitViewController+SSUtils.h"
#import "Spend_Stack_2-Swift.h"

@interface SSListItemBasicTableViewCell() <SSListItemCheckBoxDelegate>

@property (strong, nonatomic, readwrite, nonnull) UIView *tagView;
@property (strong, nonatomic, readwrite, nonnull) SSListItemCheckBox *checkBoxView;
@property (strong, nonatomic, readwrite, nonnull) SSLabel *listItemNameLabel;
@property (strong, nonatomic, readwrite, nonnull) SSLabel *listItemTotalPriceLabel;
@property (strong, nonatomic, readwrite, nonnull) UIView *dividerView;
@property (nonatomic, readonly, getter=checkboxIsAlreadyHidden) BOOL checkboxAlreadyHidden;
@property (nonatomic, readonly, getter=checkboxIsAlreadyShowing) BOOL checkboxAlreadyShowing;

@end;

@implementation SSListItemBasicTableViewCell

#pragma mark - Custom Getters

- (BOOL)checkboxIsAlreadyHidden
{
    return _checkBoxView.checkbox.constraints.firstObject.constant < 2;
}

- (BOOL)checkboxIsAlreadyShowing
{
    return _checkBoxView.checkbox.constraints.firstObject.constant > 2;
}

#pragma mark - Initializers

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self)
    {
        self.backgroundColor = [UIColor systemBackgroundColor];
        
        self.tagView = [UIView new];
        self.checkBoxView = [[SSListItemCheckBox alloc] initWithFrame:CGRectZero];
        self.listItemNameLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleBody];
        self.listItemTotalPriceLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleBody];
        self.dividerView = [UIView new];
        
        [self.listItemNameLabel setContentHuggingPriority:UILayoutPriorityRequired
                                                  forAxis:UILayoutConstraintAxisHorizontal];
        [self.listItemNameLabel setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                                forAxis:UILayoutConstraintAxisVertical];
        
        self.listItemNameLabel.numberOfLines = 4;
        self.dividerView.backgroundColor = [UIColor ssMutedColor];
        self.checkBoxView.delegate = self;
        
        [self.contentView addSubviews:@[self.tagView,
                                        self.checkBoxView,
                                        self.listItemNameLabel,
                                        self.listItemTotalPriceLabel,
                                        self.dividerView]];
        
        // Debugging constraints
        self.tagView.mas_key = @"tabView";
        self.checkBoxView.mas_key = @"checkboxView";
        self.listItemNameLabel.mas_key = @"listItemNameLabel";
        self.listItemTotalPriceLabel.mas_key = @"listItemTotalPriceLabel";
        self.dividerView.mas_key = @"dividerView";
        
        self.selectedBackgroundView = [self ssSelectionView];
        
        [self setConstraints];
        
        if ([self isKindOfClass:[SSListItemExtraDetailsTableViewCell class]] == NO)
        {
            // Super (i.e. this base class) handles the notification in the above check
            // Subclasses call super in their initializers so they'll thread through here
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(didChangePreferredContentSize:)
                                                         name:UIContentSizeCategoryDidChangeNotification
                                                       object:nil];
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(didChangePreferredContentSize:)
                                                         name:SS_TRAIT_COLLECTION_CHANGED
                                                       object:nil];
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(didChangePreferredContentSize:)
                                                         name:SS_IPAD_PSEUDO_TRAIT_COLLECTION_CHANGED
                                                       object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(handleParentTableViewEditNotification:)
                                                         name:SS_PARENT_TABLE_VIEW_IS_EDIT_MODE_CHANGED
                                                       object:nil];
        }
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.isEditing) return;
    
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
    BOOL shouldConsiderRegularEnvForTag = NO;
    UISplitViewController *rootSplitVC = (UISplitViewController *)self.window.rootViewController;
    ListViewController *baseDetailView = nil;
    
    if ([rootSplitVC isKindOfClass:[UISplitViewController class]])
    {
        baseDetailView = [rootSplitVC ss_detailViewController];
    }
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        // Work around size class limitations on iPad :-/
        shouldConsiderRegularEnvForTag = [baseDetailView shouldConsideriPadFrameRegular];
    }
    else if (baseDetailView)
    {
        shouldConsiderRegularEnvForTag = [baseDetailView shouldConsideriPhoneFrameRegular];
    }
    
    // Set alignments based off of text size
    self.listItemTotalPriceLabel.textAlignment = [SSCitizenship accessibilityFontsEnabled] ? NSTextAlignmentNatural : NSTextAlignmentRight;
    
    if ([SSCitizenship accessibilityFontsEnabled])
    {
        if (self.tagView.layer.cornerRadius != 19.0f) self.tagView.layer.cornerRadius = 19.0f;
        
        [self.tagView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView.mas_leftMargin);
            make.top.equalTo(self.contentView.mas_topMargin).with.offset(SSTopElementMargin);
            make.width.equalTo(@38);
            make.height.equalTo(@38);
        }];
        
        [self.checkBoxView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentView.mas_leadingMargin).with.offset(SSRightBigElementMargin);;
            if (self.tagView.isHidden)
            {
                make.top.equalTo(self.contentView.mas_topMargin);
            }
            else
            {
                make.top.equalTo(self.tagView.mas_bottom).with.offset(SSTopElementMargin);
            }
            
            make.height.and.width.equalTo(@88);
        }];
        
        [self toggleCheckboxConstraints:self.checkBoxView.isChecked];
        
        [self.listItemNameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.checkBoxView.checkbox.mas_bottom).with.offset(SSTopElementMargin);
            make.left.equalTo(self.tagView.mas_left);
            make.right.equalTo(self.contentView.mas_rightMargin);
        }];
        
        [self.listItemTotalPriceLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.listItemNameLabel.mas_bottom).with.offset(SSTopElementMargin);
            make.left.equalTo(self.tagView.mas_left);
            make.right.equalTo(self.contentView.mas_rightMargin);
            make.bottom.equalTo(self.dividerView.mas_top).with.offset(SSBottomBigElementMargin);
        }];
    }
    else
    {
        [self.tagView mas_remakeConstraints:^(MASConstraintMaker *make) {
            if (shouldConsiderRegularEnvForTag)
            {
                make.right.equalTo(self.contentView.mas_leftMargin).with.offset(+(10 + SSRightJumboElementMargin));
                make.height.equalTo(@10);
                if (self.tagView.layer.cornerRadius != 5.0f) self.tagView.layer.cornerRadius = 5.0f;
            }
            else
            {
                make.left.equalTo(self.contentView.mas_left).with.offset(-5);
                make.height.equalTo(@38);
                if (self.tagView.layer.cornerRadius != 4.0f) self.tagView.layer.cornerRadius = 4.0f;
            }
            
            make.centerY.equalTo(self.contentView.mas_centerY);
            make.width.equalTo(@10);
        }];
        
        [self.checkBoxView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentView.mas_leadingMargin).with.offset(SSRightBigElementMargin);
            make.centerY.equalTo(self.contentView.mas_centerY);
            make.height.equalTo(self.contentView.mas_height);
            make.width.greaterThanOrEqualTo(@72);
        }];
        
        [self.listItemNameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView.mas_top).with.offset(SSTopBigElementMargin);
            make.left.equalTo(self.checkBoxView.checkbox.mas_right).with.offset(SSLeftElementMargin);
            make.bottom.equalTo(self.dividerView.mas_top).with.offset(SSBottomBigElementMargin);
            make.width.lessThanOrEqualTo(self.dividerView.mas_width).multipliedBy(.60f);
        }];
        
        [self.listItemTotalPriceLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView.mas_top).with.offset(SSTopBigElementMargin);
            make.bottom.equalTo(self.dividerView.mas_top).with.offset(SSBottomBigElementMargin);
            make.width.lessThanOrEqualTo(self.dividerView.mas_width).multipliedBy(.38f).with.priorityHigh();
            make.trailing.equalTo(self.contentView.mas_trailingMargin);
        }];
    }
    
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

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    self.selectedBackgroundView.ss_size = self.ss_size;
    self.selectedBackgroundView.layer.cornerRadius = 0.0f;
    self.tagView.hidden = editing;
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
    
    if (self.checkboxIsAlreadyShowing)
    {
        [self.checkBoxView setHightlightedSelected:highlighted];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    self.dividerView.backgroundColor = [UIColor ssMutedColor];
    
    if (self.checkboxIsAlreadyShowing)
    {
        [self.checkBoxView setHightlightedSelected:selected];
    }
}

#pragma mark - Drag and Drop

- (UIDragPreview *)dragPreviewRepresentation
{
    CGRect contentRect = CGRectInset(self.contentView.readableContentGuide.layoutFrame, -4, -4);
    UIDragPreviewParameters *params = [UIDragPreviewParameters new];
    params.visiblePath = [UIBezierPath bezierPathWithRoundedRect:contentRect cornerRadius:SSSpacingMargin];
    return [[UIDragPreview alloc] initWithView:self.contentView parameters:params];
}

#pragma mark - Checkbox Delegate

- (UIView *)parentContentView
{
    return self.contentView;
}

- (NSArray <UIView *> *)viewsToExcludeDuringCheckAnimation
{
    return [SSCitizenship accessibilityFontsEnabled] ? @[self.dividerView, self.checkBoxView, self.tagView, self.listItemNameLabel, self.listItemTotalPriceLabel] : @[self.dividerView, self.checkBoxView, self.tagView];
}

#pragma mark - Checkbox Data Toggle

- (void)toggleCheckedForItem:(SSListItem *)listItem taxInfo:(SSTaxRateInfo *)taxRate list:(SSList *)list isChecked:(BOOL)isChecked
{
    if (self.onCheckToggled)
    {
        self.onCheckToggled(listItem.dbID, isChecked);
    }
}

- (void)handleParentTableViewEditNotification:(NSNotification *)note
{
    if (self.checkboxIsAlreadyHidden) return;
    // Right now the table view API calls isEditing:animated many times during setup.
    // So, it'll hide the checkbox when it should show. For now, we'll just have to listen to the tableview.
    BOOL isEditing = ((NSNumber *)note.object).boolValue;
    [self toggleCheckboxConstraints:!isEditing];
}

#pragma mark - Public Methods

- (void)setData:(SSListItem *)item taxInfo:(SSTaxRateInfo *)taxInfo withList:(SSList *)list
{
    if (!self.taxUtil || [self.taxUtil.localeID isEqualToString:list.currencyIdentifier] == NO)
    {
        self.taxUtil = [[TaxUtility alloc] initWithLocaleID:list.currencyIdentifier];
    }
    
    [self reloadTagViewWithTag:item.tag];
    self.listItemNameLabel.text = item.title;
    
    // Tack on attributed string for modifier data (i.e. quantity and discounts)
    NSString *modifierData = [item modifiderDataString:list.taxUtil];
    NSDictionary *modifierTextAtts = @{NSForegroundColorAttributeName:[UIColor ssSecondaryColor],
                                       NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]
    };
    
    if (modifierData && modifierData.length > 0)
    {
        NSString *listItemNameText = [NSString stringWithFormat:@"%@ %@", item.title, modifierData];
        NSRange modifierRange = [listItemNameText rangeOfString:modifierData];
        NSMutableAttributedString *attibutedString = [[NSMutableAttributedString alloc] initWithString:listItemNameText];
        [attibutedString setAttributes:modifierTextAtts range:modifierRange];
        self.listItemNameLabel.attributedText = attibutedString;
    }
    
    self.listItemTotalPriceLabel.text = [self.taxUtil guranteedCurrencyString:[item calcTotalAmount:taxInfo taxUtil:list.taxUtil].stringValue];
    
    if ([item checkIsUsingRecurringPricing])
    {
        NSString *currentText = self.listItemTotalPriceLabel.text;
        NSString *recurringFreq = [item recurringPriceDisplayString];
        
        NSString *listItemPriceText = [NSString stringWithFormat:@"%@\n%@", currentText, recurringFreq];
        NSRange modifierRange = [listItemPriceText rangeOfString:recurringFreq];
        NSMutableAttributedString *attibutedString = [[NSMutableAttributedString alloc] initWithString:listItemPriceText];
        [attibutedString setAttributes:modifierTextAtts range:modifierRange];
        
        self.listItemTotalPriceLabel.attributedText = attibutedString;
    }
    
    self.checkBoxView.checkHandlerEnabled = list.showingCheckboxes;
    [self toggleCheckboxConstraints:list.showingCheckboxes];
    
    if (list.showingCheckboxes)
    {
        __weak typeof(self) weakSelf = self;
        self.checkBoxView.onCheck = ^(BOOL isChecked) {
            [weakSelf toggleCheckedForItem:item taxInfo:taxInfo list:list isChecked:isChecked];
        };
        [self.checkBoxView toggleChecked:item.checkedOff];
    }
}

- (void)reloadTagViewWithTag:(SSListTag *)tag
{
    self.tagView.backgroundColor = tag ? [SSTag rawColorFromColor:tag.color] : [UIColor clearColor];
    self.tagView.hidden = [self.tagView.backgroundColor isEqual:[UIColor clearColor]];
}

- (void)toggleCheckboxConstraints:(BOOL)showing
{
    if (showing)
    {
        // Already expanded?
        if (self.checkboxIsAlreadyShowing) return;
        [self.checkBoxView.checkbox mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.width.and.height.equalTo([SSCitizenship accessibilityFontsEnabled] ? @33 : @18);
            make.leading.equalTo(self.dividerView.mas_leading).with.priorityHigh();
            make.centerY.equalTo(self.checkBoxView.mas_centerY);
        }];
    }
    else
    {
        // Already collapased?
        if (self.checkboxIsAlreadyHidden) return;
        [self.checkBoxView.checkbox mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.width.and.height.equalTo(@0);
            // The item label is constrained next to the checkbox, so this removes the padding
            make.leading.equalTo(self.contentView.mas_leadingMargin).with.offset(SSRightElementMargin);
            make.centerY.equalTo(self.checkBoxView.mas_centerY);
        }];
    }
}

@end
