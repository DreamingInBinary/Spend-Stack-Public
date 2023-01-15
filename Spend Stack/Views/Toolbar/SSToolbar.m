//
//  SSToolbar.m
//  Spend Stack
//
//  Created by Jordan Morgan on 1/2/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "SSToolbar.h"
#import "SSTagSelectionViewModel.h"
#import "Spend_Stack_2-Swift.h"

static const NSInteger SS_GENERIC_BUTTON_TAG = 3524;

@interface SSToolbar()

@property (strong, nonatomic, nonnull) NSArray <SSToolBarItem *> *ssItems;
@property (nonatomic, getter=doesPreferDyamicStyling) BOOL preferDynamicStyling;
@property (strong, nonatomic, nullable) TagsHorizontalView *tagsView;
@property (strong, nonatomic, nullable) UIView *cloneView;

@end

@implementation SSToolbar

#pragma mark - Customer Setters

- (void)setGenericButtonTitle:(NSString *)genericButtonTitle
{
    _genericButtonTitle = genericButtonTitle;
    
    for (UIBarButtonItem *buttonItem in self.items)
    {
        if (buttonItem.tag == SS_GENERIC_BUTTON_TAG)
        {
            [self setItems:[self generateBarButtons:self.ssItems]];
            return;
        }
    }
    
    NSLog(@"Spend Stack - Error: Couldn't find generic button item to set title.");
}

#pragma mark - Initializers

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        [self commonInit];
    }
    
    return self;
}

- (instancetype)initWithItemTypes:(NSArray<SSToolBarItem *> *)items
{
    self = [self init];
    
    if (self)
    {
        self.ssItems = items;
        [self setItems:[self generateBarButtons:self.ssItems]];
    }
    
    return self;
}

- (instancetype)initForDynamicStlyingWithItemTypes:(NSArray<SSToolBarItem *> *)items
{
    self = [self initWithItemTypes:items];
    
    if (self)
    {
        self.preferDynamicStyling = YES;
        [self configureStyling];
    }
    
    return self;
}

- (void)commonInit
{
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.tintColor = [UIColor ssPrimaryColor];
    self.ssItems = @[];
    self.clipsToBounds = YES;
    [self configureStyling];
}

#pragma mark - View Lifecycle

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.shouldHideBarBackground)
    {
        // HACK!!!: This could break in any iOS version so keep checking it.
        for (UIView *view in self.subviews)
        {
            if ([view isKindOfClass:NSClassFromString(@"_UIBarBackground")])
            {
                view.hidden = YES;
            }
        }
    }
    
    if (self.doesPreferDyamicStyling) [self configureStyling];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    [self configureStyling];
}

#pragma mark - Styling

- (void)configureStyling
{
    UIToolbarAppearance *tb = [UIToolbarAppearance new];
    if (self.preferDynamicStyling)
    {
        [tb configureWithTransparentBackground];
    }
    else
    {
        UIColor *fill = [UIColor systemBackgroundColor];
        tb.backgroundColor = fill;
    }
    
    self.standardAppearance = tb;
    self.compactAppearance = tb;
}

- (void)overrideStylingWithColor:(UIColor *)color
{
    UIToolbarAppearance *tb = [UIToolbarAppearance new];
    [tb configureWithOpaqueBackground];
    tb.backgroundColor = color;
    self.standardAppearance = tb;
    self.compactAppearance = tb;
}

- (void)animateTagView:(NSArray <SSListTag *> *)sharedTags
{
    // Duplicate view so it does *not* scale
    self.cloneView = [SSCitizenship transparentViewIfPossibleWithStyle:UIBlurEffectStyleSystemThickMaterial];
    self.cloneView.frame = self.frame;
    self.cloneView.ss_y = self.superview.ss_y;
    [SSCitizenship setViewFadeOutAnimation:self.cloneView];
    [self.window addSubview:self.cloneView];
    
    [UIFeedbackGenerator playFeedbackOfType:SSHapticFeedbackTypeStyleSoft];
    
    [UIView animateWithDuration:SSFasterThanFastestAnimationDuration animations:^{
        [SSCitizenship setViewFadeInAnimation:self.cloneView];
    } completion:^(BOOL finished) {
        [self addTagsCollectionViewIfNeeded:sharedTags];
        [UIView animateWithDuration:SSFasterThanFastestAnimationDuration animations:^{
            [SSCitizenship setViewFadeOutAnimation:self.cloneView];
        } completion:^(BOOL finished) {
            [self.cloneView removeFromSuperview];
        }];
    }];
}

