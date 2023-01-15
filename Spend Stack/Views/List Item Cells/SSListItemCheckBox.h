//
//  SSListItemCheckBox.h
//  Spend Stack
//
//  Created by Jordan Morgan on 5/31/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SSListItemCheckBoxDelegate <NSObject>

- (NSArray <UIView *> * _Nonnull)viewsToExcludeDuringCheckAnimation;
- (UIView * _Nonnull)parentContentView;

@end

@interface SSListItemCheckBox : UIView

@property (weak, nonatomic, nullable) id <SSListItemCheckBoxDelegate> delegate;
@property (strong, nonatomic, readonly, nonnull) UIImageView *checkbox;
@property (nonatomic, readonly, getter=isChecked) BOOL checked;
@property (nonatomic, getter=isCheckHandlerEnabled) BOOL checkHandlerEnabled;
@property (copy) void (^ _Nullable onCheck)(BOOL isChecked);

- (void)toggleChecked:(BOOL)checked;
- (void)setHightlightedSelected:(BOOL)highlightedOrSelected;

@end
