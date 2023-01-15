//
//  SSCountingLabel.m
//  Spend Stack
//
//  Created by Jordan Morgan on 1/14/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSCountingLabel.h"

#ifndef kSSLabelCounterRate
#define kSSLabelCounterRate 3.0
#endif

@protocol SSLabelCounter<NSObject>

-(CGFloat)update:(CGFloat)t;

@end

@interface SSLabelCounterLinear : NSObject<SSLabelCounter>

@end

@interface SSLabelCounterEaseIn : NSObject<SSLabelCounter>

@end

@interface SSLabelCounterEaseOut : NSObject<SSLabelCounter>

@end

@interface SSLabelCounterEaseInOut : NSObject<SSLabelCounter>

@end

@implementation SSLabelCounterLinear

-(CGFloat)update:(CGFloat)t
{
    return t;
}

@end

@implementation SSLabelCounterEaseIn

-(CGFloat)update:(CGFloat)t
{
    return powf(t, kSSLabelCounterRate);
}

@end

@implementation SSLabelCounterEaseOut

-(CGFloat)update:(CGFloat)t{
    return 1.0-powf((1.0-t), kSSLabelCounterRate);
}

@end

@implementation SSLabelCounterEaseInOut

-(CGFloat) update: (CGFloat) t
{
    t *= 2;
    if (t < 1)
        return 0.5f * powf (t, kSSLabelCounterRate);
    else
        return 0.5f * (2.0f - powf(2.0 - t, kSSLabelCounterRate));
}

@end

#pragma mark - SSCountingLabel

@interface SSCountingLabel ()

@property CGFloat startingValue;
@property CGFloat destinationValue;
@property NSTimeInterval progress;
@property NSTimeInterval lastUpdate;
@property NSTimeInterval totalTime;
@property CGFloat easingRate;

@property (nonatomic, strong, nullable) CADisplayLink *timer;
@property (nonatomic, strong, nullable) id<SSLabelCounter> counter;

@end

@implementation SSCountingLabel

#pragma mark - Initializer

- (instancetype)initWithTextStyle:(UIFontTextStyle)textStyle
{
    self = [super initWithTextStyle:textStyle];
    return self;
}

#pragma mark - Counting

-(void)countFrom:(CGFloat)value to:(CGFloat)endValue
{
    [self countFrom:value to:endValue withDuration:self.animationDuration];
}

-(void)countFrom:(CGFloat)startValue to:(CGFloat)endValue withDuration:(NSTimeInterval)duration
{
    
    self.startingValue = startValue;
    self.destinationValue = endValue;
    
    // remove any (possible) old timers
    [self.timer invalidate];
    self.timer = nil;
    
    if (duration == 0.0 || [SSCitizenship lowPowerOn])
    {
        NSLog(@"Spend Stack - Low power mode is on, skipping counting label animation.");
        // No animation
        [self setTextValue:endValue];
        [self runCompletionBlock];
        return;
    }
    
    self.easingRate = 3.0f;
    self.progress = 0;
    self.totalTime = duration;
    self.lastUpdate = [NSDate timeIntervalSinceReferenceDate];
    
    if(self.format == nil)
        self.format = @"%f";
    
    switch(self.method)
    {
        case SSLabelCountingMethodLinear:
            self.counter = [[SSLabelCounterLinear alloc] init];
            break;
        case SSLabelCountingMethodEaseIn:
            self.counter = [[SSLabelCounterEaseIn alloc] init];
            break;
        case SSLabelCountingMethodEaseOut:
            self.counter = [[SSLabelCounterEaseOut alloc] init];
            break;
        case SSLabelCountingMethodEaseInOut:
            self.counter = [[SSLabelCounterEaseInOut alloc] init];
            break;
    }
    
    CADisplayLink *timer = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateValue:)];
    timer.preferredFramesPerSecond = 60;
    [timer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [timer addToRunLoop:[NSRunLoop mainRunLoop] forMode:UITrackingRunLoopMode];
    self.timer = timer;
}

- (void)countFromCurrentValueTo:(CGFloat)endValue
{
    [self countFrom:[self currentValue] to:endValue];
}

- (void)countFromCurrentValueTo:(CGFloat)endValue withDuration:(NSTimeInterval)duration
{
    [self countFrom:[self currentValue] to:endValue withDuration:duration];
}

- (void)countFromZeroTo:(CGFloat)endValue
{
    [self countFrom:0.0f to:endValue];
}

- (void)countFromZeroTo:(CGFloat)endValue withDuration:(NSTimeInterval)duration
{
    [self countFrom:0.0f to:endValue withDuration:duration];
}

- (void)updateValue:(NSTimer *)timer
{
    // update progress
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    self.progress += now - self.lastUpdate;
    self.lastUpdate = now;
    
    if (self.progress >= self.totalTime) {
        [self.timer invalidate];
        self.timer = nil;
        self.progress = self.totalTime;
    }
    
    [self setTextValue:[self currentValue]];
    
    if (self.progress == self.totalTime) {
        [self runCompletionBlock];
    }
}

- (void)setTextValue:(CGFloat)value
{
    if (self.attributedFormatBlock != nil)
    {
        self.attributedText = self.attributedFormatBlock(value);
    }
    else if(self.formatBlock != nil)
    {
        self.text = self.formatBlock(value);
    }
    else
    {
        // Check if counting with ints - cast to int
        if([self.format rangeOfString:@"%(.*)d" options:NSRegularExpressionSearch].location != NSNotFound || [self.format rangeOfString:@"%(.*)i"].location != NSNotFound )
        {
            self.text = [NSString stringWithFormat:self.format,(int)value];
        }
        else
        {
            self.text = [NSString stringWithFormat:self.format,value];
        }
    }
}

- (void)setFormat:(NSString *)format
{
    _format = format;
    // update label with new format
    [self setTextValue:self.currentValue];
}

- (void)runCompletionBlock
{
    
    if (self.completionBlock)
    {
        self.completionBlock();
        self.completionBlock = nil;
    }
}

- (CGFloat)currentValue
{
    
    if (self.progress >= self.totalTime)
    {
        return self.destinationValue;
    }
    
    CGFloat percent = self.progress / self.totalTime;
    CGFloat updateVal = [self.counter update:percent];
    return self.startingValue + (updateVal * (self.destinationValue - self.startingValue));
}

- (void)updateCurrentValue:(CGFloat)currentValue
{
    _destinationValue = currentValue;
}

@end
