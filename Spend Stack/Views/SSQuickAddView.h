//
//  SSQuickAddView.h
//  Spend Stack
//
//  Created by Jordan Morgan on 6/5/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SSTagsViewController.h"

static NSString * _Nonnull const ITEM_TITLE_KEY = @"title";
static NSString * _Nonnull const ITEM_AMOUNT_KEY = @"amount";
static NSString * _Nonnull const ITEM_TAG_KEY = @"tag";

@interface SSQuickAddView : UIView <SSTagsViewControllerDelegate>

@property (nonatomic, readonly) double animationDuration;
@property (nonatomic, readonly) UIViewAnimationOptions animationCurve;
@property (nonatomic, readonly, getter=isShowing) BOOL showing;
@property (strong, nonatomic, nullable) UIView *inputAccessoryView;
@property (copy) void (^ _Nullable onDismiss)(void);
@property (nonatomic, getter=isShowingTags) BOOL showingTags;

- (NSDictionary * _Nonnull)itemDataFromInput;
- (void)clearoutUIForMoreInput;
- (void)present:(void (^ _Nonnull)(void))completion;
- (void)hide;
- (void)toggleList:(SSList * _Nonnull)list;
+ (instancetype _Nonnull)new NS_UNAVAILABLE;
- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithList:(SSList * _Nullable)list;

@end
