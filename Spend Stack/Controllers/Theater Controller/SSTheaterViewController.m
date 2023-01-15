//
//  SSTheaterViewController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 6/3/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSTheaterViewController.h"
#import "SSImageExifLabel.h"
#import "SSTheaterTransitioningDelegate.h"
#import <AVKit/AVKit.h>

@interface SSTheaterViewController () <SSTheaterImageViewProvidingDelegate, UIGestureRecognizerDelegate>

@property (strong, nonatomic, nonnull) SSTheaterTransitioningDelegate *customTransitionDelegate;
@property (strong, nonatomic, nonnull) UIImageView *imageView;
@property (strong, nonatomic, nonnull) UIView *dimmingView;
@property (strong, nonatomic, nonnull) SSImageExifLabel *exifLabel;
@property (weak, nonatomic, nullable) SSListItem *listItem;

// Gesture recognizer and 3D Touch helpers
@property (nonatomic) CGFloat originalStartingImageViewCenterX;
@property (nonatomic) CGFloat originalStartingImageViewCenterY;
@property (nonatomic) CGFloat originalStartingExifLabelCenterX;

@end

@implementation SSTheaterViewController

#pragma mark - Custom Setters

- (void)setBeingPeeked:(BOOL)beingPeeked
{
    _beingPeeked = beingPeeked;
    if (_beingPeeked)
    {
        _dimmingView.backgroundColor = [UIColor clearColor];
        _imageView.layer.cornerRadius = 14.0f;
        _exifLabel.hidden = YES;
        _imageView.ss_y = 0; // Show the full image when peeking
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleFullPopFromForceTouch:)
                                                     name:SS_CONTROLLER_WAS_POPPED
                                                   object:nil];
    }
}

#pragma mark - Initializer

- (instancetype)initWithImage:(UIImage *)image listItem:(SSListItem *)listItem
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self)
    {
        self.dimmingView = [UIView new];
        self.dimmingView.backgroundColor = [UIColor blackColor];
        UITapGestureRecognizer *tapToDismiss = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissController)];
        [self.dimmingView addGestureRecognizer:tapToDismiss];
        
        self.imageView = [UIImageView new];
        self.imageView.image = image;
        self.imageView.accessibilityIgnoresInvertColors = YES;
        self.imageView.clipsToBounds = YES;
        
        self.exifLabel = [[SSImageExifLabel alloc] initWithTextStyle:UIFontTextStyleBody image:image];
        self.exifLabel.textColor = [UIColor labelColor];
        self.exifLabel.maximumFontSize = 20.0f;
        
        self.view.backgroundColor = [UIColor clearColor];
        
        self.customTransitionDelegate = [SSTheaterTransitioningDelegate new];
        self.modalPresentationStyle = UIModalPresentationCustom;
        self.transitioningDelegate = self.customTransitionDelegate;
    }
    
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self initWithImage:[UIImage new] listItem:nil];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    return [self initWithImage:[UIImage new] listItem:nil];
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.dimmingView.frame = self.view.bounds;
    self.dimmingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    self.imageView.frame = [SSTheaterViewController imageFinalFrameDestinationForImageView:self.imageView
                                                                                    inView:self.view];
    self.originalStartingImageViewCenterY = self.imageView.centerY;

    [self.view addSubviews:@[self.dimmingView, self.imageView]];
    
    [self attachTapGestureRecognizersToImage];
    [self setNeedsUpdateOfHomeIndicatorAutoHidden];
    
    self.originalStartingImageViewCenterX = self.imageView.centerX;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [UIView animateWithDuration:0.5 animations:^{
        [self setNeedsStatusBarAppearanceUpdate];
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.isBeingPeeked == NO) self.exifLabel.hidden = NO; // Hide or show during transition
    
    [self setExifLabelFrame];
    self.originalStartingExifLabelCenterX = self.exifLabel.centerX;
    
    // Bring this back when it actually works.
    // [self showExifCoachingTipIfNeeded];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.exifLabel.hidden = YES; // Hide or show during transition
}

- (BOOL)prefersHomeIndicatorAutoHidden
{
    return YES;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (BOOL)modalPresentationCapturesStatusBarAppearance
{
    return YES;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return UIStatusBarAnimationFade;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

#pragma mark - Notification Handling

- (void)handleFullPopFromForceTouch:(NSNotification *)notification
{
    self.imageView.layer.cornerRadius = 0.0f;
    self.dimmingView.backgroundColor = [UIColor blackColor];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.beingPeeked = NO;
        [self setExifLabelFrame];
        self.exifLabel.hidden = NO;
    });
}

