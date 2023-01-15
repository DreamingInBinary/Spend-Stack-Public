//
//  UITextView+NegativeInput.h
//  Spend Stack
//
//  Created by Jordan Morgan on 7/28/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITextView (NegativeInput)

@property (nonatomic) BOOL enteringNegativeNumber;
- (void)toggleTextForNegativeInputChange;
- (void)prefixNegativeSignToText;

@end
