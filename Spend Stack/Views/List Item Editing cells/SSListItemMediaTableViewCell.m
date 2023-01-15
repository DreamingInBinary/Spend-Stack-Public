//
//  SSListItemMediaTableViewCell.m
//  Spend Stack
//
//  Created by Jordan Morgan on 2/23/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSListItemMediaTableViewCell.h"
#import "SSListItemImageView.h"
#import "SSListItemViewController.h"
#import "UITableViewCell+Common.h"
#import <LinkPresentation/LinkPresentation.h>

@interface SSListItemMediaTableViewCell() <UIPointerInteractionDelegate>

@property (strong, nonatomic, readwrite, nonnull) UIActivityIndicatorView *spinner;
@property (strong, nonatomic, readwrite, nonnull) SSLabel *errorLabel;
@property (strong, nonatomic, readwrite, nonnull) SSListItemImageView *mediaImageView;
@property (strong, nonatomic, readwrite, nonnull) LPLinkView *linkView;
@property (strong, nonatomic, readwrite, nonnull) LPMetadataProvider *provider;
@property (nonatomic, getter=hasBegunMetadataFetch) BOOL beganMetadataFetch;
 
@end

@implementation SSListItemMediaTableViewCell

#pragma mark - Custom Setters

- (void)setViewMode:(AttachmentViewMode)viewMode
{
    _viewMode = viewMode;
    if (_errorLabel) _errorLabel.text = viewMode == AttachmentViewModeLink ? ss_Localized(@"listEdit.noLink") : ss_Localized(@"listEdit.noImage");
}

#pragma mark - Initializers

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self)
    {
        self.viewMode = AttachmentViewModeImage;
        
        self.mediaImageView = [SSListItemImageView new];
        self.mediaImageView.clipsToBounds = YES;
        self.mediaImageView.layer.cornerRadius = SSSpacingMargin;
        self.mediaImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.mediaImageView.backgroundColor = [UIColor ssMutedColor];
        [self.mediaImageView addPointerInteractionWithDelegate:self];
        
        self.linkView = [[LPLinkView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
        self.linkView.hidden = YES;
        [self.linkView setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
        [self.linkView setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
        
        [self setupMetadataProvider];
        
        self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        self.spinner.hidden = YES;
        self.spinner.accessibilityLabel = ss_Localized(@"listEdit.loadingImage");
        
        self.errorLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleBody];
        self.errorLabel.text = ss_Localized(@"listEdit.noImage");
        self.errorLabel.hidden = YES;
        self.errorLabel.textAlignment = NSTextAlignmentCenter;
        
        __weak typeof(self) weakSelf = self;
        SSListItemImageViewTapHandler handler = ^ {
            if (weakSelf.mediaImageView.image == nil)
            {
                return;
            }
            
            SSListItemViewController *listItemVC = (SSListItemViewController *)[self closestViewController];
            if ([listItemVC isKindOfClass:[SSListItemViewController class]])
            {
                [listItemVC presentImageViewerWithImageView:weakSelf.mediaImageView];
            }
        };
        
        [self.mediaImageView configureImageViewForTapHandler:handler];
        
        [self.contentView addSubviews:@[self.mediaImageView, self.linkView, self.spinner, self.errorLabel]];
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.dividerView.hidden = YES;
        
        [self setConstraints];
    }
    
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.errorState = NO;
}

- (void)dealloc
{
    if (self.provider)
    {
        [self.provider cancel];
    }
}

#pragma mark - Constraint Handling

- (void)setConstraints
{
    [super setConstraints];
    
    [self.mediaImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView.mas_readableContentGuideLeft);
        make.right.equalTo(self.contentView.mas_readableContentGuideRight);
        make.top.equalTo(self.contentView.mas_top).with.offset(SSTopElementMargin);
        make.bottom.equalTo(self.contentView.mas_bottom).with.offset(SSBottomElementMargin);
        make.height.equalTo(self.mediaImageView.mas_width);
    }];
    
    [self.linkView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.contentView.mas_width);
        make.height.equalTo(self.contentView.mas_height);
        make.centerX.equalTo(self.contentView.mas_centerX);
        make.centerY.equalTo(self.contentView.mas_centerY);
    }];
    
    [self.spinner mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.mediaImageView);
    }];
    
    [self.errorLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.mediaImageView).with.insets(UIEdgeInsetsMake(SSSpacingMargin, SSSpacingMargin, SSSpacingMargin, SSSpacingMargin));
    }];
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

#pragma mark - Public Methods

