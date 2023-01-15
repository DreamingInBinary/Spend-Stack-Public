//
//  SSBarcodeScanViewController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 10/11/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSBarcodeScanViewController.h"
#import "SSBarcodeDataFetcher.h"
#import "SSBarcodeStateView.h"
#import "SSBarCodeDimmingView.h"
#import "UIView+SSShimmer.h"
#import "UITraitCollection+Utils.h"
#import <AVFoundation/AVFoundation.h>

static const NSInteger SS_ENTER_PRICE_DIMMER_TAG = 45453;
static const NSInteger SS_RESULT_VIEW_HEIGHT = 200;

typedef NS_ENUM(NSUInteger, SSScanScenario) {
    SSScanScenarioUnset,
    SSScanScenarioScanBarcode,
    SSScanScenarioEnterPrice,
};

@interface SSBarcodeScanViewController () <AVCaptureMetadataOutputObjectsDelegate, UIGestureRecognizerDelegate>

@property (nonatomic) SSScanScenario scenario;
@property (weak, nonatomic, nullable) id <SSBarcodeScanViewControllerDelegate> delegate;
@property (strong, nonatomic, nullable) SSBarcodeSearchResult *result;
@property (strong, nonatomic, nonnull) NSMutableArray <NSString *> *barcodes;
@property (strong, nonatomic, nonnull) AVCaptureSession *captureSession;
@property (strong, nonatomic, nonnull) AVCaptureVideoPreviewLayer *previewLayer;
@property (strong, nonatomic, nonnull) UIButton *closeButton;
@property (strong, nonatomic, nonnull) UIView *captureBox;
@property (strong, nonatomic, nonnull) SSBarCodeDimmingView *dimView;
@property (strong, nonatomic, nullable) SSBarcodeStateView *resultView;
@property (strong, nonatomic, nullable) SSTextField *enterPriceTextField;
@property (nonatomic, getter=didCompleteIntroAnimation) BOOL completedIntroAnimation;
 
@end

@implementation SSBarcodeScanViewController

#pragma mark - Custom Getters

- (BOOL)captureAvailable
{
    if ([self.captureSession isRunning])
    {
        return YES;
    }
    
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:nil];
    BOOL available = (videoInput != nil && [self.captureSession canAddInput:videoInput]);
    
    if (available == NO)
    {
        self.captureBox.hidden = YES;
        self.resultView.hidden = YES;
    }
    
    return available;
}

- (SSTextField *)enterPriceTextField
{
    if (!_enterPriceTextField)
    {
        // Basic Setup
        _enterPriceTextField = [[SSTextField alloc] initWithTextStyle:UIFontTextStyleTitle1];
        //_enterPriceTextField.placeholder = [self.taxUtil guranteedCurrencyString:@"0"];
        _enterPriceTextField.keyboardType = UIKeyboardTypeNumberPad;
        [_enterPriceTextField configureFontWeight:UIFontWeightBold];
        
        // Toolbar
        SSToolbar *tb = [[SSToolbar alloc] initWithItemTypes:@[SSToolBarItemTypeDoubleZero,
                                                               SSToolBarItemTypeFlexSpace,
                                                               SSToolBarItemTypeKeyboardDown]];
        tb.clipsToBounds = NO;
        
        __weak typeof(self) weakSelf = self;
        tb.onDoubleZero = ^{
            weakSelf.enterPriceTextField.text = [weakSelf.enterPriceTextField.text stringByAppendingString:@"00"];
            NSNotification *fakeNote = [NSNotification notificationWithName:UITextFieldTextDidChangeNotification object:weakSelf.enterPriceTextField];
            [weakSelf textFieldDidChangeNotification:fakeNote];
        };
        tb.onKeyboardDown = ^{
            [weakSelf removeEnterPriceUI];
        };
        _enterPriceTextField.inputAccessoryView = tb;
        
        // Respond to edits
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(textFieldDidChangeNotification:)
                                                     name:UITextFieldTextDidChangeNotification
                                                   object:_enterPriceTextField];
    }
    
    return _enterPriceTextField;
}

#pragma mark - Intializer

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [self initWithDelegate:nil];
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [self initWithDelegate:nil];
    return self;
}

