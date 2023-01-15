//
//  SSCellStackView.m
//  Spend Stack
//
//  Created by Jordan Morgan on 9/12/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSCellStackView.h"
#import "UITableViewCell+Common.h"

@interface SSCellStackView()

@property (strong, nonatomic, nonnull) UIStackView *stackView;
@property (strong, nonatomic, nonnull) SSLabel *leadingLabel;
@property (strong, nonatomic, nonnull) SSLabel *trailingLabel;
@property (strong, nonatomic, nonnull) UIView *dividerView;

@end

@implementation SSCellStackView

#pragma mark - Initializers

- (instancetype)initWithLeadingText:(NSString *)leadingText trailingText:(NSString *)trailingText
{
    self = [super init];
    
    if (self)
    {
        self.stackView = [self itemInfoStackViewWithLeadingText:leadingText trailingText:trailingText];
        self.dividerView = [self createDividerView];
        [self addSubviews:@[self.stackView, self.dividerView]];
        
        [self configureForContentSize];
        [self setConstraints];
        
        self.isAccessibilityElement = YES;
        self.stackView.isAccessibilityElement = NO;
        for (UIView *subview in self.subviews)
        {
            subview.isAccessibilityElement = NO;
        }
        
        self.accessibilityLabel = [NSString stringWithFormat:@"%@ %@", leadingText, trailingText];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(configureForContentSize)
                                                     name:UIContentSizeCategoryDidChangeNotification
                                                   object:nil];
    }
    
    return self;
}

#pragma mark - Layout

- (void)setConstraints
{
    [self.stackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_left).with.offset(SSLeftBigElementMargin);
        make.right.equalTo(self.mas_right).with.offset(SSRightBigElementMargin);
        make.top.equalTo(self.mas_top);
    }];
    
    [self.dividerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_left).with.offset(SSLeftBigElementMargin);
        make.right.equalTo(self.mas_right).with.offset(SSRightBigElementMargin);
        make.top.equalTo(self.stackView.mas_bottom).with.offset(SSTopElementMargin);
        make.height.equalTo(@([UITableViewCell preferredDividerHeight]));
        make.bottom.equalTo(self.mas_bottom).with.offset(SSBottomElementMargin);
    }];
}

#pragma mark - Private Methods

- (void)configureForContentSize
{
    if ([SSCitizenship accessibilityFontsEnabled])
    {
        self.stackView.axis = UILayoutConstraintAxisVertical;
        self.stackView.distribution = UIStackViewDistributionEqualSpacing;
        self.stackView.alignment = UIStackViewAlignmentLeading;
        self.leadingLabel.textAlignment = NSTextAlignmentNatural;
        self.trailingLabel.textAlignment = NSTextAlignmentNatural;
    }
    else
    {
        self.stackView.axis = UILayoutConstraintAxisHorizontal;
        self.stackView.distribution = UIStackViewDistributionFillProportionally;
        self.stackView.alignment = UIStackViewAlignmentCenter;
        self.leadingLabel.textAlignment = NSTextAlignmentNatural;
        self.trailingLabel.textAlignment = NSTextAlignmentRight;
    }
    
    [self.dividerView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_left).with.offset(SSLeftBigElementMargin);
        make.right.equalTo(self.mas_right).with.offset(SSRightBigElementMargin);
        make.top.equalTo(self.stackView.mas_bottom).with.offset(SSTopElementMargin);
        make.height.equalTo(@([UITableViewCell preferredDividerHeight]));
        make.bottom.equalTo(self.mas_bottom).with.offset(SSBottomElementMargin);
    }];
}

- (UIStackView *)itemInfoStackViewWithLeadingText:(NSString *)leadingText trailingText:(NSString *)trailingText
{
    UIStackView *stackView = [UIStackView new];
    stackView.spacing = SSSpacingMargin;
    
    // Leading
    self.leadingLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleBody];
    [self.trailingLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.greaterThanOrEqualTo(@100).with.priorityHigh();
    }];
    self.leadingLabel.text = leadingText;
    [self.leadingLabel configureFontWeight:UIFontWeightMedium];
    [self.leadingLabel sizeToFit];
    [stackView addArrangedSubview:self.leadingLabel];
    
    // Trailing
    self.trailingLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleBody];
    self.trailingLabel.text = trailingText;
    self.trailingLabel.textColor = [UIColor ssSecondaryColor];
    [stackView addArrangedSubview:self.trailingLabel];

    return stackView;
}

- (UIView *)createDividerView
{
    UIView *dividerView = [UIView new];
    dividerView.isAccessibilityElement = NO;
    dividerView.backgroundColor = [UIColor ssMutedColor];
    
    return dividerView;
}

@end
