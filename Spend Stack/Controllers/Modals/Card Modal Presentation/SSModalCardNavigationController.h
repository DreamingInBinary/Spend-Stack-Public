//
//  ModalCardNavigationController.h
//  Spend Stack
//
//  Created by Jordan Morgan on 2/16/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSNavigationController.h"

@interface SSModalCardNavigationController : SSNavigationController

- (void)resetCornerRadius;
- (void)prepareForDownChevron:(SEL)selector;

@end