- (void)hideTagView:(BOOL)clearingTagSelection
{
    [self.tagsView hideTags:clearingTagSelection];
}

- (void)animateTagViewDismiss
{
    // Duplicate view so it does *not* scale
    self.cloneView = [SSCitizenship transparentViewIfPossibleWithStyle:UIBlurEffectStyleSystemThickMaterial];
    self.cloneView.frame = self.frame;
    self.cloneView.ss_y = self.superview.ss_y;
    [SSCitizenship setViewFadeOutAnimation:self.cloneView];
    [self.window addSubview:self.cloneView];
    
    [UIFeedbackGenerator playFeedbackOfType:SSHapticFeedbackTypeStyleSoft];
    
    [UIView animateWithDuration:SSFasterThanFastestAnimationDuration animations:^{
        [SSCitizenship setViewFadeInAnimation:self.cloneView];
    } completion:^(BOOL finished) {
        [self.tagsView hideTags:YES];
        [UIView animateWithDuration:SSFasterThanFastestAnimationDuration animations:^{
            [SSCitizenship setViewFadeOutAnimation:self.cloneView];
        } completion:^(BOOL finished) {
            [self.cloneView removeFromSuperview];
        }];
    }];
}

#pragma mark - Public Methods

- (void)setToolBarItems:(NSArray<SSToolBarItem *> *)items
{
    self.ssItems = items;
    NSMutableArray <UIBarButtonItem *> *mutableItems = [NSMutableArray new];
    
    for (SSToolBarItem *itemType in items)
    {
        [mutableItems addObject:[self itemFromType:itemType]];
    }
    
    [self setItems:mutableItems animated:YES];
}

- (void)replaceToolBarItemForType:(SSToolBarItem * _Nonnull)itemType withItem:(UIBarButtonItem *)item
{
    if (self.items.count == 0) return;
    NSMutableArray <UIBarButtonItem *> *existingItems = [self.items mutableCopy];
    NSUInteger removalIndex = [self.ssItems indexOfObject:itemType];
    if (removalIndex == NSNotFound) return;
    [existingItems replaceObjectAtIndex:removalIndex withObject:item];
    [self setItems:existingItems animated:NO];
}

- (void)disableBarItemsAtIndicies:(NSArray<NSNumber *> *)indicesToDisable
{
    for (NSUInteger idx = 0; idx < self.items.count; idx++)
    {
        NSNumber *idxNum = @(idx);
        BOOL shouldDisable = [indicesToDisable containsObject:idxNum];
        self.items[idx].enabled = !shouldDisable;
    }
}

- (void)addTagsCollectionViewIfNeeded:(NSArray<SSListTag *> *)sharedTags
{
    if (self.tagsView == nil)
    {
        __weak typeof(self) weakSelf = self;
        self.tagsView = [[TagsHorizontalView alloc] initWithFrame:self.bounds listSharedTags:sharedTags];
        self.tagsView.onDoneTapped = ^(SSTagSelectionViewModel *selectedTag) {
            [weakSelf animateTagViewDismiss];
        };
        self.tagsView.onAddTapped = ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"tagViewAddPressed" object:nil];
        };
        [self addSubview:self.tagsView];
        [self.tagsView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
        [self.tagsView presentTags];
    }
    else
    {
        [self.tagsView presentTags];
    }
}

#pragma mark - Item Type Generators

- (NSArray <UIBarButtonItem *> * _Nonnull)generateBarButtons:(NSArray <SSToolBarItem *> * _Nonnull)items
{
    NSMutableArray <UIBarButtonItem *> *mutableItems = [NSMutableArray new];
    
    for (SSToolBarItem *itemType in items)
    {
        [mutableItems addObject:[self itemFromType:itemType]];
    }
    
    return [NSArray arrayWithArray:mutableItems];
}

