//
//  SSImagePickerViewController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 6/25/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSImagePickerViewController.h"
#import "SSModalCardViewController.h"
#import "SSImagePickerViewController+Camera.h"
#import "SSImagePickerViewController+Documents.h"
#import "SSMediaCollectionViewCell.h"
#import "UICollectionView+Utils.h"
#import "UIView+Animations.h"
#import <Photos/Photos.h>

static const NSUInteger CV_LAYOUT_INSET = 16.0f;

@interface SSImagePickerViewController () <PHPhotoLibraryChangeObserver,
                                           UICollectionViewDataSource,
                                           UICollectionViewDelegate,
                                           UICollectionViewDelegateFlowLayout,
                                           UIPointerInteractionDelegate>

@property (weak, nonatomic, readwrite, nullable) id <SSImagePickerViewControllerDelegate> delegate;
@property (strong, nonatomic, nonnull) PHFetchResult *fetchResult;
@property (strong, nonatomic, nonnull) PHCachingImageManager *imageManager;
@property (strong, nonatomic, readwrite, nonnull) SSToolbar *tb;
@property (strong, nonatomic, nonnull) UICollectionView *collectionView;
@property (strong, nonatomic, nonnull) UICollectionViewFlowLayout *layout;
@property (nonatomic) CGFloat availableWidth;
@property (nonatomic) CGRect previousPreheatRect;

@end

@implementation SSImagePickerViewController

#pragma mark - Initializers

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self initWithDelegate:nil];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    return [self initWithDelegate:nil];
}

#pragma clang diagnostic pop

- (instancetype)initWithDelegate:(id<SSImagePickerViewControllerDelegate>)delegate
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self)
    {
        self.delegate = delegate;
        self.previousPreheatRect = CGRectZero;
        self.imageManager = [PHCachingImageManager new];
    }
    
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self resetCachedAssets];
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    [self performFetch];
    
    NSAssert([self.navigationController isKindOfClass:[SSModalCardNavigationController class]], @"Spend Stack - Wrong navigation controller supplied.");
    [((SSModalCardNavigationController *)self.navigationController) prepareForDownChevron:@selector(dismissController)];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    __weak SSImagePickerViewController *weakSelf = self;
    
    [self calculateCollectionViewLayout];
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.layout];
    self.collectionView.backgroundColor = [UIColor systemBackgroundColor];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerClass:[SSMediaCollectionViewCell class] forCellWithReuseIdentifier:SS_MEDIA_CELL_ID];
    
    NSArray <SSToolBarItem *> *tbItems = @[SSToolBarItemTypeCamera, SSToolBarItemTypeCloudDocuments, SSToolBarItemTypeFlexSpace, SSToolBarItemTypeDone];
    
    if (self.navigationController.viewControllers.count > 1)
    {
        tbItems = @[SSToolBarItemTypeCamera, SSToolBarItemTypeCloudDocuments, SSToolBarItemTypeFlexSpace];
    }
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO)
    {
        tbItems = @[SSToolBarItemTypeCloudDocuments, SSToolBarItemTypeFlexSpace, SSToolBarItemTypeDone];
    }

    self.tb = [[SSToolbar alloc] initWithItemTypes:tbItems];
    
    self.tb.clipsToBounds = NO;
    self.tb.onDone = ^{
        [weakSelf dismissController];
    };
    self.tb.onCamera = ^{
        [weakSelf presentCamera];
    };
    self.tb.onCloudDocuments = ^{
        [weakSelf presentDocumentPicker];
    };
    
    [self.view addSubviews:@[self.collectionView, self.tb]];
    
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft);
        make.right.equalTo(self.view.mas_safeAreaLayoutGuideRight);
        make.bottom.equalTo(self.tb.mas_top);
    }];
    
    [self.tb mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.view.mas_width);
        make.centerX.equalTo(self.view.mas_centerX);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self resetCachedAssets];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    CGFloat width = UIEdgeInsetsInsetRect(self.view.bounds, self.view.safeAreaInsets).size.width;
    
    if (self.availableWidth != width)
    {
        self.availableWidth = width;
        [self calculateCollectionViewLayout];
    }
}

