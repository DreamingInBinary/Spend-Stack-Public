//
//  SSSyncLabelView.h
//  Spend Stack
//
//  Created by Jordan Morgan on 12/30/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SSSyncLabelView : UIView

// These should fire automatically, but for debugging they are public.
- (void)showSyncingLabel;
- (void)hideSyncingLabel;
- (void)updateBackgroundColor:(UIColor * _Nonnull)color;

@end

NS_ASSUME_NONNULL_END