- (UIBarButtonItem *)itemFromType:(SSToolBarItem *)itemType
{
    if ([itemType isEqualToString:(NSString *)SSToolBarItemTypeShare])
    {
        return [self shareBarButtonItem];
    }
    else if ([itemType isEqualToString:(NSString *)SSToolBarItemTypeSort])
    {
        return [self sortBarItem];
    }
    else if ([itemType isEqualToString:(NSString *)SSToolBarItemTypeBarcode])
    {
        return [self barcodeBarItem];
    }
    else if ([itemType isEqualToString:(NSString *)SSToolBarItemTypeTotal])
    {
        return [self totalBarItem];
    }
    else if ([itemType isEqualToString:(NSString *)SSToolBarItemTypePieChart])
    {
        return [self pieChartBarItem];
    }
    else if ([itemType isEqualToString:(NSString *)SSToolBarItemTypeDelete])
    {
        return [self deleteItem];
    }
    else if ([itemType isEqualToString:(NSString *)SSToolBarItemTypeBasicAdd])
    {
        return [self basicAddItem];
    }
    else if ([itemType isEqualToString:(NSString *)SSToolBarItemTypeBasicOutlinedAdd])
    {
        return [self basicAddOutlinedItem];
    }
    else if ([itemType isEqualToString:(NSString *)SSToolBarItemTypeAddTag])
    {
        return [self tagBarButtonItem];
    }
    else if ([itemType isEqualToString:(NSString *)SSToolBarItemTypeAddCircleTag])
    {
        return [self tagCircleBarButtonItem];
    }
    else if ([itemType isEqualToString:(NSString *)SSToolBarItemTypeAddItem])
    {
        return [self addItemBarButtonItem];
    }
    else if ([itemType isEqualToString:(NSString *)SSToolBarItemTypeDone])
    {
        return [self doneBarButtonitem];
    }
    else if ([itemType isEqualToString:(NSString *)SSToolBarItemTypeKeyboardDown])
    {
        return [self keyboardDownItem];
    }
    else if ([itemType isEqualToString:(NSString *)SSToolBarItemTypeMutedKeyboardDown])
    {
        return [self mutedKeyboardDownItem];
    }
    else if ([itemType isEqualToString:(NSString *)SSToolBarItemTypeEdit])
    {
        return [self customEditBarButtonitem];
    }
    else if ([itemType isEqualToString:(NSString *)SSToolBarItemTypeDoubleZero])
    {
        return [self doubleZeroBarButtonItem];
    }
    else if ([itemType isEqualToString:(NSString *)SSToolBarItemTypeExport])
    {
        return [self exportBarButtonItem];
    }
    else if ([itemType isEqualToString:(NSString *)SSToolBarItemTypeCamera])
    {
        return [self cameraBarButtonItem];
    }
    else if ([itemType isEqualToString:(NSString *)SSToolBarItemTypeCloudDocuments])
    {
        return [self documentsBarButtonItem];
    }
    else if ([itemType isEqualToString:(NSString *)SSToolBarItemTypeGeneric])
    {
        return [self genericBarButtonitem];
    }
    else if ([itemType isEqualToString:(NSString *)SSToolBarItemTypeGenericNoBorder])
    {
        return [self genericNoBorderBarButtonItem];
    }
    else if ([itemType isEqualToString:(NSString *)SSToolBarItemTypeFlexSpace])
    {
        return [self flexSpaceBarButtonItem];
    }
    else if ([itemType isEqualToString:(NSString *)SSToolBarItemTypePlusMinus])
    {
        return [self plusMinusBarButtonItem];
    }
    else if ([itemType isEqualToString:(NSString *)SSToolBarItemTypeCreditCard])
    {
        return [self creditCardBarButtonItem];
    }
    
    return nil;
}

- (UIBarButtonItem *)existingItemAtIndex:(NSInteger)itemIndex
{
    return self.items[itemIndex];
}

#pragma mark - Generators

- (UIBarButtonItem * _Nonnull)shareBarButtonItem
{
    UIBarButtonItem *shareBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(performOnShare)];
    return shareBarButtonItem;
}

- (UIBarButtonItem * _Nonnull)sortBarItem
{
    UIImage *sortImage = [UIImage systemImageNamed:@"arrow.up.arrow.down.circle"];
    UIBarButtonItem *sortBarButtonItem = [[UIBarButtonItem alloc] initWithImage:sortImage style:UIBarButtonItemStylePlain target:self action:@selector(performOnSort)];
    sortBarButtonItem.title = ss_Localized(@"general.sort");
    sortBarButtonItem.largeContentSizeImage = [sortImage imageScaledToSize:CGSizeMake(80, 80)];
    sortBarButtonItem.landscapeImagePhone = [sortImage imageScaledToSize:CGSizeMake(20, 20)];
    sortBarButtonItem.accessibilityLabel = ss_Localized(@"general.sort");
    
    return sortBarButtonItem;
}

