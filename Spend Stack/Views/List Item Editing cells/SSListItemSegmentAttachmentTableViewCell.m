//
//  SSListItemSegmentAttachmentTableViewCell.m
//  Spend Stack
//
//  Created by Jordan Morgan on 6/13/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

#import "SSListItemSegmentAttachmentTableViewCell.h"

@interface SSListItemSegmentAttachmentTableViewCell()

@property (strong, nonatomic, nonnull) UISegmentedControl *segment;

@end

@implementation SSListItemSegmentAttachmentTableViewCell

#pragma mark - Initializers

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self)
    {
        self.segment = [[UISegmentedControl alloc] initWithItems:@[ss_Localized(@"listEdit.attachImage"), ss_Localized(@"listEdit.attachLink")]];
        [self.segment addTarget:self action:@selector(handleSegmentChange:) forControlEvents:UIControlEventValueChanged];
        [self.segment setSelectedSegmentIndex:0];
        
        [self.contentView addSubviews:@[self.segment]];
        
        self.dividerView.hidden = YES;
        
        [self setConstraints];
    }
    
    return self;
}

#pragma mark - Constraint Handling

- (void)setConstraints
{
    [super setConstraints];
    
    [self.segment mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.contentView.mas_leadingMargin);
        make.top.equalTo(self.contentView.mas_top).with.offset(SSTopBigElementMargin);
        make.bottom.equalTo(self.dividerView.mas_top).with.offset(SSBottomBigElementMargin);
        make.trailing.equalTo(self.contentView.mas_trailingMargin);
    }];
}

#pragma mark - Segment Handling

- (void)handleSegmentChange:(UISegmentedControl *)sender
{
    [UIFeedbackGenerator playFeedbackOfType:SSHapticFeedbackTypeSelectionChanged];
    AttachmentViewMode viewMode = sender.selectedSegmentIndex;
    [[NSNotificationCenter defaultCenter] postNotificationName:SS_ATTACHMENT_VIEW_MODE_CHANGED object:@(viewMode)];
}

#pragma mark - Public Methods

- (void)setData:(SSListItem *)item list:(SSList * _Nonnull)list
{
    [super setData:item list:list];
}

- (void)setActiveMediaSegmentAtIndex:(NSInteger)index
{
    if (index > self.segment.numberOfSegments) return;
    [self.segment setSelectedSegmentIndex:index];
}

@end
