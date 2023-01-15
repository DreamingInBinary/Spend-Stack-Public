//
//  SSTagManagerViewController.h
//  Spend Stack
//
//  Created by Jordan Morgan on 7/1/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSBaseViewController.h"

@protocol SSTagsManagerViewControllerDelegate <NSObject>

@optional
- (void)newTagWasCreated:(SSTag * _Nonnull)newTag;
- (void)tagWasEdited:(SSTag * _Nonnull)editedTag;
- (void)tagWasDeleted:(SSTag * _Nonnull)deletedTag;
- (void)tagEditorWillDismiss;

@end

@interface SSTagsManagerViewController : SSBaseViewController <SSBaseViewControllerDataReloadable>

- (instancetype _Nonnull)initWithTag:(SSTag * _Nullable)tag delegate:(id <SSTagsManagerViewControllerDelegate> _Nonnull)tagsManagerDelegate;

@end
