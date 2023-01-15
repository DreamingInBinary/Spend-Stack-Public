//
//  SSAdvancedListOptionsViewController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 12/30/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSAdvancedListOptionsViewController.h"
#import "EmailSender.h"
#import "UIImageView+SSUtils.h"
#import "UIImage+Utils.h"
#import "UIView+SSShimmer.h"

typedef NS_ENUM(NSUInteger, SSCloudOperation) {
    SSCloudOperationPull,
    SSCloudOperationPush,
    SSCloudOperationAppWideFetch
};

@interface SSAdvancedListOptionsViewController () <UIPointerInteractionDelegate>

@property (nonatomic) OptionScope scope;
@property (strong, nonatomic, nonnull) EmailSender *emailer;
@property (strong, nonatomic, nullable) SSList *list;
@property (strong, nonatomic, nonnull) SSVerticalView *verticalView;
@property (strong, nonatomic, nonnull) UIActivityIndicatorView *spinnerView;
@property (strong, nonatomic, nonnull) SSLabel *resyncStatusLabel;

@end

@implementation SSAdvancedListOptionsViewController

#pragma mark - Initializer

- (instancetype)initWithList:(SSList *)list scope:(OptionScope)scope
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self)
    {
        self.scope = scope;
        self.list = list;
        self.verticalView = [[SSVerticalView alloc] initWithSecondaryBackgroundColor];
        
        self.spinnerView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        self.resyncStatusLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleTitle3];
        self.resyncStatusLabel.text = self.scope == OptionScopeList ? ss_Localized(@"advList.vc.syncing") : ss_Localized(@"advList.vc.performing");
        self.resyncStatusLabel.textAlignment = NSTextAlignmentCenter;
        self.spinnerView.hidden = YES;
        self.resyncStatusLabel.hidden = YES;
        [self.resyncStatusLabel configureFontWeight:UIFontWeightMedium];
        
        [self.view addSubviews:@[self.verticalView, self.spinnerView, self.resyncStatusLabel]];
        [self.verticalView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.and.right.equalTo(self.view);
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
        }];
        
        if (self.scope == OptionScopeApp)
        {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(appFetchComplete)
                                                         name:SS_CK_MANAGER_CLEAN_FETCH_COMPLETE
                                                       object:nil];
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(appFetchFailed)
                                                         name:SS_CK_MANAGER_CLEAN_FETCH_ERROR
                                                       object:nil];
        }
    }
    
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = ss_Localized(@"advList.vc.title");
    self.emailer = [[EmailSender alloc] initWithContainingController:self];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    SSLabel *resyncHeader = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleTitle3];
    [resyncHeader configureFontWeight:UIFontWeightSemibold];
    resyncHeader.text = ss_Localized(@"avdList.vc.iCloud");
    
    // Resync
    UIImageView *syncImgView = [UIImageView sqaureIconImageView];
    syncImgView.backgroundColor = [UIColor appleBlue];
    UIImage *syncImg = [UIImage systemImageNamed:@"icloud.and.arrow.up.fill"];
    syncImgView.image = syncImg;
    [syncImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.and.height.equalTo(@([UIImageView squareIconImageViewSize]));
    }];
    
    SSLabel *resyncButton = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleBody];
    resyncButton.textColor = [UIColor ssPrimaryColor];
    resyncButton.text = ss_Localized(@"advList.vc.resync");
    [resyncButton configureFontWeight:UIFontWeightMedium];
    
    SSHorizontalStackView *horizontalStack = [SSHorizontalStackView new];
    horizontalStack.spacing = SSSpacingBigMargin;
    [horizontalStack setArrangedSubviews:@[syncImgView, resyncButton]];
    
    SSLabel *resyncExplainer = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleFootnote];
    resyncExplainer.text = ss_Localized(@"advList.vc.explainSync");
    resyncExplainer.textColor = [UIColor ssSecondaryColor];
    
    // Refetch
    UIImageView *downloadImgView = [UIImageView sqaureIconImageView];
    downloadImgView.backgroundColor = [UIColor appleTealBlue];
    UIImage *downloadImg = [UIImage systemImageNamed:@"icloud.and.arrow.down.fill"];
    downloadImgView.image = downloadImg;
    [downloadImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.and.height.equalTo(@([UIImageView squareIconImageViewSize]));
    }];
    
    SSLabel *downloadButton = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleBody];
    downloadButton.textColor = [UIColor ssPrimaryColor];
    downloadButton.text = ss_Localized(@"advList.vc.fetch");
    [downloadButton configureFontWeight:UIFontWeightMedium];
    
    SSHorizontalStackView *horizontalStackDownload = [SSHorizontalStackView new];
    horizontalStackDownload.spacing = SSSpacingBigMargin;
    [horizontalStackDownload setArrangedSubviews:@[downloadImgView, downloadButton]];
    
    SSLabel *downloadExplainer = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleFootnote];
    downloadExplainer.text = ss_Localized(@"advList.vc.explainFetch");
    downloadExplainer.textColor = [UIColor ssSecondaryColor];
    
    // App wide fetch
    SSLabel *downloadAppWideButton = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleBody];
    downloadAppWideButton.textColor = [UIColor ssPrimaryColor];
    downloadAppWideButton.text = ss_Localized(@"advList.vc.performFetch");
    [downloadAppWideButton configureFontWeight:UIFontWeightMedium];
    
    [horizontalStackDownload addInteraction:[[UIPointerInteraction alloc] initWithDelegate:self]];
    [horizontalStack addInteraction:[[UIPointerInteraction alloc] initWithDelegate:self]];
    
    if (self.scope == OptionScopeApp)
    {
        [horizontalStackDownload removeArrangedSubview:downloadButton];
        [downloadButton removeFromSuperview];
        [horizontalStackDownload addArrangedSubview:downloadAppWideButton];
        downloadExplainer.text = ss_Localized(@"advList.vc.allFetch");
        [self.verticalView addRows:@[resyncHeader,
                                     horizontalStackDownload,
                                     downloadExplainer] animated:NO];
    }
    else
    {
        downloadExplainer.text = ss_Localized(@"advList.vc.listFetch");
        [self.verticalView addRows:@[resyncHeader,
                                     horizontalStack,
                                     resyncExplainer,
                                     horizontalStackDownload,
                                     downloadExplainer] animated:NO];
    }

    [self.verticalView setInsetForRow:resyncHeader
                                inset:UIEdgeInsetsMake(SSTopElementMargin, SSLeftBigElementMargin, 0, SSRightBigElementMargin)];
    [self.verticalView setInsetForRow:resyncExplainer
                                inset:UIEdgeInsetsMake(SSTopBigElementMargin, SSLeftBigElementMargin, SSBottomBigElementMargin, SSRightBigElementMargin)];
    [self.verticalView setInsetForRow:resyncButton
                                inset:UIEdgeInsetsMake(0, SSLeftBigElementMargin, SSBottomBigElementMargin, SSRightBigElementMargin)];
    [self.verticalView setInsetForRow:horizontalStackDownload
                                inset:UIEdgeInsetsMake(SSTopBigElementMargin, SSLeftBigElementMargin, SSBottomBigElementMargin, SSRightBigElementMargin)];
    [self.verticalView setInsetForRow:downloadExplainer
                                inset:UIEdgeInsetsMake(SSTopBigElementMargin, SSLeftBigElementMargin, SSBottomBigElementMargin, SSRightBigElementMargin)];
    
    [self.verticalView hideSeparatorForRows:@[resyncHeader, resyncExplainer, downloadExplainer]];
    
    __weak typeof(self) weakSelf = self;
    [self.verticalView setTapHandlerForRow:horizontalStack handler:^(UIView *view) {
        [weakSelf forceSaveList];
    }];
    
    [self.verticalView setTapHandlerForRow:horizontalStackDownload handler:^(UIView *view) {
        if (self.scope == OptionScopeApp)
        {
            [weakSelf performAppFetch];
        }
        else
        {
            [weakSelf refetchList];
        }
    }];
}

