//
//  SSListBreakdownViewController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 1/27/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSListBreakdownViewController.h"
#import "SSListTotalBreakdownView.h"
#import "SSCountingLabel.h"
#import "TaxUtility.h"

@interface SSListBreakdownViewController ()

@property (strong, nonatomic, nonnull) UISegmentedControl *segment;
@property (weak, nonatomic, nullable) SSList *list;
@property (strong, nonatomic, nonnull) NSArray <NSString *> *allItemsStrings;
@property (strong, nonatomic, nonnull) NSArray <NSString *> *recurringCostStrings;
@property (strong, nonatomic, nonnull) SSCountingLabel *subtotalTextLabel;
@property (strong, nonatomic, nonnull) SSCountingLabel *taxTextLabel;
@property (strong, nonatomic, nonnull) SSCountingLabel *discountsTextLabel;
@property (strong, nonatomic, nonnull) SSCountingLabel *totalTextLabel;
@property (strong, nonatomic, nonnull) SSCountingLabel *subtotalAmountLabel;
@property (strong, nonatomic, nonnull) SSCountingLabel *taxAmountLabel;
@property (strong, nonatomic, nonnull) SSCountingLabel *discountsAmountLabel;
@property (strong, nonatomic, nonnull) SSCountingLabel *totalAmountLabel;
@property (strong, nonatomic, nonnull) UILayoutGuide *scrollViewLayoutGuide;
@property (strong, nonatomic, nonnull) UIView *containerView;
@property (strong, nonatomic, nonnull) UIView *dividerView;
@property (strong, nonatomic, nonnull) TaxUtility *taxUtil;
@property (strong, nonatomic, nonnull) NSArray <SSListItem *> *recurringCosts;

@end

@implementation SSListBreakdownViewController

#pragma mark - Initializers

- (instancetype)initWithList:(SSList *)list
{
    self = [super init];
    
    if (self)
    {
        self.list = list;
        NSDictionary <NSString *, SSCountingLabel *> *labels = [SSListTotalBreakdownView labelsForListBreakdown:list.currencyIdentifier];
        
        self.taxUtil = [[TaxUtility alloc] initWithLocaleID:list.currencyIdentifier];
        self.recurringCosts = [list recurringCostItems];
        
        self.segment = [[UISegmentedControl alloc] initWithItems:@[ss_Localized(@"breakdown.vc.all"), ss_Localized(@"breakdown.vc.recurring")]];
        self.segment.selectedSegmentIndex = 0;
        [self.segment addTarget:self
                         action:@selector(segmentChangedValue:)
               forControlEvents:UIControlEventValueChanged];
        
        // Make each one have a minimum font size of 21, totals have 23 for all items (18 otherwise).
        for (SSLabel *lbl in labels.allValues)
        {
            lbl.smallestFontSize = 18.0f;
        }
        
        self.totalTextLabel.smallestFontSize = 23.0f;
        self.totalAmountLabel.smallestFontSize = 23.0f;
        
        self.subtotalTextLabel = labels[SS_SUBTOTAL_LABEL];
        self.taxTextLabel = labels[SS_TAX_TOTAL_LABEL];
        self.discountsTextLabel = labels[SS_DISCOUNT_LABEL];
        self.totalTextLabel = labels[SS_TOTAL_LABEL];
        
        self.subtotalAmountLabel = labels[SS_SUBTOTAL_AMOUNT_LABEL];
        self.taxAmountLabel = labels[SS_TAX_TOTAL_AMOUNT_LABEL];
        self.discountsAmountLabel = labels[SS_DISCOUNT_AMOUNT_LABEL];
        self.totalAmountLabel = labels[SS_TOTAL_AMOUNT_LABEL];
        
        self.allItemsStrings = @[self.subtotalTextLabel.text,
                                 self.taxTextLabel.text,
                                 self.discountsTextLabel.text,
                                 self.totalTextLabel.text];
        
        [self setLabelTextForAllItems];
        
        self.recurringCostStrings = @[ss_Localized(@"listEdit.dayColon"),
                                      ss_Localized(@"listEdit.weekColon"),
                                      ss_Localized(@"listEdit.monthColon"),
                                      ss_Localized(@"listEdit.yearColon")];
    }
    
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Nav bar
    self.title = ss_Localized(@"breakdown.vc.title");
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    if ([self.navigationController isKindOfClass:[SSNavigationController class]])
    {
        [((SSNavigationController *)self.navigationController) styleNavigationBarAsPlainWhiteWithBoldText];
    }

    // Scrollview
    self.scrollView = [UIScrollView new];
    [self.view addSubview:self.scrollView];

    self.containerView = [UIView new];
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:self.containerView];

    self.dividerView = [UIView new];
    self.dividerView.backgroundColor = [UIColor ssMainFontColor];

    self.scrollViewLayoutGuide = [UILayoutGuide new];
    
    // Add labels and divider
    [self.containerView addSubviews:@[self.segment, self.subtotalTextLabel, self.taxTextLabel, self.discountsTextLabel, self.totalTextLabel, self.subtotalAmountLabel, self.taxAmountLabel, self.discountsAmountLabel, self.totalAmountLabel, self.dividerView]];
    
    [self.scrollView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft);
        make.right.equalTo(self.view.mas_safeAreaLayoutGuideRight);
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
    }];
    
    [self setConstraints];
    [self performBlurAnimationIfPossible];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setConstraints) name:UIContentSizeCategoryDidChangeNotification object:nil];
}

