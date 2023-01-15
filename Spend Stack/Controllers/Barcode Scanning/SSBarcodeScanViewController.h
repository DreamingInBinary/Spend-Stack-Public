//
//  SSBarcodeScanViewController.h
//  Spend Stack
//
//  Created by Jordan Morgan on 10/11/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSBaseViewController.h"
#import "SSBarcodeSearchResult.h"

@protocol SSBarcodeScanViewControllerDelegate <NSObject>

- (void)ss_requestBarcodeResultAddToList:(SSBarcodeSearchResult * _Nonnull)result controller:(UIViewController * _Nonnull)controller;

@end

@interface SSBarcodeScanViewController : SSBaseViewController

+ (instancetype _Nullable)new NS_UNAVAILABLE;
- (instancetype _Nullable)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithDelegate:(id <SSBarcodeScanViewControllerDelegate> _Nullable)delegate NS_DESIGNATED_INITIALIZER;

@end
