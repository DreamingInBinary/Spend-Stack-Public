//
//  SSQuickAddView.m
//  Spend Stack
//
//  Created by Jordan Morgan on 6/5/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "SSQuickAddView.h"
#import "SSConstants.h"
#import "SSMiniTagView.h"
#import "SSVerticalViewCell.h"
#import "SSTagSelectionViewModel.h"
#import "UIView+Animations.h"
#import "UIView+SSShimmer.h"
#import "UITextView+NegativeInput.h"

@interface SSQuickAddView() <UITextViewDelegate>

@property (weak, nonatomic, nullable) SSList *list;
@property (strong, nonatomic, nullable) SSTagSelectionViewModel *itemTag;
@property (nonatomic, readwrite) double animationDuration;
@property (nonatomic, readwrite) UIViewAnimationOptions animationCurve;
@property (strong, nonatomic, nonnull) SSVerticalView *verticalView;
@property (strong, nonatomic, nonnull) SSTextView *enterItemTextView;
@property (strong, nonatomic, nonnull) SSMiniTagView *miniTagView; // Not used right now, but keeping in case I want it back
@property (strong, nonatomic, nonnull) UIView *circleTagContainer;
@property (strong, nonatomic, nonnull) SSLabel *circleTagContainerLetter;
@property (strong, nonatomic, nonnull) UIView *miniTagContainer;
@property (strong, nonatomic, nonnull) SSTextView *enterPriceTextView;
@property (strong, nonatomic, nonnull) UIView *dividerView;
@property (strong, nonatomic, nullable) __kindof UIView * dimmingView;
@property (strong, nonatomic, nonnull) NSNumberFormatter *numberFormatter;
@property (strong, nonatomic, nonnull) SSToolbar *tb;
@property (nonatomic, getter=isPresentingKeyboard) BOOL presentingKeyboard;

@end

@implementation SSQuickAddView

#pragma mark - Computed Properties

- (SSToolbar *)tb
{
    return (SSToolbar *)self.inputAccessoryView;
}

#pragma mark - Initializers

- (instancetype)initWithList:(SSList *)list
{
    self = [super init];
    
    if (self)
    {
        __weak typeof(self) weakSelf = self;
        self.list = list;
        self.clipsToBounds = YES;
        self.layer.cornerRadius = 17.0f;
        self.backgroundColor = [UIColor systemBackgroundColor];
        self.alpha = 0.0f;

        self.verticalView = [SSVerticalView new];
        self.verticalView.rowBackgroundColor = [UIColor clearColor];
        self.verticalView.separatorInset = UIEdgeInsetsZero;
        
        self.numberFormatter = [NSNumberFormatter new];
        self.numberFormatter.locale = self.list.taxUtil.currencyLocale;
        self.numberFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
        
        self.enterItemTextView = [[SSTextView alloc] initWithTextStyle:UIFontTextStyleBody];
        self.enterItemTextView.textColor = [UIColor ssTextPlaceholderColor];
        self.enterItemTextView.delegate = self;
        self.enterItemTextView.placeholderText = ss_Localized(@"quickAdd.empty");
        self.enterItemTextView.inputAccessoryView = self.inputAccessoryView;
        self.enterItemTextView.autocapitalizationType = UITextAutocapitalizationTypeWords;
        self.enterItemTextView.returnKeyType = UIReturnKeyDone;
        [self.enterItemTextView setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
        [self.enterItemTextView configureFontWeight:UIFontWeightSemibold];
        
        self.enterPriceTextView = [[SSTextView alloc] initWithTextStyle:UIFontTextStyleBody];
        self.enterPriceTextView.textColor = [UIColor ssTextPlaceholderColor];
        self.enterPriceTextView.keyboardType = UIKeyboardTypeNumberPad;
        
        self.enterPriceTextView.placeholderText = [self.list.taxUtil guranteedCurrencyString:self.list.taxUtil.localizedPlaceholderAmount];
        self.enterPriceTextView.inputAccessoryView = self.inputAccessoryView;
        self.enterPriceTextView.delegate = self;
        [self.enterPriceTextView configureFontWeight:UIFontWeightSemibold];
        
        self.miniTagContainer = [UIView new];
        self.miniTagContainer.backgroundColor = [UIColor clearColor];
        self.miniTagView = [[SSMiniTagView alloc] initWithTag:nil];
        self.miniTagView.onMiniTagViewTapped = ^{
            [weakSelf showMiniTagViewWith:nil];
        };
        [self.miniTagContainer addSubview:self.miniTagView];
        [self.miniTagView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.miniTagContainer.mas_leading);
            make.top.equalTo(self.miniTagContainer.mas_top);
            make.bottom.equalTo(self.miniTagContainer.mas_bottom);
            make.width.equalTo(self.miniTagView.mas_width);
        }];
        
        self.circleTagContainer = [UIView new];
        self.circleTagContainerLetter = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleCaption2];
        self.circleTagContainerLetter.maximumFontSize = 12.0f;
        self.circleTagContainerLetter.text = nil;
        self.circleTagContainerLetter.textAlignment = NSTextAlignmentCenter;
        self.circleTagContainerLetter.textColor = [UIColor whiteColor];
        self.circleTagContainerLetter.layer.cornerRadius = 9.0f;
        self.circleTagContainerLetter.clipsToBounds = YES;
        
        [self.circleTagContainerLetter configureFontWeight:UIFontWeightBold];
        [self.circleTagContainer addSubview:self.circleTagContainerLetter];
        [self.circleTagContainer addSubview:self.enterItemTextView];
        [self showTagCirlecWithTag:nil animated:NO];
        
        [self addSubview:self.verticalView];
        [self.verticalView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
        
        [self.verticalView addRows:@[self.circleTagContainer, self.enterPriceTextView] animated:NO];
        [self addKeyboardNotificationListeners];
        [self setUIAsShowing:NO];
    }
    
    return self;
}

