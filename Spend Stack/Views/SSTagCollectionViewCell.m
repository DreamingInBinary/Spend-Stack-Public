//
//  SSTagCollectionViewCell.m
//  Spend Stack
//
//  Created by Jordan Morgan on 2/25/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSTagCollectionViewCell.h"
#import "UICollectionViewCell+Common.h"

@interface SSTagCollectionViewCell()

@property (strong, nonatomic, nonnull) SSLabel *tagLabel;
@property (strong, nonatomic, nonnull) UIView *tagView;
@property (strong, nonatomic, nonnull) UIImageView *selectedBadgeImageView;
@property (strong, nonatomic, nonnull) UIView *dividerView;

@end

@implementation SSTagCollectionViewCell

#pragma mark - Initializer

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.tagView = [UIView new];
        self.tagView.clipsToBounds = YES;
        self.selectedBackgroundView = [UIView new];
        self.selectedBackgroundView.backgroundColor = [UIColor colorWithRed:112.0/255.0 green:162.0/255.0 blue:249.0/255.0 alpha:0.3];
        
        self.tagLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleCallout];
        self.tagLabel.text = @"";
        self.tagLabel.maximumFontSize = 16.0f;
        self.tagLabel.numberOfLines = 1;
        [self.tagLabel configureFontWeight:UIFontWeightMedium];
        [self.tagLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        
        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:8 weight:UIImageSymbolWeightBold];
        UIImage *img = [UIImage systemImageNamed:@"checkmark" withConfiguration:config];
        self.selectedBadgeImageView = [[UIImageView alloc] initWithImage:img];
        self.selectedBadgeImageView.tintColor = [UIColor systemBackgroundColor];
        self.selectedBadgeImageView.hidden = YES;
        self.selectedBadgeImageView.clipsToBounds = YES;
        self.selectedBadgeImageView.contentMode = UIViewContentModeScaleAspectFit;
        
        [self.contentView addSubviews:@[self.tagView,
                                        self.tagLabel,
                                        self.selectedBadgeImageView]];
        
        [self setConstraints];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.selectedBackgroundView.layer.cornerRadius = 4.0f;
    self.selectedBackgroundView.frame = CGRectInset(self.contentView.frame, 2, 6);
}


#pragma mark - Collection View Cell API

- (void)setSelected:(BOOL)selected
{
    [super setHighlighted:selected];
    
    if (selected)
    {
        self.selectedBadgeImageView.hidden = NO;
    }
    else
    {
        self.selectedBadgeImageView.hidden = YES;
    }
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    
    if (highlighted)
    {
        self.selectedBadgeImageView.hidden = NO;
    }
    else
    {
        self.selectedBadgeImageView.hidden = YES;
    }
}

#pragma mark - Constraint Handling

- (void)didChangePreferredContentSize:(NSNotification *)note
{
    [self setConstraints];
}

- (void)setConstraints
{
    NSNumber *tagSize = @(18);
    self.tagView.layer.cornerRadius = tagSize.integerValue/2;
    self.selectedBadgeImageView.layer.cornerRadius = self.tagView.layer.cornerRadius;
    
    [self.tagView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView.mas_left).with.offset(SSLeftElementMargin);
        make.width.and.height.equalTo(tagSize);
        make.centerY.equalTo(self.contentView.mas_centerY);
    }];
    
    [self.tagLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tagView.mas_right).with.offset(SSLeftElementMargin);
        make.height.equalTo(self.contentView.mas_height);
        make.centerY.equalTo(self.contentView.mas_centerY);
        make.right.equalTo(self.contentView.mas_right);
    }];
    
    [self.selectedBadgeImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.and.width.equalTo(@(12));
        make.centerX.equalTo(self.tagView.mas_centerX).with.offset(0.15f);
        make.centerY.equalTo(self.tagView.mas_centerY).with.offset(-0.35f);
    }];
}

#pragma mark - Public Methods

- (void)setData:(SSTagSelectionViewModel *)tag
{
    self.tagLabel.text = tag.name;
    self.tagView.backgroundColor = [SSTag rawColorFromColor:tag.color];
}

@end