- (void)setData:(SSListItem *)item list:(SSList * _Nonnull)list
{
    [super setData:item list:list];
    
    if (self.viewMode == AttachmentViewModeImage)
    {
        self.linkView.hidden = YES;
        self.linkView.alpha = 0.0f;
        
        if (item.downsampledMediaImage)
        {
            self.spinner.hidden = YES;
            [self.spinner stopAnimating];
            
            self.errorLabel.hidden = YES;
            
            self.mediaImageView.hidden = NO;
            self.mediaImageView.alpha = 1.0f;
            self.mediaImageView.image = item.downsampledMediaImage;
        }
        else if (self.isInErrorState)
        {
            self.errorLabel.hidden = NO;
            
            self.spinner.hidden = YES;
            [self.spinner stopAnimating];
            
            self.mediaImageView.alpha = 0.0f;
        }
        else
        {
            self.spinner.hidden = NO;
            self.mediaImageView.alpha = 0.5f;
            
            self.errorLabel.hidden = YES;
            
            [self.spinner startAnimating];
        }
    }
    else
    {
        self.mediaImageView.hidden = YES;
        self.spinner.hidden = YES;
        [self.spinner stopAnimating];
        self.errorLabel.hidden = YES;
       
        if (self.hasBegunMetadataFetch == NO && item.linkMetadata == nil)
        {
            NSLog(@"Spend Stack: LinkView fetching link metadata.");
            if ([self linkViewHasPlaceholderMetadata] == NO)
            {
                self.linkView.metadata = [LPLinkMetadata new];
            }
            
            self.beganMetadataFetch = YES;
            self.spinner.hidden = NO;
            [self.spinner startAnimating];
            
            __weak typeof(self) weakSelf = self;
            [self.provider startFetchingMetadataForURL:[NSURL URLWithString:item.linkAttachment] completionHandler:^(LPLinkMetadata *metadata, NSError *error) {
                NSLog(@"Spend Stack: LinkView fetched link metadata: %@ and error: %@", metadata, error);
                dispatch_async(dispatch_get_main_queue(), ^ {
                    if (weakSelf == nil || weakSelf.viewMode == AttachmentViewModeImage)
                    {
                        return;
                    }
                    
                    weakSelf.spinner.hidden = YES;
                    [weakSelf.spinner stopAnimating];
                    
                    if (metadata)
                    {
                        [self.listItem attachLink:metadata.originalURL.absoluteString metaData:metadata];
                        // Update section header and cell
                        [[NSNotificationCenter defaultCenter] postNotificationName:SS_ATTACHMENT_VIEW_MODE_CHANGED object:@(AttachmentViewModeLink)];
                    }
                    else
                    {
                        self.beganMetadataFetch = YES;
                        
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [[NSNotificationCenter defaultCenter] postNotificationName:SS_ATTACHMENT_VIEW_MODE_CHANGED object:@(AttachmentViewModeLink)];
                        });
                    }
                });
            }];
        }
        else if (item.linkMetadata && [self.linkView.metadata isKindOfClass:NSClassFromString(@"LPPlaceholderLinkMetadata")])
        {
            NSLog(@"Spend Stack: LinkView already have link metadata, showing link view.");
            [self positionLinkViewWithMetadata:item.linkMetadata];
            
            // In case they remove a link, and re-add a new one in the same viewing
            self.beganMetadataFetch = NO;
            [self setupMetadataProvider];
        }
        else
        {
            [self setUIForLinkErrorState];
        }
    }
}

- (void)setUIForLinkErrorState
{
    NSLog(@"Spend Stack: LinkView is in error state.");
    self.errorLabel.hidden = NO;
    self.errorState = YES;
    self.beganMetadataFetch = NO;
    [self setupMetadataProvider];
}

- (void)positionLinkViewWithMetadata:(LPLinkMetadata *)metadata
{
    self.linkView = [[LPLinkView alloc] initWithMetadata:metadata];
    [self.contentView addSubview:self.linkView];
    
    [self.linkView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView.mas_readableContentGuideLeft);
        make.right.equalTo(self.contentView.mas_readableContentGuideRight);
        make.top.equalTo(self.contentView.mas_top).with.offset(SSTopElementMargin);
        make.bottom.equalTo(self.contentView.mas_bottom).with.offset(SSBottomElementMargin);
        make.height.equalTo(self.linkView.mas_width);
    }];
}

- (void)setupMetadataProvider
{
    self.provider = [LPMetadataProvider new];
    self.provider.timeout = 10.0f;
}

- (BOOL)linkViewHasPlaceholderMetadata
{
    return [self.linkView.metadata isKindOfClass:NSClassFromString(@"LPPlaceholderLinkMetadata")];
}

@end
