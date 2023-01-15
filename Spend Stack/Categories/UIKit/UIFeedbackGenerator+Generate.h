//
//  UIFeedbackGenerator+Generate.h
//  Spend Stack
//
//  Created by Jordan Morgan on 1/2/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>


/**
 Describes the type of haptic feedback to play, each value maps to their UIKit counterpart.

 - SSHapticFeedbackTypeSuccess:          Maps to UINotificationFeedbackTypeSuccess.
 - SSHapticFeedbackTypeWarning:          Maps to UINotificationFeedbackTypeWarning.
 - SSHapticFeedbackTypeError:            Maps to UINotificationFeedbackTypeError.
 - SSHapticFeedbackTypeStyleLight:       Maps to UIImpactFeedbackStyleLight.
 - SSHapticFeedbackTypeStyleMedium:      Maps to UIImpactFeedbackStyleMedium.
 - SSHapticFeedbackTypeStyleHeavy:       Maps to UIImpactFeedbackStyleHeavy.
 - SSHapticFeedbackTypeStyleSoft:       Maps to UIImpactFeedbackStyleSoft
 - SSHapticFeedbackTypeStyleRigid:       Maps to UIImpactFeedbackStyleRigid.
 - SSHapticFeedbackTypeSelectionChanged: Calls [selectionFeedback selectionChanged], also invokes prepare as well.
 */
typedef NS_ENUM(NSInteger, SSHapticFeedbackType) {
    SSHapticFeedbackTypeSuccess,
    SSHapticFeedbackTypeWarning,
    SSHapticFeedbackTypeError,
    SSHapticFeedbackTypeStyleLight,
    SSHapticFeedbackTypeStyleMedium,
    SSHapticFeedbackTypeStyleHeavy,
    SSHapticFeedbackTypeStyleSoft,
    SSHapticFeedbackTypeStyleRigid,
    SSHapticFeedbackTypeSelectionChanged
};

@interface UIFeedbackGenerator (Generate)


/**
 Plays haptic feedback that maps to the current feedback type.

 @param type The feedback type, each one maps to its counterpart in @c UINotificationFeedbackGenerator and @c UIImpactFeedbackGenerator
 */
+ (void)playFeedbackOfType:(SSHapticFeedbackType)type;

@end