#pragma mark - 3D Touch
//
//- (NSArray <id <UIPreviewActionItem>> *)previewActionItems
//{
//    
//    UIPreviewAction *deleteAction = [UIPreviewAction actionWithTitle:@"Remove Image" style:UIPreviewActionStyleDestructive handler:^(UIPreviewAction *action, UIViewController *previewViewController) {
//        [[NSNotificationCenter defaultCenter] postNotificationName:SS_MEDIA_WAS_TOGGLED object:@(1)];
//    }];
//    
//    return @[deleteAction];
//}

- (void)setExifLabelFrame
{
    [self.exifLabel sizeToFit];
    self.exifLabel.centerY = self.view.centerY;
    self.exifLabel.ss_x = (self.imageView.ss_x + self.imageView.boundsWidth) - (self.exifLabel.ss_width + SSSpacingJumboMargin);
}

#pragma mark - Coaching Tip

- (void)showExifCoachingTipIfNeeded {
    if(self.exifLabel.text.length > 0 && [ss_defaults() boolForKey:@"SS_HAS_DEMOED_EXIF_GESTURE"] == NO)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.imageView.userInteractionEnabled = NO;
            [UIView animateWithDuration:SSFastestAnimationDuration delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.imageView.centerX -= (self.imageView.boundsWidth * .10f);
            }completion:nil];
            [UIView animateWithDuration:SSFastAnimationDuration delay:SSFastestAnimationDuration options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.imageView.centerX = self.originalStartingImageViewCenterX;
            }completion:^ (BOOL done) {
                self.imageView.userInteractionEnabled = YES;
                [ss_defaults() setBool:YES forKey:@"SS_HAS_DEMOED_EXIF_GESTURE"];
            }];
        });
    }
}

#pragma mark - Tap to Dimiss and Activity Gestures

- (void)attachTapGestureRecognizersToImage
{
    self.imageView.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *tapToDimiss = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissController)];
    tapToDimiss.numberOfTapsRequired = 1;
    [self.imageView addGestureRecognizer:tapToDimiss];

    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleShareLongPress:)];
    [tapToDimiss requireGestureRecognizerToFail:longPress];
    [self.imageView addGestureRecognizer:longPress];
    
    UIPanGestureRecognizer *swipeLeft = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeLeftGesture:)];
    [swipeLeft requireGestureRecognizerToFail:tapToDimiss];
    swipeLeft.name = @"ExifSwipe";
    swipeLeft.delegate = self;
    [self.imageView addGestureRecognizer:swipeLeft];
    
    UIPinchGestureRecognizer *pinchToZoom = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    [self.imageView addGestureRecognizer:pinchToZoom];
}

- (void)handleShareLongPress:(UILongPressGestureRecognizer *)longPress
{
    if (longPress.state == UIGestureRecognizerStateBegan)
    {
        UIActivityViewController *activityVC;
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        {
            activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[self.imageView.image] applicationActivities:nil];
            [self presentViewController:activityVC animated:YES completion:nil];
        }
        else
        {
            activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[self.imageView.image] applicationActivities:nil];
            activityVC.modalPresentationStyle = UIModalPresentationPopover;
            activityVC.preferredContentSize = CGSizeMake(320,400);
            UIPopoverPresentationController *popoverVC = activityVC.popoverPresentationController;
            popoverVC.sourceView = self.imageView;
            
            CGPoint touchPoint;
            // Grab the long press
            UILongPressGestureRecognizer *longPress;
            for (UIGestureRecognizer *gesture in self.imageView.gestureRecognizers)
            {
                if ([gesture isKindOfClass:[UILongPressGestureRecognizer class]])
                {
                    longPress = (UILongPressGestureRecognizer *)gesture;
                    break;
                }
            }
            
            touchPoint = [longPress locationInView:self.imageView];
            popoverVC.sourceRect = CGRectMake(touchPoint.x, touchPoint.y, 1, 1);
            
            [self presentViewController:activityVC animated:YES completion:nil];
        }
    }
}

