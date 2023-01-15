//
//  SSSyncLabelView.m
//  Spend Stack
//
//  Created by Jordan Morgan on 12/30/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSSyncLabelView.h"

@interface SSSyncLabelView()

@property (strong, nonatomic, nonnull) SSLabel *label;
@property (strong, nonatomic, nonnull) UIActivityIndicatorView *spinnerView;
@property (strong, nonatomic, nonnull) UIView *containerView;

@end

@implementation SSSyncLabelView

#pragma mark - Initializer

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.containerView = [UIView new];
        self.spinnerView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        
        self.label = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleCaption1];
        self.label.maximumFontSize = 20.0f;
        self.label.text = @"Downloading Shared List...";
        
        [self.containerView addSubviews:@[self.spinnerView, self.label]];
        [self addSubview:self.containerView];
        
        [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
        }];
        
        [self.spinnerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.containerView.mas_centerY);
            make.left.equalTo(self.containerView.mas_left);
        }];
        
        [self.label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.containerView.mas_centerY);
            make.left.equalTo(self.spinnerView.mas_right).with.offset(SSLeftElementMargin);
            make.right.equalTo(self.containerView.mas_right);
        }];
        
        [self setSyncLabelToPreAnimationState];
        
        self.userInteractionEnabled = false;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(showSyncingLabel)
                                                     name:SS_CK_MANAGER_ACCEPTING_SHARE
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(hideSyncingLabel)
                                                     name:SS_CK_MANAGER_ACCEPTED_SHARE
                                                   object:nil];
    }
    
    return self;
}

#pragma mark - Private

- (void)setSyncLabelToPreAnimationState
{
    self.label.alpha = 0.0f;
    self.label.transform = CGAffineTransformMakeScale(0.8f, 0.8f);
    self.spinnerView.transform = CGAffineTransformMakeScale(0.8f, 0.8f);
    self.hidden = YES;
    [self.spinnerView stopAnimating];
}

#pragma mark - Public

- (void)showSyncingLabel
{
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, @"Downloading Shared List");

    dispatch_async(dispatch_get_main_queue(), ^ {
        self.hidden = NO;
        [self.spinnerView startAnimating];

        // Pre animation state
        self.label.alpha = 0.0f;
        self.label.transform = CGAffineTransformMakeScale(0.8f, 0.8f);
        self.spinnerView.transform = CGAffineTransformMakeScale(0.8f, 0.8f);
        
        [UIView animateWithDuration:SSFastAnimationDuration delay:0.0f options:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionBeginFromCurrentState animations:^{
            self.label.alpha = 1.0f;
            self.label.transform = CGAffineTransformIdentity;
            self.spinnerView.transform = CGAffineTransformIdentity;
        } completion:nil];
    });
}

- (void)hideSyncingLabel
{
    dispatch_async(dispatch_get_main_queue(), ^ {
        [UIView animateWithDuration:SSFastAnimationDuration delay:0.0f options:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionBeginFromCurrentState animations:^{
            self.label.alpha = 0.0f;
            self.label.transform = CGAffineTransformMakeScale(0.8f, 0.8f);
            self.spinnerView.transform = CGAffineTransformMakeScale(0.8f, 0.8f);
        } completion:^(BOOL finished) {
            if (finished)
            {
                self.hidden = YES;
                [self.spinnerView stopAnimating];
            }
        }];
    });
}

- (void)updateBackgroundColor:(UIColor *)color
{
    self.containerView.backgroundColor = color;
    self.backgroundColor = color;
    self.label.backgroundColor = color;
}

@end
