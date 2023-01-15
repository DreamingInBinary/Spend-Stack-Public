//
//  UIImageView+SSUtils.m
//  Spend Stack
//
//  Created by Jordan Morgan on 11/17/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "UIImageView+SSUtils.h"
#import "UIView+SSShimmer.h"
#import <objc/runtime.h>

static const NSInteger SS_LOADING_ICON_SIZE = 80;

@interface UIImageView()

@property (strong, nonatomic, nullable) UIImageView *loadingIconImageView;

@end

@implementation UIImageView (SSUtils)

#pragma mark - Getters/Setters

static char const * SSLoadingIconPropertyKey = "SSLoadingIconPropertyKey";

- (UIImageView *)loadingIconImageView
{
    return objc_getAssociatedObject(self, SSLoadingIconPropertyKey);
}

- (void)setLoadingIconImageView:(UIImageView *)loadingIconImageView
{
    objc_setAssociatedObject(self, SSLoadingIconPropertyKey, loadingIconImageView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Public Methods

+ (CGFloat)squareIconImageViewSize
{
    return [SSCitizenship accessibilityFontsEnabled] ? 64 : 32;
}

+ (UIImageView *)sqaureIconImageView
{
    UIImageView *imgView = [UIImageView new];
    imgView = [UIImageView new];
    imgView.isAccessibilityElement = NO;
    imgView.clipsToBounds = YES;
    imgView.layer.cornerRadius = SSSpacingMargin;
    imgView.backgroundColor = [UIColor grayColor];
    imgView.contentMode = UIViewContentModeCenter;
    imgView.tintColor = [UIColor whiteColor];
    
    return imgView;
}

- (void)addLoadingShimmer
{
    UIImage *loadingIcon = [[[UIImage systemImageNamed:@"photo.fill"]
                             imageScaledToSize:CGSizeMake(SS_LOADING_ICON_SIZE, SS_LOADING_ICON_SIZE)]
                            imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.loadingIconImageView = [[UIImageView alloc] initWithImage:loadingIcon];
    self.loadingIconImageView.tintColor = [UIColor ssTextPlaceholderColor];
    self.loadingIconImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:self.loadingIconImageView];
    
    [self.loadingIconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.and.height.equalTo(@(SS_LOADING_ICON_SIZE));
        make.centerX.equalTo(self.mas_centerX);
        make.centerY.equalTo(self.mas_centerY);
    }];
    
    [self.loadingIconImageView startShimmering];
}

- (void)removeLoadingShimmer
{
    [self.loadingIconImageView endShimmering];
    [self.loadingIconImageView removeFromSuperview];
    self.loadingIconImageView = nil;
}

@end
