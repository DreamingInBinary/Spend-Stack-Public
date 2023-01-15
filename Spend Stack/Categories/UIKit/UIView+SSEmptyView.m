//
//  UIView+SSEmptyView.h
//  Spend Stack
//
//  Created by Jordan Morgan on 1/2/17.
//


#import "UIView+SSEmptyView.h"
#import "SSWeakObjectContainer.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import "Spend_Stack_2-Swift.h"

static NSMutableDictionary *implementationLookupTable;

@interface UIView ()

void swizzleInstanceUpdateMethods(id self);
void swizzledBatchUpdates(id self, SEL _cmd, void(^updates)(void), void(^completion)(BOOL));
void swizzledReloadData(id self, SEL _cmd);

@property (strong, nonatomic, nullable, readonly) UIView *emptyView;

@end

@implementation UIView (SSEmptyView)

#pragma mark - Getters/Setters

static char const * SSEmptyDataViewDataSourcePropertyKey = "SSEmptyDataViewDataSourcePropertyKey";
static char const * SSEmptyDataViewPropertyKey = "SSEmptyDataViewPropertyKey";

- (id <SSEmptyDataViewDataSource>)emptyDataViewDataSourceDelegate
{
    return [objc_getAssociatedObject(self, SSEmptyDataViewDataSourcePropertyKey) object];
}

