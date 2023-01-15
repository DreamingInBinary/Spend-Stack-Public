//
//  SSBarcodeFoundSearchResultView.m
//  Spend Stack
//
//  Created by Jordan Morgan on 11/8/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSBarcodeStateView.h"
#import "SSBarcodeStateItemDetailsView.h"
#import "SSBarcodeSearchResult.h"
#import "SSImageDownloader.h"

@interface SSBarcodeStateView()

@property (strong, nonatomic, nonnull) SSVerticalView *stackView;
@property (strong, nonatomic, nonnull) UIActivityIndicatorView *spinnerView;
@property (strong, nonatomic, nonnull) SSLabel *stateLabel;
@property (strong, nonatomic, nonnull) SSBarcodeStateItemDetailsView *detailsView;
@property (strong, nonatomic, nonnull) SSButton *addToListButton;
@property (strong, nonatomic, nonnull) SSButton *scanAgainButton;
@property (strong, nonatomic, nonnull) SSTextField *enterPriceTextField;
@property (weak, nonatomic, nullable) SSBarcodeSearchResult *result;

@end

@implementation SSBarcodeStateView

#pragma mark - Custom Getters

- (UIActivityIndicatorView *)spinnerView
{
    if(!_spinnerView)
    {
        _spinnerView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        [_spinnerView startAnimating];
    }
    
    return _spinnerView;
}

- (SSButton *)addToListButton
{
    if (!_addToListButton)
    {
        _addToListButton = [[SSButton alloc] initWithText:@"Add to List"];
        [_addToListButton addTarget:self action:@selector(performOnButtonPress) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _addToListButton;
}

- (SSButton *)scanAgainButton
{
    if (!_scanAgainButton)
    {
        _scanAgainButton = [[SSButton alloc] initWithLabelStyle:@"Try Again"];
        [_scanAgainButton addTarget:self action:@selector(tryAgain) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _scanAgainButton;
}

#pragma mark - Custom Setter

- (void)setLayoutState:(SSBarcodeSearchLayoutState)layoutState
{
    _layoutState = layoutState;
    [self updateViewState];
}

#pragma mark - Initializers

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        _layoutState = SSBarcodeSearchLayoutStateAwaitingScan;
        self.backgroundColor = [UIColor systemBackgroundColor];
        
        if ([self.window.rootViewController isNotch])
        {
            [self notchifyCornerRadius];
        }
        else
        {
            self.clipsToBounds = YES;
            self.layer.cornerRadius = SSSpacingMargin;
        }
        
        [self addVerticalViewToView];
        [self addStateLabelToView];
        
        // If we aren't in low power, do the blur in animation
        if ([SSCitizenship lowPowerOn] == NO)
        {
            self.stateLabel.alpha = 0.0f;
        }
    }
    
    return self;
}

#pragma mark - View Lifecycle

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Take care of showing the hint label in the correct orientation
    if (self.layoutState == SSBarcodeSearchLayoutStateAwaitingScan)
    {
        self.stateLabel.text = [self.superview isLandscape] ? @"Line up a barcode to the right to search for it." : @"Line up a barcode above to search for it.";
    }
}

#pragma mark - UI Creation

- (void)updateViewState
{
    // Remove spinner if we aren't searching
    if (self.layoutState != SSBarcodeSearchLayoutStateSearching)
    {
        [self.stackView removeRow:self.spinnerView animated:YES];
    }
    
    if (self.layoutState == SSBarcodeSearchLayoutStateAwaitingScan)
    {
        if ([self.stackView containsRow:self.scanAgainButton])
        {
            [self.stackView removeRow:self.scanAgainButton animated:YES];
        }
        
        self.stateLabel.text = @"Line up a barcode above to search for it.";
    }
    else if (self.layoutState == SSBarcodeSearchLayoutStateSearching)
    {
        self.stateLabel.text = @"Searching...";
        [self.stackView prependRow:self.spinnerView animated:YES];
        [self.stackView setInsetForRow:self.spinnerView inset:UIEdgeInsetsMake(SSTopBigElementMargin, 0, 0, 0)];
    }
    else if (self.layoutState == SSBarcodeSearchLayoutStateNoResults)
    {
        self.stateLabel.text = @"We didn't find anything for this barcode.";
        [self.stackView addRow:self.scanAgainButton animated:YES];
        [self.stackView setInsetForRow:self.scanAgainButton inset:UIEdgeInsetsMake(SSTopBigElementMargin, 0, 0, 0)];
    }
    else if (self.layoutState == SSBarcodeSearchLayoutStateResultFound)
    {
        self.stateLabel.text = @"Searching...";
        
        if ([self.stackView containsRow:self.stateLabel] == NO)
        {
            [self.stackView removeRow:self.stateLabel animated:NO];
        }
        
        if ([self.stackView containsRow:self.detailsView] == NO)
        {
            [self.stackView addRow:self.detailsView animated:NO];
        }
        
        if ([self.stackView containsRow:self.addToListButton] == NO)
        {
            [self.stackView addRow:self.addToListButton animated:NO];
            [self.stackView setInsetForRow:self.addToListButton inset:UIEdgeInsetsMake(SSTopJumboElementMargin, 0, 0, 0)];
        }
    }
    else if (self.layoutState == SSBarcodeSearchLayoutEncounteredError)
    {
        [self.stackView removeAllRows:NO];
        [self.stackView addRow:self.stateLabel animated:NO];
        [self.stackView setInsetForRow:self.stateLabel inset:UIEdgeInsetsMake(SSTopJumboElementMargin, SSLeftBigElementMargin, 0, SSRightBigElementMargin)];
        self.stateLabel.alpha = 1.0f; // May have been hidden for animation
        self.stateLabel.text = @"We ran into an issue starting your camera.\nPlease contact support if this continues.";
    }
}

- (void)addVerticalViewToView
{
    self.stackView = [SSVerticalView new];
    self.stackView.rowInset = UIEdgeInsetsZero;
    self.stackView.hidesSeparatorsByDefault = YES;
    [self addSubview:self.stackView];
    
    [self.stackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_top);
        make.left.equalTo(self.mas_readableContentGuideLeft).with.offset(SSLeftBigElementMargin);
        make.right.equalTo(self.mas_readableContentGuideRight).with.offset(SSRightBigElementMargin);
        make.bottom.equalTo(self.mas_bottom);
    }];
}

