//
//  SSEnterTaxRateViewController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 3/3/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "SSEnterTaxRateViewController.h"
#import "SSAddListViewController.h"
#import "TaxUtility.h"
#import "UIView+Animations.h"
#import "IQKeyboardManager.h"
#import "Spend_Stack_2-Swift.h"

@interface SSEnterTaxRateViewController () <UITextViewDelegate>

@property (weak, nonatomic, nullable) SSTaxRateInfo *taxInfo;
@property (strong, nonatomic, nonnull) SSTextView *taxRateTextView;
@property (strong, nonatomic, nonnull) UIBarButtonItem *doneBarButtonItem;
@property (nonatomic) BOOL shouldSetViewAsTransparent;
@property (strong, nonatomic, nonnull) TaxUtility *taxUtil;

@end

@implementation SSEnterTaxRateViewController

#pragma mark - Initializer

- (instancetype)initWithTaxInfo:(SSTaxRateInfo *)taxInfo
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self)
    {
        self.taxInfo = taxInfo;
        self.shouldSetViewAsTransparent = YES;
        self.taxUtil = [[TaxUtility alloc] initWithLocaleID:@"en_US"];
    }
    
    return self;
}

- (instancetype)initWithTaxInfoAndWhiteBackground:(SSTaxRateInfo *)taxInfo
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self)
    {
        self.taxInfo = taxInfo;
        self.taxUtil = [[TaxUtility alloc] initWithLocaleID:@"en_US"];
    }
    
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [IQKeyboardManager sharedManager].enable = NO;
    
    self.title = ss_Localized(@"enterTax.vc.title");
    
    if (self.shouldSetViewAsTransparent)
    {
        [SSCitizenship setViewAsTransparentIfPossible:self.view];
    }
    else
    {
        self.view.backgroundColor = [UIColor whiteColor];
    }
    
    self.taxRateTextView = [[SSTextView alloc] initWithTextStyle:UIFontTextStyleTitle1];
    self.taxRateTextView.backgroundColor = [UIColor clearColor];
    self.taxRateTextView.textColor = [UIColor ssTextPlaceholderColor];
    self.taxRateTextView.placeholderText = [self.taxUtil placeholderStringForManualTaxRateEntry];
    self.taxRateTextView.keyboardDistanceFromTextField = 260;
    [self.taxRateTextView configureFontWeight:UIFontWeightBold];
    [self.view addSubview:self.taxRateTextView];
        
    SSToolbar *toolBar = [SSToolbar new];
    toolBar.clipsToBounds = NO;
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.doneBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(confirmManualTaxRate)];
    self.doneBarButtonItem.enabled = NO;
    [toolBar setItems:@[flexSpace, self.doneBarButtonItem]];
    self.taxRateTextView.inputAccessoryView = toolBar;
    
    // Constraints
    [self.taxRateTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_readableContentGuideLeft);
        make.right.equalTo(self.view.mas_readableContentGuideRight);
        make.bottom.equalTo(self.view.mas_centerY).with.offset(-100);
    }];
    
    self.taxRateTextView.keyboardType = UIKeyboardTypeDecimalPad;
    self.taxRateTextView.delegate = self;
    
    if (self.taxInfo.taxRate != nil && self.taxInfo.taxRate.integerValue > 0)
    {
        self.taxRateTextView.text = [self.taxUtil taxStringForManualEntryFromString:self.taxInfo.taxRate.stringValue];
        [self textViewDidChange:self.taxRateTextView];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.shouldSetViewAsTransparent)
    {
        [SSCitizenship setViewAsTransparentIfPossible:self.view];
    }
    else
    {
        self.view.backgroundColor = [UIColor systemBackgroundColor];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    dispatch_async(dispatch_get_main_queue(), ^ {
        [self.taxRateTextView becomeFirstResponder];
    });
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [IQKeyboardManager sharedManager].enable = YES;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
}

#pragma mark - Confirm

- (void)confirmManualTaxRate
{
    [self.taxUtil decimalTaxValueFromString:self.taxRateTextView.text result:^ (BOOL valid, NSString *errorReason, NSDecimalNumber *taxRate) {
        if (valid)
        {
            self.taxInfo.taxRate = taxRate;
            self.taxInfo.taxEnabled = YES;
            [self.taxInfo setTaxRateManuallySet:YES];
            
            if (self.editingList)
            {
                [[DataStore new] updateWithList:self.editingList completion:^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:SS_REQUEST_RELOAD_LIST
                                                                        object:nil];
                }];
            }
            
            if (self.onConfirmation) self.onConfirmation();
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
        else
        {
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:ss_Localized(@"general.yes") style:UIAlertActionStyleDefault handler:^ (UIAlertAction *action) {
                
            }];

            UIAlertAction *renterAction = [UIAlertAction actionWithTitle:ss_Localized(@"enterTax.vc.change") style:UIAlertActionStyleDefault handler:^ (UIAlertAction *action) {
                
            }];

            [self showAlertControllerWithTitle:ss_Localized(@"enterTax.vc.adjust") message:errorReason actions:@[okAction, renterAction]];
        }
    }];
}

#pragma mark - Text View Delegate

- (void)textViewDidChange:(UITextView *)textView
{
    // iOS Bug where it makes some locales enter the 1,000's separator instead of the decimal
    // https://forums.developer.apple.com/thread/107269
    if ([textView.text containsString:self.taxUtil.localeSeparator])
    {
        textView.text = [textView.text stringByReplacingOccurrencesOfString:self.taxUtil.localeSeparator
                                                                 withString:self.taxUtil.localeDecimal];
    }
    
    // Double comma input validtion no matter the scenario
    NSArray *textCommaComponents = [textView.text componentsSeparatedByString:self.taxUtil.localeDecimal];
    BOOL textHasMultipleCommas = textCommaComponents.count > 2;
    if (textHasMultipleCommas)
    {
        // Strip the last one
        [textView bumpRightToLeft];
        textView.text = [NSString stringWithFormat:@"%@%@%@", textCommaComponents[0], self.taxUtil.localeDecimal, textCommaComponents[1]];
    }
    
    if ([self.taxUtil stringNumbersSeparatorsOnly:textView.text].length >= MAXIMUM_VALID_TAX_RATE_STRING_LENGTH)
    {
        [UIFeedbackGenerator playFeedbackOfType:SSHapticFeedbackTypeWarning];
        [self.taxRateTextView bumpRightToLeft];
    }
    
    NSString *inputString = [self.taxUtil taxStringForManualEntryFromString:textView.text];
    self.taxRateTextView.text = inputString;
    self.taxRateTextView.selectedRange = [self.taxUtil selectedRangeFromInput:self.taxRateTextView.text];
    self.doneBarButtonItem.enabled = [self.taxUtil stringIsValidTaxRate:self.taxRateTextView.text];
}

@end
