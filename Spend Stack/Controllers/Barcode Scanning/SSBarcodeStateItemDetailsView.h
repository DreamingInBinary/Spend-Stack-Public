//
//  SSBarcodeStateITemDetailsView.h
//  Spend Stack
//
//  Created by Jordan Morgan on 11/15/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SSBarcodeSearchResult;

@interface SSBarcodeStateItemDetailsView : UIView

@property (copy, nullable) void (^onEnterPrice)(void);
- (instancetype _Nonnull)initWithSearchResult:(SSBarcodeSearchResult * _Nonnull)result;
- (void)updateButtonText:(NSDecimalNumber * _Nullable)price;

@end
