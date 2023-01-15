//
//  SSVerticalViewController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 11/12/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSVerticalViewController.h"
#import "SSVerticalView.h"

@interface SSVerticalViewController ()

@end

@implementation SSVerticalViewController

#pragma mark - Initializer

- (instancetype)init
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self)
    {
        self.stackView = [SSVerticalView new];
    }
    
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view addSubview:self.stackView];
    
    [self.stackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft);
        make.right.equalTo(self.view.mas_safeAreaLayoutGuideRight);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
    }];
}
@end
