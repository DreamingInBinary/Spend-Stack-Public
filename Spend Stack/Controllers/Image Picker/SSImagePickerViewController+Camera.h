//
//  SSImagePickerViewController+Camera.h
//  Spend Stack
//
//  Created by Jordan Morgan on 3/18/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "SSImagePickerViewController.h"
#import <PhotosUI/PhotosUI.h>

@interface SSImagePickerViewController (Camera) <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

- (void)presentCamera;

@end
