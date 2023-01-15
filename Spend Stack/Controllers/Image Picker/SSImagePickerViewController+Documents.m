//
//  SSImagePickerViewController+Documents.m
//  Spend Stack
//
//  Created by Jordan Morgan on 3/19/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "SSImagePickerViewController+Documents.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@implementation SSImagePickerViewController (Documents)

#pragma mark - Public

- (void)presentDocumentPicker
{
    UIDocumentPickerViewController *picker;
    
    if (@available(iOS 14.0, *)) {
        picker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[UTTypeImage]];
    } else {
        picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.image"] inMode:UIDocumentPickerModeImport];
    }

    picker.delegate = self;
    picker.modalPresentationStyle = UIModalPresentationOverFullScreen;

    if (self.isiPad == NO)
    {
        ((SSNavigationController *)self.navigationController).preferBlackStatusBar = YES;
        
        [picker.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            [self.navigationController setNeedsStatusBarAppearanceUpdate];
        } completion:nil];
    }
    
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - Doc Picker Methods/Delegate

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller
{
    ((SSNavigationController *)self.navigationController).preferBlackStatusBar = NO;
    [self.navigationController setNeedsStatusBarAppearanceUpdate];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls
{
    if (@available(iOS 14.0, *)) {
        [self handleDocumentSelectionWithURL:urls.firstObject];
    } else {
        if (controller.documentPickerMode == UIDocumentPickerModeImport) {
            [self handleDocumentSelectionWithURL:urls.firstObject];
        }
    }
}

- (void)handleDocumentSelectionWithURL:(NSURL *)url
{
    NSData *assetData = [NSData dataWithContentsOfURL:url];
    UIImage *img = [UIImage imageWithData:assetData];
    [self.delegate didSelectImage:img];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