#pragma mark - Nofitications

- (void)addKeyboardNotificationListeners
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(pinToKeyboard:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(pinToBottom:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleTagHorizontalViewTagSelection:)
                                                 name:@"tagViewTagPressed"
                                               object:nil];
}

- (void)removeKeyboardNotificationListeners
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark - Tags Delegate

- (void)onTagSelectionChanged:(SSTagSelectionViewModel *)tag controller:(SSTagsViewController *)controller
{
    [self showMiniTagViewWith:tag];
}

- (NSArray <SSListTag *> *)tagsFromListShare
{
    self.showingTags = YES;
    if (self.list.listIsShared == NO) return @[];
    return [[SSDataStore sharedInstance] queryListTagsSharedToMeForListID:self.list.dbID];
}

- (BOOL)controllerShouldPushTagsManagerWhenPresenting
{
    self.hidden = YES;
    return YES;
}

- (void)tagsControllerWillDismiss:(SSTagSelectionViewModel *)selectedTag
{
    self.hidden = NO;
    self.showingTags = NO;
    [self showMiniTagViewWith:selectedTag];
}

- (void)showMiniTagViewWith:(SSTagSelectionViewModel *)tag
{
    self.itemTag = tag;
    
    if (self.itemTag)
    {
        [self.miniTagView showTag:tag];
        [self.verticalView insertRow:self.miniTagContainer after:self.enterItemTextView animated:YES];
        [self.verticalView setInsetForRow:self.miniTagContainer inset:UIEdgeInsetsMake(0, 16, -16, 16)];
        [self.verticalView hideSeparatorForRow:self.enterItemTextView];
    }
    else
    {
        [self.verticalView removeRow:self.miniTagContainer animated:YES];
        [self.verticalView showSeparatorForRow:self.enterItemTextView];
    }
    
    [self.verticalView hideSeparatorForRow:self.enterPriceTextView];
    
    [self mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.greaterThanOrEqualTo(@(self.verticalView.contentSize.height));
    }];
    
    [UIView animateWithDuration:0.25f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self layoutIfNeeded];
    } completion:nil];
}

