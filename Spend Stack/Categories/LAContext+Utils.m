//
//  LAContext+Utils.m
//  Spend Stack
//
//  Created by Jordan Morgan on 8/2/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "LAContext+Utils.h"

@implementation LAContext (Utils)

- (BOOL)authFormIsAvailbleOnDevice
{
    // Face ID, Touch ID or PIN setup?
    return [self canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil] ||
           [self canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:nil];
}

+ (NSString *)localizedBiometryAuthType
{
    LAContext *ctx = [LAContext new];
    
    BOOL hasBioAuth = [ctx canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil];
    BOOL hasAuthOnlyWithPin = [ctx canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:nil] && !hasBioAuth;
    
    if (!hasBioAuth && !hasAuthOnlyWithPin)
    {
        return @"";
    }
    
    if (hasAuthOnlyWithPin)
    {
        return ss_Localized(@"authContext.authType.pin");
    }
    
    switch (ctx.biometryType)
    {
        case LABiometryTypeFaceID:
            return ss_Localized(@"authContext.biometryType.faceID");
            break;
        case LABiometryTypeTouchID:
            return ss_Localized(@"authContext.biometryType.touchID");
            break;
        default:
            return @"";
            break;
    }
    
}

+ (NSString *)localizedLockedOutBiometryAuthType
{
    LAContext *ctx = [LAContext new];
    BOOL hasBioAuth = [ctx canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil];
    BOOL hasAuthOnlyWithPin = [ctx canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:nil] && !hasBioAuth;
    
    if (hasAuthOnlyWithPin)
    {
        return ss_Localized(@"authContext.authType.pin");
    }
    
    NSString *biometricAuthType = ss_Localized(@"authContext.biometryType.touchID");
    
    if (ctx.biometryType == LABiometryTypeFaceID)
    {
        biometricAuthType = ss_Localized(@"authContext.biometryType.faceID");
    }
    
    return biometricAuthType;
}

+ (NSString *)friendlyErrorStringFromAuthError:(NSInteger)errorCode
{
    switch (errorCode)
    {
        case LAErrorAuthenticationFailed:
            return @"Authenticaion failed. Please try again.";
            break;
        case LAErrorUserCancel:
            return @"";
            break;
        case LAErrorUserFallback:
            return @"";
            break;
        case LAErrorPasscodeNotSet:
            return @"Your passcode hasn't been set.\nPlease open Settings on your device to add one.";
            break;
        case LAErrorBiometryNotAvailable:
            return @"Authentication isn't currently available.";
            break;
        case LAErrorBiometryNotEnrolled:
            return @"Touch ID, Face ID or a PIN hasn't been configured.\nPlease open Settings on your device to finish setup.";
            break;
        case LAErrorBiometryLockout:
            return @"Authenticaiton has been locked out.";
            break;
        case LAErrorAppCancel:
            return @"";
            break;
        case LAErrorInvalidContext:
            return @"Authentication encountered an error, please try again.";
            break;
        case LAErrorNotInteractive:
            return @"We're unable to use authentication. Please try again later.";
            break;
        default:
            return @"";
            break;
    }
}

@end
