//
//  SSBarcodeStateITemDetailsView.m
//  Spend Stack
//
//  Created by Jordan Morgan on 11/15/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSBarcodeStateItemDetailsView.h"
#import "SSBarcodeSearchResult.h"
#import "SSImageDownloader.h"
#import "UIView+Animations.h"
#import "UIImageView+SSUtils.h"

static const NSInteger SS_IMAGE_WIDTH_HEIGHT = 140;

@interface SSBarcodeStateItemDetailsView()

@property (weak, nonatomic, nullable) SSBarcodeSearchResult *result;
@property (strong, nonatomic, nonnull) UIImageView *itemImgView;
@property (strong, nonatomic, nonnull) SSLabel *itemLabel;
@property (strong, nonatomic, nonnull) SSLabel *bottomLabel;

@end

@implementation SSBarcodeStateItemDetailsView

#pragma mark - Initializer

- (instancetype)initWithSearchResult:(SSBarcodeSearchResult *)result
{
    self = [super init];
    
    if (self)
    {
        self.clipsToBounds = YES;
        
        self.itemImgView = [UIImageView new];
        self.itemImgView.ss_size = CGSizeMake(SS_IMAGE_WIDTH_HEIGHT, SS_IMAGE_WIDTH_HEIGHT);
        self.itemImgView.contentMode = UIViewContentModeScaleAspectFit;
        
        // Shadow
        self.itemImgView.backgroundColor = [UIColor systemBackgroundColor];
        self.itemImgView.layer.cornerRadius= 8.0f;
        self.itemImgView.layer.shadowColor = [UIColor blackColor].CGColor;
        self.itemImgView.layer.shadowOffset = CGSizeMake(8, 8);
        self.itemImgView.layer.shadowRadius = 20.0f;
        self.itemImgView.layer.shadowOpacity = 0.10f;
        
        self.itemLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleTitle2];
        self.itemLabel.text = result.title;
        self.itemLabel.textAlignment = NSTextAlignmentCenter;
        
        self.bottomLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleSubheadline];
        self.bottomLabel.textColor = [UIColor ssPrimaryColor];
        self.bottomLabel.text = @"Enter Price";
        self.bottomLabel.accessibilityTraits = UIAccessibilityTraitButton;
        self.bottomLabel.accessibilityHint = @"Tap to add price to item.";
        self.bottomLabel.textAlignment = NSTextAlignmentCenter;
        [self.bottomLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [self.bottomLabel configureFontWeight:UIFontWeightMedium];
        
        self.bottomLabel.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(notifyEnterPrice)];
        [self.bottomLabel addGestureRecognizer:tap];
        
        BOOL hasImage = result.image;
        
        if (hasImage)
        {
            [self.itemImgView addLoadingShimmer];
            [[SSImageDownloader sharedInstance] dataAtURL:result.image completion:^(NSData *data) {
                CGFloat scale = self.traitCollection.displayScale;
                CGFloat maxPixelSize = SS_IMAGE_WIDTH_HEIGHT * scale;
                result.imageData = data;
                
                dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
                    // Downsample
                    UIImage *downsampledImage = [UIImage downsampledImageFromData:data
                                                                            scale:scale
                                                                     maxPixelSize:maxPixelSize];
                    
                    dispatch_async(dispatch_get_main_queue(), ^ {
                        self.itemImgView.image = downsampledImage;
                        [self.itemImgView removeLoadingShimmer];
                    });
                });
            }];
        }
        
        [self addSubviews:@[self.itemLabel, self.itemImgView, self.bottomLabel]];
        
        [self.itemLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.mas_left).with.offset(SSLeftElementMargin);
            make.top.equalTo(self.mas_top).with.offset(SSTopElementMargin);
            make.right.equalTo(self.mas_right).with.offset(SSRightElementMargin);
            make.height.equalTo(self.itemLabel.mas_height);
        }];
        
        [self.itemImgView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.and.width.equalTo(hasImage ? @(SS_IMAGE_WIDTH_HEIGHT) : @0);
            make.top.equalTo(self.itemLabel.mas_bottom).with.offset(SSTopElementMargin);
            make.centerX.equalTo(self.mas_centerX);
        }];
        
        [self.bottomLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.itemImgView.mas_bottom).with.offset(SSTopElementMargin);
            make.centerX.equalTo(self.mas_centerX);
            make.bottom.equalTo(self.mas_bottom).with.offset(SSBottomElementMargin);
        }];
    }
    
    return self;
}

#pragma mark - Scan Price

- (void)notifyEnterPrice
{
    [UIFeedbackGenerator playFeedbackOfType:SSHapticFeedbackTypeStyleLight];
    [self.bottomLabel dimInFromTapAnimationWithHighlight:SSSpacingMargin];
    __weak typeof(self) weakSelf = self;
    self.bottomLabel.onAnimationFinished = ^{
        if (weakSelf.onEnterPrice) weakSelf.onEnterPrice();
    };
}

- (void)updateButtonText:(NSDecimalNumber *)price
{
//    NSString *buttonText = @"Enter Price";
//    if (price)
//    {
//        buttonText = [self.taxUtil guranteedCurrencyString:price.stringValue];
//        self.bottomLabel.accessibilityHint = [NSString stringWithFormat:@"Price is set to %@. Tap to edit price.", buttonText];
//    }
//    else
//    {
//        self.bottomLabel.accessibilityHint = @"Tap to add price to item.";
//    }
//    
//    self.bottomLabel.text = buttonText;
}

@end