- (BOOL)accessibilityPerformEscape
{
    [self dismissViewControllerAnimated:NO completion:nil];
    return YES;
}

#pragma mark - Constraints

- (void)setConstraints
{
    // Masonry can't attach to a layoutguide, so a bit of extra work here
    [self.containerView removeAllConstraints];
    
    BOOL showSegment = self.recurringCosts.count > 0;
    if (showSegment == NO)
    {
        self.segment.hidden = YES;
        self.segment.userInteractionEnabled = NO;
    }
    
    // Optional Toggle
    [self.segment mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.containerView.mas_left);
        make.right.equalTo(self.containerView.mas_right);
        make.top.equalTo(self.containerView.mas_top);
        if (showSegment == NO) make.height.equalTo(@0);
    }];
    
    if ([SSCitizenship accessibilityFontsEnabled])
    {
        if (self.scrollViewLayoutGuide.owningView != nil)
        {
            [self.scrollView removeLayoutGuide:self.scrollViewLayoutGuide];
        }
        
        [self.containerView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.scrollView.mas_centerX);
            make.width.equalTo(self.scrollView.mas_width).multipliedBy(0.74f);
            make.top.and.bottom.equalTo(self.scrollView);
        }];
        
        // Divider
        [self.dividerView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@(.5));
            make.centerX.equalTo(self.containerView.mas_centerX);
            make.width.equalTo(self.containerView.mas_width);
            make.top.equalTo(self.discountsAmountLabel.mas_bottom).with.offset(SSTopElementMargin);
        }];
        
        // Subtotal
        [self.subtotalTextLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.and.right.equalTo(self.containerView);
            make.top.equalTo(self.segment.mas_bottom).with.offset(SSTopBigElementMargin);
        }];
        
        [self.subtotalAmountLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.and.right.equalTo(self.containerView);
            make.top.equalTo(self.subtotalTextLabel.mas_bottom);
        }];
        
        // Discounts
        [self.discountsTextLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.and.right.equalTo(self.containerView);
            make.top.equalTo(self.taxAmountLabel.mas_bottom).with.offset(SSTopElementMargin);
        }];
        
        [self.discountsAmountLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.and.right.equalTo(self.containerView);
            make.top.equalTo(self.discountsTextLabel.mas_bottom).with.offset(SSTopElementMargin);
        }];
    }
    else
    {
        if (self.scrollViewLayoutGuide.owningView == nil)
        {
            [self.scrollView addLayoutGuide:self.scrollViewLayoutGuide];
            [self.scrollViewLayoutGuide.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor].active = YES;
            [self.scrollViewLayoutGuide.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor].active = YES;
            [self.scrollViewLayoutGuide.centerXAnchor constraintEqualToAnchor:self.scrollView.centerXAnchor].active = YES;
            [self.scrollViewLayoutGuide.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor multiplier:0.64f].active = YES;
        }
        
        [self.containerView.widthAnchor constraintEqualToAnchor:self.scrollViewLayoutGuide.widthAnchor].active = YES;
        [self.containerView.centerXAnchor constraintEqualToAnchor:self.scrollViewLayoutGuide.centerXAnchor].active = YES;
        [self.containerView.centerYAnchor constraintEqualToAnchor:self.scrollViewLayoutGuide.centerYAnchor constant:(SSBottomJumboElementMargin + SSSpacingMargin)].active = YES;
        
        [self.dividerView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@(.5));
            make.centerX.equalTo(self.containerView.mas_centerX);
            make.width.equalTo(self.containerView.mas_width);
            make.top.equalTo(self.discountsAmountLabel.mas_bottom).with.offset(SSTopElementMargin);
        }];
    
        // Subtotal
        [self.subtotalTextLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.containerView.mas_left);
            make.top.equalTo(self.segment.mas_bottom).with.offset(SSTopBigElementMargin);
        }];
        
        [self.subtotalAmountLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.containerView.mas_right);
            make.left.equalTo(self.subtotalTextLabel.mas_right).with.offset(SSLeftElementMargin);
            make.top.equalTo(self.segment.mas_bottom).with.offset(SSTopBigElementMargin);
        }];
        
        
        // Discounts
        [self.discountsTextLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.subtotalTextLabel.mas_left);
            make.top.equalTo(self.taxAmountLabel.mas_bottom).with.offset(SSTopElementMargin);
        }];
        
        [self.discountsAmountLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.subtotalAmountLabel.mas_right);
            make.left.equalTo(self.discountsTextLabel.mas_right).with.offset(SSLeftElementMargin);
            make.top.equalTo(self.taxAmountLabel.mas_bottom).with.offset(SSTopElementMargin);
        }];
    }
    
    // Tax
    [self setTaxAndMonthLabelConstraints];
    
    // Total
    [self setTotalAndYearLabelConstraints];
}

