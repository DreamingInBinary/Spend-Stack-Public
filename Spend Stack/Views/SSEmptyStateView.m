//
//  SSEmptyStateView.m
//  Spend Stack
//
//  Created by Jordan Morgan on 1/2/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "SSEmptyStateView.h"
#import "SSConstants.h"

@interface SSEmptyStateView()

@property (strong, nonatomic, nonnull) SSLabel * stateLabel;
@property (strong, nonatomic, nullable) SSButton *button;
@property (copy) void (^ _Nullable onButtonTapped)(void);

@end

@implementation SSEmptyStateView

#pragma mark - Initializer

- (instancetype _Nonnull)initWithStateText:(NSString * _Nonnull)text;
{
    self = [self initWithStateText:text performAnimaton:YES];
    return self;
}

- (instancetype)initWithStateText:(NSString *)text performAnimaton:(BOOL)animate
{
    self = [super init];
    
    if (self)
    {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.stateLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleTitle2];
        self.stateLabel.textAlignment = NSTextAlignmentCenter;
        self.stateLabel.textColor = [UIColor ssSecondaryColor];
        self.stateLabel.text = text;
        self.stateLabel.backgroundColor = [UIColor clearColor];
        self.stateLabel.userInteractionEnabled = NO;
        
        [self addSubview:self.stateLabel];

        [self.stateLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;
        [self.stateLabel.leadingAnchor constraintEqualToAnchor:self.readableContentGuide.leadingAnchor constant:SSLeftElementMargin].active = YES;
        [self.stateLabel.trailingAnchor constraintEqualToAnchor:self.readableContentGuide.trailingAnchor constant:SSRightElementMargin].active = YES;
        
        if (animate) [self performAnimation];
    }
    
    return self;
}

- (instancetype _Nonnull)initWithStateText:(NSString * _Nonnull)text buttonText:(NSString * _Nonnull)buttonText handler:(void (^ _Nonnull)(void))handler;
{
    self = [super init];
    
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        self.onButtonTapped = handler;

        self.stateLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleTitle2];
        self.stateLabel.textAlignment = NSTextAlignmentCenter;
        self.stateLabel.textColor = [UIColor ssSecondaryColor];
        self.stateLabel.text = text;
        [self.stateLabel sizeToFit];
        
        self.button = [[SSButton alloc] initWithLabelStyle:buttonText];
        self.button.desiredIntrinsicContentSize = CGSizeMake(100, 44);
        [self.button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
   
        UIView *containerView = [UIView new];
        [containerView addSubviews:@[self.stateLabel, self.button]];
        [self addSubview:containerView];
        
        [containerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.mas_centerX);
            make.centerY.equalTo(self.mas_centerY);
            make.width.and.height.equalTo(containerView);
        }];
        
        [self.stateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(containerView.mas_centerX);
            make.top.equalTo(containerView.mas_top);
            make.width.and.height.equalTo(self.stateLabel);
        }];
        
        [self.button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(containerView.mas_centerX);
            make.top.equalTo(self.stateLabel.mas_bottom);
            make.bottom.equalTo(containerView.mas_bottom);
            make.width.and.height.equalTo(self.button);
        }];
        
        [self performAnimation];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    if (self.superview != nil)
    {
        self.backgroundColor = self.superview.backgroundColor;
    }
}

#pragma mark - Button

- (void)buttonTapped:(SSButton *)button
{
    if (self.onButtonTapped) self.onButtonTapped();
}

#pragma mark - Blurring

- (void)performAnimation
{
    for (UIView *subview in self.subviews)
    {
        subview.alpha = 0.0f;
        subview.transform = CGAffineTransformMakeScale(0.8, 0.8);
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:SSFastestAnimationDuration delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
            for (UIView *subview in self.subviews)
            {
                subview.alpha = 1.0f;
                subview.transform = CGAffineTransformIdentity;
            }
        } completion:nil];
    });
}

@end
