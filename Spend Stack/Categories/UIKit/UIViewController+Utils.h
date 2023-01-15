//
//  UIViewController+Utils.h
//  Spend Stack
//
//  Created by Jordan Morgan on 1/2/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (Utils)

/**
 *  Returns YES if the current device has a notch. There are outlier design considerations, like rounded corners, that should only be applied on the iPhone X.
 *
 */
- (BOOL)isNotch;

/**
 *  Returns the corner radius for a notched device vs a non-notced device.
 *
 */
- (CGFloat)preferredCornerRadius;

/**
 *  Displays a @c UIAlertController displaying the error's localized description as the message.
 *
 *  @param error The error that has occurred.
 *  @param title The title to display in the alert controller.
 */
- (void)showError:(NSError * _Nonnull)error title:(NSString * _Nonnull)title;

/**
 *  Displays a @c UIAlertController with the given title and message with a close action.
 *
 *  @param title   The desired title of the prompt.
 *  @param message The desired message of the prompt.
 */
- (void)showAlertControllerWithTitle:(NSString * _Nonnull)title message:(NSString * _Nonnull)message;

/**
 *  Displays a @c UIAlertController with the given title and message with a the supplied actions.
 *
 *  @param title   The desired title of the prompt.
 *  @param message The desired message of the prompt.
 *  @param actions The @c UIAlertAction instances that will be added to the alert controller.
 */
- (void)showAlertControllerWithTitle:(NSString * _Nonnull)title message:(NSString * _Nonnull)message actions:(NSArray <UIAlertAction *> * _Nonnull)actions;

/**
 *  Displays a @c UIAlertController with the given title and message with a the supplied actions.
 *
 *  @param title   The desired title of the prompt.
 *  @param message The desired message of the prompt.
 *  @param actions The @c UIAlertAction instances that will be added to the alert controller.
 *  @param completion An optional completion handler that will be invoked after the controller is dimissed, if supplied.
 */
- (void)showAlertControllerWithTitle:(NSString * _Nonnull)title message:(NSString * _Nonnull)message actions:(NSArray <UIAlertAction *> * _Nonnull)actions completion:(void (^ _Nullable)(void))completion;

/**
 *  Displays a @c UIAlertController with the given title and message with a the supplied actions as an action sheet.
 *
 *  @param title   The desired title of the prompt.
 *  @param message The desired message of the prompt.
 *  @param actions The @c UIAlertAction instances that will be added to the alert controller.
 */
- (void)showActionSheetWithTitle:(NSString * _Nullable)title message:(NSString * _Nullable)message actions:(NSArray <UIAlertAction *> * _Nonnull)actions;

/**
 *  Displays a @c UIAlertController with the given title and message with a the supplied actions as an action sheet.
 *
 *  @param title   The desired title of the prompt.
 *  @param message The desired message of the prompt.
 *  @param actions The @c UIAlertAction instances that will be added to the alert controller.
 *  @param anchor The @c UIView instance to anchor a popover on iPad.
 */
- (void)showActionSheetWithTitle:(NSString * _Nullable)title message:(NSString * _Nullable)message actions:(NSArray <UIAlertAction *> * _Nonnull)actions anchorView:(UIView * _Nonnull)anchor;

/**
 *  Adds the controller as a child controller to the receiver.
 *
 *  @param childController  The desired controller to add.
 *  @param frame The desired frame of the added child controller.
 */
- (void)addChildViewController:(UIViewController * _Nonnull)childController frame:(CGRect)frame;

/**
 *  Removes the controller, which should be a child controller, from its parent.
 */
- (void)removeSelfFromParentViewController;

/**
 *  This is a more granular check that returns YES if I consider the iPad view to be regular.
 */
- (BOOL)shouldConsideriPadFrameRegular;

/**
 *  This is a more granular check that returns YES if I consider the iPhone view to be regular.
 */
- (BOOL)shouldConsideriPhoneFrameRegular;

/**
*  Attempts to return the controller's window scene if it's not nil.
*/
- (UIWindowScene * _Nullable)ss_windowScene;

@end
