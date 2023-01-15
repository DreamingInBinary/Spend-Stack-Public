//
//  LAContext+Utils.h
//  Spend Stack
//
//  Created by Jordan Morgan on 8/2/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <LocalAuthentication/LocalAuthentication.h>

@interface LAContext (Utils)

- (BOOL)authFormIsAvailbleOnDevice;
+ (NSString * _Nonnull)localizedBiometryAuthType;
+ (NSString * _Nonnull)localizedLockedOutBiometryAuthType;
+ (NSString * _Nonnull)friendlyErrorStringFromAuthError:(NSInteger)errorCode;

@end
