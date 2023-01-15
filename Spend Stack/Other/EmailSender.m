//
//  EmailSender.m
//  Spend Stack
//
//  Created by Jordan Morgan on 4/12/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "EmailSender.h"
#import "TwitterLinkOpener.h"
#import <MessageUI/MessageUI.h>
#import <UIKit/UIKit.h>

@interface EmailSender() <MFMailComposeViewControllerDelegate>

@property (weak, nonatomic, nullable) UIViewController *containingController;

@end

@implementation EmailSender

#pragma mark - Initializer

- (instancetype)initWithContainingController:(UIViewController *)controller
{
    self = [super init];
    
    if (self)
    {
        self.containingController = controller;
    }
    
    return self;
}

#pragma mark - Email Logic

- (void)sendSupportEmail
{
    [self sendEmailWithSubjectLine:@"Spend Stack Question"];
}

- (void)sendTranslationSuggestion
{
    [self sendEmailWithSubjectLine:[NSString stringWithFormat:@"Spend Stack: Translation Improvement for %@", [NSLocale currentLocale].countryCode]];
}

- (void)sendEmailWithSubjectLine:(NSString *)subjectLine
{
    if ([MFMailComposeViewController canSendMail] == NO)
    {
        UIAlertAction *acOk = [UIAlertAction actionWithTitle:ss_Localized(@"general.ok") style:UIAlertActionStyleDefault handler:nil];
        UIAlertAction *acCopy = [UIAlertAction actionWithTitle:ss_Localized(@"email.copy") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[UIPasteboard generalPasteboard] setString:@"hi@spendstack.com"];
        }];
        UIAlertAction *twitterContact = [UIAlertAction actionWithTitle:ss_Localized(@"email.twitter") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [TwitterLinkOpener openSpendStackTwitter];
        }];
        
        [self.containingController showAlertControllerWithTitle:ss_Localized(@"email.client") message:ss_Localized(@"email.noClient") actions:@[acOk, acCopy, twitterContact]];
        
        return;
    }
    
    MFMailComposeViewController* composeVC = [MFMailComposeViewController new];
    composeVC.view.tintColor = [UIColor ssPrimaryColor];
    composeVC.mailComposeDelegate = self;
    
    [composeVC setToRecipients:@[@"hi@spendstack.com"]];
    [composeVC setSubject:subjectLine];
    [composeVC setMessageBody:[@"\n\n\n\n\n\n\n\n\n\n\n" stringByAppendingFormat:@"Device: %@\niOS Version: %@\nSpend Stack Version:%@\nSpend Stack Build:%@", ss_deviceName(), [[UIDevice currentDevice] systemVersion], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey]] isHTML:NO];
    
    [self.containingController presentViewController:composeVC animated:YES completion:nil];
}

#pragma mark - Private

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultSent:
            // Email sent
            break;
        case MFMailComposeResultSaved:
            // Email saved
            break;
        case MFMailComposeResultCancelled:
            // Handle cancelling of the email
            break;
        case MFMailComposeResultFailed:
            // Handle failure to send.
            break;
        default:
            //A failure occurred while completing the email
            break;
    }
    
    if (controller.navigationController.viewControllers.count > 1)
    {
        [controller.navigationController popViewControllerAnimated:YES];
    }
    else
    {
        [controller dismissViewControllerAnimated:YES completion:NULL];
    }
}

@end
