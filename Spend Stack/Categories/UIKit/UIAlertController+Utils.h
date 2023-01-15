//
//  UIAlertController+Utils.h
//  Spend Stack
//
//  Created by Jordan Morgan on 1/2/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAlertController (Utils)

/**
 *  Attaches action objects to the alert or action sheet.
 *
 *  @param actions An @c NSArray of actions to add to the controller. They will appear in the same order of their index in the array.
 */
- (void)addActions:(NSArray <UIAlertAction *> * _Nonnull)actions;

@end
