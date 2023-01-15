//
//  SSImagePickerViewController.h
//  Spend Stack
//
//  Created by Jordan Morgan on 6/25/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSModalCardViewController.h"
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

@protocol SSImagePickerViewControllerDelegate <NSObject>

- (void)didSelectAsset:(PHAsset * _Nonnull)asset;
- (void)didSelectImage:(UIImage * _Nonnull)image;

@end

@interface SSImagePickerViewController : SSModalCardViewController

@property (strong, nonatomic, readonly, nonnull) SSToolbar *tb;
@property (weak, nonatomic, readonly, nullable) id <SSImagePickerViewControllerDelegate> delegate;

+ (instancetype _Nullable)new NS_UNAVAILABLE;
- (instancetype _Nullable)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithDelegate:(id <SSImagePickerViewControllerDelegate> _Nonnull)delegate NS_DESIGNATED_INITIALIZER;

@end

