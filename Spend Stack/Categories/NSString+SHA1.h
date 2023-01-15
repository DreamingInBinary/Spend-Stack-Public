//
//  NSString+SHA1.h
//  DigitEyes
//

#import <Foundation/Foundation.h>

@interface NSString (SHA1)

- (NSString * _Nonnull)hashedValue:(NSString * _Nonnull)key;

@end
