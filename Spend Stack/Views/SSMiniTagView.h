//
//  SSMiniTagView.h
//  Spend Stack
//
//  Created by Jordan Morgan on 4/3/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SSTagSelectionViewModel;

@interface SSMiniTagView : UIView

@property (copy) void (^ _Nullable onMiniTagViewTapped)(void);
- (instancetype _Nonnull)initWithTag:(SSTagSelectionViewModel * _Nullable)tag;

- (void)showTag:(SSTagSelectionViewModel * _Nonnull)tag;

@end