- (void)addStateLabelToView
{
    self.stateLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleCaption1];
    self.stateLabel.textAlignment = NSTextAlignmentCenter;
    [self.stateLabel configureFontWeight:UIFontWeightBold];
    [self addSubview:self.stateLabel];
    
    [self.stackView addRow:self.stateLabel animated:NO];
    [self.stackView setInsetForRow:self.stateLabel inset:UIEdgeInsetsMake(SSTopBigElementMargin, 0, 0, 0)];
}

#pragma mark - Button Presses

- (void)performOnButtonPress
{
    if (self.onAddToList)
    {
        self.onAddToList();
    }
}

- (void)performOnEnterPrice
{
    if (self.onEnterPrice)
    {
        self.onEnterPrice();
    }
}

- (void)tryAgain
{
    self.layoutState = SSBarcodeSearchLayoutStateAwaitingScan;
    if (self.onRetry) self.onRetry();
}

#pragma mark - Public Methods

- (void)showSearchResult:(SSBarcodeSearchResult *)result
{
    self.result = result;
    self.detailsView = [[SSBarcodeStateItemDetailsView alloc] initWithSearchResult:result];
    
    __weak typeof(self) weakSelf = self;
    self.detailsView.onEnterPrice = ^{
        [weakSelf performOnEnterPrice];
    };
    
    self.layoutState = SSBarcodeSearchLayoutStateResultFound;
}

- (void)updateAddPriceButtonText:(NSDecimalNumber *)price
{
    [self.detailsView updateButtonText:price];
}

- (void)performBlurIn
{
    if ([SSCitizenship lowPowerOn] == NO)
    {
        self.layoutState = SSBarcodeSearchLayoutStateAwaitingScan;
        UIView *blurView = [SSCitizenship transparentViewIfPossible];
        blurView.clipsToBounds = self.clipsToBounds;
        blurView.layer.cornerRadius = self.layer.cornerRadius;
        blurView.layer.maskedCorners = self.layer.maskedCorners;
        [self addSubview:blurView];
        [blurView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
        
        CGFloat duration = SSBriefAnimationDuration;
        [UIView animateWithDuration:duration animations:^ {
            [SSCitizenship setViewFadeOutAnimation:blurView];
            
            // Show UI
            self.stateLabel.alpha = 1.0f;
        } completion:^(BOOL finished) {
            if (finished) [blurView removeFromSuperview];
        }];
    }
}

@end
