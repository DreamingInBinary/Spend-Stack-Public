//
//  SSListItemDateTableViewCell.m
//  Spend Stack
//
//  Created by Jordan Morgan on 6/4/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

#import "SSListItemDateTableViewCell.h"
#import "SSListItemTableControllerAdapter.h"
#import "UIView+Animations.h"
#import "Spend_Stack_2-Swift.h"

@interface SSListItemDateTableViewCell()

@property (strong, nonatomic, nonnull) SSLabel *leftTitleLabel;
@property (strong, nonatomic, nonnull) SSLabel *editDateLabel;
@property (strong, nonatomic, nonnull) NSDateFormatter *dateFormatter;

@end

@implementation SSListItemDateTableViewCell

#pragma mark - Initializers

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self)
    {
        self.leftTitleLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleBody];
        [self.leftTitleLabel configureFontWeight:UIFontWeightMedium];
        self.leftTitleLabel.text = ss_Localized(@"listEdit.date");
        
        self.editDateLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleBody];
        self.editDateLabel.userInteractionEnabled = YES;
        self.editDateLabel.accessibilityTraits = UIAccessibilityTraitButton;
        self.editDateLabel.text = @"-";
        self.editDateLabel.textColor = [UIColor ssPrimaryColor];
        self.editDateLabel.textAlignment = NSTextAlignmentRight;
        [self.editDateLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(presentDateEditor:)]];
        [self.editDateLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [self.editDateLabel configureFontWeight:UIFontWeightMedium];
        
        self.dateFormatter = [NSDateFormatter new];
        self.dateFormatter.locale = [NSLocale currentLocale];
        self.dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        
        [self.contentView addSubviews:@[self.leftTitleLabel, self.editDateLabel]];

        [self setConstraints];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangePreferredContentSize:) name:UIContentSizeCategoryDidChangeNotification object:nil];
    }
    
    return self;
}

#pragma mark - Constraint Handling

- (void)didChangePreferredContentSize:(NSNotification *)note
{
    [self setConstraints];
}

- (void)setConstraints
{
    [super setConstraints];
    
    BOOL isAccessibility = [SSCitizenship accessibilityFontsEnabled];
    
    self.editDateLabel.textAlignment = isAccessibility ? NSTextAlignmentNatural : NSTextAlignmentRight;
    
    if (isAccessibility)
    {
        [self.leftTitleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentView.mas_leadingMargin);
            make.top.equalTo(self.contentView.mas_top).with.offset(SSTopBigElementMargin);
            make.trailing.equalTo(self.contentView.mas_trailingMargin);
        }];

        [self.editDateLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentView.mas_leadingMargin);
            make.top.equalTo(self.leftTitleLabel.mas_bottom).with.offset(SSBottomElementMargin);
            make.trailing.equalTo(self.contentView.mas_trailingMargin);
            make.bottom.equalTo(self.dividerView.mas_top).with.offset(SSBottomBigElementMargin);
        }];
    }
    else
    {
        [self.leftTitleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentView.mas_leadingMargin);
            make.top.equalTo(self.contentView.mas_top).with.offset(SSTopBigElementMargin);
            make.bottom.equalTo(self.dividerView.mas_top).with.offset(SSBottomBigElementMargin);
        }];
        
        [self.editDateLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(self.contentView.mas_trailingMargin);
            make.left.equalTo(self.leftTitleLabel.mas_right).with.offset(SSLeftElementMargin);
            make.centerY.equalTo(self.leftTitleLabel.mas_centerY);
        }];
    }
}

#pragma mark - Date Editing

- (void)presentDateEditor:(UITapGestureRecognizer *)sender
{
    [UIFeedbackGenerator playFeedbackOfType:SSHapticFeedbackTypeStyleLight];
    [self.editDateLabel dimInFromTapAnimationWithHighlight:SSSpacingMargin];
    __weak typeof(self) weakSelf = self;
    self.editDateLabel.onAnimationFinished = ^{
        DateEditorViewController *dateVC = [[DateEditorViewController alloc] initWithListItem:weakSelf.listItem onDimiss:^(NSDate *date) {
            weakSelf.listItem.customDate = date;
            
            NSIndexPath *dateIDP = [NSIndexPath indexPathForRow:2
                                                      inSection:SECTION_NAME_TAX_DATE];
            [weakSelf.containingTableView reloadRowsAtIndexPaths:@[dateIDP]
                                                withRowAnimation:UITableViewRowAnimationAutomatic];
        }];
        
        __kindof UINavigationController *navVC;
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
        {
            navVC = [[SSNavigationController alloc] initWithRootViewController:dateVC];
            
            navVC.popoverPresentationController.sourceView = weakSelf.editDateLabel;
            navVC.modalPresentationStyle = UIModalPresentationPopover;
            navVC.popoverPresentationController.sourceView = weakSelf.contentView;
            navVC.popoverPresentationController.sourceRect = CGRectMake(weakSelf.editDateLabel.ss_x, weakSelf.contentView.boundsHeight/2, 0, 0);
            navVC.preferredContentSize = CGSizeMake(380, 380);
            navVC.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionRight;
        }
        else
        {
            navVC = [[SSBottomNavigationViewController alloc] initWithRootViewController:dateVC];
            ((SSBottomNavigationViewController *)navVC).fixedHeight = 380;
        }
        
        [weakSelf.closestViewController presentViewController:navVC animated:YES completion:nil];
    };
}

#pragma mark - Public Methods

- (void)setData:(SSListItem *)item list:(SSList * _Nonnull)list
{
    [super setData:item list:list];
    self.editDateLabel.text = item.customDate ? [self.dateFormatter stringFromDate:item.customDate] : ss_Localized(@"listEdit.setDate");
}

@end