- (void)setTaxAndMonthLabelConstraints
{
    NSUInteger taxTopPadding = SSTopElementMargin;
    
    if ([SSCitizenship accessibilityFontsEnabled])
    {
        [self.taxTextLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.and.right.equalTo(self.containerView);
            make.top.equalTo(self.subtotalAmountLabel.mas_bottom).with.offset(taxTopPadding);
        }];
        
        [self.taxAmountLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.and.right.equalTo(self.containerView);
            make.top.equalTo(self.taxTextLabel.mas_bottom).with.offset(taxTopPadding);
        }];
    }
    else
    {
        [self.taxTextLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.subtotalTextLabel.mas_left);
            make.top.equalTo(self.subtotalAmountLabel.mas_bottom).with.offset(taxTopPadding);
        }];
        
        [self.taxAmountLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.subtotalAmountLabel.mas_right);
            make.left.equalTo(self.taxTextLabel.mas_right).with.offset(SSLeftElementMargin);
            make.top.equalTo(self.subtotalAmountLabel.mas_bottom).with.offset(taxTopPadding);
        }];
    }
}

- (void)setTotalAndYearLabelConstraints
{
    BOOL dividerShowing = self.segment.selectedSegmentIndex == IDX_ALL_ITEMS;
    
    if ([SSCitizenship accessibilityFontsEnabled])
    {
        [self.totalTextLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.and.right.equalTo(self.containerView);
            if (dividerShowing)
            {
                make.top.equalTo(self.dividerView.mas_bottom).with.offset(SSTopElementMargin);
            }
            else
            {
                make.top.equalTo(self.discountsAmountLabel.mas_top).with.offset(SSTopElementMargin);
            }
        }];
        
        [self.totalAmountLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.and.right.equalTo(self.containerView);
            make.top.equalTo(self.totalTextLabel.mas_bottom).with.offset(SSTopElementMargin);
            make.bottom.equalTo(self.containerView.mas_bottom);
        }];
    }
    else
    {
        [self.totalTextLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.subtotalTextLabel.mas_left);
            if (dividerShowing)
            {
                make.top.equalTo(self.dividerView.mas_bottom).with.offset(SSTopElementMargin);
            }
            else
            {
                make.top.equalTo(self.discountsTextLabel.mas_bottom).with.offset(SSTopElementMargin);
            }
            make.bottom.equalTo(self.containerView.mas_bottom);
        }];
        
        [self.totalAmountLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.subtotalAmountLabel.mas_right);
            make.left.equalTo(self.totalTextLabel.mas_right).with.offset(SSLeftElementMargin);
            if (dividerShowing)
            {
                make.top.equalTo(self.dividerView.mas_bottom).with.offset(SSTopElementMargin);
            }
            else
            {
                make.top.equalTo(self.discountsAmountLabel.mas_bottom).with.offset(SSTopElementMargin);
            }
            make.bottom.equalTo(self.containerView.mas_bottom);
        }];
    }
}

