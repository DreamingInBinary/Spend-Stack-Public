//
//  SSListItemImageView.h
//  Spend Stack
//
//  Created by Jordan Morgan on 6/1/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^SSListItemImageViewTapHandler)(void);

@interface SSListItemImageView : UIImageView

@property (copy, nullable, readonly) SSListItemImageViewTapHandler tapHandler;

- (void)configureImageViewForTapHandler:(SSListItemImageViewTapHandler _Nonnull)handler;

@end
