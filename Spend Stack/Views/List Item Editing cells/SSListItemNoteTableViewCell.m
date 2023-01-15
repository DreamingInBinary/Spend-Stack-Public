//
//  SSListItemNoteTableViewCell.m
//  Spend Stack
//
//  Created by Jordan Morgan on 2/22/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSListItemNoteTableViewCell.h"
#import "IQKeyboardManager.h"

@interface SSListItemNoteTableViewCell() <UITextViewDelegate>

@property (strong, nonatomic, nonnull) SSTextView *textView;

@end

@implementation SSListItemNoteTableViewCell

#pragma mark - Initializers

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self)
    {
        self.textView = [[SSTextView alloc] initWithTextStyle:UIFontTextStyleBody];
        self.textView.delegate = self;
        self.textView.scrollEnabled = NO;
        self.textView.selectable = YES;
        self.textView.placeholderText = ss_Localized(@"listEdit.note");
        self.textView.dataDetectorTypes = UIDataDetectorTypeAll;
        
        // iPads have their own dismiss keyboard button
        if ([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad)
        {
            SSToolbar *tb = [[SSToolbar alloc] initWithItemTypes:@[SSToolBarItemTypeFlexSpace, SSToolBarItemTypeKeyboardDown]];
            __weak SSListItemNoteTableViewCell *weakSelf = self;
            tb.onKeyboardDown = ^{
                [weakSelf.textView resignFirstResponder];
            };
            tb.clipsToBounds = NO;
            self.textView.inputAccessoryView = tb;
        }
        
        self.textView.keyboardDistanceFromTextField = SSSpacingJumboMargin;
        
        [self.contentView addSubview:self.textView];
        
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
    
    [self.textView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.contentView.mas_leadingMargin);
        make.top.equalTo(self.contentView.mas_top).with.offset(SSTopBigElementMargin);
        make.trailing.equalTo(self.contentView.mas_trailingMargin);
        make.bottom.equalTo(self.dividerView.mas_top).with.offset(SSBottomBigElementMargin);
    }];
}

#pragma mark - Textview Delegate

- (void)textViewDidChange:(UITextView *)textView
{
    if ([textView isEqual:self.textView])
    {
        [textView sizeToFit];
        [[self containingTableView] beginUpdates];
        [[self containingTableView] endUpdates];
        self.listItem.notes = textView.text;
        
        dispatch_async(dispatch_get_main_queue(), ^ {
            [[IQKeyboardManager sharedManager] reloadLayoutIfNeeded];
        });
    }
}

#pragma mark - Public Methods

- (void)setData:(SSListItem *)item list:(SSList * _Nonnull)list
{
    [super setData:item list:list];
    self.textView.text = item.notes;
    self.textView.autocapitalizationType = UITextAutocapitalizationTypeSentences;
}

- (void)markTextViewAsFirstResponder
{
    [self.textView becomeFirstResponder];
}

@end
