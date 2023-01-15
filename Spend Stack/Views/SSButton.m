//
//  SSButton.m
//  Spend Stack
//
//  Created by Jordan Morgan on 1/13/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "SSButton.h"

static const NSInteger BORDER_RADIUS = 8.0f;

@interface SSButton()

@property (strong, nonatomic, nonnull) SSLabel *customLabel;
@property (nonatomic, getter=isUsingLabelStyle) BOOL usingLabelStyle;

@end

@implementation SSButton

#pragma mark - Initializers

- (instancetype)initWithText:(NSString *)text;
{
    self = [super init];
    
    if (self)
    {
        self.desiredIntrinsicContentSize = CGSizeZero;
        self.backgroundColor = [UIColor ssPrimaryColor];
        self.layer.cornerRadius = BORDER_RADIUS;
        self.customLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleBody];
        [self.customLabel configureFontWeight:UIFontWeightBold];
        self.customLabel.textColor = [UIColor whiteColor];
        self.customLabel.textAlignment = NSTextAlignmentCenter;
        self.customLabel.text = text;
        [self addSubview:self.customLabel];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                selector:@selector(didChangePreferredContentSize:)
                                                     name:UIContentSizeCategoryDidChangeNotification
                                                   object:nil];
        
        [self.customLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
    }
    
    return self;
}

- (instancetype)initWithLabelStyle:(NSString *)text
{
    self = [self initWithText:text];
    
    if (self)
    {
        self.usingLabelStyle = YES;
        self.desiredIntrinsicContentSize = CGSizeZero;
        self.backgroundColor = [UIColor clearColor];
        self.layer.cornerRadius = 0.0f;
        
        [self.customLabel removeFromSuperview];
        
        self.customLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleCaption2];
        [self.customLabel configureFontWeight:UIFontWeightBold];
        self.customLabel.textColor = [UIColor ssPrimaryColor];
        self.customLabel.textAlignment = NSTextAlignmentCenter;
        self.customLabel.text = text;
        [self addSubview:self.customLabel];

        [self.customLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
    }
    
    return self;
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    if (self.isUsingLabelStyle)
    {
        self.customLabel.textColor = highlighted ? [UIColor ssTextPlaceholderColor] : [UIColor ssPrimaryColor];
        return;
    }
    self.customLabel.textColor = highlighted ? [UIColor ssPrimaryColor] : [UIColor systemBackgroundColor];
    self.backgroundColor = highlighted ? [UIColor ssControlHighlightedColor] : [UIColor ssPrimaryColor];
}

#pragma mark - Public Methods

- (void)updateLabelText:(NSString *)text
{
    self.customLabel.text = text;
}

#pragma mark - Sizing

- (CGSize)intrinsicContentSize
{
    return CGSizeEqualToSize(self.desiredIntrinsicContentSize, CGSizeZero) ? CGSizeMake([SSCitizenship accessibilityFontsEnabled] ? 300: 200, 48) : self.desiredIntrinsicContentSize;
}

- (void)didChangePreferredContentSize:(NSNotification *)note
{
    [self.titleLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
}

@end