- (void)dealloc
{
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

#pragma mark - Asset Fetch

- (void)performFetch
{
    PHFetchOptions *allPhotosOptions = [PHFetchOptions new];
    allPhotosOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    allPhotosOptions.predicate = [NSPredicate predicateWithFormat:@"SELF.mediaType = %@", @(PHAssetMediaTypeImage)];
    
    self.fetchResult = [PHAsset fetchAssetsWithOptions:allPhotosOptions];
    [self.collectionView reloadData];
}

#pragma mark - Asset Caching

- (void)resetCachedAssets
{
    [self.imageManager stopCachingImagesForAllAssets];
    self.previousPreheatRect = CGRectZero;
}

- (void)updateCachedAssets
{
    if (self.isViewLoaded && self.view.window != nil)
    {
        // The window you prepare ahead of time is twice the height of the visible rect.
        CGRect visibleRect = CGRectMake(self.collectionView.contentOffset.x, self.collectionView.contentOffset.y, self.collectionView.bounds.size.width, self.collectionView.bounds.size.height);
        CGRect preheatRect = CGRectInset(visibleRect, 0, -0.5 * visibleRect.size.height);
        
        // Update only if the visible area is significantly different from the last preheated area.
        NSInteger delta = fabs(CGRectGetMidY(preheatRect) - CGRectGetMidY(self.previousPreheatRect));
        if (delta > (self.view.bounds.size.height/3) == NO)
        {
            return;
        }
        
        // Compute the assets to start and stop caching.
        NSArray <NSArray <NSValue *> *> *diff = [self differencesBetweenRects:self.previousPreheatRect new:preheatRect];
        NSArray <NSValue *> *addedAssetRects = diff.firstObject;
        NSArray <NSValue *> *removedAssetRects = diff.lastObject;
        NSMutableArray <PHAsset *> *addedAssets = [NSMutableArray new];
        NSMutableArray <PHAsset *> *removedAssets = [NSMutableArray new];
        
        for (NSValue *rect in addedAssetRects)
        {
            for (NSIndexPath *idp in [self.collectionView indexPathsForElementsInRect:rect.CGRectValue])
            {
                [addedAssets addObject:self.fetchResult[idp.item]];
            }
        }
        
        for (NSValue *rect in removedAssetRects)
        {
            for (NSIndexPath *idp in [self.collectionView indexPathsForElementsInRect:rect.CGRectValue])
            {
                [removedAssets addObject:self.fetchResult[idp.item]];
            }
        }
        
        // Update the assets the PHCachingImageManager is caching.
        [self.imageManager startCachingImagesForAssets:addedAssets targetSize:CGSizeMake(80, 80) contentMode:PHImageContentModeAspectFill options:nil];
        [self.imageManager stopCachingImagesForAssets:removedAssets targetSize:CGSizeMake(80, 80) contentMode:PHImageContentModeAspectFill options:nil];
        self.previousPreheatRect = preheatRect;
    }
}

- (NSArray <NSArray <NSValue *> *> *)differencesBetweenRects:(CGRect)old new:(CGRect)new
{
    if (CGRectIntersectsRect(old, new))
    {
        NSMutableArray <NSValue *> *added = [NSMutableArray new];
        CGRect rect;
        NSValue *value;
        if (CGRectGetMaxY(new) > CGRectGetMaxY(old)) {
            rect = CGRectMake(new.origin.x, CGRectGetMaxY(old), new.size.width, CGRectGetMaxY(new) - CGRectGetMaxY(old));
            value = [NSValue valueWithCGRect:rect];
            [added addObject:value];
        }
        if (CGRectGetMinY(old) > CGRectGetMinY(new)) {
            rect = CGRectMake(new.origin.x, CGRectGetMaxY(new), new.size.width, CGRectGetMinY(old) - CGRectGetMinY(new));
            value = [NSValue valueWithCGRect:rect];
            [added addObject:value];
        }
        NSMutableArray <NSValue *> *removed = [NSMutableArray new];
        if (CGRectGetMaxY(new) < CGRectGetMaxY(old)) {
            rect = CGRectMake(new.origin.x, CGRectGetMaxY(new), new.size.width, CGRectGetMaxY(old) - CGRectGetMaxY(new));
            value = [NSValue valueWithCGRect:rect];
            [removed addObject:value];
        }
        if (CGRectGetMinY(old) < CGRectGetMinY(new)) {
            rect = CGRectMake(new.origin.x, CGRectGetMinY(old), new.size.width, CGRectGetMinY(new) - CGRectGetMinY(old));
            value = [NSValue valueWithCGRect:rect];
            [removed addObject:value];
        };
        
        return @[added, removed];
    }
    else
    {
        return @[@[[NSValue valueWithCGRect:new]], @[[NSValue valueWithCGRect:old]]];
    }
}

#pragma mark - Change Observer

- (void)photoLibraryDidChange:(nonnull PHChange *)changeInstance
{
    if (self.fetchResult == nil) return;
    PHFetchResultChangeDetails *changes = [changeInstance changeDetailsForFetchResult:self.fetchResult];
    
    if (!changes) return;
    
    dispatch_sync(dispatch_get_main_queue(), ^ {
        // Hang on to the new fetch result.
        self.fetchResult = changes.fetchResultAfterChanges;
        
        // If we have incremental changes, animate them in the collection view.
        if (changes.hasIncrementalChanges)
        {
            [self.collectionView performBatchUpdates:^{
                // Removals, insertions and moves
                if (changes.removedIndexes && changes.removedIndexes.count > 0) {
                    NSArray <NSIndexPath *> *idps = [self indexPathArrayFromIndexSet:changes.removedIndexes];
                    [self.collectionView deleteItemsAtIndexPaths:idps];
                }
                
                if (changes.insertedIndexes && changes.insertedIndexes.count > 0) {
                    NSArray <NSIndexPath *> *idps = [self indexPathArrayFromIndexSet:changes.insertedIndexes];
                    [self.collectionView insertItemsAtIndexPaths:idps];
                }
                
                [changes enumerateMovesWithBlock:^(NSUInteger fromIndex, NSUInteger toIndex) {
                    NSIndexPath *from = [NSIndexPath indexPathForItem:fromIndex inSection:0];
                    NSIndexPath *to = [NSIndexPath indexPathForItem:toIndex inSection:0];
                    [self.collectionView moveItemAtIndexPath:from toIndexPath:to];
                }];
            } completion:nil];
            
            // We are reloading items after the batch update since `PHFetchResultChangeDetails.changedIndexes` refers to
            // items in the *after* state and not the *before* state as expected by `performBatchUpdates(_:completion:)`.
            if (changes.changedIndexes && changes.changedIndexes.count > 0)
            {
                NSArray <NSIndexPath *> *idps = [self indexPathArrayFromIndexSet:changes.changedIndexes];
                [self.collectionView reloadItemsAtIndexPaths:idps];
            }
        }
        else
        {
            // Sledgehammer
            [self.collectionView reloadData];
        }
        
        [self resetCachedAssets];
    });
}

- (NSArray <NSIndexPath *> *)indexPathArrayFromIndexSet:(NSIndexSet *)indexSet
{
    NSMutableArray <NSIndexPath *> *idps = [NSMutableArray new];
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        NSIndexPath *idp = [NSIndexPath indexPathForItem:idx inSection:0];
        [idps addObject:idp];
    }];
    
    return idps;
}

