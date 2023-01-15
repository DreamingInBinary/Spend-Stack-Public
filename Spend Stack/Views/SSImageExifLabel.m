//
//  SSImageExifLabel.m
//  Spend Stack
//
//  Created by Jordan Morgan on 6/8/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSImageExifLabel.h"

@interface SSImageExifLabel()

@property (strong, nonatomic, nullable) NSDictionary *exifInfomation;

@end

@implementation SSImageExifLabel

#pragma mark - Initializer

- (instancetype)initWithTextStyle:(UIFontTextStyle)textStyle image:(UIImage *)image
{
    self = [super initWithTextStyle:textStyle];
    
    if (self)
    {
        NSData *data = UIImageJPEGRepresentation(image, 1.0);
        CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)data, NULL);
        NSDictionary *metadata = (NSDictionary *)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source, 0, NULL));
        self.exifInfomation = metadata;
        
        [self setExifInformationToText];
    }
    
    return self;
}

#pragma mark - Text Setting

- (void)setExifInformationToText
{
    NSMutableString *imageDataString = [NSMutableString new];
    
    // Color Model
    if (isSafe(self.exifInfomation[@"ColorModel"])) {
        [imageDataString appendString:[NSString stringWithFormat:@"Color Model: %@\n", self.exifInfomation[@"ColorModel"]]];
    }

    // Dimensions
    if (isSafe(self.exifInfomation[@"PixelHeight"]) && isSafe(self.exifInfomation[@"PixelWidth"])) {
        [imageDataString appendString:[NSString stringWithFormat:@"Size: %@ x %@", self.exifInfomation[@"PixelWidth"], self.exifInfomation[@"PixelHeight"]]];
    }
    
    self.text = imageDataString;
}

@end
