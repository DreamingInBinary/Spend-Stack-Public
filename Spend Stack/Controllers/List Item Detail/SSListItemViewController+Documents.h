//
//  SSListItemViewController+Documents.h
//  Spend Stack
//
//  Created by Jordan Morgan on 9/25/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

#import "SSListItemViewController.h"

@interface SSListItemViewController (Documents) <UIDocumentPickerDelegate>

- (void)presentDocumentPicker;

@end
