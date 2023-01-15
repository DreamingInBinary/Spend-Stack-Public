
//
//  SSMiniTagView.m
//  Spend Stack
//
//  Created by Jordan Morgan on 4/3/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "SSMiniTagView.h"
#import "SSTagSelectionViewModel.h"
#import "UIView+Animations.h"
#import "UIView+SSUtils.h"

@interface SSMiniTagView() <UIPointerInteractionDelegate>

@property (strong, nonatomic, nonnull) SSLabel *tagName;

@end

@implementation SSMiniTagView

#pragma mark - Initializer

- (instancetype)initWithTag:(SSTagSelectionViewModel *)tag
{
    self = [super initWithFrame:CGRectZero];
    
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        self.accessibilityTraits = UIAccessibilityTraitButton;
        self.clipsToBounds = YES;
        
        UIImageView *closeImgView = [[UIImageView alloc] initWithImage:[[UIImage systemImageNamed:@"xmark.circle.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        closeImgView.contentMode = UIViewContentModeScaleAspectFit;
        closeImgView.tintColor = [UIColor systemBackgroundColor];
        closeImgView.isAccessibilityElement = NO;
        
        self.tagName = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleCaption2];
        self.tagName.isAccessibilityElement = NO;
        self.tagName.maximumFontSize = 18.0f;
        self.tagName.textColor = [UIColor systemBackgroundColor];
        [self.tagName configureFontWeight:UIFontWeightSemibold];
        [self.tagName setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        
        [self addSubviews:@[closeImgView, self.tagName]];
        
        [closeImgView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.and.height.equalTo(@22);
            make.leading.equalTo(self.mas_leading).with.offset(SSLeftElementMargin);
            make.bottom.equalTo(self.mas_bottom).with.offset(-4);
            make.top.equalTo(self.mas_top).with.offset(4);
        }];
        
        [self.tagName mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(closeImgView.mas_trailing).with.offset(4);
            make.trailing.equalTo(self.mas_trailing).with.offset(SSRightElementMargin);
            make.centerY.equalTo(self.mas_centerY);
            make.height.and.width.equalTo(self.tagName);
        }];
        
        [self mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.greaterThanOrEqualTo(self.tagName.mas_height);
            make.width.greaterThanOrEqualTo(self.tagName.mas_width);
        }];
        
        if (tag)
        {
            [self showTag:tag];
        }
        
        self.alpha = 0.75f;
        
        UITapGestureRecognizer *tapToRemove = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
        tapToRemove.numberOfTapsRequired = 1;
        
        [self addGestureRecognizer:tapToRemove];
        
        [self addPointerInteractionWithDelegate:self];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.layer.cornerRadius = self.boundsHeight/2;
}

#pragma mark - Pointer Interaction Delegate

- (nullable UIPointerStyle *)pointerInteraction:(UIPointerInteraction *)interaction styleForRegion:(UIPointerRegion *)region API_AVAILABLE(ios(13.4))
{
    if (interaction.view == nil) return nil;
    
    UITargetedPreview *targetedPreview = [[UITargetedPreview alloc] initWithView:interaction.view];
    
    UIPointerLiftEffect *hover = [UIPointerLiftEffect effectWithPreview:targetedPreview];
    UIPointerStyle *pointerStyle = [UIPointerStyle styleWithEffect:hover
                                                             shape:nil];
    return pointerStyle;
}

#pragma mark - Tap Handler

- (void)handleTap
{
    __weak typeof(self) weakSelf = self;
    self.onAnimationFinished = ^{
        if (weakSelf.onMiniTagViewTapped) {
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                weakSelf.hidden = YES;
                weakSelf.onMiniTagViewTapped();
            });
            
        }
    };
    [self bobble];
}

#pragma mark - Public Methods

- (void)showTag:(SSTagSelectionViewModel *)tag
{
    self.hidden = NO;
    self.backgroundColor = [SSTag rawColorFromColor:tag.color];
    self.tagName.text = tag.name;
    
    self.accessibilityLabel = self.tagName.text;
    self.accessibilityHint = @"Tap to remove this tag from item";
}

@end