- (void)setEmptyDataViewDataSourceDelegate:(id <SSEmptyDataViewDataSource>)emptyDataSource
{
    objc_setAssociatedObject(self, SSEmptyDataViewDataSourcePropertyKey, [[SSWeakObjectContainer alloc] initWithObject:emptyDataSource], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if ([self respondsToSelector:@selector(performBatchUpdates:completion:)])
    {
        if ([self isKindOfClass:[UICollectionView class]])
        {
            static dispatch_once_t onceCollectionViewToken;
            dispatch_once(&onceCollectionViewToken, ^{
                swizzleInstanceUpdateMethods(self);
            });
        }
        else if ([self isKindOfClass:[UITableView class]])
        {
            static dispatch_once_t onceTableViewToken;
            dispatch_once(&onceTableViewToken, ^{
                swizzleInstanceUpdateMethods(self);
            });
        }
    }
}

- (UIView *)emptyView
{
    return objc_getAssociatedObject(self, SSEmptyDataViewPropertyKey);
}

- (void)setEmptyView:(UIView *)view
{
    objc_setAssociatedObject(self, SSEmptyDataViewPropertyKey, view, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Swizzle

void swizzleInstanceUpdateMethods(id self)
{
    if (!implementationLookupTable) implementationLookupTable = [[NSMutableDictionary alloc] initWithCapacity:2];
    
    Method methodBatchUpdates = class_getInstanceMethod([self class], @selector(performBatchUpdates:completion:));
    IMP performBatchUpdates_orig = method_setImplementation(methodBatchUpdates, (IMP)swizzledBatchUpdates);
    [implementationLookupTable setValue:[NSValue valueWithPointer:performBatchUpdates_orig] forKey:[self instanceLookupKeyForSelector:@selector(performBatchUpdates:completion:)]];
    
    Method methodReloadData = class_getInstanceMethod([self class], @selector(reloadData));
    IMP performReloadData_orig = method_setImplementation(methodReloadData, (IMP)swizzledReloadData);
    [implementationLookupTable setValue:[NSValue valueWithPointer:performReloadData_orig] forKey:[self instanceLookupKeyForSelector:@selector(reloadData)]];
}

void swizzledBatchUpdates(id self, SEL _cmd, void(^updates)(void), void(^completion)(BOOL))
{
    if ([self respondsToSelector:@selector(dataSource)])
    {
        // Figure out how to avoid this in Swift
        id datasource = [self performSelector:@selector(dataSource)];
        if ([datasource isKindOfClass:[UITableViewDiffableDataSource class]])
        {
            NSLog(@"Need a different approach for diffable data source: %@", datasource);
        }
    }
    
    // Get the original performBatchUpdates
    NSValue *impValue = [implementationLookupTable valueForKey:[self instanceLookupKeyForSelector:_cmd]];
    IMP performBatchUpdates_orig = [impValue pointerValue];
    
    // Call OG implementation for whichever instance we have
    if (performBatchUpdates_orig)
    {
        ((void(*)(id,SEL, void(^updates)(void), void(^completion)(BOOL)))performBatchUpdates_orig)(self,_cmd, updates, completion);
    }
    
    // Now trigger empty view
    [self showEmptyViewIfNeeded];
}

void swizzledReloadData(id self, SEL _cmd)
{
    // Get the original reloadDataWithCompletion
    NSValue *impValue = [implementationLookupTable valueForKey:[self instanceLookupKeyForSelector:_cmd]];
    IMP performReloadData_orig = [impValue pointerValue];
    
    // Call OG implementation for a table view
    if (performReloadData_orig)
    {
        ((void(*)(id,SEL))performReloadData_orig)(self,_cmd);
    }
    
    // Now trigger empty view
    [self showEmptyViewIfNeeded];
}

- (NSString *)instanceLookupKeyForSelector:(SEL)selector
{
    return [NSString stringWithFormat:@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(selector)];
}

#pragma mark - Empty Data View Hide/Show

- (void)showEmptyViewIfNeeded
{
    
    BOOL dataIsEmpty;
    
    NSInteger sections = 1;
    NSInteger totalItems = 0;
    
    if ([self isKindOfClass:[UICollectionView class]])
    {
        id <UICollectionViewDataSource> collectionViewDataSource = ((UICollectionView *)self).dataSource;
        
        if ([collectionViewDataSource respondsToSelector:@selector(numberOfSectionsInCollectionView:)])
        {
            sections = [collectionViewDataSource numberOfSectionsInCollectionView:(UICollectionView *)self];
        }
        
        if ([collectionViewDataSource respondsToSelector:@selector(collectionView:numberOfItemsInSection:)])
        {
            for (NSInteger sectionIDX = 0; sectionIDX < sections; sectionIDX++)
            {
                totalItems += [collectionViewDataSource collectionView:(UICollectionView *)self numberOfItemsInSection:sectionIDX];
            }
        }
        
    }
    else if ([self isKindOfClass:[UITableView class]])
    {
        id <UITableViewDataSource> tableViewDataSource = ((UITableView *)self).dataSource;
        
        if ([tableViewDataSource respondsToSelector:@selector(numberOfSectionsInTableView:)])
        {
            sections = [tableViewDataSource numberOfSectionsInTableView:(UITableView *)self];
        }
        
        if ([tableViewDataSource respondsToSelector:@selector(tableView:numberOfRowsInSection:)])
        {
            for (NSInteger sectionIDX = 0; sectionIDX < sections; sectionIDX++)
            {
                totalItems += [tableViewDataSource tableView:(UITableView *)self numberOfRowsInSection:sectionIDX];
            }
        }
    }
    
    dataIsEmpty = totalItems <= 0;
    
    if (self.emptyDataViewDataSourceDelegate != nil)
    {
        if (dataIsEmpty)
        {
            if (self.emptyView != nil) return;
            self.emptyView = [self.emptyDataViewDataSourceDelegate viewForEmptyData];
            if (self.emptyView == nil) return;

            // Add empty view
            CGFloat offset = 0;
            if ([self.emptyDataViewDataSourceDelegate respondsToSelector:@selector(offsetForEmptyView)])
            {
                offset = [self.emptyDataViewDataSourceDelegate offsetForEmptyView];
            }
            
            UIViewController *closetController = self.closestViewController;
            if (closetController == nil)
            {
                NSLog(@"Spend Stack - Closet view controller was nil when attempting to display empty data set.");
                return;
            }
            
            [closetController.view addSubview:self.emptyView];
            
            if ([self.emptyDataViewDataSourceDelegate respondsToSelector:@selector(constraintsBlockForEmptyView)])
            {
                [self.emptyView mas_makeConstraints:[self.emptyDataViewDataSourceDelegate constraintsBlockForEmptyView]];
            }
            else
            {
                [self.emptyView mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.width.equalTo(closetController.view.mas_safeAreaLayoutGuideWidth);
                    make.height.equalTo(closetController.view.mas_safeAreaLayoutGuideHeight);
                    make.centerX.equalTo(closetController.view.mas_safeAreaLayoutGuideCenterX);
                    make.centerY.equalTo(closetController.view.mas_safeAreaLayoutGuideCenterY).with.offset(offset);
                }];
            }
        }
        else
        {
            [self.emptyView removeFromSuperview];
            self.emptyView = nil;
        }
    }
}

@end
