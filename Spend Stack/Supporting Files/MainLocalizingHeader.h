//
//  MainLocalizingHeader.h
//  Spend Stack
//
//  Created by Jordan Morgan on 8/2/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#ifndef MainLocalizingHeader_h
#define MainLocalizingHeader_h
#import <Foundation/Foundation.h>

static inline NSString * _Nonnull ss_Localized(NSString * _Nonnull key) {
    return NSLocalizedString(key, NULL) ?: @"";
}

#endif /* MainLocalizingHeader_h */
