//
//  SSModalViewController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 4/1/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "SSModalViewController.h"

@interface SSModalViewController ()

@end

@implementation SSModalViewController

#pragma mark - Initializers
- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.view.layer.cornerRadius = 17.0f;
    }
    
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.scrollView = [UIScrollView new];
    [self.view addSubview:self.scrollView];
    
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
        make.right.equalTo(self.view.mas_safeAreaLayoutGuideRight);
    }];
}

@end