- (void)handleSwipeLeftGesture:(UIPanGestureRecognizer *)swipe
{
    CGPoint translation = [swipe translationInView:self.view];
    CGPoint velocity = [swipe velocityInView:self.view];

    if (swipe.state == UIGestureRecognizerStateBegan || swipe.state == UIGestureRecognizerStateChanged)
    {
        if (velocity.x > 0)
        {
            // Don't let them drag past the image's original center point
            CGFloat proposedX = self.imageView.centerX + translation.x;
            if (proposedX < self.originalStartingImageViewCenterX)
            {
                self.imageView.centerX = proposedX;
            }
        }
        else
        {
            CGFloat exifLabelMaxX = self.view.boundsWidth - (self.exifLabel.ss_width + SSSpacingJumboMargin);
            
            if (self.exifLabel.ss_x >= exifLabelMaxX)
            {
                BOOL imageViewIsOverlappingExifLabel = CGRectIntersectsRect(self.imageView.frame, self.exifLabel.frame);
                
                if (imageViewIsOverlappingExifLabel)
                {
                    self.imageView.centerX = self.imageView.centerX + translation.x;
                }
                else
                {
                    self.imageView.centerX = self.imageView.centerX + (translation.x * .25f);
                }
            }
            else
            {
                self.imageView.centerX = self.imageView.centerX + translation.x;
                self.exifLabel.centerX = self.exifLabel.centerX - translation.x;
            }
        }
        
        [swipe setTranslation:CGPointZero inView:self.view];
    }
    else if (swipe.state == UIGestureRecognizerStateEnded)
    {
        // NOTE!!!: Maybe use UISnapBehavior here to snap it back to the center
        [UIView animateWithDuration:SSFastestAnimationDuration delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.imageView.centerX = self.originalStartingImageViewCenterX;
            self.exifLabel.centerX = self.originalStartingExifLabelCenterX;
            [self setExifLabelFrame];
        } completion:^(BOOL finished) {
            
        }];
    }
}

- (void)handlePinch:(UIPinchGestureRecognizer *)gesture
{
    CGFloat MINIMUM_SCALE = 0.5f;
    CGFloat MAXIMUM_SCALE = 6.0f;

    if (gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateChanged)
    {
        self.exifLabel.hidden = YES;
        CGFloat currentScale = self.imageView.ss_width / self.imageView.boundsWidth;
        CGFloat newScale = currentScale * gesture.scale;
        
        if (newScale < MINIMUM_SCALE)
        {
            newScale = MINIMUM_SCALE;
        }
        
        if (newScale > MAXIMUM_SCALE)
        {
            newScale = MAXIMUM_SCALE;
        }
        
        CGAffineTransform transform = CGAffineTransformMakeScale(newScale, newScale);
        self.imageView.transform = transform;
        gesture.scale = 1;
    }
    else
    {
        [UIView animateWithDuration:SSFastAnimationDuration delay:0.00f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.imageView.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            if (finished)
            {
                gesture.scale = 1;
                self.exifLabel.hidden = NO;
            }
        }];
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]])
    {
        UIPanGestureRecognizer *pan = (UIPanGestureRecognizer *)gestureRecognizer;
        CGPoint velocity = [pan velocityInView:self.view];
        BOOL isSwipeToViewExifGesture = [gestureRecognizer.name isEqualToString:@"ExifSwipe"];
        
        if (isSwipeToViewExifGesture)
        {
            return fabs(velocity.x) > fabs(velocity.y);
        }
        else
        {
            return fabs(velocity.y) > fabs(velocity.x);
        }
    }
    
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return NO;
}

#pragma mark - Public Methods

+ (CGRect)imageFinalFrameDestinationForImageView:(UIImageView *)imageView inView:(UIView *)view
{
    CGRect boundingRect = [view convertRect:view.bounds toView:nil];
    CGSize aspectRatio = CGSizeMake(imageView.image.size.width, imageView.image.size.height);
    CGRect initialRect = AVMakeRectWithAspectRatioInsideRect(aspectRatio, boundingRect);
    
    return initialRect;
}

- (void)adjustImageViewYCoordinateToFinalPosition
{
    self.imageView.centerY = self.originalStartingImageViewCenterY;
}

#pragma mark - Theater Image Providing Delegate

- (UIImageView *)ss_presentedControllerImageView
{
    return self.imageView;
}

- (CGRect)ss_destinationRectForAnimatingImageView
{
    return [SSTheaterViewController imageFinalFrameDestinationForImageView:self.imageView
                                                                    inView:self.view];
}

- (UIView *)ss_viewForDimissingAnimation
{
    return self.dimmingView;
}

@end
