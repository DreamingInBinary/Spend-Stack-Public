//
//  SSImagePickerViewController+Documents.h
//  Spend Stack
//
//  Created by Jordan Morgan on 3/19/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "SSImagePickerViewController.h"

@interface SSImagePickerViewController (Documents) <UIDocumentPickerDelegate>

- (void)presentDocumentPicker;

@end
