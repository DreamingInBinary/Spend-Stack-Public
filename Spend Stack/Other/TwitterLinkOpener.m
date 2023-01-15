//
//  TwitterLinkOpener.m
//  Spend Stack
//
//  Created by Jordan Morgan on 12/30/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "TwitterLinkOpener.h"

@implementation TwitterLinkOpener

+ (void)openSpendStackTwitter
{
    [TwitterLinkOpener openTwitterHandle:@"spendstackapp"];
}

+ (void)openJordansTwitter
{
    [TwitterLinkOpener openTwitterHandle:@"jordanmorgan10"];
}

+ (void)openTwitterHandle:(NSString *)handle
{
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetbot://"]])
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tweetbot:///user_profile/%@", handle]] options:@{} completionHandler:^(BOOL success) {
            
        }];
    }
    else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]])
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"twitter://user?screen_name=" stringByAppendingString:handle]] options:@{} completionHandler:^(BOOL success) {
            
        }];
    }
    else
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"https://twitter.com/" stringByAppendingString:handle]] options:@{} completionHandler:^(BOOL success) {
            
        }];
    }
}

@end