#pragma mark - Collection View Flow Delegate

- (void)calculateCollectionViewLayout
{
    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.minimumInteritemSpacing = SSSpacingMargin;
    layout.minimumLineSpacing = SSSpacingMargin;
    layout.sectionInset = UIEdgeInsetsMake(0, CV_LAYOUT_INSET, CV_LAYOUT_INSET, CV_LAYOUT_INSET);
    self.layout = layout;
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSSet <NSString *> *oneInARowItems = [NSSet setWithArray:@[@"3"]];
    NSSet <NSString *> *twoInARowItems = [NSSet setWithArray:@[@"8",@"9"]];
    NSSet <NSString *> *threeInARowItems = [NSSet setWithArray:@[@"0",@"1",@"2"]];
    NSSet <NSString *> *fourInARowItems = [NSSet setWithArray:@[@"4",@"5",@"6",@"7"]];
    
    NSString *numAsString = @(indexPath.item).stringValue;
    numAsString = [numAsString substringFromIndex:numAsString.length - 1];
    NSInteger size = 0;
    
    if ([oneInARowItems containsObject:numAsString] && [self.view isLandscape] == NO) {
        size = [self sizeNumberOfRows:1];
    } else if ([twoInARowItems containsObject:numAsString]) {
        size = [self sizeNumberOfRows:2];
    } else if ([threeInARowItems containsObject:numAsString]) {
        size = [self sizeNumberOfRows:3];
    } else if ([fourInARowItems containsObject:numAsString]) {
        size = [self sizeNumberOfRows:4];
    }
    
    return CGSizeMake(size, size);
}

