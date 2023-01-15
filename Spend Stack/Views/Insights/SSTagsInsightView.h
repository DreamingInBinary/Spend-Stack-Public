//
//  SSTagsInsightView.h
//  Spend Stack
//
//  Created by Jordan Morgan on 9/4/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SSTagsInsightView : UIView

- (instancetype)initWithList:(SSList * _Nullable)list frame:(CGRect)frame;

@end

@interface SSTagsInsightLegendView : UIView

@property (strong, nonatomic, nonnull) UIView *dotView;
@property (strong, nonatomic, nonnull) SSLabel *tagLabel;
@property (nonatomic, readonly) CGFloat tagSize;

@end


NS_ASSUME_NONNULL_END