- (instancetype)initWithDelegate:(id<SSBarcodeScanViewControllerDelegate>)delegate
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self)
    {
        self.delegate = delegate;
    }
    
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Scan Barcode";
    self.captureSession = [AVCaptureSession new];
    self.barcodes = [NSMutableArray new];
    
    UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissController)];
    self.navigationItem.leftBarButtonItem = doneBarButtonItem;
    
    [self beginCaptureSession];
    [self addDimViewToView];
    [self addCloseButtonToView];
    [self drawCaptureBox];
    [self addResultViewToView];
    [self setNeedsStatusBarAppearanceUpdate];
    
    if ([self captureAvailable])
    {
        self.scenario = SSScanScenarioScanBarcode;
        
        // Animate in the state view
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self updateFinalPositionConstraintsForResultView];
            [self.resultView performBlurIn];
            
            [UIView animateWithDuration:SSBriefAnimationDuration delay:0 usingSpringWithDamping:.70f initialSpringVelocity:.80f options:UIViewAnimationOptionCurveEaseOut animations:^{
                [UIView animateWithDuration:SSFastestAnimationDuration animations:^{
                    [self.view layoutIfNeeded];
                }];
            } completion:^ (BOOL done) {
                self.completedIntroAnimation = done;
            }];
        });
    }
    else
    {
        [self showErrorStateUI];
    }
    
    // Swipe to dismiss
    UISwipeGestureRecognizer *swipeToLeave = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(dismissController)];
    swipeToLeave.direction = UISwipeGestureRecognizerDirectionDown;
    swipeToLeave.delegate = self;
    [self.view addGestureRecognizer:swipeToLeave];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.previewLayer.frame = self.view.bounds;
    self.dimView.cutOutFrame = self.captureBox.frame;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    if (self.traitCollection == previousTraitCollection ||
        self.captureBox.superview == nil ||
        self.resultView.superview == nil ||
        self.didCompleteIntroAnimation == NO) return;
 
    if (self.resultView.layoutState == SSBarcodeSearchLayoutStateResultFound)
    {
        [self updateFinalPositionConstraintsForResultViewResultsFound];
    }
    else
    {
        [self updateFinalPositionConstraintsForCaptureBox];
        [self updateFinalPositionConstraintsForResultView];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return self.enterPriceTextField.isFirstResponder ? UIStatusBarStyleDefault : UIStatusBarStyleLightContent;
}

#pragma mark - Gesture Recognizer Delegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint locationInView = [gestureRecognizer locationInView:self.view];
    
    // Swipe to dismiss shouldn't occur when entering the price or swiping on the result view
    return CGRectContainsPoint(self.resultView.frame, locationInView) == NO &&
           self.enterPriceTextField.isFirstResponder == NO;
}

#pragma mark - Error UI

- (void)showErrorStateUI
{
    self.dimView.closeCutOut = YES;
    [self.dimView setNeedsDisplay];
    
    NSInteger iconSize = 80;
    
    SSLabel *errorLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleTitle3];
    errorLabel.textAlignment = NSTextAlignmentCenter;
    errorLabel.textColor = [UIColor systemBackgroundColor];
    errorLabel.text = @"We ran into an issue starting your camera.\nPlease contact support if this continues.";
    [errorLabel sizeToFit];
    
    // Add no camera icon
    UIImage *noCamIcon = [[[UIImage imageNamed:@"noCamera"]
                           imageScaledToSize:CGSizeMake(iconSize, iconSize)]
                          imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImageView *noCamIconImgView = [[UIImageView alloc] initWithImage:noCamIcon];
    noCamIconImgView.tintColor = [UIColor ssSecondaryColor];
    noCamIconImgView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    noCamIconImgView.ss_size = CGSizeMake(iconSize, iconSize);
    
    [self.view addSubviews:@[errorLabel, noCamIconImgView]];
    
    [errorLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.captureBox.mas_top).with.offset(SSTopBigElementMargin);
        make.left.equalTo(self.captureBox.mas_left).with.offset(SSLeftBigElementMargin);
        make.right.equalTo(self.captureBox.mas_right).with.offset(SSRightBigElementMargin);
        make.height.equalTo(errorLabel.mas_height);
    }];
    
    [noCamIconImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(errorLabel.mas_bottom).with.offset(SSTopBigElementMargin);
        make.centerX.equalTo(self.captureBox.mas_centerX);
        make.width.and.height.equalTo(@(iconSize));
    }];
}