#pragma mark - App Fetch

- (void)performAppFetch
{
    if ([self performOperationPreflightChecks] == NO) return;
    [self showLoadingUI:SSCloudOperationAppWideFetch];
    [[SSDataStore sharedInstance].ckManager cleanFetchAllData];
}

- (void)appFetchComplete
{
    [self handleOperationCompleted:nil operationType:SSCloudOperationAppWideFetch];
}

- (void)appFetchFailed
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self handleOperationCompleted:[NSError errorWithDomain:@"com.spendstack.fetchFailure" code:0101 userInfo:@{NSLocalizedDescriptionKey:ss_Localized(@"advList.vc.appFetchFailed")}] operationType:SSCloudOperationAppWideFetch];
    });
}

#pragma mark - Resave

- (void)forceSaveList
{
    if ([self performOperationPreflightChecks] == NO) return;
    [self showLoadingUI:SSCloudOperationPush];
    
    NSMutableArray <SSObject *> *listItems = [NSMutableArray new];
    [listItems addObjectsFromArray:@[self.list, self.list.taxInfo]];
    [listItems addObjectsFromArray:self.list.datasourceAdapter.allItems];

    [[self.list dbForList] saveObjects:listItems
                        withSavePolicy:CKRecordSaveAllKeys
                         deleteObjects:@[]
                        withCompletion:^(NSError *error) {
                            NSLog(@"Spend Stack - Finished force push with error:%@", error);
                            [self handleOperationCompleted:error
                                             operationType:SSCloudOperationPush];
    }];
}

