//
//  EmailSender.h
//  Spend Stack
//
//  Created by Jordan Morgan on 4/12/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>
@class UIViewController;

@interface EmailSender : NSObject

- (instancetype _Nonnull)initWithContainingController:(UIViewController * _Nonnull)controller;
- (void)sendSupportEmail;
- (void)sendTranslationSuggestion;

@end
