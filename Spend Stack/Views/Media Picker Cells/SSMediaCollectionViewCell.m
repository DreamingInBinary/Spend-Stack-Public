//
//  SSMediaCollectionViewCell.m
//  Spend Stack
//
//  Created by Jordan Morgan on 3/14/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "SSMediaCollectionViewCell.h"
#import <Photos/Photos.h>

@interface SSMediaCollectionViewCell()

@property (strong, nonatomic, nonnull) UIImageView *imageView;
@property (strong, nonatomic, nonnull) UIImageView *livePhotoBadgeImageView;

@end

@implementation SSMediaCollectionViewCell

#pragma mark - Custom Getters/Setters

- (void)setImage:(UIImage *)image
{
    _imageView.image = image;
}

- (UIImage *)image
{
    return _imageView.image;
}

#pragma mark - Initializers

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.clipsToBounds = YES;
        self.layer.cornerRadius = SSSpacingMargin;
        self.imageView = [[UIImageView alloc] initWithFrame:frame];
        self.imageView.clipsToBounds = YES;
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentView addSubview:self.imageView];
        [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView);
        }];
        
        self.contentView.backgroundColor = [UIColor ssMutedColor];
        self.imageView.backgroundColor = self.contentView.backgroundColor;
        self.accessibilityTraits = UIAccessibilityTraitButton;
        self.accessibilityHint = @"Tap to add this photo to your item.";
    }
    
    return self;
}

- (void)setupAccessibility
{
    self.accessibilityElements = @[self.imageView];
}

#pragma mark - Collection View Cell Overrides

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.imageView.image = nil;
    self.livePhotoBadgeImageView.image = nil;
}

@end
