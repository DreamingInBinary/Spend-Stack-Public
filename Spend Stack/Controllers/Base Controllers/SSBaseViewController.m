//
//  SSBaseViewController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 1/9/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "SSBaseViewController.h"
#import "Reachability.h"
#import "Spend_Stack_2-Swift.h"
#import <AVFoundation/AVFoundation.h>

@interface SSBaseViewController ()

@property (nonatomic, readwrite, nonnull) dispatch_queue_t diffQueue;
@property (strong, nonatomic, readwrite, nonnull) FMDatabaseQueue *readWriteQueue;
@property (nonatomic) CGRect iPadPsuedoTraitCollectionLastBounds;
@property (strong, nonatomic, nonnull) AVAudioPlayer *audioPlayer;

@end

@implementation SSBaseViewController

@synthesize undoManager;

#pragma mark - Lazy Loads/Computed Properties

- (BOOL)connectionIsAvailable
{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];
    return networkStatus != NotReachable;
}

- (BOOL)isOniPad
{
    return [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad;
}

- (NSString *)restorationIdentifier
{
    return NSStringFromClass([self class]);
}

- (dispatch_queue_t)diffQueue
{
    if (_diffQueue == nil)
    {
        _diffQueue = dispatch_queue_create("diffQueue", NULL);
    }
    
    return _diffQueue;
}

- (FMDatabaseQueue *)readWriteQueue
{
    if (!_readWriteQueue)
    {
        _readWriteQueue = [FMDatabaseQueue databaseQueueWithPath:[SSDataStore databaseFilePath]];
    }
    
    return _readWriteQueue;
}

#pragma mark - Initializers and Dealloc

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    // Register for keyboard notifications and content size changes
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:self.view.window];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangePreferredContentSize:)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleQuickActionDismissalIfNeeded)
                                                 name:SS_HANDLING_QUICK_ACTION
                                               object:nil];
    
    self.undoManager = [NSUndoManager new];
    self.undoManager.levelsOfUndo = 1;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
    
    if (self.windowSceneID == nil || self.windowSceneID.length < 1)
    {
        self.windowSceneID = [self ss_windowScene].session.persistentIdentifier ?: @"";
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self resignFirstResponder];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (self.presentedViewController == nil)
    {
        [self.readWriteQueue close];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.shouldUseSecondaryBackgroundColor)
    {
        self.view.backgroundColor = [UIColor systemBackgroundColor];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    // Combats some of the trait collection limitations on iPad. For example, on the iPad pro we get no trait collection
    // Change notification going from portrait to landscape or vice versa when in reality we need to react to some of
    // Those changes.
    if (self.preferCustomBroadcastContentSizeChange &&
        CGRectEqualToRect(self.view.bounds, self.iPadPsuedoTraitCollectionLastBounds) == NO)
    {
        self.iPadPsuedoTraitCollectionLastBounds = self.view.bounds;
        [[NSNotificationCenter defaultCenter] postNotificationName:SS_IPAD_PSEUDO_TRAIT_COLLECTION_CHANGED object:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self.undoManager removeAllActions];
}

#pragma mark - Key Commands

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (UIKeyCommand *)dismissOrPopControllerKeyCommand
{
    NSString *discoverabilityTitle = [NSString stringWithFormat:@"Close %@", self.title];
    
    if (self.navigationController.viewControllers.count > 1)
    {
        discoverabilityTitle = @"Go Back";
    }
    
    return [UIKeyCommand keyCommandWithInput:@"Q"
                               modifierFlags:UIKeyModifierCommand
                                      action:@selector(dismissOrPopControllerKeyAction)];
}

- (void)dismissOrPopControllerKeyAction
{
    if (self.navigationController.viewControllers.count > 1)
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
    else
    {
        [self dismissController];
    }
}

#pragma mark - Notification Considerations

- (void)keyboardWillShow:(NSNotification *)note
{
    CGRect frame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect relativeKeyboardRect = [self.view convertRect:frame fromView:[[UIApplication sharedApplication] delegate].window];
    self.activeKeyboardFrame = relativeKeyboardRect;
}

- (void)didChangePreferredContentSize:(NSNotification *)note
{
    if (self.onPreferredContentSizeChanged)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.20f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.onPreferredContentSizeChanged();
        });
    }
}

- (void)handleQuickActionDismissalIfNeeded
{
    if (CGAffineTransformIsIdentity(self.view.transform) == NO)
    {
        self.view.transform = CGAffineTransformIdentity;
    }
    
    if (self.navigationController.viewControllers.count > 1)
    {
        [self.navigationController popViewControllerAnimated:NO];
    }
    else
    {
        BOOL isListController = [self isKindOfClass:[ListViewController class]];
        
        if (isListController == NO)
        {
            [self dismissViewControllerAnimated:NO completion:nil];
        }
    }
}

#pragma mark - Public Methods

- (void)dismissController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)deselectTableRow:(UITableView *)tableView
{
    NSIndexPath *selectedIndexPath = [tableView indexPathForSelectedRow];
    
    if (selectedIndexPath != nil)
    {
        id<UIViewControllerTransitionCoordinator> coordinator = self.transitionCoordinator;
        
        if (coordinator != nil)
        {
            [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
                [tableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
            } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
                if (context.cancelled)
                {
                    [tableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                }
            }];
        }
        else
        {
            [tableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
        }
    }
}

- (void)deselectCollectionItem:(UICollectionView *)collectionView
{
    NSArray <NSIndexPath *> *selectedIDPs = [collectionView indexPathsForSelectedItems];
    if (selectedIDPs.count != 1) { return; }
    NSIndexPath *selectedIndexPath = selectedIDPs.firstObject;
    
    if (selectedIndexPath != nil)
    {
        id<UIViewControllerTransitionCoordinator> coordinator = self.transitionCoordinator;
        
        if (coordinator != nil)
        {
            [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
                [collectionView deselectItemAtIndexPath:selectedIndexPath animated:YES];
            } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
                if (context.cancelled)
                {
                    [collectionView selectItemAtIndexPath:selectedIndexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
                }
            }];
        }
        else
        {
            [collectionView deselectItemAtIndexPath:selectedIndexPath animated:YES];
        }
    }
}

- (void)performBlurAnimationIfPossible
{
    if ([SSCitizenship lowPowerOn] == NO)
    {
        UIView *blurView = [SSCitizenship transparentViewIfPossible];
        [self.navigationController.view insertSubview:blurView aboveSubview:self.navigationController.navigationBar];
        
        blurView.frame = self.navigationController.view.bounds;
        blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        CGFloat duration = SSFastAnimationDuration;
        [UIView animateWithDuration:duration animations:^ {
            [SSCitizenship setViewFadeOutAnimation:blurView];
        } completion:^(BOOL finished) {
            if (finished) [blurView removeFromSuperview];
        }];
    }
}

- (void)playSoundNamed:(NSString *)soundName
{
    NSString *path = [[NSBundle mainBundle] pathForResource:soundName ofType:@"m4a"];
    NSURL *pathURL = [NSURL fileURLWithPath:path];
    
    NSError *error = nil;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:pathURL error:&error];
    [self.audioPlayer play];
}

@end
