//
//  SSBarCodeDimmingView.h
//  Spend Stack
//
//  Created by Jordan Morgan on 11/9/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SSBarCodeDimmingView : UIView

@property (nonatomic) CGRect cutOutFrame;
@property (nonatomic, getter=shouldCloseCutOut) BOOL closeCutOut;

@end

NS_ASSUME_NONNULL_END