#pragma mark - UI Construction

- (void)addDimViewToView
{
    self.dimView = [[SSBarCodeDimmingView alloc] initWithFrame:self.view.bounds];
    self.dimView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.5f];
    [self.view addSubview:self.dimView];
    
    [self.dimView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (void)addCloseButtonToView
{
    self.closeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.closeButton.tintColor = [UIColor systemBackgroundColor];
    [self.closeButton setImage:[UIImage systemImageNamed:@"xmark.circle.fill"] forState:UIControlStateNormal];
    [self.closeButton addTarget:self action:@selector(dismissController) forControlEvents:UIControlEventTouchUpInside];
    self.closeButton.accessibilityHint = @"Stop barcode scan";
    self.closeButton.accessibilityValue = @"Close";
    [self.view addSubview:self.closeButton];
    
    [self.closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.and.width.equalTo(@46);
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).with.offset(SSTopBigElementMargin);
        make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft).with.offset(SSLeftBigElementMargin);
    }];
}

- (void)drawCaptureBox
{
    self.captureBox = [UIView new];
    self.captureBox.backgroundColor = [UIColor clearColor];
    self.captureBox.layer.borderWidth = 3.0f;
    self.captureBox.layer.borderColor = [UIColor systemBackgroundColor].CGColor;
    self.captureBox.layer.cornerRadius = SSSpacingBigMargin;
    [self.view addSubview:self.captureBox];
    [self updateFinalPositionConstraintsForCaptureBox];
}

- (void)addResultViewToView
{
    self.resultView = [[SSBarcodeStateView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.resultView];
    
    __weak typeof(self) weakSelf = self;
    self.resultView.onEnterPrice = ^{
        [weakSelf enterPrice];
    };
    
    self.resultView.onRetry = ^{
        weakSelf.previewLayer.connection.enabled = YES;
    };
    
    if ([self.view isLandscape])
    {
        [self.resultView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.view.mas_left);
            make.width.equalTo(self.view.mas_width).multipliedBy(0.33f);
            make.top.equalTo(self.closeButton.mas_bottom).with.offset(SSTopBigElementMargin);
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).with.offset(SSBottomBigElementMargin);
        }];
    }
    else
    {
        [self.resultView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@(SS_RESULT_VIEW_HEIGHT));
            make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft).with.offset(4);
            make.right.equalTo(self.view.mas_safeAreaLayoutGuideRight).with.offset(-4);
            make.bottom.equalTo(self.view.mas_bottom).with.offset(SS_RESULT_VIEW_HEIGHT);
        }];
    }
}

#pragma mark - Constraint Updates

- (void)updateFinalPositionConstraintsForCaptureBox
{
    if ([self.view isLandscape])
    {
        [self.captureBox mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.view.mas_centerY);
            make.width.equalTo(self.view.mas_width).multipliedBy(0.50f);
            make.right.equalTo(self.view.mas_safeAreaLayoutGuideRight).with.offset(SSRightBigElementMargin);
            make.height.equalTo(self.view.mas_height).multipliedBy(0.33f);
        }];
    }
    else
    {
        [self.captureBox mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.view.mas_centerY).with.offset(SSBottomBigElementMargin);
            make.left.equalTo(self.view.mas_leftMargin);
            make.right.equalTo(self.view.mas_rightMargin);
            make.height.equalTo(self.view.mas_height).multipliedBy(0.24f);
        }];
    }
}

- (void)updateFinalPositionConstraintsForResultView
{
    if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular)
    {
        [self.resultView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@(SS_RESULT_VIEW_HEIGHT));
            make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft).with.offset(4);
            make.right.equalTo(self.view.mas_safeAreaLayoutGuideRight).with.offset(-4);
            make.bottom.equalTo(self.view.mas_bottom).with.offset(-4);
        }];
    }
    else
    {
        [self.resultView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.closeButton.mas_left);
            make.right.equalTo(self.captureBox.mas_left).with.offset(SSRightBigElementMargin);
            make.top.equalTo(self.closeButton.mas_bottom).with.offset(SSTopBigElementMargin);
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).with.offset(SSBottomBigElementMargin);
        }];
    }
}

