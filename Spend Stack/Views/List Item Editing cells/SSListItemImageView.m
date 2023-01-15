//
//  SSListItemImageView.m
//  Spend Stack
//
//  Created by Jordan Morgan on 6/1/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSListItemImageView.h"

@interface SSListItemImageView()

@property (copy, nullable, readwrite) SSListItemImageViewTapHandler tapHandler;

@end

@implementation SSListItemImageView

#pragma mark - Initializer

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.accessibilityIgnoresInvertColors = YES;
    }
    
    return self;
}

#pragma mark - Public Methods

- (void)configureImageViewForTapHandler:(SSListItemImageViewTapHandler)handler
{
    if ([SSCitizenship voiceOverOn]) return;
    
    self.tapHandler = handler;
    self.accessibilityHint = ss_Localized(@"listEdit.image.acc");
    UITapGestureRecognizer *tapToPerformHandler = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                          action:@selector(performOnTap)];
    self.userInteractionEnabled = YES;
    [self addGestureRecognizer:tapToPerformHandler];
}

#pragma mark - Tap Handling

- (void)performOnTap
{
    self.tapHandler();
}

@end