- (void)showTagCirlecWithTag:(SSTagSelectionViewModel *)tag animated:(BOOL)animated
{
    self.itemTag = tag;
    
    if (self.itemTag)
    {
        self.circleTagContainerLetter.backgroundColor = [SSTag rawColorFromColor:tag.color];
        self.circleTagContainerLetter.text = [[tag.name substringToIndex:1] capitalizedString];
        
        [self.circleTagContainerLetter mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.height.and.width.equalTo(@18);
            make.left.equalTo(self.circleTagContainer.mas_left);
            make.centerY.equalTo(self.circleTagContainer.mas_centerY);
        }];
        [self.enterItemTextView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.circleTagContainer.mas_top);
            make.bottom.equalTo(self.circleTagContainer.mas_bottom);
            make.left.equalTo(self.circleTagContainerLetter.mas_right).with.offset(SSLeftElementMargin);
            make.right.equalTo(self.circleTagContainer.mas_right).with.offset(SSLeftBigElementMargin);
        }];
    }
    else
    {
        self.circleTagContainerLetter.text = nil;
        
        [self.circleTagContainerLetter mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.height.and.width.equalTo(@0);
            make.left.equalTo(self.circleTagContainer.mas_left);
            make.centerY.equalTo(self.circleTagContainer.mas_centerY);
        }];
        [self.enterItemTextView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.circleTagContainer.mas_top);
            make.bottom.equalTo(self.circleTagContainer.mas_bottom);
            make.left.equalTo(self.circleTagContainerLetter.mas_right);
            make.right.equalTo(self.circleTagContainer.mas_right).with.offset(SSLeftBigElementMargin);
        }];
    }
    
    if (animated)
    {
        [UIView animateWithDuration:0.25f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self.circleTagContainer layoutIfNeeded];
        } completion:nil];
    }
    else
    {
        [self.circleTagContainer layoutIfNeeded];
    }
}

#pragma mark - Tag Selections from TagHorizontalView

- (void)handleTagHorizontalViewTagSelection:(NSNotification *)note
{
    SSTagSelectionViewModel *vm = (SSTagSelectionViewModel *)note.object;
    if (vm) NSAssert([vm isKindOfClass:[SSTagSelectionViewModel class]], @"");
    [self showTagCirlecWithTag:vm animated:YES];
}

#pragma mark - Textview Delegate

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    BOOL isEnteringItem = [textView isEqual:self.enterItemTextView];
    

    if (isEnteringItem)
    {
        [self.tb disableBarItemsAtIndicies:@[@1,@2]];
    }
    else
    {
        [self.tb hideTagView:false];
        [self.tb disableBarItemsAtIndicies:@[@0]];
    }
    
    __weak typeof(self) weakSelf = self;
    
    // Set double zero handler if we haven't yet. This toolbar is actually
    // Created and managed by the presenter so it's a little weird in that it handles
    // Presenter logic, but also internal logic like this.
    if (self.tb.onDoubleZero == nil)
    {
        self.tb.onDoubleZero = ^{
            if (!isEnteringItem) return;
            weakSelf.enterPriceTextView.text = [weakSelf.enterPriceTextView.text stringByAppendingString:@"00"];
            [weakSelf textViewDidChange:weakSelf.enterPriceTextView];
        };
    }
    
    if (self.tb.onPlusMinus == nil)
    {
        self.tb.onPlusMinus = ^{
            if (!isEnteringItem) return;
            weakSelf.enterPriceTextView.enteringNegativeNumber = !weakSelf.enterPriceTextView.enteringNegativeNumber;
        };
    }
    
    if (self.list.taxUtil.localeHasTrailingCurrencyFormat && isEnteringItem == NO)
    {
        textView.selectedTextRange = [self.list.taxUtil selectTextRangeForPriceTextView:textView];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([textView isEqual:self.enterItemTextView])
    {
        if ([text isEqualToString:@"\n"])
        {
            [self hide];
            return NO;
        }
        else
        {
            return YES;
        }
    }
    
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    if ([textView isEqual:self.enterPriceTextView])
    {
        textView.text = [self.list.taxUtil currencyStringFromInput:textView.text];
        
        if (self.list.taxUtil.localeHasTrailingCurrencyFormat)
        {
            textView.selectedTextRange = [self.list.taxUtil selectTextRangeForPriceTextView:textView];
        }
        
        if (textView.enteringNegativeNumber)
        {
            [textView prefixNegativeSignToText];
        }
    }
}

#pragma mark - Keyboard Handling

