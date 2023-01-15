//
//  SSListItemViewController.h
//  Spend Stack
//
//  Created by Jordan Morgan on 2/15/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSBaseViewController.h"
#import "SSModalCardViewController.h"

typedef NS_ENUM(NSUInteger, SSListItemAttribute) {
    SSListItemAttributeUnset,
    SSListItemAttributeNotes
};

@protocol SSListItemViewControllerDelegate <NSObject, UIPopoverPresentationControllerDelegate>

@optional
- (BOOL)shouldReflectSingleWindowUI;
- (void)requestCloseSceneSessionForListItemController:(UISceneSession * _Nullable)sceneSession;

@required
- (void)onEditsCommitted:(SSListItem * _Nonnull)editedListItem;
- (BOOL)requestDeleteItem:(SSListItem * _Nonnull)itemToDelete;

@end

@interface SSListItemViewController : SSModalCardViewController <SSBaseViewControllerDataReloadable>

- (instancetype _Nonnull)initWithListItem:(SSListItem * _Nonnull)listItem delegate:(id <SSListItemViewControllerDelegate> _Nonnull)delegate;
- (instancetype _Nonnull)initWithListItem:(SSListItem * _Nonnull)listItem delegate:(id <SSListItemViewControllerDelegate> _Nonnull)delegate editingAttribute:(SSListItemAttribute)attribute;
- (void)presentImageViewerWithImageView:(__kindof UIImageView * _Nonnull)imageView;
- (SSListItem * _Nonnull)editingItem;
- (void)didSelectAsset:(PHAsset * _Nullable)asset;
- (void)didSelectImage:(UIImage * _Nullable)image;

@end
