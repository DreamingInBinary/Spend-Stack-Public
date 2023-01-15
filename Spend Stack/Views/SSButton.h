//
//  SSButton.h
//  Spend Stack
//
//  Created by Jordan Morgan on 1/13/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SSButton : UIButton

@property (nonatomic) CGSize desiredIntrinsicContentSize;

- (instancetype _Nonnull)initWithText:(NSString * _Nonnull)text;
- (instancetype _Nonnull)initWithLabelStyle:(NSString * _Nonnull)text;

- (void)updateLabelText:(NSString * _Nonnull)text;

@end