#pragma mark - Segment Toggle

static NSUInteger IDX_ALL_ITEMS = 0;
static NSUInteger IDX_RECURRING_ITEMS = 1;

- (void)segmentChangedValue:(UISegmentedControl *)sender
{
    [self setTaxAndMonthLabelConstraints];
    [self setTotalAndYearLabelConstraints];
    [self.view layoutIfNeeded];
    
    if (sender.selectedSegmentIndex == IDX_ALL_ITEMS)
    {
        [UIView animateWithDuration:SSFastestAnimationDuration animations:^{
            [self setLabelTextForAllItems];
            [self setTotalTextLabelsForAllItemsStyling];
            self.dividerView.alpha = 1.0f;
        }];
    }
    else if (sender.selectedSegmentIndex == IDX_RECURRING_ITEMS)
    {
        // Day, week, month and year
        [UIView animateWithDuration:SSFastestAnimationDuration animations:^{
            [self setLabelTextForRecurringItems];
            [self setTotalTextLabelsForRecurringCostStyling];
            self.dividerView.alpha = 0.0f;
        }];
    }
}

- (void)setLabelTextForAllItems
{
    self.subtotalTextLabel.text = self.allItemsStrings[0];
    self.taxTextLabel.text = self.allItemsStrings[1];
    self.discountsTextLabel.text = self.allItemsStrings[2];
    self.totalTextLabel.text = self.allItemsStrings[3];

    // Apply text to amounts
    self.subtotalAmountLabel.text = [self.taxUtil guranteedCurrencyString:[self.list calcBaseCost].stringValue];
    self.taxAmountLabel.text = [self.taxUtil guranteedCurrencyString:[self.list calcTaxAmount].stringValue];
    self.discountsAmountLabel.text = [self.taxUtil guranteedCurrencyString:[self.list calcDiscountAmount].stringValue];
    self.totalAmountLabel.text = [self.taxUtil guranteedCurrencyString:[self.list calcTotalCost].stringValue];
}

- (void)setLabelTextForRecurringItems
{
    self.subtotalTextLabel.text = self.recurringCostStrings[0];
    self.taxTextLabel.text = self.recurringCostStrings[1];
    self.discountsTextLabel.text = self.recurringCostStrings[2];
    self.totalTextLabel.text = self.recurringCostStrings[3];
    
    // Calc totals
    self.subtotalAmountLabel.text = [self.taxUtil guranteedCurrencyString:[self.list calcTotalRecurringCost:ListItemRecurringPricingChoiceDay].stringValue];
    self.taxAmountLabel.text = [self.taxUtil guranteedCurrencyString:[self.list calcTotalRecurringCost:ListItemRecurringPricingChoiceWeek].stringValue];
    self.discountsAmountLabel.text = [self.taxUtil guranteedCurrencyString:[self.list calcTotalRecurringCost:ListItemRecurringPricingChoiceMonth].stringValue];
    self.totalAmountLabel.text = [self.taxUtil guranteedCurrencyString:[self.list calcTotalRecurringCost:ListItemRecurringPricingChoiceYear].stringValue];
}

- (void)setTotalTextLabelsForAllItemsStyling
{
    NSDictionary <NSString *, SSLabel *> *ogLabels = [SSListTotalBreakdownView labelsForListBreakdown:self.list.currencyIdentifier];
    
    self.totalTextLabel.font = ogLabels[SS_TOTAL_LABEL].font;
    self.totalTextLabel.textColor = ogLabels[SS_TOTAL_LABEL].textColor;
    self.totalAmountLabel.font = ogLabels[SS_TOTAL_AMOUNT_LABEL].font;
    self.totalAmountLabel.textColor = ogLabels[SS_TOTAL_AMOUNT_LABEL].textColor;
    self.totalTextLabel.smallestFontSize = 23.0f;
    self.totalAmountLabel.smallestFontSize =  23.0f;
}

- (void)setTotalTextLabelsForRecurringCostStyling
{
    self.totalTextLabel.font = self.discountsTextLabel.font;
    self.totalTextLabel.textColor = self.discountsTextLabel.textColor;
    self.totalAmountLabel.font = self.discountsAmountLabel.font;
    self.totalAmountLabel.textColor = self.discountsAmountLabel.textColor;
    self.totalTextLabel.smallestFontSize = 18.0f;
    self.totalAmountLabel.smallestFontSize =  18.0f;
}

@end
