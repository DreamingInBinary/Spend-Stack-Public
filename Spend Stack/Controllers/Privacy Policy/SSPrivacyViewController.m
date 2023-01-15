//
//  SSPrivacyViewController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 4/25/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "SSPrivacyViewController.h"
#import "EmailSender.h"

@interface SSPrivacyViewController ()

@property (strong, nonatomic, nonnull) EmailSender *emailer;

@end

@implementation SSPrivacyViewController

#pragma mark - Initializer

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.emailer = [[EmailSender alloc] initWithContainingController:self];
        self.view.backgroundColor = [UIColor systemBackgroundColor];
        UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissController)];
        self.navigationItem.rightBarButtonItem = done;
        
        SSVerticalView *verticalView = [[SSVerticalView alloc] initWithSecondaryBackgroundColor];
        verticalView.separatorHeight = 1.0f;
        verticalView.showsVerticalScrollIndicator = NO;
        [self.view addSubview:verticalView];
        [verticalView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
            make.left.equalTo(self.view.mas_leftMargin);
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).with.offset(SSBottomBigElementMargin);
            make.right.equalTo(self.view.mas_rightMargin).with.offset(SSRightElementMargin);
        }];
        
        UIEdgeInsets nextSectionInset = UIEdgeInsetsMake(SSTopJumboElementMargin, verticalView.rowInset.left, verticalView.rowInset.bottom, verticalView.rowInset.right);
        UIEdgeInsets textHeaderInset = UIEdgeInsetsMake(SSTopElementMargin, verticalView.rowInset.left, verticalView.rowInset.bottom, verticalView.rowInset.right);
        
        SSLabel *header = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleTitle1];
        header.text = ss_Localized(@"privacy.vc.title");
        [header configureFontWeight:UIFontWeightHeavy];
        [verticalView addRow:header animated:NO];
        
        // Location Data
        SSLabel *locationHeader = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleTitle3];
        locationHeader.text = ss_Localized(@"privacy.vc.subhead1");
        [locationHeader configureFontWeight:UIFontWeightBold];
        [verticalView addRow:locationHeader animated:NO];
        [verticalView setInsetForRow:locationHeader inset:nextSectionInset];
        
        SSLabel *locationText = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleBody];
        locationText.text = ss_Localized(@"privacy.vc.explain1");
        [verticalView addRow:locationText animated:NO];
        [verticalView setInsetForRow:locationText inset:textHeaderInset];
        
        // Debugging Data
        SSLabel *debuggingHeader = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleTitle3];
        debuggingHeader.text = ss_Localized(@"privacy.vc.subhead2");
        [debuggingHeader configureFontWeight:UIFontWeightBold];
        [verticalView addRow:debuggingHeader animated:NO];
        [verticalView setInsetForRow:debuggingHeader inset:nextSectionInset];
        
        SSLabel *debuggingText = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleBody];
        debuggingText.text = ss_Localized(@"privacy.vc.explain2");
        [verticalView addRow:debuggingText animated:NO];
        [verticalView setInsetForRow:debuggingText inset:textHeaderInset];
        
        // Personal Data
        SSLabel *personalDataHeader = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleTitle3];
        personalDataHeader.text = ss_Localized(@"privacy.vc.subhead3");
        [personalDataHeader configureFontWeight:UIFontWeightBold];
        [verticalView addRow:personalDataHeader animated:NO];
        [verticalView setInsetForRow:personalDataHeader inset:nextSectionInset];
        
        SSLabel *personalDataText = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleBody];
        personalDataText.text = ss_Localized(@"privacy.vc.explain3");
        [verticalView addRow:personalDataText animated:NO];
        [verticalView setInsetForRow:personalDataText inset:textHeaderInset];
        
        // Questions Data
        SSLabel *questionsHeader = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleTitle3];
        questionsHeader.text = ss_Localized(@"privacy.vc.question");
        [questionsHeader configureFontWeight:UIFontWeightBold];
        [verticalView addRow:questionsHeader animated:NO];
        [verticalView setInsetForRow:questionsHeader inset:nextSectionInset];
        
        SSLabel *questionsText = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleBody];
        questionsText.text = ss_Localized(@"privacy.vc.contact");
        [verticalView addRow:questionsText animated:NO];
        [verticalView setInsetForRow:questionsText inset:textHeaderInset];
        
        SSButton *button = [[SSButton alloc] initWithText:ss_Localized(@"general.contactUs")];
        [button addTarget:self action:@selector(sendEmail) forControlEvents:UIControlEventTouchUpInside];
        [verticalView addRow:button animated:NO];
        
        [verticalView hideSeparatorForRows:@[locationHeader, locationText,
                                             debuggingHeader, debuggingText,
                                             personalDataHeader, personalDataText,
                                             questionsHeader, questionsText, button]];
    }
    
    return self;
}

- (void)sendEmail
{
    [self.emailer sendSupportEmail];
}

@end
