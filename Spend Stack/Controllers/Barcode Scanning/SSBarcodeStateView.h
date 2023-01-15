//
//  SSBarcodeFoundSearchResultView.h
//  Spend Stack
//
//  Created by Jordan Morgan on 11/8/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SSBarcodeSearchResult;

typedef NS_ENUM(NSUInteger, SSBarcodeSearchLayoutState) {
    SSBarcodeSearchLayoutStateAwaitingScan,
    SSBarcodeSearchLayoutStateSearching,
    SSBarcodeSearchLayoutStateResultFound,
    SSBarcodeSearchLayoutStateNoResults,
    SSBarcodeSearchLayoutEncounteredError
};

@interface SSBarcodeStateView : UIView

@property (copy, nullable) void (^onAddToList)(void);
@property (copy, nullable) void (^onEnterPrice)(void);
@property (copy, nullable) void (^onRetry)(void);
@property (nonatomic) SSBarcodeSearchLayoutState layoutState;
- (void)showSearchResult:(SSBarcodeSearchResult * _Nonnull)result;
- (void)updateAddPriceButtonText:(NSDecimalNumber * _Nullable)price;
- (void)performBlurIn;

@end
