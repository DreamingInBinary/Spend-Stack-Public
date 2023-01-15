//
//  NSString+SHA1.m
//  DigitEyes
//

#import "NSString+SHA1.h"
#import <CommonCrypto/CommonHMAC.h>

@implementation NSString (SHA1)

- (NSString *)hashedValue:(NSString *)key
{
    const char *cKey  = [key cStringUsingEncoding:NSUTF8StringEncoding];
    const char *cData = [self cStringUsingEncoding:NSUTF8StringEncoding];
    
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    
    NSString *hash = [HMAC base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    
    return hash;
}

@end