#pragma mark - Force Pull

- (void)refetchList
{
    if ([self performOperationPreflightChecks] == NO) return;
    [self showLoadingUI:SSCloudOperationPull];
    
    NSMutableArray <CKRecord *> *listItemRecords = [NSMutableArray new];
    NSMutableArray <SSObject *> *listItems = [NSMutableArray new];
    [listItems addObjectsFromArray:@[self.list, self.list.taxInfo]];
    [listItems addObjectsFromArray:self.list.datasourceAdapter.allItems];
    
    for (SSObject *obj in listItems)
    {
        [listItemRecords addObject:obj.objCKRecord];
    }
    
    __weak typeof(self) weakSelf = self;
    [[SSDataStore sharedInstance].ckManager fetchRecords:listItemRecords inDatabase:[self.list dbForList] withCompletion:^(NSError *error) {
        NSLog(@"Spend Stack - Finished force pull with error:%@", error);
        [weakSelf handleOperationCompleted:error
                             operationType:SSCloudOperationPull];
    }];
}

#pragma mark - Misc

- (void)sendEmail
{
    [self.emailer sendSupportEmail];
}

- (BOOL)performOperationPreflightChecks
{
    if ([SSDataStore sharedInstance].ckManager.accountStatus == CKAccountStatusNoAccount)
    {
        [self showAlertControllerWithTitle:ss_Localized(@"advList.vc.signIn")
                                   message:ss_Localized(@"advList.vc.singInExplain")];
        return NO;
    }
    else if (self.connectionIsAvailable == NO)
    {
        [self showAlertControllerWithTitle:ss_Localized(@"general.noConnection")
                                   message:ss_Localized(@"advList.vc.noCon")];
        return NO;
        
    }
    
    return YES;
}

- (void)showLoadingUI:(SSCloudOperation)op
{
    [self.spinnerView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_centerY).with.offset(SSBottomElementMargin);
        make.centerX.equalTo(self.view.mas_centerX);
        make.height.and.width.equalTo(self.spinnerView);
    }];
    
    [self.resyncStatusLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_centerY).with.offset(SSTopElementMargin);
        make.centerX.equalTo(self.view.mas_centerX);
        make.height.equalTo(self.resyncStatusLabel);
        make.width.equalTo(self.view.mas_width).multipliedBy(0.64f);
    }];
    
    [self.spinnerView startAnimating];
    
    self.verticalView.hidden = YES;
    self.spinnerView.hidden = NO;
    self.resyncStatusLabel.hidden = NO;
    self.resyncStatusLabel.text = op == SSCloudOperationPush ? ss_Localized(@"advList.vc.syncing") : ss_Localized(@"advList.vc.fetching");
    if (op == SSCloudOperationAppWideFetch) self.resyncStatusLabel.text = ss_Localized(@"advList.vc.performing2");
    [self.resyncStatusLabel startShimmering];
}

