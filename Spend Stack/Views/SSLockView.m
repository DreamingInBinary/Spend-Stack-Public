//
//  SSLockView.m
//  Spend Stack
//
//  Created by Jordan Morgan on 7/22/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSLockView.h"
#import "NSString+SSUtils.h"
#import "LAContext+Utils.h"
#import <LocalAuthentication/LocalAuthentication.h>

@interface SSLockView()

@property (strong, nonatomic, nonnull) LAContext *ctx;
@property (weak, nonatomic, nullable) UIViewController *parentController;
@property (strong, nonatomic, nonnull) UIImageView *lockImageView;
@property (strong, nonatomic, nonnull) SSLabel *lockLabel;
@property (strong, nonatomic, nonnull) SSButton *performAuthButton;
@property (strong, nonatomic, nonnull) UIStackView *contentStackView;

@end

@implementation SSLockView

- (instancetype)initWithContainingController:(__kindof UIViewController *)controller
{
    self = [super initWithFrame:CGRectZero];
    
    if (self)
    {
        self.ctx = [LAContext new];
        self.parentController = controller;
        
        [SSCitizenship setViewAsTransparentIfPossible:self];
        
        self.lockImageView = [[UIImageView alloc] initWithImage:[[UIImage systemImageNamed:@"lock.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        self.lockImageView.accessibilityIgnoresInvertColors = YES;
        self.lockImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.lockImageView.tintColor = [UIColor ssOppositeSystemBackgroundColor];
        
        [self.lockImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.and.width.equalTo(@64);
        }];
        
        self.lockLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleTitle3];
        [self.lockLabel configureFontWeight:UIFontWeightSemibold];
        self.lockLabel.text = @"List is Locked.";
        self.lockLabel.textAlignment = NSTextAlignmentCenter;
        
        self.performAuthButton = [[SSButton alloc] initWithText:@"Unlock"];
        [self.performAuthButton addTarget:self action:@selector(performAuthChallenge) forControlEvents:UIControlEventTouchUpInside];
        
        self.contentStackView = [[UIStackView alloc] initWithArrangedSubviews:@[self.lockImageView, self.lockLabel, self.performAuthButton]];
        self.contentStackView.alignment = UIStackViewAlignmentCenter;
        self.contentStackView.spacing = SSSpacingBigMargin;
                
        [self addSubview:self.contentStackView];
        [self configureStackViewConstraintsAndAxis];
    }
    
    return self;
}

- (void)configureStackViewConstraintsAndAxis
{
    UILayoutConstraintAxis desiredAxis = [self isLandscape] ? UILayoutConstraintAxisHorizontal : UILayoutConstraintAxisVertical;
    UILayoutConstraintAxis currentAxis = self.contentStackView.axis;
    
    if (currentAxis != desiredAxis)
    {
        CGFloat textWidth = [self.lockLabel.text boundingRectWithWidth:self.ss_width text:self.lockLabel.text font:self.lockLabel.font].size.width;
        
        // Ensure the stack view doesn't crunch it down in landscape
        [self.lockLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.width.greaterThanOrEqualTo(@(textWidth));
        }];
        
        self.contentStackView.axis = desiredAxis;
        
        [self.contentStackView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.mas_centerX);
            make.centerY.equalTo(self.mas_centerY);
            
            if (desiredAxis == UILayoutConstraintAxisVertical)
            {
                make.width.equalTo(self.mas_width).with.insets(UIEdgeInsetsMake(0, SSLeftBigElementMargin, 0, SSRightBigElementMargin));
                make.height.equalTo(self.contentStackView.mas_height);
            }
            else
            {
                make.width.greaterThanOrEqualTo(self.contentStackView.mas_width);
                make.height.equalTo(self.mas_height).with.insets(UIEdgeInsetsMake(SSTopBigElementMargin, 0, SSTopBigElementMargin, 0));;
            }
         }];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self configureStackViewConstraintsAndAxis];
}

#pragma mark - Public Methods

- (void)performAuthChallenge
{
    [self.ctx evaluatePolicy:LAPolicyDeviceOwnerAuthentication localizedReason:@"Unlock your list." reply:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            if (success)
            {
                self.lockImageView.image = [[UIImage systemImageNamed:@"lock.open.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                [UIView animateWithDuration:SSFastAnimationDuration delay:1 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    self.alpha = 0.0f;
                    self.contentStackView.transform = CGAffineTransformMakeScale(1.2f, 1.2f);
                } completion:^ (BOOL done) {
                    if (self.onDismiss) self.onDismiss();
                }];
            }
            else
            {
                NSString *errorText = [LAContext friendlyErrorStringFromAuthError:error.code];
                if ([errorText isEqualToString:@""] == NO)
                {
                    self.lockLabel.text = errorText;
                }
                
                [self.performAuthButton updateLabelText:ss_Localized(@"lock.try")];
                [UIView animateWithDuration:SSFastAnimationDuration animations:^{
                    self.performAuthButton.hidden = NO;
                }];
                
            }
        });
    }];
}

@end
