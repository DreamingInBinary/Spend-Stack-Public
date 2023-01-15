//
//  SSListItemViewController+Camera.h
//  Spend Stack
//
//  Created by Jordan Morgan on 9/25/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

#import "SSListItemViewController.h"
#import <PhotosUI/PhotosUI.h>

@interface SSListItemViewController (Camera) <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

- (void)presentCamera;

@end
