//
//  SSListItemViewController+Documents.m
//  Spend Stack
//
//  Created by Jordan Morgan on 9/25/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

#import "SSListItemViewController+Documents.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@implementation SSListItemViewController (Documents)

#pragma mark - Public

- (void)presentDocumentPicker
{
    UIDocumentPickerViewController *picker;
    
    if (@available(iOS 14.0, *)) {
        picker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[UTTypeImage] asCopy:YES];
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
        [self handleDocumentSelectionWithURL:urls.firstObject picker:controller];
    } else {
        if (controller.documentPickerMode == UIDocumentPickerModeImport) {
            [self handleDocumentSelectionWithURL:urls.firstObject picker:controller];
        }
    }
}

- (void)handleDocumentSelectionWithURL:(NSURL *)url picker:(UIDocumentPickerViewController *)docPickerVC
{
    NSData *assetData = [NSData dataWithContentsOfURL:url];
    UIImage *img = [UIImage imageWithData:assetData];
    [self didSelectImage:img];
    [docPickerVC dismissViewControllerAnimated:YES completion:nil];
}

@end
