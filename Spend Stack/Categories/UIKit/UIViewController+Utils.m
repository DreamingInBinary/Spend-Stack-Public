//
//  UIViewController+Utils.m
//  Spend Stack
//
//  Created by Jordan Morgan on 1/2/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "UIViewController+Utils.h"
#import "UIAlertController+Utils.h"

@implementation UIViewController (Utils)

- (BOOL)isNotch
{
    if ([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPhone || [UIScreen mainScreen].scale == 1) return NO;
    
    CGRect screenRect = [UIScreen mainScreen].bounds;
    if (screenRect.size.width > screenRect.size.height) {
        return screenRect.size.height == 375 || screenRect.size.height == 414;
    } else {
        return screenRect.size.height == 812 || screenRect.size.height == 896;
    }
}

- (CGFloat)preferredCornerRadius
{
    return [self isNotch] ? 40.0f : 17.0f;
}

- (void)showError:(NSError *)error title:(NSString *)title
{
    [self showAlertControllerWithTitle:title message:error.localizedDescription];
}

- (void)showAlertControllerWithTitle:(NSString *)title message:(NSString *)message
{
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *close = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil];
    [ac addAction:close];
    
    [self presentViewController:ac animated:YES completion:nil];
}

- (void)showAlertControllerWithTitle:(NSString *)title message:(NSString *)message actions:(NSArray<UIAlertAction *> *)actions
{
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [ac addActions:actions];
    
    [self presentViewController:ac animated:YES completion:nil];
}

- (void)showAlertControllerWithTitle:(NSString *)title message:(NSString *)message actions:(NSArray<UIAlertAction *> *)actions completion:(void (^)(void))completion
{
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [ac addActions:actions];
    
    if (completion) {
        [self presentViewController:ac animated:YES completion:completion];
    } else {
        [self presentViewController:ac animated:YES completion:nil];
    }
}

- (void)showActionSheetWithTitle:(NSString *)title message:(NSString *)message actions:(NSArray<UIAlertAction *> *)actions
{
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:title
                                                                message:message
                                                         preferredStyle:UIAlertControllerStyleActionSheet];
    
    if ([self conformsToProtocol:@protocol(UIPopoverPresentationControllerDelegate)])
    {
        ac.popoverPresentationController.delegate = (id <UIPopoverPresentationControllerDelegate>)self;
    }
    
    [ac addActions:actions];
    
    [self presentViewController:ac animated:YES completion:nil];
}

- (void)showActionSheetWithTitle:(NSString *)title message:(NSString *)message actions:(NSArray<UIAlertAction *> *)actions anchorView:(UIView * _Nonnull)anchor
{
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:title
                                                                message:message
                                                         preferredStyle:UIAlertControllerStyleActionSheet];
    
    ac.popoverPresentationController.sourceView = anchor;
    
    [ac addActions:actions];
    
    [self presentViewController:ac animated:YES completion:nil];
}

- (void)addChildViewController:(UIViewController *)childController frame:(CGRect)frame
{
    [self addChildViewController:childController];
    
    if (CGRectIsNull(frame) == NO)
    {
        childController.view.frame = frame;
    }
    else
    {
        childController.view.frame = self.view.bounds;
    }
    
    [self.view addSubview:childController.view];
    [childController didMoveToParentViewController:self];
}

- (void)removeSelfFromParentViewController
{
    [self willMoveToParentViewController:nil];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}

- (BOOL)shouldConsideriPadFrameRegular
{
    if ([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad) return NO;
    return [self.view isLandscape] || self.view.boundsWidth > SS_iPadProDetailViewWidthLandscape;
}

- (BOOL)shouldConsideriPhoneFrameRegular
{
    if ([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPhone == NO) return NO;
    return [self.view isLandscape] && self.view.ss_width > SS_iPhoneDetailViewWidthLandscape;
}

- (UIWindowScene *)ss_windowScene
{
    return self.view.window.windowScene;
}

@end
