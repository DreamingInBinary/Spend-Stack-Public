//
//  SSHeaderCollectionReusableView.h
//  Spend Stack
//
//  Created by Jordan Morgan on 7/2/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString * _Nonnull const SS_HEADER_ID = @"ssHeaderID";

@interface SSHeaderCollectionReusableView : UICollectionReusableView

@property (strong, nonatomic, readonly, nonnull) SSLabel *label;
+ (CGSize)estimatedSizeHeaderInView:(UIView * _Nonnull)view withText:(NSString * _Nonnull)text;

@end
