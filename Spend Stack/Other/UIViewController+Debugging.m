//
//  UIViewController+Debugging.m
//  Spend Stack
//
//  Created by Jordan Morgan on 5/26/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "UIViewController+Debugging.h"

@implementation UIViewController (Debugging)
- (void)showDebugger
{
#ifdef DEBUG
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    id debugClass = NSClassFromString(@"UIDebuggingInformationOverlay");
    [debugClass performSelector:NSSelectorFromString(@"prepareDebuggingOverlay")];
    
    id debugOverlayInstance = [debugClass performSelector:NSSelectorFromString(@"overlay")];
    [debugOverlayInstance performSelector:NSSelectorFromString(@"toggleVisibility")];
#pragma clang diagnostic pop
#endif
}
@end
