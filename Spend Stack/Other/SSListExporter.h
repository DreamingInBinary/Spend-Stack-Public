//
//  SSListExporter.h
//  Spend Stack
//
//  Created by Jordan Morgan on 8/13/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SSListExporter : NSObject

+ (instancetype _Nonnull)new NS_UNAVAILABLE;
- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithSnapshot:(DiffSnapShot *_Nonnull)snapshot list:(SSList * _Nonnull)list;
- (instancetype _Nonnull)initWithList:(SSList * _Nullable)list;
- (instancetype _Nonnull)initWithLists:(NSArray <SSList *> * _Nonnull)lists;

- (NSAttributedString * _Nullable)textRepresentationForList;
- (NSAttributedString * _Nullable)textRepresentationForLists;
- (UIImage * _Nullable)imageRepresentationForList:(UITableView * _Nullable)tableView;
- (NSData * _Nullable)pdfRepresentationForList;
- (NSData * _Nullable)pdfRepresentationForLists;
- (NSString * _Nullable)htmlStringForList;
- (NSString * _Nullable)htmlStringForLists;
- (UIPrintInteractionController * _Nullable)printControllerForList;
- (UIPrintInteractionController * _Nullable)printControllerForLists;

@end