- (UIBarButtonItem * _Nonnull)barcodeBarItem
{
    UIImage *barcodeImage = [UIImage imageNamed:@"barcode"];
    UIBarButtonItem *barcodeBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[barcodeImage imageScaledToSize:CGSizeMake(20, 20)] style:UIBarButtonItemStylePlain target:self action:@selector(performOnBarcode)];
    barcodeBarButtonItem.title = ss_Localized(@"barItem.scan");
    barcodeBarButtonItem.largeContentSizeImage = [[UIImage imageNamed:@"barcode"] imageScaledToSize:CGSizeMake(80, 80)];
    barcodeBarButtonItem.landscapeImagePhone = [[UIImage imageNamed:@"barcode"] imageScaledToSize:CGSizeMake(20, 20)];
    barcodeBarButtonItem.accessibilityLabel = ss_Localized(@"barItem.scan");
    
    return barcodeBarButtonItem;
}

- (UIBarButtonItem * _Nonnull)totalBarItem
{
    UIImage *totalImage = [UIImage imageNamed:@"total"];
    UIBarButtonItem *totalBarItem = [[UIBarButtonItem alloc] initWithImage:[totalImage imageScaledToSize:CGSizeMake(20, 20)] style:UIBarButtonItemStylePlain target:self action:@selector(performOnTotal)];
    totalBarItem.title = ss_Localized(@"barItem.listBreakdown");
    totalBarItem.largeContentSizeImage = [[UIImage imageNamed:@"total"] imageScaledToSize:CGSizeMake(80, 80)];
    totalBarItem.landscapeImagePhone = [[UIImage imageNamed:@"total"] imageScaledToSize:CGSizeMake(20, 20)];
    totalBarItem.accessibilityLabel = ss_Localized(@"barItem.listBreakdown.asc");
    
    return totalBarItem;
}

- (UIBarButtonItem * _Nonnull)pieChartBarItem
{
    UIImage *pieChartImage = [UIImage systemImageNamed:@"chart.pie"];
    UIBarButtonItem *pieChartBarItem = [[UIBarButtonItem alloc] initWithImage:pieChartImage style:UIBarButtonItemStylePlain target:self action:@selector(performOnPieChart)];
    pieChartBarItem.title = ss_Localized(@"barItem.insights");
    pieChartBarItem.largeContentSizeImage = [pieChartImage imageScaledToSize:CGSizeMake(80, 80)];
    pieChartBarItem.landscapeImagePhone = [pieChartImage imageScaledToSize:CGSizeMake(20, 20)];
    pieChartBarItem.accessibilityLabel = ss_Localized(@"barItem.insights");
    
    return pieChartBarItem;
}

- (UIBarButtonItem * _Nonnull)deleteItem
{
    UIBarButtonItem *deleteBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:ss_Localized(@"general.delete") style:UIBarButtonItemStylePlain target:self action:@selector(performOnDelete)];
    deleteBarButtonItem.tintColor = [UIColor colorFromHexString:@"#FF3B30"];
    
    return deleteBarButtonItem;
}

- (UIBarButtonItem * _Nonnull)basicAddItem
{
    UIImage *glyphImage = [UIImage systemImageNamed:@"plus.circle.fill"];
    UIBarButtonItem *basicAdd = [[UIBarButtonItem alloc] initWithImage:glyphImage style:UIBarButtonItemStylePlain target:self action:@selector(performOnBasicAdd)];
    basicAdd.title = ss_Localized(@"barItem.addItem");
    basicAdd.largeContentSizeImage = [glyphImage imageScaledToSize:CGSizeMake(80, 80)];
    basicAdd.landscapeImagePhone = [glyphImage imageScaledToSize:CGSizeMake(20, 20)];
    basicAdd.accessibilityLabel = ss_Localized(@"barItem.addItem");
    
    return basicAdd;
}

- (UIBarButtonItem * _Nonnull)basicAddOutlinedItem
{
    UIImage *glyphImage = [UIImage systemImageNamed:@"plus.circle"];
    UIBarButtonItem *basicAdd = [[UIBarButtonItem alloc] initWithImage:glyphImage style:UIBarButtonItemStylePlain target:self action:@selector(performOnBasicAdd)];
    basicAdd.title = ss_Localized(@"barItem.addItem");
    basicAdd.largeContentSizeImage = [glyphImage imageScaledToSize:CGSizeMake(80, 80)];
    basicAdd.landscapeImagePhone = [glyphImage imageScaledToSize:CGSizeMake(20, 20)];
    basicAdd.accessibilityLabel = ss_Localized(@"barItem.addItem");
    
    return basicAdd;
}

