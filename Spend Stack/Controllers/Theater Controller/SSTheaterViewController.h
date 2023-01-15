//
//  SSTheaterViewController.h
//  Spend Stack
//
//  Created by Jordan Morgan on 6/3/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSBaseViewController.h"
@class SSListItem;

@interface SSTheaterViewController : SSBaseViewController 

@property (nonatomic, getter=isBeingPeeked) BOOL beingPeeked;

+ (instancetype _Nonnull)new NS_UNAVAILABLE;
- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithImage:(UIImage * _Nonnull)image listItem:(SSListItem * _Nullable)listItem NS_DESIGNATED_INITIALIZER;

+ (CGRect)imageFinalFrameDestinationForImageView:(UIImageView * _Nonnull)imageView inView:(UIView * _Nonnull)view;
- (void)adjustImageViewYCoordinateToFinalPosition; 

@end
