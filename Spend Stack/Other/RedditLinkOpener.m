
//
//  RedditLinkOpener.m
//  Spend Stack
//
//  Created by Jordan Morgan on 9/3/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "RedditLinkOpener.h"

@implementation RedditLinkOpener

+ (void)openSpendStackReddit
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.reddit.com/r/SpendStack/new/"] options:@{} completionHandler:^(BOOL success) {
        
    }];
    
    /*
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"reddit://"]])
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"reddit://r=spendstack"]] options:@{} completionHandler:^(BOOL success) {
            
        }];
    }
    else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"apollo://"]])
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"apollo://r/spendstack"]] options:@{} completionHandler:^(BOOL success) {
            
        }];
    }
    else
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.reddit.com/r/SpendStack/new/"] options:@{} completionHandler:^(BOOL success) {
            
        }];
    }
     */
}

@end