- (NSInteger)sizeNumberOfRows:(NSInteger)rows
{
    NSInteger collectionViewInset = CV_LAYOUT_INSET + self.view.safeAreaInsets.left;
    NSInteger collectionViewSpacingPerItem = SSSpacingMargin;
    
    NSInteger desiredItemsPerRow = rows;
    NSInteger leftRightCollectionViewMargins = (collectionViewInset * 2);
    NSInteger spacingPerItemsInRow = (collectionViewSpacingPerItem * 1);
    CGFloat size = floorf((self.view.boundsWidth - leftRightCollectionViewMargins)/desiredItemsPerRow) - spacingPerItemsInRow;
    
    if (rows == 1)
    {
        size = self.view.boundsWidth - (collectionViewInset * 2);
    }
    
    return size;
}

#pragma mark - Collection View Datasource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.fetchResult.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PHAsset *asset = self.fetchResult[indexPath.item];
    SSMediaCollectionViewCell *cell = (SSMediaCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:SS_MEDIA_CELL_ID forIndexPath:indexPath];
    
    cell.assetID = asset.localIdentifier;
    
    CGSize targetSize = [self collectionView:self.collectionView layout:self.layout sizeForItemAtIndexPath:indexPath];
    CGFloat scale = [UIScreen mainScreen].scale;
    targetSize = CGSizeMake(targetSize.width * scale, targetSize.height * scale);
    
    PHImageRequestOptions *options = [PHImageRequestOptions new];
    options.networkAccessAllowed = YES;
    
    [self.imageManager requestImageForAsset:asset targetSize:targetSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage *result, NSDictionary *info) {
        if ([cell.assetID isEqualToString:asset.localIdentifier])
        {
            [cell setImage:result];
        }
    }];
    
    return cell;
}

#pragma mark - Collection View Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    [self.delegate didSelectAsset:self.fetchResult[indexPath.item]];
    
    if (self.navigationController.viewControllers.count > 1)
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Pointer Interaction Delegate

- (nullable UIPointerStyle *)pointerInteraction:(UIPointerInteraction *)interaction styleForRegion:(UIPointerRegion *)region API_AVAILABLE(ios(13.4))
{
    if (interaction.view == nil) return nil;
    
    UITargetedPreview *targetedPreview = [[UITargetedPreview alloc] initWithView:interaction.view];
    
    UIPointerLiftEffect *hover = [UIPointerLiftEffect effectWithPreview:targetedPreview];
    UIPointerStyle *pointerStyle = [UIPointerStyle styleWithEffect:hover
                                                             shape:nil];
    return pointerStyle;
}


#pragma mark - Scrollview

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self updateCachedAssets];
}

@end