- (void)updateFinalPositionConstraintsForResultViewResultsFound
{
    if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular)
    {
        [self.resultView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view.mas_centerY).with.offset(50);
            make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft).with.offset(4);
            make.right.equalTo(self.view.mas_safeAreaLayoutGuideRight).with.offset(-4);
            make.bottom.equalTo(self.view.mas_bottom).with.offset(-4);
        }];
    }
    else
    {
        [self.resultView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.closeButton.mas_bottom).with.offset(SSTopBigElementMargin);
            make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft).with.offset(4);
            make.right.equalTo(self.view.mas_safeAreaLayoutGuideRight).with.offset(-4);
            make.bottom.equalTo(self.view.mas_bottom).with.offset(-4);
        }];
    }
}

#pragma mark - Capture Logic

- (void)beginCaptureSession
{
    // Capture Setup
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:nil];
    
    if ([self captureAvailable] == NO)
    {
        NSLog(@"Spend Stack - Error in creating an AVCaptureDeviceInput for barcode scanning.");
        self.resultView.layoutState = SSBarcodeSearchLayoutEncounteredError;
        return;
    }
    
    [self.captureSession addInput:videoInput];
    
    AVCaptureMetadataOutput *metadataOutput = [AVCaptureMetadataOutput new];
    [metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [self.captureSession addOutput:metadataOutput];
    metadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code];
    
    // Video feedback
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    self.previewLayer.frame = self.view.bounds;
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:self.previewLayer];
    
    [self.captureSession startRunning];
}

-(void)playDingSound
{
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"ding" ofType:@"m4a"];
    SystemSoundID soundID;
    AudioServicesCreateSystemSoundID((CFURLRef)CFBridgingRetain([NSURL fileURLWithPath: soundPath]), &soundID);
    AudioServicesPlaySystemSound (soundID);
}

#pragma mark - Capture Delly

- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    AVMetadataObject *obj = metadataObjects.firstObject;
    obj = [self.previewLayer transformedMetadataObjectForMetadataObject:obj];
    BOOL withinCaptureBox = CGRectContainsRect(self.captureBox.frame, obj.bounds);
   
    // Outside the area of interest, the scan box
    if (withinCaptureBox == NO) return;
    
    AVMetadataMachineReadableCodeObject *barcode = (AVMetadataMachineReadableCodeObject *)obj;
    if (obj == nil ||
        [barcode isKindOfClass:[AVMetadataMachineReadableCodeObject class]] == NO ||
        [self.barcodes containsObject:barcode.stringValue]) return;

    [self.barcodes addObject:barcode.stringValue];
    [self animateInSearchingBarCode];
    [self fetchBarcode:barcode.stringValue];
}

#pragma mark - Barcode Fetch

- (void)fetchBarcode:(NSString *)barcodeID
{
    // Perform fetch
    [SSBarcodeDataFetcher broadSearchEAN13Code:self.barcodes.firstObject completion:^(SSBarcodeSearchResult *result) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            [self.captureBox endShimmering];
            
            if (result)
            {
                self.result = result;
                [self.resultView showSearchResult:result];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.10f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                    [self updateFinalPositionConstraintsForResultViewResultsFound];
                    
                    __weak typeof(self) weakSelf = self;
                    self.resultView.onAddToList = ^{
                        [weakSelf.delegate ss_requestBarcodeResultAddToList:weakSelf.result
                                                                 controller:weakSelf];
                    };
                    
                    [UIView animateWithDuration:SSFastestAnimationDuration animations:^{
                        self.captureBox.alpha = 0.0f;
                        self.dimView.closeCutOut = YES;
                        [self.dimView setNeedsDisplay];
                        [self.view layoutIfNeeded];
                    }];
                });
            }
            else
            {
                self.resultView.layoutState = SSBarcodeSearchLayoutStateNoResults;
            }
        });
    }];
}

