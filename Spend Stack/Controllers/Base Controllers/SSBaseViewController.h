//
//  SSBaseViewController.h
//  Spend Stack
//
//  Created by Jordan Morgan on 1/9/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SSConstants.h"
@class SSListBuilder;
@class FMDatabaseQueue;

@protocol SSBaseViewControllerDataReloadable <NSObject>

- (void)loadChangedIndices:(NSNotification * _Nullable)notification;
- (void)performDiffAndAssignNewDataFromLists:(NSArray <__kindof SSObject *> * _Nonnull)freshData;

@end

@interface SSBaseViewController : UIViewController

@property (nonatomic) BOOL shouldUseSecondaryBackgroundColor;
@property (nonatomic, strong, nullable) UIScrollView *scrollView;
@property (nonatomic, getter=doesPreferCustomBroadcastContentSize) BOOL preferCustomBroadcastContentSizeChange;
@property (copy) void (^ _Nullable onPreferredContentSizeChanged)(void);
@property (nonatomic, readonly, getter=connectionIsAvailable) BOOL connectionAvailable;
@property (assign) CGRect activeKeyboardFrame;
@property (nonatomic, readonly, getter=isOniPad) BOOL isiPad;
@property (retain, nonatomic, nonnull) NSUndoManager *undoManager;
@property (nonatomic, readonly, nonnull) dispatch_queue_t diffQueue;
@property (strong, nonatomic, readonly, nonnull) FMDatabaseQueue *readWriteQueue;
@property (strong, nonatomic, nullable) NSString *windowSceneID;

- (void)dismissController;
- (void)deselectTableRow:(UITableView * _Nonnull)tableView;
- (void)deselectCollectionItem:(UICollectionView * _Nonnull)collectionView;
- (void)performBlurAnimationIfPossible;
- (UIKeyCommand * _Nonnull)dismissOrPopControllerKeyCommand;
- (void)dismissOrPopControllerKeyAction;
- (void)playSoundNamed:(NSString * _Nonnull)soundName;

@end
