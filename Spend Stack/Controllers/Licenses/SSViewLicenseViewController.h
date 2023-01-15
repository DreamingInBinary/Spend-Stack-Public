//
//  SSViewLicenseViewController.h
//  Spend Stack
//
//  Created by Jordan Morgan on 4/26/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "SSBaseViewController.h"

typedef NS_ENUM(NSUInteger, License) {
    LicenseMasonry,
    LicenseFMDB,
    LicenseIGListKit
};

@interface SSViewLicenseViewController : SSBaseViewController

- (instancetype _Nonnull)initWithLicense:(License)license;

@end