- (void)handleOperationCompleted:(NSError *)error operationType:(SSCloudOperation)op {
    dispatch_async(dispatch_get_main_queue(), ^ {
        [self.resyncStatusLabel endShimmering];
        [self.spinnerView stopAnimating];
        self.spinnerView.hidden = YES;
        
        NSString *completionString = op == SSCloudOperationPush ? ss_Localized(@"advList.vc.doneList") : ss_Localized(@"advList.vc.doneFetch");
        if (op == SSCloudOperationAppWideFetch) completionString = ss_Localized(@"advList.vc.completed");
        
        [self.resyncStatusLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.view.mas_centerY).with.offset(SSBottomElementMargin);
            make.centerX.equalTo(self.view.mas_centerX);
            make.height.equalTo(self.resyncStatusLabel);
            make.width.equalTo(self.view.mas_width).multipliedBy(0.64f);
        }];
        
        [UIView animateWithDuration:SSFastestAnimationDuration animations:^{
            [self.view layoutIfNeeded];
        }];
        
        if (error == nil)
        {
            [UIFeedbackGenerator playFeedbackOfType:SSHapticFeedbackTypeSuccess];
            self.resyncStatusLabel.text = completionString;
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.resyncStatusLabel.hidden = YES;
                
                self.verticalView.hidden = NO;
                self.verticalView.alpha = 0.0f;
                [UIView animateWithDuration:SSFastAnimationDuration animations:^{
                    self.verticalView.alpha = 1.0f;
                }];
            });
        }
        else
        {
            [UIFeedbackGenerator playFeedbackOfType:SSHapticFeedbackTypeError];
            self.resyncStatusLabel.text = [NSString stringWithFormat:ss_Localized(@"advList.vc.error"), error.localizedDescription];
            
            SSButton *contactSupport = [[SSButton alloc] initWithLabelStyle:ss_Localized(@"general.contactSupport")];
            [contactSupport addTarget:self action:@selector(sendEmail) forControlEvents:UIControlEventTouchUpInside];
            [self.view addSubview:contactSupport];
            
            [contactSupport mas_makeConstraints:^(MASConstraintMaker *make) {
                make.centerX.equalTo(self.view.mas_centerX);
                make.top.equalTo(self.view.mas_centerY).with.offset(SSTopElementMargin);
            }];
        }
    });
}

#pragma mark - Pointer Interaction Delegate

- (nullable UIPointerStyle *)pointerInteraction:(UIPointerInteraction *)interaction styleForRegion:(UIPointerRegion *)region API_AVAILABLE(ios(13.4))
{
    SSHorizontalStackView *hStack = (SSHorizontalStackView *)interaction.view;
    SSLabel *downloadButton;
    
    for (UIView *view in hStack.arrangedSubviews)
    {
        if ([view isKindOfClass:[SSLabel class]])
        {
            downloadButton = (SSLabel *)view;
            break;
        }
    }
    
    if (downloadButton == nil) return nil;
    
    CGRect targetRect = [downloadButton.text boundingRectWithWidth:hStack.boundsWidth
                                                              text:downloadButton.text
                                                              font:downloadButton.font];
    targetRect = CGRectMake(0, 0, targetRect.size.width, downloadButton.boundsHeight);
    targetRect = CGRectInset(targetRect, -4, -4);
    UIPreviewParameters *previewParams = [UIPreviewParameters new];
    previewParams.visiblePath = [UIBezierPath bezierPathWithRoundedRect:targetRect cornerRadius:SSSpacingMargin];
    
    UITargetedPreview *targetedPreview = [[UITargetedPreview alloc] initWithView:downloadButton parameters:previewParams];
    UIPointerHoverEffect *hover = [UIPointerHoverEffect effectWithPreview:targetedPreview];
    hover.prefersScaledContent = NO;
    
    return [UIPointerStyle styleWithEffect:hover shape:nil];
}


@end