- (void)pinToKeyboard:(NSNotification *)note
{
    if (self.superview == nil ||
        self.window.isKeyWindow == NO) return;
    
    CGRect frame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect relativeKeyboardRect = [self.superview convertRect:frame fromView:[[UIApplication sharedApplication] delegate].window];
    
    CGFloat bottomOffset = -(CGRectGetHeight(relativeKeyboardRect) + SSSpacingBigMargin);
    
    double animationDuration = ((NSNumber *)note.userInfo[UIKeyboardAnimationDurationUserInfoKey]).doubleValue;
    UIViewAnimationOptions animationCurve = ((NSNumber *)note.userInfo[UIKeyboardAnimationCurveUserInfoKey]).unsignedIntegerValue;
    
    self.animationDuration = animationDuration;
    self.animationCurve = animationCurve | UIViewAnimationOptionBeginFromCurrentState;
    
    UIView *containingView = self.superview;
    
    [self mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(@(bottomOffset));
        make.width.equalTo(containingView.mas_width).multipliedBy(.92f);
        make.centerX.equalTo(containingView.mas_centerX);
        make.height.greaterThanOrEqualTo(@(self.verticalView.contentSize));
    }];
        
    CGFloat alpha = self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ? 0.6 : 0.4f;
    
    [UIView animateWithDuration:self.animationDuration delay:0.0f options:self.animationCurve animations:^ {
        [containingView layoutIfNeeded];
        self.alpha = 1.0f;
        self.dimmingView.alpha = alpha;
    } completion:^(BOOL finished) {
        self.presentingKeyboard = NO;
        self.dimmingView.userInteractionEnabled = YES;
    }];
}

- (void)pinToBottom:(NSNotification *)note
{
    if (self.superview == nil || (self.hidden == NO && ((NSNumber *)note.userInfo[UIKeyboardIsLocalUserInfoKey]).boolValue == NO)) {
        self.dimmingView.alpha = 0.0f;
        self.dimmingView.userInteractionEnabled = NO;
        return;
    }
    
    self.dimmingView.userInteractionEnabled = NO;
    
    double animationDuration = ((NSNumber *)note.userInfo[UIKeyboardAnimationDurationUserInfoKey]).doubleValue;
    UIViewAnimationOptions animationCurve = ((NSNumber *)note.userInfo[UIKeyboardAnimationCurveUserInfoKey]).unsignedIntegerValue;
    
    self.animationDuration = animationDuration;
    self.animationCurve = animationCurve | UIViewAnimationOptionBeginFromCurrentState;
    
    [self mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.superview.mas_bottom).with.offset(self.ss_height);
        make.left.equalTo(self.superview.mas_safeAreaLayoutGuideLeft);
        make.right.equalTo(self.superview.mas_safeAreaLayoutGuideRight);
        make.height.equalTo(self.mas_height);
    }];
    
    [UIView animateWithDuration:self.animationDuration delay:0.0f options:self.animationCurve animations:^ {
        [self.superview layoutIfNeeded];
        self.dimmingView.alpha = 0.0f;
        self.alpha = 0.0f;
    } completion:^(BOOL finished) {
        if (self.isShowingTags == NO)
        {
            [self hide];
        }
    }];
}

#pragma mark - Public Methods

- (NSDictionary *)itemDataFromInput
{
    // Ensure default values
    NSString *amountAsString = @"0";
    if (self.enterPriceTextView.text.length <= 0)
    {
        amountAsString = @"0";
    }
    else
    {
        amountAsString = [self.enterPriceTextView.text stringByReplacingOccurrencesOfString:self.list.taxUtil.currencyLocale.currencySymbol withString:@""];
    }

    NSString *itemTitle = self.enterItemTextView.text.length > 0 ? self.enterItemTextView.text : ss_Localized(@"quickAdd.defaultItem");
    NSDecimalNumber *itemAmount = [self.list.taxUtil priceDecimalFromString:amountAsString];
    
    if (self.itemTag)
    {
        return @{ITEM_TITLE_KEY:itemTitle, ITEM_AMOUNT_KEY:itemAmount, ITEM_TAG_KEY:self.itemTag};
    }
    else
    {
        return @{ITEM_TITLE_KEY:itemTitle, ITEM_AMOUNT_KEY:itemAmount};
    }
}

