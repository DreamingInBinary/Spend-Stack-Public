//
//  UIFeedbackGenerator+Generate.m
//  Spend Stack
//
//  Created by Jordan Morgan on 1/2/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "UIFeedbackGenerator+Generate.h"

@implementation UIFeedbackGenerator (Generate)

+ (void)playFeedbackOfType:(SSHapticFeedbackType)type
{
    
    if ([SSCitizenship lowPowerOn]) return;
    
    switch (type)
    {
        case SSHapticFeedbackTypeSuccess:
        case SSHapticFeedbackTypeWarning:
        case SSHapticFeedbackTypeError:
            [self playNotificationFeedback:type];
            break;
        case SSHapticFeedbackTypeStyleHeavy:
        case SSHapticFeedbackTypeStyleMedium:
        case SSHapticFeedbackTypeStyleLight:
        case SSHapticFeedbackTypeStyleSoft:
        case SSHapticFeedbackTypeStyleRigid:
            [self playImpactFeedback:type];
            break;
        case SSHapticFeedbackTypeSelectionChanged:
            [UIFeedbackGenerator playSelectionFeedback:type];
            break;
        default:
            break;
    }
}

+ (void)playNotificationFeedback:(SSHapticFeedbackType)type
{
    UINotificationFeedbackGenerator *hapticFeedback = [UINotificationFeedbackGenerator new];
    [hapticFeedback prepare];
    
    switch (type)
    {
        case SSHapticFeedbackTypeSuccess:
            [hapticFeedback notificationOccurred:UINotificationFeedbackTypeSuccess];
            break;
        case SSHapticFeedbackTypeWarning:
            [hapticFeedback notificationOccurred:UINotificationFeedbackTypeWarning];
            break;
        case SSHapticFeedbackTypeError:
            [hapticFeedback notificationOccurred:UINotificationFeedbackTypeError];
            break;
        default:
            break;
    }
}

+ (void)playImpactFeedback:(SSHapticFeedbackType)type
{
    UIImpactFeedbackGenerator *hapticFeedback;
    
    switch (type)
    {
        case SSHapticFeedbackTypeStyleHeavy:
            hapticFeedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
            break;
        case SSHapticFeedbackTypeStyleMedium:
            hapticFeedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
            break;
        case SSHapticFeedbackTypeStyleLight:
            hapticFeedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
            break;
        case SSHapticFeedbackTypeStyleSoft:
            hapticFeedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleSoft];
            break;
        case SSHapticFeedbackTypeStyleRigid:
            hapticFeedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleRigid];
            break;
        default:
            break;
    }
    
    if (hapticFeedback)
    {
        [hapticFeedback prepare];
        [hapticFeedback impactOccurred];
    }
}

+ (void)playSelectionFeedback:(SSHapticFeedbackType)type
{
    UISelectionFeedbackGenerator *hapticFeedback = [UISelectionFeedbackGenerator new];
    [hapticFeedback prepare];
    
    //Only one option here for now
    [hapticFeedback selectionChanged];
}

@end
