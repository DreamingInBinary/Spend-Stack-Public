//
//  UITextField+NegativeInput.h
//  Spend Stack
//
//  Created by Jordan Morgan on 7/28/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UITextField (NegativeInput)

@property (nonatomic) BOOL enteringNegativeNumber;
- (void)toggleTextForNegativeInputChange;
- (void)prefixNegativeSignToText;

@end

NS_ASSUME_NONNULL_END