- (void)clearoutUIForMoreInput
{
    [UIFeedbackGenerator playFeedbackOfType:SSHapticFeedbackTypeStyleLight];
    
    self.enterPriceTextView.enteringNegativeNumber = NO;
    
    __block UIView *fadeOrBlurView = [SSCitizenship transparentViewIfPossible];
    fadeOrBlurView.frame = self.bounds;
    fadeOrBlurView.clipsToBounds = YES;
    fadeOrBlurView.layer.maskedCorners = self.layer.maskedCorners;
    fadeOrBlurView.layer.cornerRadius = self.layer.cornerRadius;
    [SSCitizenship setViewFadeOutAnimation:fadeOrBlurView];
    [self addSubview:fadeOrBlurView];
    
    [UIView animateWithDuration:SSFasterThanFastestAnimationDuration animations:^{
        [SSCitizenship setViewFadeInAnimation:fadeOrBlurView];
        
        self.enterItemTextView.transform = CGAffineTransformMakeScale(0.90, 0.90);
        self.enterItemTextView.alpha = 0.25f;
        
        self.enterPriceTextView.transform = CGAffineTransformMakeScale(0.90, 0.90);
        self.enterPriceTextView.alpha = 0.25f;
    } completion:^(BOOL done) {
        if (done)
        {
            self.enterItemTextView.text = @"";
            self.enterPriceTextView.text = @"";
            
            [UIView animateWithDuration:SSFasterThanFastestAnimationDuration animations:^{
                [SSCitizenship setViewFadeOutAnimation:fadeOrBlurView];
                
                self.enterItemTextView.transform = CGAffineTransformIdentity;
                self.enterItemTextView.alpha = 1.0f;
                
                self.enterPriceTextView.transform = CGAffineTransformIdentity;
                self.enterPriceTextView.alpha = 1.0f;
            } completion:^(BOOL done) {
                if (done)
                {
                    [fadeOrBlurView removeFromSuperview];
                    fadeOrBlurView = nil;
                    [self.enterItemTextView becomeFirstResponder];
                }
            }];
        }
    }];
}

- (void)present:(void (^)(void))completion
{
    [self setUIAsShowing:YES];
    self.presentingKeyboard = YES;
    
    if (!self.dimmingView)
    {
        [self setupDimmingView];
    }
    
    [self.superview bringSubviewToFront:self.dimmingView];
    [self.superview bringSubviewToFront:self];
    
    if (self.enterItemTextView.isFirstResponder)
    {
        [self.enterItemTextView resignFirstResponder];
    }

    if (self.window.isKeyWindow == NO)
    {
        [self.window makeKeyAndVisible];
    }
    
    [self.tb setToolBarItems:@[SSToolBarItemTypeAddCircleTag,
                               SSToolBarItemTypeDoubleZero,
                               SSToolBarItemTypePlusMinus,
                               SSToolBarItemTypeFlexSpace,
                               SSToolBarItemTypeAddItem]];
    
    [self.enterItemTextView becomeFirstResponder];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (completion) completion();
    });
}

- (void)hide
{
    if (self.isPresentingKeyboard) return;
    
    [self setUIAsShowing:NO];
    [self.tb hideTagView:true];
    self.itemTag = nil;
    [self.enterItemTextView resignFirstResponder];
    [self.enterPriceTextView resignFirstResponder];
    
    if (self.onDismiss)
    {
        self.onDismiss();
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self showMiniTagViewWith:nil];
        self.enterItemTextView.text = @"";
        self.enterPriceTextView.text = @"";
        [self showTagCirlecWithTag:nil animated:NO];
        [self removeKeyboardNotificationListeners];
    });
}

- (void)toggleList:(SSList *)list
{
    self.list = list;
     self.enterPriceTextView.placeholderText = [self.list.taxUtil guranteedCurrencyString:self.list.taxUtil.localizedPlaceholderAmount];
    self.numberFormatter.locale = self.list.taxUtil.currencyLocale;
}

#pragma mark - Private Functions

- (void)setUIAsShowing:(BOOL)showing
{
    [self addKeyboardNotificationListeners];
    self.hidden = !showing;
    self.enterItemTextView.hidden = self.hidden;
    self.enterPriceTextView.hidden = self.hidden;
    if (self.enterPriceTextView.hidden)
    {
        self.enterPriceTextView.placeholderText = [self.list.taxUtil guranteedCurrencyString:self.list.taxUtil.localizedPlaceholderAmount];
    }
}

- (void)setupDimmingView
{
    self.dimmingView = [UIView new];
    self.dimmingView.backgroundColor = [UIColor ssDimmingBackgroundColor];
    self.dimmingView.alpha = 0.0f;
    self.dimmingView.userInteractionEnabled = NO;
    
    UITapGestureRecognizer *tapToDismiss = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hide)];
    UISwipeGestureRecognizer *swipeToDismiss = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(hide)];
    swipeToDismiss.direction = UISwipeGestureRecognizerDirectionDown;
    
    [self.dimmingView addGestureRecognizer:swipeToDismiss];
    [self.dimmingView addGestureRecognizer:tapToDismiss];
    
    [self.superview insertSubview:self.dimmingView belowSubview:self];
    self.dimmingView.frame = self.superview.bounds;
    
    [self.dimmingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.superview);
    }];
}

@end
