//
//  SSLIstItemEntryTableViewCell.m
//  Spend Stack
//
//  Created by Jordan Morgan on 2/17/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSListItemEntryTableViewCell.h"
#import "SSBaseListItemEditingTableViewCell.h"
#import "SSConstants.h"

@interface SSListItemEntryTableViewCell()

@property (strong, nonatomic, nonnull) SSTextField *textField;

@end

@implementation SSListItemEntryTableViewCell

#pragma mark - Initializers

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self)
    {
        self.textField = [[SSTextField alloc] initWithTextStyle:UIFontTextStyleBody];
        self.textField.clearButtonMode = UITextFieldViewModeAlways;
        self.textField.placeholder = ss_Localized(@"quickAdd.empty");
        
        // iPads have their own dismiss keyboard button
        if ([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad)
        {
            SSToolbar *tb = [[SSToolbar alloc] initWithItemTypes:@[SSToolBarItemTypeFlexSpace, SSToolBarItemTypeKeyboardDown]];
            __weak SSListItemEntryTableViewCell *weakSelf = self;
            tb.onKeyboardDown = ^{
                [weakSelf.textField resignFirstResponder];
            };
            tb.clipsToBounds = NO;
            
            self.textField.inputAccessoryView = tb;
        }
        
        [self.contentView addSubviews:@[self.textField]];
        
        [self setConstraints];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangePreferredContentSize:) name:UIContentSizeCategoryDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChangeNotification:) name:UITextFieldTextDidChangeNotification object:self.textField];
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
    
    [self.textField mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.contentView.mas_leadingMargin);
        make.top.equalTo(self.contentView.mas_top).with.offset(SSTopElementMargin);
        make.bottom.equalTo(self.dividerView.mas_top).with.offset(SSBottomBigElementMargin);
        make.trailing.equalTo(self.contentView.mas_trailingMargin);
    }];
}

#pragma mark - Item Model Mutation

- (void)textFieldDidChangeNotification:(NSNotification *)note
{
    SSTextField *changedTextField = note.object;
    
    if ([changedTextField isKindOfClass:[SSTextField class]] == NO) return;
    self.listItem.title = changedTextField.text;
}

#pragma mark - Public Methods

- (void)setData:(SSListItem *)item list:(SSList * _Nonnull)list
{
    [super setData:item list:list];
    self.textField.text = item.title;
    self.textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
}

@end