#pragma mark - Enter Price and TextField Delegate

- (void)enterPrice
{
    // Setup dimmer
    __kindof UIView *dimmerView = [SSCitizenship transparentViewIfPossible];
    dimmerView.tag = SS_ENTER_PRICE_DIMMER_TAG;
    [SSCitizenship setViewFadeOutAnimation:dimmerView];
    [self.view addSubview:dimmerView];
    [dimmerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    // Add text field
    [self.view addSubview:self.enterPriceTextField];
    self.enterPriceTextField.alpha = 1.0f;
    
    [self.enterPriceTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.view.mas_leading).with.offset(SSLeftBigElementMargin);
        make.trailing.equalTo(self.view.mas_trailing).with.offset(SSRightBigElementMargin);
        make.centerY.equalTo(self.view.mas_centerY);
    }];
    
    [self.enterPriceTextField becomeFirstResponder];
    [UIView animateWithDuration:SSFastestAnimationDuration animations:^{
        [SSCitizenship setViewFadeInAnimation:dimmerView];
        [self setNeedsStatusBarAppearanceUpdate];
    }];
}

- (void)removeEnterPriceUI
{
    __block __kindof UIView *dimmerView = [self.view viewWithTag:SS_ENTER_PRICE_DIMMER_TAG];
    
    [self.enterPriceTextField resignFirstResponder];
    [self.resultView updateAddPriceButtonText:self.result.price];
    
    [UIView animateWithDuration:SSFastestAnimationDuration animations:^{
        [SSCitizenship setViewFadeOutAnimation:dimmerView];
        self.enterPriceTextField.alpha = 0.0f;
        [self setNeedsStatusBarAppearanceUpdate];
    } completion:^(BOOL finished) {
        if (finished)
        {
            [dimmerView removeFromSuperview];
            [self.enterPriceTextField removeFromSuperview];
            dimmerView = nil;
        }
    }];
}

- (void)textFieldDidChangeNotification:(NSNotification *)note
{
//    SSTextField *changedTextField = note.object;
//    if ([changedTextField isKindOfClass:[SSTextField class]] == NO) return;
//    
//    changedTextField.text = [[self.taxUtil  currencyStringFromInput:changedTextField.text];
//    
//    // Ensure default values
//    NSString *amountAsString = @"0";
//    if (changedTextField.text.length <= 0)
//    {
//        changedTextField.text = [[self.taxUtil  guranteedCurrencyString:@"0"];
//    }
//    else
//    {
//        amountAsString = [changedTextField.text stringByReplacingOccurrencesOfString:self.taxUtil.currencyLocale.currencySymbol withString:@""];
//    }
//    
//    NSDecimalNumber *itemAmount = [[self.taxUtil  priceDecimalFromString:amountAsString];
//    self.result.price = itemAmount;
}

#pragma mark - Animations

- (void)animateInSearchingBarCode
{
    // UI Feedback for captured code
    [UIFeedbackGenerator playFeedbackOfType:SSHapticFeedbackTypeSuccess];
    [self playDingSound];
    
    // Stop video capture
    self.previewLayer.connection.enabled = NO;
    [self.captureBox startShimmering];
    self.resultView.layoutState = SSBarcodeSearchLayoutStateSearching;
}

#pragma mark - Debug

- (void)mockBarcodeFoundAfterThreeSeconds
{
    [self animateInSearchingBarCode];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        SSBarcodeSearchResult *mockedResult = [SSBarcodeSearchResult new];
        mockedResult.title = @"Playstation 5";
        mockedResult.image = [NSURL URLWithString:@"https://www.vgr.com/wp-content/uploads/2018/08/Untitled-1-1200x450.jpg"];
        
        [self.resultView showSearchResult:mockedResult];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.10f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.resultView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.view.mas_centerY).with.offset(50);
                make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft).with.offset(4);
                make.right.equalTo(self.view.mas_safeAreaLayoutGuideRight).with.offset(-4);
                make.bottom.equalTo(self.view.mas_bottom).with.offset(-4);
            }];
            
            [UIView animateWithDuration:SSBriefAnimationDuration animations:^{
                [self.view layoutIfNeeded];
            }];
        });
    });
}

@end