- (UIBarButtonItem * _Nonnull)tagBarButtonItem
{
    UIImage *tagIcon = [[UIImage systemImageNamed:@"tag.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIBarButtonItem *addTag = [[UIBarButtonItem alloc] initWithImage:tagIcon style:UIBarButtonItemStylePlain target:self action:@selector(performOnAddTag)];
    addTag.title = ss_Localized(@"barItem.addTag");
    addTag.accessibilityLabel = ss_Localized(@"barItem.addTag");
    
    return addTag;
}

- (UIBarButtonItem * _Nonnull)tagCircleBarButtonItem
{
    UIImage *tagIcon = [[UIImage systemImageNamed:@"tag.circle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIBarButtonItem *addTag = [[UIBarButtonItem alloc] initWithImage:tagIcon style:UIBarButtonItemStylePlain target:self action:@selector(performOnAddCircleTag)];
    addTag.title = ss_Localized(@"barItem.addTag");
    addTag.accessibilityLabel = ss_Localized(@"barItem.addTag");
    
    return addTag;
}

- (UIBarButtonItem * _Nonnull)addItemBarButtonItem
{
    return [self borderedButtonWithTitle:ss_Localized(@"barItem.add") selector:@selector(performOnAddItem)];
}

- (UIBarButtonItem * _Nonnull)doneBarButtonitem
{
    UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(performOnDone)];
    return doneItem;
}

- (UIBarButtonItem * _Nonnull)customEditBarButtonitem
{
    UIImage *editImage = [UIImage systemImageNamed:@"pencil.circle"];
    UIBarButtonItem *customEditBarButtonitem = [[UIBarButtonItem alloc] initWithImage:editImage style:UIBarButtonItemStylePlain target:self action:@selector(performOnEdit)];
    customEditBarButtonitem.title = ss_Localized(@"barItem.edit");
    customEditBarButtonitem.largeContentSizeImage = [editImage imageScaledToSize:CGSizeMake(80, 80)];
    customEditBarButtonitem.landscapeImagePhone = [editImage imageScaledToSize:CGSizeMake(20, 20)];
    customEditBarButtonitem.accessibilityLabel = ss_Localized(@"barItem.edit");
    
    return customEditBarButtonitem;
}

- (UIBarButtonItem * _Nonnull)keyboardDownItem
{
    UIImage *keyboardIcon = [[UIImage systemImageNamed:@"keyboard.chevron.compact.down"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.layer.cornerRadius = 4.0f;
    button.tintColor = [UIColor whiteColor];
    button.clipsToBounds = YES;
    button.backgroundColor = [UIColor ssPrimaryColor];
    button.bounds = CGRectMake(0, 0, 60, 34);
    button.accessibilityLabel = ss_Localized(@"barItem.kb");
    [button addTarget:self action:@selector(performOnKeyboardDown) forControlEvents:UIControlEventTouchUpInside];
    
    [button setBackgroundImage:[UIColor imageWithColor:[UIColor lightTextColor]] forState:UIControlStateHighlighted];
    [button setImage:keyboardIcon forState:UIControlStateNormal];
    
    return [[UIBarButtonItem alloc] initWithCustomView:button];
}

- (UIBarButtonItem * _Nonnull)mutedKeyboardDownItem
{
    UIImage *keyboardIcon = [[UIImage systemImageNamed:@"keyboard.chevron.compact.down"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.layer.cornerRadius = 4.0f;
    button.tintColor = [UIColor ssMainFontColor];
    button.clipsToBounds = YES;
    button.backgroundColor = [UIColor systemBackgroundColor];
    button.bounds = CGRectMake(0, 0, 60, 34);
    button.accessibilityLabel = ss_Localized(@"barItem.kb");
    [button addTarget:self action:@selector(performOnKeyboardDown) forControlEvents:UIControlEventTouchUpInside];
    
    [button setBackgroundImage:[UIColor imageWithColor:[UIColor ssControlHighlightedColor]] forState:UIControlStateHighlighted];
    [button setImage:keyboardIcon forState:UIControlStateNormal];
    
    return [[UIBarButtonItem alloc] initWithCustomView:button];
}

- (UIBarButtonItem * _Nonnull)doubleZeroBarButtonItem
{
    UIImage *plusMinus = [UIImage systemImageNamed:@"00.circle"];
    UIBarButtonItem *doubleZeroBarButtonItem = [[UIBarButtonItem alloc] initWithImage:plusMinus style:UIBarButtonItemStylePlain target:self action:@selector(performOnDoubleZero)];
    doubleZeroBarButtonItem.title = ss_Localized(@"barItem.zeroes.asc");
    doubleZeroBarButtonItem.largeContentSizeImage = [plusMinus imageScaledToSize:CGSizeMake(80, 120)];
    doubleZeroBarButtonItem.landscapeImagePhone = [plusMinus imageScaledToSize:CGSizeMake(20, 40)];
    doubleZeroBarButtonItem.accessibilityLabel = ss_Localized(@"barItem.zeroes.ascHint");
    
    return doubleZeroBarButtonItem;
}

- (UIBarButtonItem * _Nonnull)exportBarButtonItem
{
    UIBarButtonItem *exportBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:ss_Localized(@"barItem.export") style:UIBarButtonItemStylePlain target:self action:@selector(performOnExport)];
    exportBarButtonItem.accessibilityLabel = ss_Localized(@"barItem.export.asc");
    
    return exportBarButtonItem;
}

- (UIBarButtonItem * _Nonnull)cameraBarButtonItem
{
    UIBarButtonItem *cameraBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(performOnCamera)];
    cameraBarButtonItem.accessibilityLabel = ss_Localized(@"barItem.photo");
    
    return cameraBarButtonItem;
}

- (UIBarButtonItem * _Nonnull)documentsBarButtonItem
{
    UIImage *docIcon = [[UIImage systemImageNamed:@"folder"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIBarButtonItem *documentsBarButtonItem = [[UIBarButtonItem alloc] initWithImage:docIcon style:UIBarButtonItemStylePlain target:self action:@selector(performOnCloudDocuments)];
    documentsBarButtonItem.title = ss_Localized(@"barItem.docs");
    documentsBarButtonItem.largeContentSizeImage = [[UIImage systemImageNamed:@"folder"] imageScaledToSize:CGSizeMake(80, 80)];
    documentsBarButtonItem.landscapeImagePhone = [[UIImage systemImageNamed:@"folder"] imageScaledToSize:CGSizeMake(22, 24)];
    documentsBarButtonItem.accessibilityLabel = ss_Localized(@"barItem.docs");
    
    return documentsBarButtonItem;
}

- (UIBarButtonItem * _Nonnull)genericBarButtonitem
{
    UIBarButtonItem *genericItem = [self borderedButtonWithTitle:self.genericButtonTitle selector:@selector(performGenericAction)];
    genericItem.tag = SS_GENERIC_BUTTON_TAG;
    return genericItem;
}

- (UIBarButtonItem * _Nonnull)genericNoBorderBarButtonItem
{
    UIBarButtonItem *enericNoBorderBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:self.genericNoBorderButtonTitle style:UIBarButtonItemStylePlain target:self action:@selector(performGenericNoBorderAction)];
    
    return enericNoBorderBarButtonItem;
}

- (UIBarButtonItem * _Nonnull)flexSpaceBarButtonItem
{
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
}

- (UIBarButtonItem *)borderedButtonWithTitle:(NSString *)title selector:(SEL)selector
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    button.layer.cornerRadius = 4.0f;
    button.clipsToBounds = YES;
    button.backgroundColor = [UIColor ssPrimaryColor];
    button.bounds = CGRectMake(0,0,50,30);
    CGFloat width = [title boundingRectWithWidth:0 text:title font:button.titleLabel.font].size.width;
    width = (width + SSSpacingMargin) < 50 ? 50 : width + SSSpacingMargin;
    button.bounds = CGRectMake(0,0,width,30);
    
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor ssTextPlaceholderColor] forState:UIControlStateHighlighted];
    [button setBackgroundImage:[UIColor imageWithColor:[UIColor systemBackgroundColor]] forState:UIControlStateHighlighted];
    
    UIBarButtonItem *barButtonItem =  [[UIBarButtonItem alloc] initWithCustomView:button];
    barButtonItem.accessibilityLabel = title;
    
    return barButtonItem;
}

- (UIBarButtonItem *)secondaryBorderedButtonWithTitle:(NSString *)title selector:(SEL)selector
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    button.backgroundColor = [UIColor systemBackgroundColor];
    button.bounds = CGRectMake(0,0,50,30);
    CGFloat width = [title boundingRectWithWidth:0 text:title font:button.titleLabel.font].size.width;
    width = (width + SSSpacingMargin) < 50 ? 50 : width + SSSpacingMargin;
    button.bounds = CGRectMake(0,0,width,30);
    button.layer.cornerRadius = 4.0f;
    button.clipsToBounds = YES;
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    [button setTitleColor:[UIColor ssPrimaryColor] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor systemBackgroundColor] forState:UIControlStateHighlighted];
    [button setTitleColor:[UIColor ssMutedColor] forState:UIControlStateDisabled];
    [button setBackgroundImage:[UIColor imageWithColor:[UIColor ssMutedColor]] forState:UIControlStateHighlighted];
    
    UIBarButtonItem *barButtonItem =  [[UIBarButtonItem alloc] initWithCustomView:button];
    barButtonItem.accessibilityLabel = title;
    
    return barButtonItem;
}

- (UIBarButtonItem *)plusMinusBarButtonItem
{
    UIImage *plusMinus = [UIImage systemImageNamed:@"plusminus.circle"];
    UIBarButtonItem *plusMinusBarButtonItem = [[UIBarButtonItem alloc] initWithImage:plusMinus style:UIBarButtonItemStylePlain target:self action:@selector(performOnPlusMinus)];
    plusMinusBarButtonItem.title = ss_Localized(@"barItem.plusMinus");
    plusMinusBarButtonItem.largeContentSizeImage = [plusMinus imageScaledToSize:CGSizeMake(80, 120)];
    plusMinusBarButtonItem.landscapeImagePhone = [plusMinus imageScaledToSize:CGSizeMake(20, 40)];
    plusMinusBarButtonItem.accessibilityLabel = ss_Localized(@"barItem.plusMinus.asc");
            
    return plusMinusBarButtonItem;
}

- (UIBarButtonItem *)creditCardBarButtonItem
{
    UIImage *creditCardImage = [UIImage systemImageNamed:@"creditcard"];
    UIBarButtonItem *creditCardBarButtonItem = [[UIBarButtonItem alloc] initWithImage:creditCardImage style:UIBarButtonItemStylePlain target:self action:@selector(performOnCreditCard)];
    creditCardBarButtonItem.title = ss_Localized(@"barItem.appleCard");
    creditCardBarButtonItem.largeContentSizeImage = [creditCardImage imageScaledToSize:CGSizeMake(80, 120)];
    creditCardBarButtonItem.landscapeImagePhone = [creditCardImage imageScaledToSize:CGSizeMake(20, 40)];
    creditCardBarButtonItem.accessibilityLabel = ss_Localized(@"barItem.appleCard");
        
    return creditCardBarButtonItem;
}

#pragma mark - Completion Handlers

- (void)performOnShare
{
    self.onShare();
}

- (void)performOnSort
{
    self.onSort();
}

- (void)performOnBarcode
{
    self.onBarcode();
}

- (void)performOnTotal
{
    self.onTotal();
}

- (void)performOnPieChart
{
    self.onPieChart();
}

- (void)performOnDelete
{
    self.onDelete();
}

- (void)performOnBasicAdd
{
    self.onBasicAdd();
}

- (void)performOnAddTag
{
    self.onAddTag();
}

- (void)performOnAddCircleTag
{
    self.onAddCircleTag();
}

- (void)performOnAddItem
{
    self.onAddItem();
}

- (void)performOnKeyboardDown
{
    self.onKeyboardDown();
}

- (void)performOnEdit
{
    self.onEdit();
}

- (void)performOnDoubleZero
{
    self.onDoubleZero();
}

- (void)performOnExport
{
    self.onExport();
}

- (void)performOnCamera
{
    self.onCamera();
}

- (void)performOnCloudDocuments
{
    self.onCloudDocuments();
}

- (void)performOnDone
{
    self.onDone();
}

- (void)performGenericAction
{
    self.onGenericAction();
}

- (void)performGenericNoBorderAction
{
    self.onGenericNoBorderAction();
}

- (void)performOnPlusMinus
{
    self.onPlusMinus();
}

- (void)performOnCreditCard
{
    self.onCreditCard();
}

@end
