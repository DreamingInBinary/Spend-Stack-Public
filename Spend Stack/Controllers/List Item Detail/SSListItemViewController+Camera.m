//
//  SSListItemViewController+Camera.m
//  Spend Stack
//
//  Created by Jordan Morgan on 9/25/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

#import "SSListItemViewController+Camera.h"
#import "SSCameraPermissionViewController.h"

@implementation SSListItemViewController (Camera)

- (void)presentCamera
{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    if (authStatus == AVAuthorizationStatusDenied)
    {
        SSCameraPermissionViewController *permissionVC = [SSCameraPermissionViewController new];
        [self presentViewController:permissionVC animated:YES completion:nil];
    }
    else if (authStatus == AVAuthorizationStatusNotDetermined)
    {
        // The user has not yet been presented with the option to grant access to the camera hardware.
        // Ask for permission.
        //
        // (Note: you can test for this case by deleting the app on the device, if already installed).
        // (Note: we need a usage description in our Info.plist to request access.
        //
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if (granted)
            {
                dispatch_async(dispatch_get_main_queue(), ^ {
                    // Show picker
                    [self presentCamraPermissionsGranted];
                });
            }
        }];
    }
    else
    {
        // Allowed access to camera, go ahead and present the UIImagePickerController.
        [self presentCamraPermissionsGranted];
    }
}

#pragma mark - Private

- (void)presentCamraPermissionsGranted
{
    UIImagePickerController *cameraVC = [UIImagePickerController new];
    cameraVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
    cameraVC.sourceType = UIImagePickerControllerSourceTypeCamera;
    cameraVC.allowsEditing = YES;
    cameraVC.delegate = self;
    [self presentViewController:cameraVC animated:YES completion:nil];
}

#pragma mark - Image Picker Delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info
{
    if (info[UIImagePickerControllerPHAsset])
    {
        PHAsset *asset = (PHAsset *)info[UIImagePickerControllerPHAsset];
        [self didSelectAsset:asset];
    }
    else if (info[UIImagePickerControllerEditedImage])
    {
        UIImage *img = info[UIImagePickerControllerEditedImage];
        [self didSelectImage:img];
    }
    else if (info[UIImagePickerControllerOriginalImage])
    {
        UIImage *img = info[UIImagePickerControllerOriginalImage];
        [self didSelectImage:img];
    }
    
    [picker dismissViewControllerAnimated:YES completion:^{
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
